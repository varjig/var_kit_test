#!/bin/bash -e


EEPROM_IMAGE=/run/media/sda1/ddr/DART-MX8M-MINI-Samsung-2G-K4F6E3S4HM-MGCJ.bin
EEPROM_SYSFS=/sys/devices/platform/30a20000.i2c/i2c-0/0-0052/eeprom
IMAGE_SIZE=$(ls -l ${EEPROM_IMAGE} | awk '{print $5}')
EEPROM_TEMP=/tmp/eeprom.$$

cleanup()
{
	rm -f ${EEPROM_TEMP}
}

trap cleanup EXIT

if [ ! -f ${EEPROM_SYSFS} ]; then
  echo "No EEPROM systfs file"
  exit 1
fi

if [ ! -f ${EEPROM_IMAGE} ]; then
  echo "No EEPROM image file"
  exit 1
fi

# Write image file to EEPROM and verify that write was successful
dd if=${EEPROM_IMAGE} of=${EEPROM_SYSFS} bs=1 count=${IMAGE_SIZE}
sleep 1

echo 3 > /proc/sys/vm/drop_caches
dd if=${EEPROM_SYSFS} of=${EEPROM_TEMP} bs=1 count=${IMAGE_SIZE}
if ! cmp ${EEPROM_IMAGE} ${EEPROM_TEMP}; then
  echo "EEPROM write failed"
  exit 1
fi

# Write EEPROM signature
echo -n -e '\x38\x4d' | dd of=${EEPROM_SYSFS} bs=1
echo "EEPROM write successful"

exit 0

