#!/bin/bash -e

if [ -d /run/media/sda1 ]; then
	SCRIPT_POINT="/run/media/sda1"
else
	SCRIPT_POINT="/run/media/imx_kit_test-sda1"
fi

EEPROM_IMAGE_DIR=${SCRIPT_POINT}/ddr
I2C_BUS=3
I2C_ADDR=0x50

write_i2c_byte()
{
	i2cset -r -y $1 $2 $3 $4 > /dev/null
	usleep 5000
	VAL=`i2cget -y $1 $2 $3`
	if [ "$VAL" != "$4" ]; then
		echo "FAIL! EEPROM VERIFY ADDRESS $3 SHOULD BE $4. READ $VAL."
		exit 1
	fi
}

write_i2c_file()
{
	offset=$3
	od -An -vtx1 -w1 | cut -c2- |
	while read byte; do
		byte=$(printf "0x%02x" 0x$byte)
		write_i2c_byte $1 $2 ${offset} ${byte}
		offset=$((offset+1))
	done
}

# Select DRAM P/N
echo "Select DRAM PN"
echo "1) 2048-VIC1041"

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
	EEPROM_IMAGE=AM62-SOM-VIC1041_16Gb_IT_K4AAG165WA-BIWE_DDR_Config_0.09.08.0000.bin
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
