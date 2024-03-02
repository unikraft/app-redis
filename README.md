**This repository is no longer maintained.
Please visit the [application catalog](https://github.com/unikraft/catalog/tree/main/library/redis/7.0).**

# Redis on Unikraft

This application starts a Redis web server with Unikraft.
Follow the instructions below to set up, configure, build and run Redis.

To get started immediately, you can use Unikraft's companion command-line companion tool, [`kraft`](https://github.com/unikraft/kraftkit).
Start by running the interactive installer:

```console
curl --proto '=https' --tlsv1.2 -sSf https://get.kraftkit.sh | sudo sh
```

Once installed, clone [this repository](https://github.com/unikraft/app-redis) and run `kraft build`:

```console
git clone https://github.com/unikraft/app-redis redis
cd redis/
kraft build
```

This will guide you through an interactive build process where you can select one of the available targets (architecture/platform combinations).
Otherwise, we recommend building for `qemu/x86_64` like so:

```console
kraft build --target redis-qemu-x86_64-initrd
```

Once built, you can instantiate the unikernel via:

```console
kraft run --target redis-qemu-x86_64-initrd --initrd ./rootfs -p 6379:6379 -- /redis.conf
```

If you don't have KVM support (such as when running inside a virtual machine), pass the `-W` option to `kraft run` to disable virtualization support:

```console
kraft run -W --target redis-qemu-x86_64-initrd --initrd ./rootfs -p 6379:6379 -- /redis.conf
```

When left without the `--target` argument, you'll be queried for the desired target from the list.

To test if the Unikraft instance of the Redis server works, open another console and use the `redis-cli` command below to query the server:

```console
redis-cli -h localhost
```

You can test it using `set/get` commands:

```text
127.0.0.1:6379> set a 1
OK
127.0.0.1:6379> get a
"1"
127.0.0.1:6379>
```

## Quick Setup (aka TLDR)

For a quick setup, run the commands below.
Note that you still need to install the [requirements](#requirements).

For building and running everything for `x86_64`, follow the steps below:

```console
git clone https://github.com/unikraft/app-redis redis
cd redis/
./scripts/setup.sh
wget https://raw.githubusercontent.com/unikraft/app-testing/staging/scripts/generate.py -O scripts/generate.py
chmod a+x scripts/generate.py
./scripts/generate.py
./scripts/build/make-qemu-x86_64-9pfs.sh
./scripts/run/qemu-x86_64-9pfs.sh
```

This will configure, build and run the `redis` server, that can be tested using the instructions in the [running section](#run).

Close the QEMU instance by using the `Ctrl+a x` keyboard combination.
That is, press `Ctrl` and `a` simultaneously, then release and press `x`.

Information about every step is detailed below.

## Requirements

In order to set up, configure, build and run Redis on Unikraft, the following packages are required:

* `build-essential` / `base-devel` / `@development-tools` (the meta-package that includes `make`, `gcc` and other development-related packages)
* `flex`
* `bison`
* `git`
* `wget`
* `uuid-runtime`
* `qemu-system-x86`
* `qemu-system-arm`
* `redis-tools`
* `qemu-kvm`
* `sgabios`
* `gcc-aarch64-linux-gnu`
* `redis-tools`

GCC >= 8 is required to build Redis on Unikraft.

On Ubuntu/Debian or other `apt`-based distributions, run the following command to install the requirements:

```console
sudo apt install -y --no-install-recommends \
  build-essential \
  gcc-aarch64-linux-gnu \
  libncurses-dev \
  libyaml-dev \
  flex \
  bison \
  git \
  wget \
  uuid-runtime \
  qemu-kvm \
  qemu-system-x86 \
  qemu-system-arm \
  redis-tools \
  sgabios \
  redis-tools
```

Running Redis Unikraft with QEMU requires networking support.
For this to work properly a specific configuration must be enabled for QEMU.
Run the commands below to enable that configuration (for the network bridge to work):

```console
sudo mkdir /etc/qemu/
echo "allow all" | sudo tee /etc/qemu/bridge.conf
```

### Set Up

The following repositories are required for Redis:

* The application repository (this repository): [`app-redis`](https://github.com/unikraft/app-redis)
* The Unikraft core repository: [`unikraft`](https://github.com/unikraft/unikraft)
* Library repositories:
  * The Redis "library" repository: [`lib-redis`](https://github.com/unikraft/lib-redis)
  * The standard C library: [`lib-musl`](https://github.com/unikraft/lib-musl)
  * The networking stack library: [`lib-lwip`](https://github.com/unikraft/lib-lwip)

Follow the steps below for the setup:

  1. First clone the [`app-redis` repository](https://github.com/unikraft/app-redis) in the `redis/` directory:

     ```console
     git clone https://github.com/unikraft/app-redis redis
     ```

     Enter the `redis/` directory:

     ```console
     cd redis/
     ls -F
     ```

      This will print the contents of the repository.

     ```text
     defconfigs/  kraft.cloud.yaml  kraft.yaml  Makefile  Makefile.uk  README.md  rootfs/  scripts/
     ```

  1. While inside the `redis/` directory, clone all required repositories by using the `setup.sh` script:

     ```console
     ./scripts/setup.sh
     ```

  1. Use the `tree` command to inspect the contents of the `workdir/` directory.

     ```console
     tree -F -L 2 workdir/
     ```

     The layout of the `workdir/` directory should look something like this:

     ```text
     workdir/
     |-- libs/
     |   |-- lwip/
     |   |-- musl/
     |   `-- redis/
     `-- unikraft/
         |-- arch/
         |-- Config.uk
         |-- CONTRIBUTING.md
         |-- COPYING.md
         |-- include/
         |-- lib/
         |-- Makefile
         |-- Makefile.uk
         |-- plat/
         |-- README.md
         |-- support/
         `-- version.mk

     10 directories, 7 files
     ```

## Scripted Building and Running

To build and run Unikraft images, it's easiest to generate build and running scripts and use those.

### Set Up

First of all, grab the [`generate.py` script](https://github.com/unikraft/app-testing/blob/staging/scripts/generate.py) and place it in the `scripts/` directory by running:

```console
wget https://raw.githubusercontent.com/unikraft/app-testing/staging/scripts/generate.py -O scripts/generate.py
chmod a+x scripts/generate.py
```

Now, run the `generate.py` script.
You must run it in the root directory of this repository:

```console
./scripts/generate.py
```

Running the script will generate build and run scripts in the `scripts/build/` and the `scripts/run/` directories:

```text
scripts/
|-- build/
|   |-- kraft-fc-arm64-initrd.sh*
|   |-- kraft-fc-x86_64-initrd.sh*
|   |-- kraft-qemu-arm64-9pfs.sh*
|   |-- kraft-qemu-arm64-initrd.sh*
|   |-- kraft-qemu-x86_64-9pfs.sh*
|   |-- kraft-qemu-x86_64-initrd.sh*
|   |-- make-fc-arm64-initrd.sh*
|   |-- make-fc-x86_64-initrd.sh*
|   |-- make-qemu-arm64-9pfs.sh*
|   |-- make-qemu-arm64-initrd.sh*
|   |-- make-qemu-x86_64-9pfs.sh*
|   `-- make-qemu-x86_64-initrd.sh*
|-- generate.py*
|-- run/
|   |-- fc-arm64-initrd.json
|   |-- fc-arm64-initrd.sh*
|   |-- fc-x86_64-initrd.json
|   |-- fc-x86_64-initrd.sh*
|   |-- kraft-fc-arm64-initrd.sh*
|   |-- kraft-fc-x86_64-initrd.sh*
|   |-- kraft-qemu-arm64-9pfs.sh*
|   |-- kraft-qemu-arm64-initrd.sh*
|   |-- kraft-qemu-x86_64-9pfs.sh*
|   |-- kraft-qemu-x86_64-initrd.sh*
|   |-- qemu-arm64-9pfs.sh*
|   |-- qemu-arm64-initrd.sh*
|   |-- qemu-x86_64-9pfs.sh*
|   `-- qemu-x86_64-initrd.sh*
|-- run.yaml
`-- setup.sh*
```

They are shell scripts, so you can use an editor or a text viewer to check their contents:

```console
cat scripts/run/qemu-x86_64-9pfs.sh
```

### Build and Run

You can now build and run images for different configurations

For example, to build and run for Firecracker on x86_64, run:

```console
./scripts/build/make-fc-x86_64-initrd.sh
./scripts/run/fc-x86_64-initrd.sh
```

To build and run for QEMU on x86_64 using KraftKit, run:

```console
./scripts/build/kraft-qemu-x86_64-9pfs.sh
./scripts/run/kraft-qemu-x86_64-9pfs.sh
```

The run script will start a Redis server.
Note that, currently (release 0.14), there is not yet networking support in Unikraft for Firecracker, so Redis cannot be properly used.

You should now see the Redis server banner:

```text
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
             Prometheus 0.14.0~a45354b4
1:C 06 Jan 1992 19:04:00.012 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
1:C 06 Jan 1992 19:04:00.013 # Redis version=7.0.11, bits=64, commit=c5ee3442, modified=1, pid=1, just started
1:C 06 Jan 1992 19:04:00.015 # Configuration loaded
[    0.137956] ERR:  [libposix_process] <deprecated.c @  348> Ignore updating resource 7: cur = 10032, max = 10032
1:M 06 Jan 1992 19:04:00.039 * Increased maximum number of open files to 10032 (it was originally set to 1024).
1:M 06 Jan 1992 19:04:00.041 * monotonic clock: POSIX clock_gettime
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 7.0.11 (c5ee3442/1) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 1
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           https://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

1:M 06 Jan 1992 19:04:00.061 # WARNING: The TCP backlog setting of 511 cannot be enforced because SOMAXCONN is set to the lower value of 128.
1:M 06 Jan 1992 19:04:00.063 # Server initialized
1:M 06 Jan 1992 19:04:00.072 * Ready to accept connections
```

### Use

The server listens for connections on the `172.44.0.2` address advertised.
A Redis client (such as
[`redis-cli`](https://github.com/unikraft/summer-of-code-2021/blob/main/content/en/docs/sessions/04-complex-applications/sol/03-set-up-and-run-redis/redis-cli))
is required to query the server.

To test if the Unikraft instance of the Redis server works, open another console and use the `redis-cli` command below to query the server:

```console
redis-cli -h 172.44.0.2
```

You can test it using `set/get` commands:

```text
172.44.0.2:6379> set a 1
OK
172.44.0.2:6379> get a
"1"
172.44.0.2:6379>
```

### Stop

To close the QEMU Redis server, use the `Ctrl+a x` keyboard shortcut;
that is press the `Ctrl` and `a` keys at the same time and then, separately, press the `x` key.

Close KraftKit-opened instances by running `Ctrl+c`.
Then, check the open instances by using `kraft ps` or `sudo kraft ps.
Stop the instances by running `kraft stop <instance-id>`.

Close the QEMU instance by using the `Ctrl+a x` keyboard combination.
That is, press `Ctrl` and `a` simultaneously, then release and press `x`.

For Firecracker, you would have to kill the process by issuing a command.
Simplest is to open up another console and run:

```console
pkill -f firecracker
```

## Detailed Steps

### Configure

Configuring, building and running a Unikraft application depends on our choice of platform and architecture.
Currently, supported platforms are QEMU (KVM), Xen and linuxu.
QEMU (KVM) is known to be working, so we focus on that.

Supported architectures are x86_64 and AArch64.

Use the corresponding the configuration files (`config-...`), according to your choice of platform and architecture.

#### QEMU x86_64

Use the `defconfigs/qemu-x86_64-9pfs` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/defconfigs/qemu-x86_64-9pfs make defconfig
```

This results in the creation of the `.config` file:

```console
ls .config
.config
```

The `.config` file will be used in the build step.

#### QEMU AArch64

Use the `defconfigs/qemu-arm64-9pfs` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/defconfigs/qemu-arm64-9pfs make defconfig
```

Similar to the x86_64 configuration, this results in the creation of the `.config` file that will be used in the build step.

### Build

Building uses as input the `.config` file from above, and results in a unikernel image as output.
The unikernel output image, together with intermediary build files, are stored in the `workdir/build/` directory.

#### Clean Up

Before starting a build on a different platform or architecture, you must clean up the build output.
This may also be required in case of a new configuration.

Cleaning up is done with 3 possible commands:

* `make clean`: cleans all actual build output files (binary files, including the unikernel image)
* `make properclean`: removes the entire `workdir/build/` directory
* `make distclean`: removes the entire `workdir/build/` directory **and** the `.config` file

Typically, you would use `make properclean` to remove all build artifacts, but keep the configuration file.

#### QEMU x86_64

Building for QEMU x86_64 assumes you did the QEMU x86_64 configuration step above.
Build the Unikraft Redis image for QEMU x86_64 by using the commands below:

```console
make prepare
make -j $(nproc)
```

You will see a list of all files generated by the build system.

```text
[...]
  LD      redis_qemu-x86_64.dbg
  UKBI    redis_qemu-x86_64.dbg.bootinfo
  SCSTRIP redis_qemu-x86_64
  GZ      redis_qemu-x86_64.gz
make[1]: Leaving directory '/media/razvan/c4f6765a-efa5-4ebd-9cf0-7da9908a0189/razvan/unikraft/solo/redis/workdir/unikraft'
```

At the end of the build command, the `redis_qemu-x86_64` unikernel image is generated.
This image is to be used in the run step.

#### QEMU AArch64

If you had configured and build a unikernel image for another platform or architecture (such as x86_64) before, then:

1. Do a cleanup step with `make properclean`.

1. Configure for QEMU AAarch64, as shown above.

1. Follow the instructions below to build for QEMU AArch64.

Building for QEMU AArch64 assumes you did the QEMU AArch64 configuration step above.
Build the Unikraft Redis image for QEMU AArch64 by using the same command as for x86_64:

```console
make prepare
make -j $(nproc)
```

Similar to the x86_64 build, you will see a list of all files generated by the build system.

```text
[...]
  LD      redis_qemu-arm64.dbg
  UKBI    redis_qemu-arm64.dbg.bootinfo
  SCSTRIP redis_qemu-arm64
  GZ      redis_qemu-arm64.gz
make[1]: Leaving directory '/media/razvan/c4f6765a-efa5-4ebd-9cf0-7da9908a0189/razvan/unikraft/solo/redis/workdir/unikraft
```

Similarly to x86_64, at the end of the build command, the `redis_qemu-arm64` unikernel image is generated.
This image is to be used in the run step.

### Run

#### QEMU x86_64

To run the QEMU x86_64 build, use commands below to create a network setup and then start a Redis Unikraft instance:

```console
sudo ip link set dev tap0 down 2> /dev/null
sudo ip link del dev tap0 2> /dev/null
sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo ip link add dev virbr0 type bridge
sudo ip address add 172.44.0.1/24 dev virbr0
sudo ip link set dev virbr0 up
sudo qemu-system-x86_64 \
    -kernel "$kernel" \
    -nographic \
    -m 256M \
    -netdev bridge,id=en0,br=virbr0 -device virtio-net-pci,netdev=en0 \
    -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- $cmd" \
    -fsdev local,id=myid,path="$rootfs",security_model=none \
    -device virtio-9p-pci,fsdev=myid,mount_tag=fs1,disable-modern=on,disable-legacy=off \
    -cpu max
```

The server listens for connections on the `172.44.0.2` address advertised.
To test / use the server, follow the instructions in the ["Use" section](#use).

To close the QEMU Redis server, use the `Ctrl+a x` keyboard shortcut;
that is press the `Ctrl` and `a` keys at the same time and then, separately, press the `x` key.

#### QEMU AArch64

To run the QEMU x86_64 build, use commands below to create a network setup and then start a Redis Unikraft instance:

```console
sudo ip link set dev tap0 down 2> /dev/null
sudo ip link del dev tap0 2> /dev/null
sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo ip link add dev virbr0 type bridge
sudo ip address add 172.44.0.1/24 dev virbr0
sudo ip link set dev virbr0 up
sudo qemu-system-aarch64 \
    -machine virt \
    -kernel "$kernel" \
    -nographic \
    -m 256M \
    -netdev bridge,id=en0,br=virbr0 -device virtio-net-pci,netdev=en0 \
    -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- $cmd" \
    -fsdev local,id=myid,path="$rootfs",security_model=none \
    -device virtio-9p-pci,fsdev=myid,mount_tag=fs1,disable-modern=on,disable-legacy=off \
    -cpu max
```

The server listens for connections on the `172.44.0.2` address advertised.
To test / use the server, follow the instructions in the ["Use" section](#use).

To close the QEMU Redis server, use the `Ctrl+a x` keyboard shortcut;
that is press the `Ctrl` and `a` keys at the same time and then, separately, press the `x` key.

### Building and Running with initrd

The examples above use 9pfs as the filesystem interface.
Clean up the previous configuration, use the initrd configuration and build the unikernel by using the commands:

```console
make distclean
UK_DEFCONFIG=$(pwd)/defconfigs/qemu-x86_64-initrd make defconfig
make prepare
make -j $(nproc)
```

To run the QEMU x86_64 initrd build, use the commands below:

```console
old="$PWD"
cd "$rootfs"
find -depth -print | tac | bsdcpio -o --format newc > "$old"/rootfs.cpio
cd "$old"
sudo ip link set dev tap0 down 2> /dev/null
sudo ip link del dev tap0 2> /dev/null
sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo ip link add dev virbr0 type bridge
sudo ip address add 172.44.0.1/24 dev virbr0
sudo ip link set dev virbr0 up
sudo qemu-system-x86_64 \
    -kernel "$kernel" \
    -nographic \
    -m 256M \
    -netdev bridge,id=en0,br=virbr0 -device virtio-net-pci,netdev=en0 \
    -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- $cmd" \
    -initrd "$PWD"/rootfs.cpio \
    -cpu max
```

The commands for AArch64 are similar:

```console
make distclean
UK_DEFCONFIG=$(pwd)/defconfigs/qemu-arm64-initrd make defconfig
make prepare
make -j $(nproc)
old="$PWD"
cd "$rootfs"
find -depth -print | tac | bsdcpio -o --format newc > "$old"/rootfs.cpio
cd "$old"
sudo ip link set dev tap0 down 2> /dev/null
sudo ip link del dev tap0 2> /dev/null
sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo ip link add dev virbr0 type bridge
sudo ip address add 172.44.0.1/24 dev virbr0
sudo ip link set dev virbr0 up
sudo qemu-system-aarch64 \
    -machine virt \
    -kernel "$kernel" \
    -nographic \
    -m 256M \
    -netdev bridge,id=en0,br=virbr0 -device virtio-net-pci,netdev=en0 \
    -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- $cmd" \
    -initrd "$PWD"/rootfs.cpio \
    -cpu max
```

### Building and Running with Firecracker

[Firecracker](https://firecracker-microvm.github.io/) is a lightweight VMM (*virtual machine manager*) that can be used as more efficient alternative to QEMU.

Configure and build commands are similar to a QEMU-based build with an initrd-based filesystem:

```console
make distclean
UK_DEFCONFIG=$(pwd)/defconfigs/fc-x86_64-initrd make defconfig
make prepare
make -j $(nproc)
```

To use Firecraker, you need to download a [Firecracker release](https://github.com/firecracker-microvm/firecracker/releases).
You can use the commands below to make the `firecracker-x86_64` executable from release v1.4.0 available globally in the command line:

```console
cd /tmp
wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.4.0/firecracker-v1.4.0-x86_64.tgz
tar xzf firecracker-v1.4.0-x86_64.tgz
sudo cp release-v1.4.0-x86_64/firecracker-v1.4.0-x86_64 /usr/local/bin/firecracker-x86_64
```

To run a unikernel image, you need to configure a JSON file.
The generated JSON file for Firecraker on x86_64 is located in `scripts/run/fc-x86_64-initrd.json`:

```json
{
  "boot-source": {
    "kernel_image_path": "workdir/build/redis_fc-x86_64",
    "boot_args": "redis_fc-x86_64 netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- /redis.conf",
    "initrd_path": "rootfs.cpio"
  },
  "drives": [],
  "machine-config": {
    "vcpu_count": 1,
    "mem_size_mib": 256,
    "smt": false,
    "track_dirty_pages": false
  },
  "cpu-config": null,
  "balloon": null,
  "network-interfaces": [
    {
      "iface_id": "net1",
      "guest_mac":  "06:00:ac:10:00:02",
      "host_dev_name": "tap0"
    }
  ],
  "vsock": null,
  "logger": {
    "log_path": "/tmp/firecracker.log",
    "level": "Debug",
    "show_level": true,
    "show_log_origin": true
  },
  "metrics": null,
  "mmds-config": null,
  "entropy": null
}
```

To run the Firecracker x86_64 build, use the commands below:

```console
old="$PWD"
cd "$rootfs"
find -depth -print | tac | bsdcpio -o --format newc > "$old"/rootfs.cpio
cd "$old"
sudo ip link set dev tap0 down 2> /dev/null
sudo ip link del dev tap0 2> /dev/null
sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo ip tuntap add dev tap0 mode tap
sudo ip address add 172.44.0.1/24 dev tap0
sudo ip link set dev tap0 up
sudo rm -f /tmp/firecracker.log
> /tmp/firecracker.log
sudo rm -f /tmp/firecracker.socket
sudo firecracker-x86_64 \
        --api-sock /tmp/firecracker.socket \
        --config-file "$config"
```

Same as running with QEMU, the application will start a server on address 172.44.0.2, on port `6379`.

Note that, currently (release 0.14), there is not yet networking support in Unikraft for Firecracker, so Redis cannot be properly used.
