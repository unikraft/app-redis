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
kraft run --target redis-qemu-x86_64-initrd --initrd ./fs0 -p 6379:6379 -- /redis.conf
```

If you don't have KVM support (such as when running inside a virtual machine), pass the `-W` option to `kraft run` to disable virtualization support:

```console
kraft run -W --target redis-qemu-x86_64-initrd --initrd ./fs0 -p 6379:6379 -- /redis.conf
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

## Work with the Basic Build & Run Toolchain (Advanced)

You can set up, configure, build and run the application from grounds up, without using the companion tool `kraft`.

### Quick Setup (aka TLDR)

For a quick setup, run the commands below.
Note that you still need to install the [requirements](#requirements).

For building and running everything for `x86_64`, follow the steps below:

```console
git clone https://github.com/unikraft/app-redis redis
cd redis/
mkdir .unikraft
git clone https://github.com/unikraft/unikraft .unikraft/unikraft
git clone https://github.com/unikraft/lib-redis .unikraft/libs/redis
git clone https://github.com/unikraft/lib-musl .unikraft/libs/musl
git clone https://github.com/unikraft/lib-lwip .unikraft/libs/lwip
UK_DEFCONFIG=$(pwd)/.config.redis-qemu-x86_64-9pfs make defconfig
make -j $(nproc)
./run-qemu-x86_64-9pfs.sh
```

This will configure, build and run the `redis` server, that can be tested using the instructions in the [running section](#run).

The same can be done for `AArch64`, by running the commands below:

```console
make properclean
UK_DEFCONFIG=$(pwd)/.config.redis-qemu-aarch64-9pfs make defconfig
make -j $(nproc)
./run-qemu-aarch64-9pfs.sh
```

Similar to the `x86_64` build, this will configure, build and run the `redis` server, that can be tested using the instructions in the [running section](#run).
Information about every step is detailed below.

### Requirements

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

     ls -a
     ```

      This will print the contents of the repository.

     ```text
     fs0/  kraft.yaml  Makefile  Makefile.uk.default  README.md .config.redis-qemu-x86_64-9pfs .config.redis-qemu-aarch64-9pfs [...]  run-fc-x86_64-initrd.sh*  run-qemu-aarch64-9pfs.sh*  [...]
     ```

  1. While inside the `redis/` directory, create the `.unikraft/` directory:

     ```console
     mkdir .unikraft
     ```

     Enter the `.unikraft/` directory:

     ```console
     cd .unikraft/
     ```

  1. While inside the `.unikraft` directory, clone the [`unikraft` repository](https://github.com/unikraft/unikraft):

     ```console
     git clone https://github.com/unikraft/unikraft unikraft
     ```

  1. While inside the `.unikraft/` directory, create the `libs/` directory:

     ```console
     mkdir libs
     ```

  1. While inside the `.unikraft/` directory, clone the library repositories in the `libs/` directory:

     ```console
     git clone https://github.com/unikraft/lib-redis libs/redis

     git clone https://github.com/unikraft/lib-musl libs/musl

     git clone https://github.com/unikraft/lib-lwip libs/lwip
     ```

  1. Get back to the application directory:

     ```console
     cd ../
     ```

     Use the `tree` command to inspect the contents of the `.unikraft/` directory.

     ```console
     tree -F -L 2 .unikraft/
     ```

     The layout of the `.unikraft/` directory should look something like this:

     ```text
     .unikraft/
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

### Configure

Configuring, building and running a Unikraft application depends on our choice of platform and architecture.
Currently, supported platforms are QEMU (KVM), Xen and linuxu.
QEMU (KVM) is known to be working, so we focus on that.

Supported architectures are x86_64 and AArch64.

Use the corresponding the configuration files (`config-...`), according to your choice of platform and architecture.

#### QEMU x86_64

Use the `.config.redis-qemu-x86_64-9pfs` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/.config.redis-qemu-x86_64-9pfs make defconfig
```

This results in the creation of the `.config` file:

```console
ls .config
.config
```

The `.config` file will be used in the build step.

#### QEMU AArch64

Use the `.config.redis-qemu-aarch64-9pfs` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/.config.redis-qemu-aarch64-9pfs make defconfig
```

Similar to the x86_64 configuration, this results in the creation of the `.config` file that will be used in the build step.

### Build

Building uses as input the `.config` file from above, and results in a unikernel image as output.
The unikernel output image, together with intermediary build files, are stored in the `build/` directory.

#### Clean Up

Before starting a build on a different platform or architecture, you must clean up the build output.
This may also be required in case of a new configuration.

Cleaning up is done with 3 possible commands:

* `make clean`: cleans all actual build output files (binary files, including the unikernel image)
* `make properclean`: removes the entire `build/` directory
* `make distclean`: removes the entire `build/` directory **and** the `.config` file

Typically, you would use `make properclean` to remove all build artifacts, but keep the configuration file.

#### QEMU x86_64

Building for QEMU x86_64 assumes you did the QEMU x86_64 configuration step above.
Build the Unikraft Redis image for QEMU x86_64 by using the command below:

```console
make -j $(nproc)
```

You will see a list of all files generated by the build system.

```text
[...]
  LD      redis_qemu-x86_64.dbg
  UKBI    redis_qemu-x86_64.dbg.bootinfo
  SCSTRIP redis_qemu-x86_64
  GZ      redis_qemu-x86_64.gz
make[1]: Leaving directory '/media/razvan/c4f6765a-efa5-4ebd-9cf0-7da9908a0189/razvan/unikraft/solo/redis/.unikraft/unikraft'
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
make -j $(nproc)
```

Similar to the x86_64 build, you will see a list of all files generated by the build system.

```text
[...]
  LD      redis_qemu-arm64.dbg
  UKBI    redis_qemu-arm64.dbg.bootinfo
  SCSTRIP redis_qemu-arm64
  GZ      redis_qemu-arm64.gz
make[1]: Leaving directory '/media/razvan/c4f6765a-efa5-4ebd-9cf0-7da9908a0189/razvan/unikraft/solo/redis/.unikraft/unikraft
```

Similarly to x86_64, at the end of the build command, the `redis_qemu-arm64` unikernel image is generated.
This image is to be used in the run step.

### Run

#### QEMU x86_64

To run the QEMU x86_64 build, use the `run-qemu-x86_64-9pfs.sh` script:

```console
./run-qemu-x86_64-9pfs.sh
```

You should now see the Redis server banner:

```text
SeaBIOS (version 1.13.0-1ubuntu1.1)


iPXE (http://ipxe.org) 00:04.0 CA00 PCI2.10 PnP PMM+07F8C860+07ECC860 CA00


Booting from ROM..1: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en1: Added
en1: Interface is up
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                  Atlas 0.13.1~5eb820bd
1:C 10 Jul 2015 09:05:19.076 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
1:C 10 Jul 2015 09:05:19.078 # Redis version=7.0.11, bits=64, commit=c5ee3442, modified=1, pid=1, just started
1:C 10 Jul 2015 09:05:19.079 # Configuration loaded
[    0.195035] ERR:  [libposix_process] <deprecated.c @  348> Ignore updating resource 7: cur = 10032, max = 10032
1:M 10 Jul 2015 09:05:19.096 * Increased maximum number of open files to 10032 (it was originally set to 1024).
1:M 10 Jul 2015 09:05:19.098 * monotonic clock: POSIX clock_gettime
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

1:M 10 Jul 2015 09:05:19.145 # WARNING: The TCP backlog setting of 511 cannot be enforced because SOMAXCONN is set to the lower value of 128.
1:M 10 Jul 2015 09:05:19.148 # Server initialized
1:M 10 Jul 2015 09:05:19.158 # Warning: can't mask SIGALRM in bio.c thread: No error information
1:M 10 Jul 2015 09:05:19.162 # Warning: can't mask SIGALRM in bio.c thread: No error information
1:M 10 Jul 2015 09:05:19.164 # Warning: can't mask SIGALRM in bio.c thread: No error information
1:M 10 Jul 2015 09:05:19.167 * Ready to accept connections
```

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

To close the QEMU Redis server, use the `Ctrl+a x` keyboard shortcut;
that is press the `Ctrl` and `a` keys at the same time and then, separately, press the `x` key.

#### QEMU AArch64

To run the AArch64 build, use the `run-qemu-aarch64-9pfs.sh` script:

```console
./run-qemu-aarch64-9pfs.sh
```

You should now see the Redis server banner, just like when running for x86_64.

```text
1: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en1: Added
en1: Interface is up
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                  Atlas 0.13.1~5eb820bd
1:C -748820 Jan 1970 -23:-20:00.178 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
1:C -748820 Jan 1970 -23:-20:00.182 # Redis version=7.0.11, bits=64, commit=c5ee3442, modified=1, pid=1, just started
1:C -748820 Jan 1970 -23:-20:00.183 # Configuration loaded
[    0.372571] ERR:  [libposix_process] <deprecated.c @  348> Ignore updating resource 7: cur = 10032, max = 10032
1:M -748820 Jan 1970 -23:-20:00.374 * Increased maximum number of open files to 10032 (it was originally set to 1024).
1:M -748820 Jan 1970 -23:-20:00.375 * monotonic clock: POSIX clock_gettime
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

1:M -748820 Jan 1970 -23:-20:00.499 # WARNING: The TCP backlog setting of 511 cannot be enforced because SOMAXCONN is set to the lower value of 128.
1:M -748820 Jan 1970 -23:-20:00.499 # Server initialized
1:M -748820 Jan 1970 -23:-20:00.550 # Warning: can't mask SIGALRM in bio.c thread: No error information
1:M -748820 Jan 1970 -23:-20:00.551 # Warning: can't mask SIGALRM in bio.c thread: No error information
1:M -748820 Jan 1970 -23:-20:00.551 # Warning: can't mask SIGALRM in bio.c thread: No error information
1:M -748820 Jan 1970 -23:-20:00.556 * Ready to accept connections
```

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

Similar to the `x86_64` application, to close the QEMU Redis server, use the `Ctrl+a x` keyboard shortcut.

### Building and Running with initrd

The examples above use 9pfs as the filesystem interface.
Clean up the previous configuration, use the initrd configuration and build the unikernel by using the commands:

```console
make distclean
UK_DEFCONFIG=$(pwd)/.config.redis-qemu-x86_64-initrd make defconfig
make -j $(nproc)
```

To run the QEMU x86_64 initrd build, use `run-qemu-x86_64-initrd.sh`:

```console
./run-qemu-x86_64-initrd.sh
```

The commands for AArch64 are similar:

```console
make distclean
UK_DEFCONFIG=$(pwd)/.config.redis-qemu-aarch64-initrd make defconfig
make -j $(nproc)
./run-qemu-aarch64-initrd.sh
```

### Building and Running with Firecracker

[Firecracker](https://firecracker-microvm.github.io/) is a lightweight VMM (*virtual machine manager*) that can be used as more efficient alternative to QEMU.

Configure and build commands are similar to a QEMU-based build with an initrd-based filesystem:

```console
make distclean
UK_DEFCONFIG=$(pwd)/.config.redis-fc-x86_64-initrd make defconfig
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
This is the `redis-fc-x86_64-initrd.json` file.
This configuration file is uses as part of the run script `run-fc-x86_64-initrd`:

```console
./run-qemu-x86_64-initrd.sh
```

Same as running with QEMU, the application will start:

```text
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                  Atlas 0.13.1~f7511c8b
```

Note that, currently (release 0.14), there is not yet networking support in Unikraft for Firecracker, so Redis cannot be properly used.
