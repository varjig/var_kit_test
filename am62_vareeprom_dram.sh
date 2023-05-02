#!/bin/bash -e

if [ -d /run/media/sda1 ]; then
	SCRIPT_POINT="/run/media/sda1"
else
	SCRIPT_POINT="/run/media/var_kit_test-sda1"
fi

EEPROM_IMAGE_DIR=${SCRIPT_POINT}/ddr
I2C_BUS=3
I2C_ADDR=0x50

SCRIPTDIR="$(dirname "$(realpath "$0")")"

# Source common eeprom code
. ${SCRIPTDIR}/vareeprom_common.sh

# Select DRAM P/N
echo "Select DRAM PN"
echo "1) 512-VIC1039"
echo "2) 1024-VIC1040"
echo "3) 2048-VIC1041"
echo "4) 4096-VIC1042"

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
	EEPROM_IMAGE=AM62-SOM-VIC1039_4Gb_IT_K4A4G165WF-BIWE_DDR_Config_0.09.08.0000.bin
	;;
2)
	EEPROM_IMAGE=AM62-SOM-VIC1040_8Gb_IT_K4A8G165WC-BIWE_DDR_Config_0.09.08.0000.bin
	;;
3)
	EEPROM_IMAGE=AM62-SOM-VIC1041_16Gb_IT_K4AAG165WA-BIWE_DDR_Config_0.09.08.0000.bin
	;;
4)
	EEPROM_IMAGE=AM62-SOM-VIC1042_32Gb_CT_K4ABG165WA-MCWE_DDR_Config_0.09.08.0000_Width-8_Density-16_CS-1.bin
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
echo -n -e '\x41\x4d' | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

echo "EEPROM write successful"

exit 0
