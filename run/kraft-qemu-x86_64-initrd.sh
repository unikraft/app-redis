#!/bin/sh

sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo kraft net create -n 172.44.0.1/24 virbr0

sudo kraft run -W --target redis-qemu-x86_64-initrd --network bridge:virbr0 -M 128M --initrd fs0/ -a netdev.ipv4_addr=172.44.0.2 -a netdev.ipv4_gw_addr=172.44.0.1 -a netdev.ipv4_subnet_mask=255.255.255.0 -- /redis.conf
