# based on https://github.com/davibe/docker-gstreamer-raspbian-build

FROM debian:stretch

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
  && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  automake \
  cmake \
  curl \
  fakeroot \
  g++ \
  git \
  make \
  runit \
  sudo \
  xz-utils 

ENV HOST=arm-linux-gnueabihf \
  TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64

WORKDIR /

RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/"

ENV ARCH=arm \
  CROSS_COMPILE=/bin/$HOST- \
  PATH=$RPXC_ROOT/bin:$PATH \
  QEMU_PATH=/usr/bin/qemu-arm-static \
  QEMU_EXECVE=1 \
  SYSROOT=/sysroot

WORKDIR $SYSROOT

# Use full raspbian rather than lite
RUN curl -Ls https://downloads.raspberrypi.org/raspbian/archive/2019-07-12-14:50/root.tar.xz \
  | tar -xJf -
  
#RUN curl -Ls https://downloads.raspberrypi.org/raspbian_lite/root.tar.xz \
#  | tar -xJf -

ADD https://github.com/resin-io-projects/armv7hf-debian-qemu/raw/master/bin/qemu-arm-static $SYSROOT/$QEMU_PATH

RUN chmod +x $SYSROOT/$QEMU_PATH && mkdir -p $SYSROOT/build

# Remove preload file, as it just causes warning spam
RUN rm $SYSROOT/etc/ld.so.preload

#RUN chroot $SYSROOT $QEMU_PATH /bin/sh -c '\
#  echo "deb http://archive.raspbian.org/raspbian buster firmware" \
#  >> /etc/apt/sources.list \
#  && apt-get update \
#  && sudo apt-mark hold \
#  raspberrypi-bootloader raspberrypi-kernel raspberrypi-sys-mods raspi-config \
#  && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
#  && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
#  && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
#  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
#  libc6-dev \
#  symlinks \
#  && symlinks -cors /'
  
# Update and Upgrade the Pi, otherwise the build may fail due to inconsistencies
RUN chroot $SYSROOT $QEMU_PATH /bin/sh -c 'sudo apt-get --allow-releaseinfo-change update && sudo apt-get upgrade -y --force-yes'

# Get build dependencies
# -libqt4-opengl-dev 
RUN chroot $SYSROOT $QEMU_PATH /bin/sh -c 'sudo apt-get install -y --force-yes -y curl git make clang wget rsync cmake libsdl2-dev libglew-dev'

CMD chroot $SYSROOT $QEMU_PATH /bin/bash
