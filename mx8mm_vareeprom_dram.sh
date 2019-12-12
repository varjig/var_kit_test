#!/bin/bash -e

EEPROM_IMAGE_DIR=/run/media/sda1/ddr
EEPROM_SYSFS=/sys/devices/platform/30a20000.i2c/i2c-0/0-0052/eeprom
EEPROM_TEMP=/tmp/eeprom.$$
MAGIC=/tmp/magic.$$
MAGIC_TEMP=/tmp/magic_temp.$$

cleanup()
{
	rm -f ${EEPROM_TEMP} ${MAGIC} ${MAGIC_TEMP}
}

trap cleanup EXIT

if [ ! -f ${EEPROM_SYSFS} ]; then
  echo "No EEPROM systfs file"
  exit 1
fi

echo "Select DRAM PN"
echo "1) 2048-VIC0885"
echo "2) 4096-VIC0765"
echo "3) 1024-VIC0779"
echo "4) 512-VIC0901"
echo "5) 2048-VIC0877"
echo "6) 2048-VIC0915"

echo
echo -n "Your choice: "
read DRAM_TYPE

echo
echo "The following DRAM PN was selected: $DRAM_TYPE"
echo
echo -n "To continue press Enter, to abort Ctrl-C:"
read temp


case ${DRAM_TYPE} in
1)
	EEPROM_IMAGE=DART-MX8M-MINI-Samsung-2G-K4F6E3S4HM-MGCJ.bin
	;;
2)
	EEPROM_IMAGE=DART-MX8M-MINI-Samsung-4G-K4FBE3D4HM-MGCJ.bin
	;;
3)
	EEPROM_IMAGE=DART-MX8M-MINI-Samsung-1G-K4F8E304HB-MGCJ.bin
	;;
4)
	EEPROM_IMAGE=DART-MX8M-MINI-Samsung-512M-K4F4E3S4HF-MGCJ.bin
	;;
5)
	EEPROM_IMAGE=DART-MX8M-MINI-Micron-2G-MT53D512M32D2DS-046.bin
	;;
6)
	EEPROM_IMAGE=VAR-SOM-MX8M-MINI-Samsung-2G-K4A8G165WC-BCTD.bin
	;;
*)
	echo "Unsupported DRAM P/N"
	exit 1
esac

if [ ! -f ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} ]; then
  echo "No EEPROM image file"
  exit 1
fi

# Write image file to EEPROM and verify that write was successful
IMAGE_SIZE=$(ls -l ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} | awk '{print $5}')
dd if=${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} of=${EEPROM_SYSFS} bs=1 count=${IMAGE_SIZE}
sleep 1

echo 3 > /proc/sys/vm/drop_caches
dd if=${EEPROM_SYSFS} of=${EEPROM_TEMP} bs=1 count=${IMAGE_SIZE}
if ! cmp ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} ${EEPROM_TEMP}; then
  echo "EEPROM write failed"
  exit 1
fi

# Write EEPROM signature and verify that write was successful
echo -n -e '\x38\x4d' > ${MAGIC}
dd if=${MAGIC} of=${EEPROM_SYSFS} bs=1
sleep 1

echo 3 > /proc/sys/vm/drop_caches
dd if=${EEPROM_SYSFS} of=${MAGIC_TEMP} bs=1 count=2
if ! cmp ${MAGIC} ${MAGIC_TEMP}; then
  echo "EEPROM magic write failed"
  exit 1
fi

echo "EEPROM write successful"

exit 0

