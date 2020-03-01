#!/bin/bash

I2C_BUS=0
I2C_ADDR=0x52

# Magic offset and size
MAGIC_OFFSET=0x00
MAGIC_LEN=2

# Part number offsets and sizes
PN1_OFFSET=0x02
PN1_LEN=3

PN2_OFFSET=0x2a
PN2_MAX_LEN=5

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

# DRAM size offset and size
DS_OFFSET=0x21
DS_SIZE=1

# EEPROM Field Values
MAGIC="8M"
EEPROM_VER="0x02"
SOM_OPTIONS="0x0f"

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

if [ `grep i.MX8MM /sys/devices/soc0/soc_id` ]; then
	SOC="MX8MM"
	if [ `grep DART-MX8MM /sys/devices/soc0/machine` ]; then
		BOARD="DART-MX8MM"
	else
		BOARD="VAR-SOM-MX8MM"
		EEPROM_VER="0x03"
	fi
elif [ `grep i.MX8MN /sys/devices/soc0/soc_id` ]; then
	SOC="MX8MN"
	EEPROM_VER="0x03"
elif [ `grep i.MX8QXP /sys/devices/soc0/soc_id` ]; then
	SOC="MX8QX"
elif [ `grep i.MX8QM /sys/devices/soc0/soc_id` ]; then
	SOC="MX8QM"
else
	echo "Unsupported SoM"
	exit 1
fi

if [ $SOC = "MX8MM" ]; then
	if [ $BOARD = "DART-MX8MM" ]; then
		SOM_REV="0x01"
	else
		SOM_REV="0x00"
	fi
elif [ $SOC = "MX8MN" ]; then
	SOM_REV="0x00"
elif [ $SOC = "MX8QX" ]; then
	SOM_REV="0x00"
	SOM_OPTIONS="0x07"
elif [ $SOC = "MX8QM" ]; then
	SOM_REV="0x00"
	SOM_OPTIONS="0x07"
fi

if [ $SOC = "MX8MM" ]; then
	if [ $BOARD = "DART-MX8MM" ]; then
		echo -n "Enter Part Number: VSM-DT8MM-"
	else
		echo -n "Enter Part Number: VSM-VS8MM-"
	fi
elif [ $SOC = "MX8MN" ]; then
	echo -n "Enter Part Number: VSM-VS8MN-"
elif [ $SOC = "MX8QX" ]; then
	echo -n "Enter Part Number: VSM-MX8X-"
elif [ $SOC = "MX8QM" ]; then
	echo -n "Enter Part Number: VSM-MX8-"
fi
read -e PN
PN1=$(echo ${PN} | cut -c1-3)
PN2=$(echo ${PN} | cut -c4-)

echo -n "Enter Assembly: "
read -e AS

echo -n "Enter Date (YYYY MMM DD, e.g. 2018 May 10): "
read -e DATE

echo -n "Enter MAC: "
read -e MAC

# Set VAR-SOM-MX8 DRAM size and SOM options according to P/N
if [ $SOC = "MX8QM" ]; then
	case $PN in
	"101")
		DRAM_SIZE=4
		DRAM_PART="4096-VIC0885x2"
		SOM_OPTIONS="0x07"
		;;
	"102")
		DRAM_SIZE=4
		DRAM_PART="4096-VIC0885x2"
		SOM_OPTIONS="0x07"
		;;
	*)
		echo "Unsupported VAR-SOM-MX8 P/N"
		exit 1
	esac
fi

# Set VAR-SOM-MX8X DRAM size and SOM options according to P/N
if [ $SOC = "MX8QX" ]; then
	case $PN in
	"101")
		DRAM_SIZE=2
		DRAM_PART="2048-VIC0877"
		SOM_OPTIONS="0x07"
		;;
	"103")
		DRAM_SIZE=2
		DRAM_PART="2048-VIC0877"
		SOM_OPTIONS="0x06"
		;;
	"201")
		DRAM_SIZE=2
		DRAM_PART="2048-VIC0885"
		SOM_OPTIONS="0x07"
		;;
	"204")
		DRAM_SIZE=2
		DRAM_PART="2048-VIC0885"
		SOM_OPTIONS="0x06"
		;;
	*)
		echo "Unsupported VAR-SOM-MX8X P/N"
		exit 1
	esac
fi

# Set DART-MX8M-MINI/VAR-SOM-MX8M-MINI SOM options according to P/N
if [ $SOC = "MX8MM" ]; then
	if [ $BOARD = "DART-MX8MM" ]; then
		case $PN in
		"102")
			SOM_OPTIONS="0x0f"
			;;
		"103")
			SOM_OPTIONS="0x03"
			;;
		*)
			echo "Unsupported DART-MX8MM P/N"
			exit 1
		esac
	else
		case $PN in
		"001B")
			SOM_OPTIONS="0x0f"
			;;
		"101")
			SOM_OPTIONS="0x0f"
			;;
		"102")
			SOM_OPTIONS="0x0e"
			;;
		*)
			echo "Unsupported VAR-SOM-MX8MM P/N"
			exit 1
		esac
	fi
fi

# Set VAR-SOM-MX8M-NANO SOM options according to P/N
if [ $SOC = "MX8MN" ]; then
	case $PN in
	"001")
		SOM_OPTIONS="0x0f"
		;;
	*)
		echo "Unsupported VAR-SOM-MX8MN P/N"
		exit 1
	esac
fi

echo
echo "The following parameters were given:"
if [ $SOC = "MX8MM" ]; then
	if [ $BOARD = "DART-MX8MM" ]; then
		echo -e "PN:\t\t VSM-DT8MM-${PN}"
	else
		echo -e "PN:\t\t VSM-VS8MM-${PN}"
	fi
elif [ $SOC = "MX8MN" ]; then
	echo -e "PN:\t\t VSM-MX8MN-${PN}"
elif [ $SOC = "MX8QX" ]; then
	echo -e "PN:\t\t VSM-MX8X-${PN}"
elif [ $SOC = "MX8QM" ]; then
	echo -e "PN:\t\t VSM-MX8-${PN}"
fi

echo -e "Assembly:\t $AS"
echo -e "DATE:\t\t $DATE"
echo -e "MAC:\t\t $MAC"
if [ $SOC = "MX8QX" -o $SOC = "MX8QM" ]; then
	echo -e "DRAM P/N:\t $DRAM_PART"
fi
echo
echo -n "To continue press Enter, to abort Ctrl-C:"
read temp

if ! pn_is_valid $PN1; then
	fail "Invalid Part Number"
fi

if ! as_is_valid $AS; then
	fail "Invalid Assembly"
fi

# Cut part number to fit into EEPROM field
PN2=${PN2::$PN2_MAX_LEN}

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

if [ $SOC = "MX8QX" -o $SOC = "MX8QM" ]; then

	# Check DRAM size validity
	if ! dram_size_is_valid $DRAM_SIZE; then
		fail "Invalid DRAM size"
	fi

	# Convert DRAM size to number of 128MB blocks
	DRAM_SIZE=$(((DRAM_SIZE * 1024) / 128))

	# Convert DRAM size to hexadecimal
	DRAM_SIZE=$(printf "0x%.2x" $DRAM_SIZE)
fi

# Program EEPROM fields
write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${PN1_OFFSET}	${PN1}

if [ $EEPROM_VER = "0x03" ]; then
	for i in $(seq 0 $((PN2_MAX_LEN-1))); do
		write_i2c_byte ${I2C_BUS} ${I2C_ADDR} $((PN2_OFFSET+$i)) 0x00
	done

	write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${PN2_OFFSET}	${PN2}
fi

write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${AS_OFFSET}	${AS}
write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${DATE_OFFSET}	${DATE}
write_i2c_mac  ${I2C_BUS} ${I2C_ADDR} ${MAC_OFFSET}	${MAC}
write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${SR_OFFSET}	${SOM_REV}
write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${OPT_OFFSET}	${SOM_OPTIONS}

if [ $SOC = "MX8QX" -o $SOC = "MX8QM" ]; then
	write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${MAGIC_OFFSET}	${MAGIC}
	write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${VER_OFFSET}	${EEPROM_VER}
	write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${DS_OFFSET}	${DRAM_SIZE}
fi
