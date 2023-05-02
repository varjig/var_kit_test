#!/bin/bash -e

if [ -d /run/media/sda1 ]; then
	SCRIPT_POINT="/run/media/sda1"
else
	SCRIPT_POINT="/run/media/var_kit_test-sda1"
fi

EEPROM_IMAGE_DIR=${SCRIPT_POINT}/ddr
I2C_BUS=2
I2C_ADDR=0x52

SCRIPTDIR="$(dirname "$(realpath "$0")")"

# Source common eeprom code
. ${SCRIPTDIR}/vareeprom_common.sh

# Select DRAM P/N
echo "Select DRAM PN"
echo "1) 2048-VIC1032"

echo
echo -n "Your choice: "
read DRAM_TYPE

echo
echo "The following DRAM PN was selected: $DRAM_TYPE"
echo
echo -n "To continue press Enter, to abort Ctrl-C:"
read temp

# Select image file
case ${DRAM_TYPE} in
1)
	EEPROM_IMAGE=MX93DDR_2G_3733_default.bin
	;;
*)
	echo "Unsupported DRAM P/N"
	exit 1
esac

# Check that image file exists
if [ ! -f ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} ]; then
	echo "No EEPROM image file"
	exit 1
fi

# Check that image sha256 file exists
if [ ! -f ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE}.sha256 ]; then
	echo "No EEPROM image sha256 file"
	exit 1
fi

# Write image file to EEPROM
cd ${EEPROM_IMAGE_DIR}
sha256sum -c "${EEPROM_IMAGE}.sha256" || (echo "Error: sha256sum failed" && exit -1)
cat ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

# Write EEPROM magic
echo -n -e '\x4d\x58' | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

echo "EEPROM write successful"

exit 0
