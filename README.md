# Redis on Unikraft

This application starts a Redis server.

To configure, build and run the application you need to have [kraft](https://github.com/unikraft/kraft) installed.

To be able to interact with the server, configure the application to run on the KVM platform:
```
$ kraft configure -p kvm -m x86_64
```

Build the application:
```
$ kraft build
```

We use a virtual bridge to create a connection between the VM and the host system.
We assign address `172.44.0.1/24` to the bridge interface (pointing to the host) and we assign address `172.44.0.2/24` to the virtual machine, by passing boot arguments.
The IP addresses are of our choosing, they can be changed to other values.

We run the commands below to create and assign the IP address to the bridge `virbr0` (once again, our choice of name; any name works):
```
$ sudo brctl addbr virbr0
$ sudo ip a a  172.44.0.1/24 dev virbr0
$ sudo ip l set dev virbr0 up
```

We can check the proper configuration:
```
$ ip a s virbr0
420: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 3a:3e:88:e6:a1:e4 brd ff:ff:ff:ff:ff:ff
    inet 172.44.0.1/24 scope global virbr0
       valid_lft forever preferred_lft forever
    inet6 fe80::383e:88ff:fee6:a1e4/64 scope link
       valid_lft forever preferred_lft forever
```

Now we start the virtual machine and pass it the proper arguments to assign the IP address `172.44.0.2/24`:
```
$ kraft run -b virbr0 "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- /redis.conf"
[...]
0: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en0: Added
en0: Interface is up
[...]
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 5.0.6 (c5ee3442/1) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 1
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _ 
 |    `-._`-._        _.-'_.-'    |           http://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'
[...]
```

The boot message confirms the assigning of the `172.44.0.2/24` IP address to the virtual machine.
We use `ping` to validate it's working properly:
```
$  ping 172.44.0.2 -c5
PING 172.44.0.2 (172.44.0.2) 56(84) bytes of data.
64 bytes from 172.44.0.2: icmp_seq=1 ttl=255 time=0.155 ms
64 bytes from 172.44.0.2: icmp_seq=2 ttl=255 time=0.172 ms
64 bytes from 172.44.0.2: icmp_seq=3 ttl=255 time=0.193 ms
64 bytes from 172.44.0.2: icmp_seq=4 ttl=255 time=0.166 ms
64 bytes from 172.44.0.2: icmp_seq=5 ttl=255 time=0.688 ms
[...]
```

Cleaning up means closing the virtual machine (and the server) and disabling and deleting the bridge interface:
```
$ sudo ip l set dev virbr0 down
$ sudo brctl delbr virbr0
```

If you want to have more control you can also configure, build and run the application manually.

To configure it for the KVM platform:
```
$ make menuconfig
```

Be aware of the fact that you'll have to choose a file system: for instance, from the `vfscore` library, choose the `Default root filesystem` to be `9pfs`.

If you are going to use the `qemu-guest` script or `kraft` to launch the app, you need to name the `Default root device` `fs0` (`Library Configuration` -> `vfscore` -> `Default root device`).
This is due to how the `qemu-guest` script and `kraft` automatically tag the FS devices attached to `qemu`.

Build the application:
```
$ make
```

Run the application:
```
sudo qemu-system-x86_64 -fsdev local,id=myid,path=$(pwd)/fs0,security_model=none \
                        -device virtio-9p-pci,fsdev=myid,mount_tag=fs0,disable-modern=on,disable-legacy=off \
                        -netdev bridge,id=en0,br=virbr0 \
                        -device virtio-net-pci,netdev=en0 \
                        -kernel "build/app-redis_qemu-x86_64" \
                        -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- /redis.conf" \
                        -cpu host \
                        -enable-kvm \
                        -nographic
```


For more information about `kraft` type ```kraft -h``` or read the
[documentation](http://docs.unikraft.org).
