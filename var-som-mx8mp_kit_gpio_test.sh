#!/bin/sh

# GPIO test script for VAR-SOM-MX8X on Symphony carrier board

RED="\\033[0;31m"
NOCOLOR="\\033[0;39m"
GREEN="\\033[0;32m"
GRAY="\\033[0;37m"
OK="${GREEN}OK$NOCOLOR"
FAIL="${RED}FAIL$NOCOLOR"
STATUS=$OK

fail()
{
	STATUS=$FAIL;
	echo -e "$@"
}

gpio_test_pair_num()
{
	if [ ! -d "/sys/class/gpio/gpio$1" ]; then
		echo $1 > /sys/class/gpio/export
	fi
	if [ ! -d "/sys/class/gpio/gpio$2" ]; then
		echo $2 > /sys/class/gpio/export
	fi
	echo in > /sys/class/gpio/gpio$2/direction
	echo out > /sys/class/gpio/gpio$1/direction

	echo 0 > /sys/class/gpio/gpio$1/value
	usleep 20000
	grep -q 0 /sys/class/gpio/gpio$2/value || fail "set 0 gpio $1 -> $2 $FAIL"

	echo 1 > /sys/class/gpio/gpio$1/value
	usleep 20000
	grep -q 1 /sys/class/gpio/gpio$2/value || fail "set 1 gpio $1 -> $2 $FAIL"

	echo in > /sys/class/gpio/gpio$1/direction
	echo in > /sys/class/gpio/gpio$2/direction
	echo $1 > /sys/class/gpio/unexport
	echo $2 > /sys/class/gpio/unexport
}

gpio_test_pair_bank()
{
	echo "Testing GPIO$1[$2] to GPIO$3[$4] raising and falling"
	gpio_test_pair_num $((($1-1)*32+$2)) $((($3-1)*32+$4))
}

##############################################
# J3 HEADER TEST
##############################################

# Configure SPDIF_EXT_CLK as GPI05_IO5 
/unit_tests/memtool -32 303301DC=5 > /dev/null

gpio_test_pair_bank 5 5  1 7

# Configure SPDIF_EXT_CLK as PWM1_OUT
/unit_tests/memtool -32 303301DC=1 > /dev/null

# Restore LVDS backlight 
echo 80 > /sys/class/backlight/backlight/brightness

##############################################
# J16 HEADER TEST
##############################################

# Unbind spidev and ECSPI2 controller
echo spi1.0 > /sys/bus/spi/drivers/spidev/unbind
echo 30830000.spi > /sys/bus/platform/drivers/spi_imx/unbind

# Configure SAI2_TXFS as GPI04_I24
/unit_tests/memtool -32 303301A8=5 > /dev/null
# Configure SAI2_TXC as GPI04_I25
/unit_tests/memtool -32 303301AC=5 > /dev/null
# Configure SAI2_TXD0 as GPI04_I26
/unit_tests/memtool -32 303301B0=5 > /dev/null
# Configure ECSPI2_CLK as GPI05_I10
/unit_tests/memtool -32 303301F0=5 > /dev/null
# Configure ECSPI2_MOSI as GPI05_I11
/unit_tests/memtool -32 303301F4=5 > /dev/null
# Configure ECSPI2_MISO as GPI05_I12
/unit_tests/memtool -32 303301F8=5 > /dev/null

gpio_test_pair_bank 5 10 4 25
gpio_test_pair_bank 5 13 4 23
gpio_test_pair_bank 5 12 4 26
gpio_test_pair_bank 5 11 4 24

# Configure SAI2_TXFS as SAI2_TXFS
/unit_tests/memtool -32 303301A8=0 > /dev/null
# Configure SAI2_TXC as SAI2_TXC
/unit_tests/memtool -32 303301AC=0 > /dev/null
# Configure SAI2_TXD0 as SAI2_TXD0
/unit_tests/memtool -32 303301B0=0 > /dev/null
# Configure ECSPI2_CLK as ECSPI2_CLK
/unit_tests/memtool -32 303301F0=0 > /dev/null
# Configure ECSPI2_MOSI as ECSPI2_MOSI
/unit_tests/memtool -32 303301F4=0 > /dev/null
# Configure ECSPI2_MISO as ECSPI2_MISO
/unit_tests/memtool -32 303301F8=0 > /dev/null

##############################################
# J18 HEADER TEST
##############################################

# Configure UART1_RXD as GPIO_5_23
/unit_tests/memtool -32 30330220=5 > /dev/null
# Configure UART1_TXD as GPIO_5_23
/unit_tests/memtool -32 30330224=5 > /dev/null
# Configure UART4_RXD as GPIO_5_28
/unit_tests/memtool -32 30330238=5 > /dev/null
# Configure UART4_TXD as GPIO_5_29
/unit_tests/memtool -32 3033023C=5 > /dev/null

gpio_test_pair_bank 1 11 5 23
gpio_test_pair_bank 5 23 5 22
gpio_test_pair_bank 5 29 5 28

# Configure UART1_RXD as UART1_RXD
/unit_tests/memtool -32 30330220=0 > /dev/null
# Configure UART1_TXD as UART1_TXD
/unit_tests/memtool -32 30330224=0 > /dev/null
# Configure UART4_RXD as UART4_RXD
/unit_tests/memtool -32 30330238=0 > /dev/null
# Configure UART4_TXD as UART4_TXD
/unit_tests/memtool -32 3033023C=0 > /dev/null

##############################################
# J13 (HDMI) HEADER TEST
##############################################

# Configure NAND_DAT00 as GPIO3_IO06
/unit_tests/memtool -32 303300F8=5 > /dev/null
# Configure NAND_DQS as GPIO3_IO14
/unit_tests/memtool -32 30330118=5 > /dev/null
# Configure HDMI_CEC as GPIO3_IO28
/unit_tests/memtool -32 30330248=5 > /dev/null
# Configure SAI2_MCLK as GPIO4_IO27
/unit_tests/memtool -32 303301B4=5 > /dev/null

gpio_test_pair_bank 4 27 3 14
gpio_test_pair_bank 1 9 3 6
gpio_test_pair_bank 3 28 3 6

# Configure NAND_DAT00 as NAND_DAT00
#/unit_tests/memtool -32 303300F8=0 > /dev/null
# Configure NAND_DQS as NAND_DQS
#/unit_tests/memtool -32 30330118=0 > /dev/null
# Configure HDMI_CEC as HDMI_CEC
#/unit_tests/memtool -32 30330248=0 > /dev/null
# Configure SAI2_MCLK as SAI2_MCLK
#/unit_tests/memtool -32 303301B=0 > /dev/null

##############################################
# J19 (Camera) HEADER TEST
##############################################
gpio_test_pair_bank 1 1 1 13
gpio_test_pair_bank 1 1 1  3

echo ==================================================
echo -e GPIO: ${STATUS}
