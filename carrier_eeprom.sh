#!/bin/bash -e

if [ -d /run/media/sda1 ]; then
	SCRIPT_POINT="/run/media/sda1"
else
	SCRIPT_POINT="/run/media/var_kit_test-sda1"
fi

EEPROM_IMAGE_DIR=${SCRIPT_POINT}/carrier_eeprom
SYMPHONY_16_IMAGE=symphony_1.6.bin
SYMPHONY_17_IMAGE=symphony_1.7.bin
DT8MCUSTOM_21_IMAGE=dt8mcustom_2.1.bin
DT8MCUSTOM_30_IMAGE=dt8mcustom_3.0.bin

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
if [ `grep AM62X /sys/devices/soc0/family` ]; then
		I2C_BUS=1
elif [ `grep i.MX8MQ /sys/devices/soc0/soc_id` ]; then
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
elif [ `grep i.MX93 /sys/devices/soc0/soc_id` ]; then
		I2C_BUS=0
else
	echo "Unsupported SOM"
	exit 1
fi

# Select EEPROM image
if grep -q DART /sys/devices/soc0/machine; then
	echo "Please select DTM8CustomBoard revision:"
	echo "2) DTM8CustomBoard 2.1"
	echo "3) DTM8CustomBoard 3.0"
	echo -n "Your choice: "
	read carrier_rev

	case $carrier_rev in
	2)
		EEPROM_IMAGE=${DT8MCUSTOM_21_IMAGE}
		BOARD="DTM8CustomBoard 2.1"
		;;
	3)
		EEPROM_IMAGE=${DT8MCUSTOM_30_IMAGE}
		BOARD="DTM8CustomBoard 3.0"
		;;
	*)
		echo "Invalid DTM8CustomBoard revision"
		exit 1
	esac
else
	echo "Please select the Symphony-Board revision:"
	echo "6) Symphony-Board 1.6"
	echo "7) Symphony-Board 1.7"
	echo -n "Your choice: "
	read carrier_rev

	case $carrier_rev in
	6)
		EEPROM_IMAGE=${SYMPHONY_16_IMAGE}
		BOARD="Symphony-Board 1.6"
		;;
	7)
		EEPROM_IMAGE=${SYMPHONY_17_IMAGE}
		BOARD="Symphony-Board 1.7"
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

echo "EEPROM write successful: $BOARD"

exit 0
