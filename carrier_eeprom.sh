#!/bin/bash -e

EEPROM_IMAGE_DIR=/run/media/sda1/carrier_eeprom
SYMPHONY_15_IMAGE=symphony_1.5.bin
SYMPHONY_16_IMAGE=symphony_1.6.bin
DT8MCUSTOM_20_IMAGE=dt8mcustom_2.0.bin
DT8MCUSTOM_21_IMAGE=dt8mcustom_2.1.bin

I2C_ADDR=0x54

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

######################################################################
#                        Execution starts here                       #
######################################################################
if [ `grep i.MX8MQ /sys/devices/soc0/soc_id` ]; then
	I2C_BUS=1
elif [ `grep i.MX8MM /sys/devices/soc0/soc_id` ]; then
	if grep -q DART /sys/devices/soc0/machine; then
		I2C_BUS=1
	else
		I2C_BUS=2
	fi
elif [ `grep i.MX8MP /sys/devices/soc0/soc_id` ]; then
	if grep -q DART /sys/devices/soc0/machine; then
		I2C_BUS=1
	else
		I2C_BUS=3
	fi
elif [ `grep i.MX8QXP /sys/devices/soc0/soc_id` ]; then
		I2C_BUS=2
elif [ `grep i.MX8QM /sys/devices/soc0/soc_id` ]; then
		I2C_BUS=4
else
	echo "Unsupported SOM"
	exit 1
fi

# Select EEPROM image
if grep -q DART /sys/devices/soc0/machine; then
	echo "Please select DTM8CustomBoard revision:"
	echo "1) DTM8CustomBoard 2.0"
	echo "2) DTM8CustomBoard 2.1"
	echo -n "Your choice: "
	read carrier_rev

	case $carrier_rev in
	1)
		EEPROM_IMAGE=${DT8MCUSTOM_20_IMAGE}
		;;
	2)
		EEPROM_IMAGE=${DT8MCUSTOM_21_IMAGE}
		;;
	*)
		echo "Invalid DTM8CustomBoard revision"
		exit 1
	esac
else
	echo "Please select the Symphony-Board revision:"
	echo "1) Symphony-Board 1.5"
	echo "2) Symphony-Board 1.6"
	echo -n "Your choice: "
	read carrier_rev

	case $carrier_rev in
	1)
		EEPROM_IMAGE=${SYMPHONY_15_IMAGE}
		;;
	2)
		EEPROM_IMAGE=${SYMPHONY_16_IMAGE}
		;;
	*)
		echo "Invalid Symphony-Board revision"
		exit 1
	esac
fi

# Check that image file exists
if [ ! -f ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} ]; then
	echo "No EEPROM image file"
	exit 1
fi

# Write image file to EEPROM
cat ${EEPROM_IMAGE_DIR}/${EEPROM_IMAGE} | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

# Write EEPROM magic
echo -n -e '\x56\x43' | write_i2c_file ${I2C_BUS} ${I2C_ADDR} 0

echo "EEPROM write successful"

exit 0
