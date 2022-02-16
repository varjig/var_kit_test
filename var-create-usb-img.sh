#!/bin/sh -e

commit=$(git log --oneline | head -n 1 | awk '{print $1}')
img=imx_kit_test_usb_${commit}.img

# Detach all loop devices 
sudo losetup -D
sudo rm -f $img

# Create empty image file
dd if=/dev/zero of=$img bs=1M count=500

# Attach loop device to image file
sudo losetup -Pf $img
loopdev=$(losetup -a | grep ${img} | awk -F: '{print $1}')

# Create single ext4 partition spanning the entire image
sudo parted -s -a optimal ${loopdev} mklabel msdos -- mkpart primary ext4 1 -1s

# Format the partition
sudo mkfs.ext4 ${loopdev}p1

# Label the partition
sudo e2label ${loopdev}p1 imx_kit_test

# Mount the parition
tmpdir=$(mktemp -d /tmp/mount.XXX)
sudo mount -t ext4 ${loopdev}p1 ${tmpdir}

# Copy files to partition
sudo cp -a ddr carrier_eeprom mp4/*.mp4 *.sh iMX6_mac_test wpa_variscite.conf ${tmpdir}
sudo cat mp4/Sony_Surfing_4K_Demo.mp4.* | sudo dd of=${tmpdir}/Sony_Surfing_4K_Demo.mp4
sync; sync

# Detach image file from loop device
sudo umount ${tmpdir}
sudo rm -rf ${tmpdir}
sudo losetup -d ${loopdev}

# Compress image file
gzip ${img}

exit 0



