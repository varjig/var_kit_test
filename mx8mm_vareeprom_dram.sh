#!/bin/bash -e

EEPROM_IMAGE_DIR=/run/media/sda1/ddr
I2C_BUS=0
I2C_ADDR=0x52

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
echo "1) 2048-VIC0915"
echo "2) 1024-VIC0915"
echo "3) 2048-VIC0936"
echo "4) 1024-VIC0936"
echo "5) 4096-VIC0923"
echo "6) 2048-VIC0923"

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
	EEPROM_IMAGE=VAR-SOM-MX8M-MINI-Samsung-2G-K4A8G165WC-BCTD.bin
	;;
2)
	EEPROM_IMAGE=VAR-SOM-MX8M-NANO-Samsung-1G-K4A8G165WC-BCTD.bin
	;;
3)
	EEPROM_IMAGE=VAR-SOM-MX8M-MINI-Samsung-2G-K4A8G165WC-BITD.bin
	;;
4)
	EEPROM_IMAGE=VAR-SOM-MX8M-NANO-Samsung-1G-K4A8G165WC-BITD.bin
	;;
5)
	EEPROM_IMAGE=VAR-SOM-MX8M-MINI-Samsung-4G-K4AAG165WA-BCTD.bin
	;;
5)
	EEPROM_IMAGE=VAR-SOM-MX8M-NANO-Samsung-2G-K4AAG165WA-BCTD.bin
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

# Write image file to EEPROM
cat ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

# Write EEPROM magic
echo -n -e '\x38\x4d' | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

echo "EEPROM write successful"

exit 0

