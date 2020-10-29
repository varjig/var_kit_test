#!/bin/sh

# EEPROM Magic
MAGIC="VC"
MAGIC_OFFSET=0x00
MAGIC_LEN=2

# EEPROM version
EEPROM_VER="0x01"
EEPROM_VER_OFFSET=0x02
EEPROM_VER_LEN=1

# EEPROM board revision
BOARD_REV_OFFSET=0x03
BOARD_REV_LEN=8

# EEPROM I2C address
I2C_ADDR=0x54

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

######################################################################
#                        Execution starts here                       #
######################################################################
if [ `grep i.MX8MM /sys/devices/soc0/soc_id` ]; then
	if [ `grep DART-MX8MM /sys/devices/soc0/machine` ]; then
		BOARD="DART-MX8M-MINI"
		I2C_BUS=1
	else
		BOARD="VAR-SOM-MX8M-MINI"
		I2C_BUS=2
	fi
elif [ `grep i.MX8MN /sys/devices/soc0/soc_id` ]; then
	BOARD="VAR-SOM-MX8M-NANO"
	I2C_BUS=2
elif [ `grep i.MX8MQ /sys/devices/soc0/soc_id` ]; then
	BOARD="DART-MX8M"
	I2C_BUS=1
elif [ `grep i.MX8MP /sys/devices/soc0/soc_id` ]; then
	if grep -q DART-MX8M-PLUS /sys/devices/soc0/machine; then
		BOARD="DART-MX8M-PLUS"
		I2C_BUS=1
	else
		BOARD="VAR-SOM-MX8M-PLUS"
		I2C_BUS=2
	fi
elif [ `grep i.MX8QXP /sys/devices/soc0/soc_id` ]; then
	BOARD="VAR-SOM-MX8X"
	I2C_BUS=2
elif [ `grep i.MX8QM /sys/devices/soc0/soc_id` ]; then
	BOARD="VAR-SOM-MX8"
	I2C_BUS=4
else
	echo "Unsupported SoM"
	exit 1
fi


if [ "$BOARD" = "DART-MX8M" -o "$BOARD" = "DART-MX8M-MINI" -o "$BOARD" = "DART-MX8M-PLUS" ]; then
	CARRIER="DM8MCustomBoard"
	echo "Select DM8MCustomBoard revision"
	echo "1) 2.0"
else
	CARRIER="Symphony"
	echo "Select Symphony revision"
	echo "1) 1.4A"
fi

echo
echo -n "Your choice: "
read CARRIER_REV

echo
echo "The following $CARRRIER revision was selected: $CARRIER_REV"
echo
echo -n "To continue press Enter, to abort Ctrl-C:"
read temp

if [ "$CARRIER" = "DM8MCustomBoard" ]; then
	case $CARRIER_REV in
	1) 
		CARRIER_REV_STR="2.0"
		;;
	*)
		echo "Unsupported "$CARRIER" revision"
		exit 1
	esac
else
	case $CARRIER_REV in
	1) 
		CARRIER_REV_STR="1.4A"
		;;
	*)
		echo "Unsupported "$CARRIER" revision"
		exit 1
	esac
fi

# Write EEPROM version
write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${EEPROM_VER_OFFSET} ${EEPROM_VER}

# Zero board revision field
for i in $(seq 0 $((BOARD_REV_LEN-1))); do
	write_i2c_byte ${I2C_BUS} ${I2C_ADDR} $((BOARD_REV_OFFSET+$i)) 0x00
done

# Write board revision
write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${BOARD_REV_OFFSET} ${CARRIER_REV_STR}

# Write EEPROM magic
write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${MAGIC_OFFSET} ${MAGIC}

echo "EEPROM write successful"

exit 0
