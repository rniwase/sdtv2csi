### install_patch.sh: Build and install patched adv7180 kernel module ###

set -e

if [ $USER != root ]; then
  echo '--- It must run on a shell with root privileges. Try again with "sudo bash install_patch.sh".' 1>&2
  exit 1
fi

echo "--> Install build dependencies" 1>&2
apt-get update
apt-get -y install git bc bison flex libssl-dev

echo "--> Extract git commit IDs for firmware" 1>&2
# - for bullseye
if [ -e /usr/share/doc/raspberrypi-bootloader/changelog.Debian.gz ]; then
  FW_GIT=$(zgrep "* firmware as of" /usr/share/doc/raspberrypi-bootloader/changelog.Debian.gz | head -1 | cut -d " " -f 7)
  echo "--- raspberrypi/firmware commit id: $FW_GIT" 1>&2
# - for bookworm
elif [ -e /usr/share/doc/raspi-firmware/changelog.Debian.gz ]; then
  FW_GIT=$(zgrep "raspi-firmware (" /usr/share/doc/raspi-firmware/changelog.Debian.gz | head -1 | sed -n 's/.*\(1\.[0-9]\{8\}\).*/\1/p')
  echo "--- raspberrypi/firmware tag: $FW_GIT" 1>&2
else
  echo "--- Failed to extract firmware ID due to missing changelog file."
  exit 1
fi

echo "--> Extract git commit IDs for linux kernel" 1>&2
KERNEL_GIT=$(curl -fL https://github.com/raspberrypi/firmware/raw/$FW_GIT/extra/git_hash)
echo "--- raspberrypi/linux commit id: $KERNEL_GIT" 1>&2

echo "--> Download linux kernel source" 1>&2
if [ -e /usr/src/linux-$KERNEL_GIT/ ]; then
  echo "--- Download aborted because directory already exists."
else
  curl -fL https://github.com/raspberrypi/linux/archive/$KERNEL_GIT.tar.gz | tar -zx -C /usr/src/
fi

echo "--> Download symbol file" 1>&2
KERNEL_RELEASE=$(uname -r)
# - for RPi 5, 64-bit
if [[ $KERNEL_RELEASE == *rpi-2712* ]]; then
  MODULE_SYMVERS="Module_2712.symvers"
# - for RPi Zero 2W / 3(+) / 4, 64-bit
elif [[ $KERNEL_RELEASE == *v8* ]]; then
  MODULE_SYMVERS="Module8.symvers"
# - for RPi 4, 32-bit
elif [[ $KERNEL_RELEASE == *v7l* ]]; then
  MODULE_SYMVERS="Module7l.symvers"
# - for RPi 2 / 3(+) / Zero 2W / 4, 32-bit
elif [[ $KERNEL_RELEASE == *v7* ]]; then
  MODULE_SYMVERS="Module7.symvers"
else
# - for RPi 1 / Zero(W), 32-bit
  MODULE_SYMVERS="Module.symvers"
fi

if [ -e /usr/src/linux-$KERNEL_GIT/Module.symvers ]; then
  echo "--- Download aborted because file already exists."
else
  curl -fL https://github.com/raspberrypi/firmware/raw/$FW_GIT/extra/$MODULE_SYMVERS > /usr/src/linux-$KERNEL_GIT/Module.symvers
fi

echo "--> Porting configs from current system" 1>&2
modprobe configs
zcat /proc/config.gz > /usr/src/linux-$KERNEL_GIT/.config

echo "--> Generate files needed to build kernel modules" 1>&2
make -C /usr/src/linux-$KERNEL_GIT/ -j$(nproc) modules_prepare

echo "--> Preparing for adv7180 kernel module build" 1>&2
mkdir -p /usr/src/adv7180_patch/
cp /usr/src/linux-$KERNEL_GIT/drivers/media/i2c/adv7180.c /usr/src/adv7180_patch/
echo "obj-m := adv7180.o" > /usr/src/adv7180_patch/Makefile

echo "--> Apply patch to adv7180.c" 1>&2
sed -i.bak -e "s/480 : 576/507 : 576/" /usr/src/adv7180_patch/adv7180.c
diff /usr/src/adv7180_patch/adv7180.c.bak /usr/src/adv7180_patch/adv7180.c || true

echo "--> Build adv7180.ko" 1>&2
make -C /usr/src/linux-$KERNEL_GIT/ M=/usr/src/adv7180_patch/

echo "--> Install driver" 1>&2
mv /lib/modules/$KERNEL_RELEASE/kernel/drivers/media/i2c/adv7180.ko.xz /lib/modules/$KERNEL_RELEASE/kernel/drivers/media/i2c/adv7180.ko.xz.bak
xz -c /usr/src/adv7180_patch/adv7180.ko > /lib/modules/$KERNEL_RELEASE/kernel/drivers/media/i2c/adv7180.ko.xz

echo "--- Installation completed. Set dtoverlay and reboot to load module." 1>&2
