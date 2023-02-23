#!/bin/bash

I2C_ADDR=0x52

# Magic offset and size
MAGIC_OFFSET=0x00
MAGIC_LEN=2

if [ `grep i.MX93 /sys/devices/soc0/soc_id` ]; then
	I2C_BUS=2

	# Part number offsets and sizes
	PN1_OFFSET=0x02
	PN1_LEN=8

	# Assembly offset and size
	AS_OFFSET=0x0a
	AS_LEN=10

	# Date offset and size
	DATE_OFFSET=0x14
	DATE_LEN=9

	# MAC offset and size
	MAC_OFFSET=0x1d
	MAC_LEN=6

	# SOM revision offset and size
	SR_OFFSET=0x23
	SR_LEN=1

	# EEPROM version offset and size
	VER_OFFSET=0x24
	VER_LEN=1

	# SOM options offset and size
	OPT_OFFSET=0x25
	OPT_LEN=1

	# DRAM size offset and size
	DS_OFFSET=0x26
	DS_SIZE=1

	# DDR CRC32
	DRAM_CRC_OFFSET=0x2c
	DRAM_CRC_SIZE=0x4

	# DDR VIC Part Number
	DRAM_VIC_OFFSET=0x30
	DRAM_VIC_SIZE=0x2

	# EEPROM Field Values
	MAGIC="MX"
	EEPROM_VER="0x01"
	SOM_OPTIONS="0x0f"
else
	I2C_BUS=0

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

	# EEPROM version offset and size
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
fi

# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
read_i2c_byte()
{
	VAL=`i2cget -y $1 $2 $3`
	echo $VAL
}

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

# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
# 4: value
write_i2c_u16()
{
	# Convert the input to hex and pad with leading zeros
	hex=$(printf '%04x' "$4")

	# Extract the low and high bytes and save to variables
	LOW="0x${hex:2:2}"
	HIGH="0x${hex:0:2}"

	# Get next address
	ADDR_LOW=$3
	ADDR_HIGH=$(printf '0x%X' $((ADDR_LOW + 1)))

	# Write each byte
	write_i2c_byte $1 $2 ${ADDR_LOW} ${LOW}
	write_i2c_byte $1 $2 ${ADDR_HIGH} ${HIGH}
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

dram_pn_is_valid()
{
	case $1 in
		[0-9][0-9][0-9]-VIC[0-9][0-9][0-9][0-9])
			return 0
			;;
		[0-9][0-9][0-9][0-9]-VIC[0-9][0-9][0-9][0-9])
			return 0
			;;
		*)
			return 1;
			;;
	esac
}

dram_vic_is_valid()
{
	case $1 in
		[0-9][0-9][0-9][0-9])
			return 0
			;;
		*)
			return 1;
			;;
	esac
}

dram_pn_matches_eeprom_size()
{
	# Get DRAM_SIZE from DRAM_PART
	DRAM_SIZE=$(echo "$1" | grep -oE '^[0-9]+')
	EEPROM_DRAM_SIZE="$(read_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${DS_OFFSET})"
	EEPROM_DRAM_SIZE=$(((EEPROM_DRAM_SIZE * 128)))

	if [ "$DRAM_SIZE" = "$EEPROM_DRAM_SIZE" ]; then
		return 0
	else
		return 1
	fi
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
elif [ `grep i.MX8MP /sys/devices/soc0/soc_id` ]; then
	SOC="MX8MP"
	EEPROM_VER="0x03"
	if grep -q DART-MX8M-PLUS /sys/devices/soc0/machine; then
		BOARD="DART-MX8MP"
	else
		BOARD="VAR-SOM-MX8MP"
	fi
elif [ `grep i.MX8QXP /sys/devices/soc0/soc_id` ]; then
	SOC="MX8QX"
elif [ `grep i.MX8QM /sys/devices/soc0/soc_id` ]; then
	SOC="MX8QM"
elif [ `grep i.MX93 /sys/devices/soc0/soc_id` ]; then
	SOC="MX93"
else
	echo "Unsupported SoM"
	exit 1
fi

if [ $SOC = "MX8MM" ]; then
	SOM_REV="0x01"
elif [ $SOC = "MX8MN" ]; then
	SOM_REV="0x01"
elif [ $SOC = "MX8MP" ]; then
	SOM_REV="0x01"
elif [ $SOC = "MX8QX" ]; then
	SOM_REV="0x00"
	SOM_OPTIONS="0x07"
elif [ $SOC = "MX8QM" ]; then
	SOM_REV="0x00"
	SOM_OPTIONS="0x07"
elif [ $SOC = "MX93" ]; then
	SOM_REV="0x01"
fi

if [ $SOC = "MX8MM" ]; then
	if [ $BOARD = "DART-MX8MM" ]; then
		echo -n "Enter Part Number: VSM-DT8MM-"
	else
		echo -n "Enter Part Number: VSM-MX8MM-"
	fi
elif [ $SOC = "MX8MP" ]; then
	if [ $BOARD = "DART-MX8MP" ]; then
		echo -n "Enter Part Number: VSM-DT8MP-"
	else
		echo -n "Enter Part Number: VSM-MX8MP-"
	fi
elif [ $SOC = "MX8MN" ]; then
	echo -n "Enter Part Number: VSM-MX8MN-"
elif [ $SOC = "MX8QX" ]; then
	echo -n "Enter Part Number: VSM-MX8X-"
elif [ $SOC = "MX8QM" ]; then
	echo -n "Enter Part Number: VSM-MX8-"
elif [ $SOC = "MX93" ]; then
	echo -n "Enter Part Number: VSM-MX93-"
fi
read -e PN
# if PN2_OFFSET is empty, PN1 and PN2 are combined into PN1
if [ ! -z ${PN2_OFFSET} ]; then
	PN1=$(echo ${PN} | cut -c1-3)
	PN2=$(echo ${PN} | cut -c4-)
else
	PN1=$PN
fi
echo -n "Enter Assembly: "
read -e AS

echo -n "Enter Date (YYYY MMM DD, e.g. 2018 May 10): "
read -e DATE

echo -n "Enter MAC: "
read -e MAC

# Set VAR-SOM-MX8X DRAM size and SOM options according to P/N
# AC EC WB|D Options are defined here:
# https://github.com/varigit/uboot-imx/blob/277ff23bfc0eb4a1fdd0bc114b64edddff311903/board/variscite/common/imx9_eeprom.h#L18-L21
if [ $SOC = "MX93" ]; then
	WIFI=1    # Bit 0 is set
	ETH=2     # Bit 1 is set
	AUDIO=4   # Bit 2 is set
	case $PN in
	"004") # VAR-SOM-MX93D_1700C_2048R_16G_AC_EC_TP_WBD_CT_REV1.0
		DRAM_PART="2048-VIC1032"
		SOM_OPTIONS=$((WIFI | ETH | AUDIO))
		;;
	"007") # VAR-SOM-MX93D_1700C_2048R_64G_AC_EC_TP_WBD_CT_REV1.0
		DRAM_PART="2048-VIC1032"
		SOM_OPTIONS=$((WIFI | ETH | AUDIO))
		;;
	"008") # VAR-SOM-MX93D_1700C_2048R_8G_EC_CET_REV1.0
		DRAM_PART="2048-VIC1032"
		SOM_OPTIONS=$((ETH))
		;;
	"009") # VAR-SOM-MX93D_1500C_2048R_8G_EC_ET_REV1.0
		DRAM_PART="2048-VIC1032"
		SOM_OPTIONS=$((ETH))
		;;
	*)
		echo "Unsupported VAR-SOM-MX93 P/N ($PN)"
		exit 1
	esac
	# Convert to hex and print
	SOM_OPTIONS=$(printf "0x%02x" $SOM_OPTIONS)
	echo "SOM Options: ${SOM_OPTIONS}"
fi

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
		"103")
			SOM_OPTIONS="0x0f"
			;;
		"104")
			SOM_OPTIONS="0x00"
			;;
		"105")
			SOM_OPTIONS="0x01"
			;;
		"106")
			SOM_OPTIONS="0x0f"
			;;
		"107")
			SOM_OPTIONS="0x07"
			;;
		"110")
			SOM_OPTIONS="0x06"
			;;
		"112")
			SOM_OPTIONS="0x03"
			;;
		"113")
			SOM_OPTIONS="0x00"
			;;
		"114")
			SOM_OPTIONS="0x02"
			;;
		"115")
			SOM_OPTIONS="0x03"
			;;
		"117")
			SOM_OPTIONS="0x0f"
			;;
		"118")
			SOM_OPTIONS="0x02"
			;;
		"119")
			SOM_OPTIONS="0x0a"
			;;
		"201")
			SOM_OPTIONS="0x0f"
			;;
		"202")
			SOM_OPTIONS="0x0f"
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
	"002")
		SOM_OPTIONS="0x00"
		;;
	"101")
		SOM_OPTIONS="0x0f"
		;;
	"102")
		SOM_OPTIONS="0x00"
		;;
	"103")
		SOM_OPTIONS="0x0c"
		;;
	"104")
		SOM_OPTIONS="0x07"
		;;
	"107")
		SOM_OPTIONS="0x00"
		;;
	"109")
		SOM_OPTIONS="0x03"
		;;
	"201")
		SOM_OPTIONS="0x0f"
		;;
	*)
		echo "Unsupported VAR-SOM-MX8MN P/N"
		exit 1
	esac
fi

# Set DART-MX8M-PLUS/VAR-SOM-MX8M-PLUS SOM options according to P/N
if [ $SOC = "MX8MP" ]; then
	if [ $BOARD = "DART-MX8MP" ]; then
		case $PN in
		"005A")
			SOM_OPTIONS="0x07"
			;;
		"101")
			SOM_OPTIONS="0x07"
			;;
		"102")
			SOM_OPTIONS="0x07"
			;;
		"103")
			SOM_OPTIONS="0x07"
			;;
		"104")
			SOM_OPTIONS="0x07"
			;;
		"105")
			SOM_OPTIONS="0x01"
			;;
		*)
			echo "Unsupported DART-MX8MP P/N"
			exit 1
		esac
	else
		case $PN in
		"003A")
			SOM_OPTIONS="0x07"
			;;
		"004")
			SOM_OPTIONS="0x07"
			;;
		"103")
			SOM_OPTIONS="0x07"
			;;
		"104")
			SOM_OPTIONS="0x07"
			;;
		"105")
			SOM_OPTIONS="0x05"
			;;
		"106")
			SOM_OPTIONS="0x02"
			;;
		"107")
			SOM_OPTIONS="0x03"
			;;
		"108")
			SOM_OPTIONS="0x02"
			;;
		"109")
			SOM_OPTIONS="0x03"
			;;
		"110")
			SOM_OPTIONS="0x02"
			;;
		"111")
			SOM_OPTIONS="0x01"
			;;
		"112")
			SOM_OPTIONS="0x07"
			;;
		"113A")
			SOM_OPTIONS="0x07"
			;;
		*)
			echo "Unsupported VAR-SOM-MX8MP P/N"
			exit 1
		esac
	fi
fi

echo
echo "The following parameters were given:"
if [ $SOC = "MX8MM" ]; then
	if [ $BOARD = "DART-MX8MM" ]; then
		echo -e "PN:\t\t VSM-DT8MM-${PN}"
	else
		echo -e "PN:\t\t VSM-MX8MM-${PN}"
	fi
elif [ $SOC = "MX8MP" ]; then
	if [ $BOARD = "DART-MX8MP" ]; then
		echo -e "PN:\t\t VSM-DT8MP-${PN}"
	else
		echo -e "PN:\t\t VSM-MX8MP-${PN}"
	fi
elif [ $SOC = "MX8MN" ]; then
	echo -e "PN:\t\t VSM-MX8MN-${PN}"
elif [ $SOC = "MX8QX" ]; then
	echo -e "PN:\t\t VSM-MX8X-${PN}"
elif [ $SOC = "MX8QM" ]; then
	echo -e "PN:\t\t VSM-MX8-${PN}"
elif [ $SOC = "MX93" ]; then
	echo -e "PN:\t\t VSM-MX93-${PN}"
fi

echo -e "Assembly:\t $AS"
echo -e "DATE:\t\t $DATE"
echo -e "MAC:\t\t $MAC"
if [ $SOC = "MX8QX" -o $SOC = "MX8QM" -o $SOC = "MX93" ]; then
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

# Verify DRAM_PART:
#   1. Is a valid format
#   2. Matches the size already written in eeprom by the eeprom tool
if [ $SOC = "MX93" ]; then
	if ! dram_pn_is_valid "${DRAM_PART}"; then
		fail "Invalid DRAM Part Number ($DRAM_PART)"
	fi
	if ! dram_pn_matches_eeprom_size ${DRAM_PART}; then
		fail "DRAM_PART: \"$DRAM_PART\" does not match size written by EEPROM tool"
	fi
	DRAM_VIC=${DRAM_PART##*-VIC}
	if ! dram_vic_is_valid "${DRAM_VIC}"; then
		fail "Invalid DRAM VIC ($DRAM_VIC)"
	fi
fi

if [ ! -z ${PN2_OFFSET} ]; then
	# Cut part number to fit into EEPROM field
	PN2=${PN2::$PN2_MAX_LEN}
fi

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

# Write PN2 if EEPROM_VER == 0x03 and PN2_OFFSET is not empty
if [ "$EEPROM_VER" = "0x03" ] && [ ! -z "${PN2_OFFSET}" ]; then
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

# Starting with MX93, write the DRAM VIC to EEPROM if
# DRAM_VIC and DRAM_VIC_OFFSET are not empty
if [ ! -z "${DRAM_VIC}" ] && [ ! -z "${DRAM_VIC_OFFSET}" ]; then
	write_i2c_u16 ${I2C_BUS} ${I2C_ADDR} ${DRAM_VIC_OFFSET}	${DRAM_VIC}
fi

if [ $SOC = "MX8QX" -o $SOC = "MX8QM" ]; then
	write_i2c_string ${I2C_BUS} ${I2C_ADDR} ${MAGIC_OFFSET}	${MAGIC}
	write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${VER_OFFSET}	${EEPROM_VER}
	write_i2c_byte ${I2C_BUS} ${I2C_ADDR} ${DS_OFFSET}	${DRAM_SIZE}
fi
