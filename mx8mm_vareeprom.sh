#!/bin/bash

I2C_BUS=0
I2C_ADDR=0x52

# Part number offset and size
PN_OFFSET=0x02
PN_LEN=3

# Assembly offset and size
AS_OFFSET=0x05
AS_LEN=10

# Date offset and size
DATE_OFFSET=0x0f
DATE_LEN=9

# MAC offset and size
MAC_OFFSET=0x18
MAC_LEN=6

# SOM revision offset and size
SR_OFFSET=0x1e
SR_LEN=1

# EEPROM version offsetand size
VER_OFFSET=0x1f
VER_LEN=1

# SOM options offset and size
OPT_OFFSET=0x20
OPT_LEN=1

# EEPROM Field Values
SOM_OPTIONS="0x0f"
SOM_REV="0x01"

# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
# 4: value
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

# This func doesn't write a trailing
# zero at the end of the string
#
# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
# 4: value
write_i2c_string()
{
	DATA_ADDR=$3
	A=$(echo $4 | awk NF=NF FS=)
	for i in $A; do
		B=$(printf '0x%x' "'$i")
		write_i2c_byte $1 $2 $DATA_ADDR $B
		let DATA_ADDR="$DATA_ADDR + 1"
	done
}

# This func doesn't write a trailing
# zero at the end of the string
#
# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
# 4: value
write_i2c_mac()
{
	DATA_ADDR=$3
	A=$(echo $4 | grep -o ..)
	for i in $A; do
		B=$(printf 0x%s "$i")
		write_i2c_byte $1 $2 $DATA_ADDR $B
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

fail()
{
	echo -e "FAIL: $@"
	exit 1
}

######################################################################
#                        Execution starts here                       #
######################################################################

SOC="MX8MM"

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
write_i2c_string  ${I2C_BUS} ${I2C_ADDR} ${PN_OFFSET}	  ${PN}
write_i2c_string  ${I2C_BUS} ${I2C_ADDR} ${AS_OFFSET}	  ${AS}
write_i2c_string  ${I2C_BUS} ${I2C_ADDR} ${DATE_OFFSET}   ${DATE}
write_i2c_mac     ${I2C_BUS} ${I2C_ADDR} ${MAC_OFFSET}	  ${MAC}
write_i2c_byte    ${I2C_BUS} ${I2C_ADDR} ${SR_OFFSET}	  ${SOM_REV}
write_i2c_byte    ${I2C_BUS} ${I2C_ADDR} ${OPT_OFFSET}	  ${SOM_OPTIONS}

