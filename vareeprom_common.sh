#!/bin/bash

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
