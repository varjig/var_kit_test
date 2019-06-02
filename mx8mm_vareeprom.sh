#!/bin/bash

EEPROM_SYSFS=/sys/devices/platform/30a20000.i2c/i2c-0/0-0052/eeprom

# Part number offset and size
PN_OFFSET=2
PN_LEN=3

# Assembly offset and size
AS_OFFSET=5
AS_LEN=10

# Date offset and size
DATE_OFFSET=15
DATE_LEN=9

# MAC offset and size
MAC_OFFSET=24
MAC_LEN=6

# SOM revision offset and size
SR_OFFSET=30
SR_LEN=1

# SOM options offset and size
OPT_OFFSET=32
OPT_LEN=1

# EEPROM Field Values
SOM_OPTIONS="0f"

# params:
# 1: data addr
# 2: value
write_i2c_byte()
{
	echo -n -e \\x$2 | dd of=${EEPROM_SYSFS} bs=1 seek=$1 2>/dev/null
	usleep 5000
	VAL=$(dd if=${EEPROM_SYSFS} bs=1 skip=$1 count=1 2>/dev/null | od -t x1 | head -n 1 | awk '{print $2}')
	if [ "$VAL" != "$2" ]; then
		echo "FAIL! EEPROM VERIFY ADDRESS $1 SHOULD BE $2. READ $VAL."
		exit 1
	fi
}


# This func doesn't write a trailing
# zero at the end of the string
#
# params:
# 1: data addr
# 2: value
write_i2c_string()
{
	DATA_ADDR=$1
	A=$(echo $2 | awk NF=NF FS=)
	for i in $A; do
		B=$(printf '%x' "'$i")
		write_i2c_byte $DATA_ADDR $B
		let DATA_ADDR="$DATA_ADDR + 1"
	done
}

# This func doesn't write a trailing
# zero at the end of the string
#
# params:
# 1: data addr
# 2: value
write_i2c_mac()
{
	DATA_ADDR=$1
	A=$(echo $2 | grep -o ..)
	for i in $A; do
		B=$(printf %s "$i")
		write_i2c_byte $DATA_ADDR $B
		let DATA_ADDR="$DATA_ADDR + 1"
	done
}

pn_is_valid()
{
	case $1 in
		[0-9][0-9][0-9])
		return 0
		;;
	*)
		return 1
		;;
	esac
}

as_is_valid()
{
	case $1 in
		AS[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
		return 0
		;;
		[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
		return 0
		;;
		*)
		return 1
		;;
	esac
}

mac_is_valid()
{
	case $1 in

		[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])
			return 0
			;;
		[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f])
			MAC=$(echo $1 | sed 's/\://g')
			return 0
			;;
		*)
			return 1
			;;
	esac
}

dram_size_is_valid()
{
	case $1 in
		[1-4])
			return 0
			;;
		*)
			return 1;
			;;
	esac
}

fail()
{
	echo -e "FAIL: $@"
	exit 1
}

######################################################################
#                        Execution starts here                       #
######################################################################

SOC="MX8MM"
SOM_REV="01"

echo -n "Enter Part Number: VSM-DT8MM-"
read -e PN

echo -n "Enter Assembly: "
read -e AS

echo -n "Enter Date (YYYY MMM DD, e.g. 2018 May 10): "
read -e DATE

echo -n "Enter MAC: "
read -e MAC

echo
echo "The following parameters were given:"
echo -e "PN:\t\t VSM-DT8MM-${PN}"
echo -e "Assembly:\t $AS"
echo -e "DATE:\t\t $DATE"
echo -e "MAC:\t\t $MAC"
echo
echo -n "To continue press Enter, to abort Ctrl-C:"
read temp

if ! pn_is_valid $PN; then
	fail "Invalid Part Number"
fi

if ! as_is_valid $AS; then
	fail "Invalid Assembly"
fi

# Remove part number VSM-DT8M- prefix
PN=${PN#VSM-DT8M-}

# Cut part number to fit into EEPROM field
PN=${PN::$PN_LEN}

# Remove assembly AS prefix
AS=${AS#AS}

# Cut assembly to fit into EEPROM field
AS=${AS::$AS_LEN}

# Remove spaces from date
DATE=$(echo $DATE | tr -d '[:space:]')

# Cut date to fit into EEPROM field
DATE=${DATE::$DATE_LEN}

# Convert MAC address to lower case
MAC=$(echo $MAC | tr '[:upper:]' '[:lower:]')

if ! mac_is_valid $MAC; then
	fail "Invalid MAC"
fi


# Program EEPROM fields
write_i2c_string  ${PN_OFFSET}	  ${PN}
write_i2c_string  ${AS_OFFSET}	  ${AS}
write_i2c_string  ${DATE_OFFSET}  ${DATE}
write_i2c_mac     ${MAC_OFFSET}	  ${MAC}
write_i2c_byte    ${SR_OFFSET}	  ${SOM_REV}
write_i2c_byte    ${OPT_OFFSET}	  ${SOM_OPTIONS}
