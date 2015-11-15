netns
=====
netns is a utility that allows you to quickly setup a network namespace. It was
written for the purpose of capturing network traffic from a single application
(using tcpdump / dumpcap).

When a network namespace is started, all commands used to set this up are
printed.

To execute commands inside this network namespace, use the `netns exec` command
which will use `socat` to make the external DBus session visible inside this
application (see `env.sh`). Adjust that file as needed.

Example
-------

Start network namespace:

    peter@al:~$ sudo ~/netns/netns 0 start
    # ip netns add netns0
    # ip link add veth0 type veth peer name veth1
    # ip link set veth1 netns netns0
    # ip link set veth0 up
    # ip addr add 10.9.0.1/24 dev veth0
    # ip netns exec netns0 ip link set veth1 up
    # ip netns exec netns0 ip addr add 10.9.0.2/24 dev veth1
    # ip netns exec netns0 ip route add default via 10.9.0.1 dev veth1
    # iptables -t nat -A POSTROUTING -o veth0 -j MASQUERADE
    # iptables -A FORWARD -i veth0 -j ACCEPT
    # iptables -A FORWARD -o veth0 -j ACCEPT
    # Done!

    peter@al:~$ ip addr show veth0
    14: veth0@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 36:13:bd:c5:2f:e8 brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 10.9.0.1/24 scope global veth0
           valid_lft forever preferred_lft forever
        inet6 fe80::3413:bdff:fec5:2fe8/64 scope link
           valid_lft forever preferred_lft forever

Enter the network namespace. It uses sudo to change the user back to the
original user:

    peter@al:~$ sudo ~/netns/netns 0 exec

    (netns0)peter@al:~$ whoami
    peter

    (netns0)peter@al:~$ ip addr show veth1
    13: veth1@if14: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 26:01:ad:ba:a1:ee brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 10.9.0.2/24 scope global veth1
           valid_lft forever preferred_lft forever
        inet6 fe80::2401:adff:feba:a1ee/64 scope link
           valid_lft forever preferred_lft forever


Run it without arguments to get usage information:

    peter@al:~$ ~/netns/netns
    Usage: netns ns-no [dry-]{start|stop}
           netns ns-no status
           netns ns-no exec [command [command args]]

    The namespace number must be between 0 and 255 (inclusive)
    For namespace number 4, the layout will be:

      (host)      veth8 (10.9.4.1)
                    |
               [ netns: ns4 ]
                    |
    (namespace)   veth9 (10.9.4.2)

bash prompt
-----------
To help you identify whether your shell is in a namespace, you can look at the
output of `ip link`.

For your convenience, you can also make the prompt display the network namespace
name by putting this in your `~/.bashrc`:

    _ns_name=$(ip netns identify 2>/dev/null)
    PS1=${_ns_name:+(${_ns_name})}${PS1}
    unset _ns_name

To use the `ip netns identify` command as a regular user, the permissions of
`/var/run/netns` need to be adjusted. For example:

    sudo setfacl -m u:$USER:rx /var/run/netns

