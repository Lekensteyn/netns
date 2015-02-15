
# Tries to find the D-Bus session bus address, listening on a Unix domain socket
# as needed.
dbus_addr() {
    local user home x_display dbus_file abstract_path
    user=${SUDO_USER:-$(id -u)}

    # Only start socat if not running as root.
    if [[ $user == root ]]; then
        return
    fi

    # Find dbus session bus path
    home=$(getent passwd "$user" | cut -d: -f6)
    x_display=${DISPLAY:-:0}
    x_display=${x_display#*:}
    x_display=${x_display%.*}
    dbus_file="$home/.dbus/session-bus/$(cat /etc/machine-id)-${x_display}"

    env_re='^DBUS_SESSION_BUS_ADDRESS=unix:abstract=\K/tmp/dbus-[a-zA-Z0-9]+'

    abstract_path=
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -e "$dbus_file" ]; then
        abstract_path=$(grep -Po -m1 "$env_re" "$dbus_file") || :
    fi
    if [ -z "${abstract_path}" ]; then
        abstract_path=$(env | grep -Po -m1 "$env_re") || :
    fi

    # Hurrah! Found a Unix domain socket!
    if [ -n "${abstract_path}" ]; then
        # If the dbus session bus address is found, try to listen on a named
        # Unix domain socket (if not already). This ensures that it is visible
        # in the net namespace.
        if ! [ -e "${abstract_path}" ]; then
            sudo -u "$user" \
            socat UNIX-LISTEN:$abstract_path,fork \
                  ABSTRACT-CONNECT:$abstract_path >&2 &
        fi
        export DBUS_SESSION_BUS_ADDRESS=unix:path=$abstract_path
    fi
}

# Only try to find the dbus session address when running outside the netns.
# If inside the netns, the parent could be determined, and then a swap using
# /proc/xxx/ns/net could be done, but that is ugly.
[ -n "$(ip netns identify)" ] || dbus_addr
