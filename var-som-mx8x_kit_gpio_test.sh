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

gpio_set()
{
	num=$(($1*32+$2))

	if [ ! -d "/sys/class/gpio/gpio$1" ]; then
		echo ${num} > /sys/class/gpio/export
	fi

	echo out > /sys/class/gpio/gpio${num}/direction
	echo $3 > /sys/class/gpio/gpio${num}/value
}

gpio_free()
{
	num=$(($1*32+$2))
	echo $num > /sys/class/gpio/unexport
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
	gpio_test_pair_num $(($1*32+$2)) $(($3*32+$4))
}

if [ `grep i.MX8QX /sys/devices/soc0/soc_id` ]; then
	# Disabling, GPIO3_0 and GPIO3_2 are used by parallel camera
	#gpio_test_pair_bank 3 2  3 0
	#gpio_test_pair_bank 3 0  3 23
	gpio_test_pair_bank 3 1  0 28
	# Disabling, GPIO0_26 is used by MIPI camera, GPIO3_3 is used by parallel camera
	#gpio_test_pair_bank 0 26  3 3
	gpio_test_pair_bank 3 1   3 23
	gpio_test_pair_bank 0 24  0 21
	gpio_test_pair_bank 0 21  0 22
	gpio_test_pair_bank 1 4  1 8
	gpio_test_pair_bank 1 5  1 6
	gpio_test_pair_bank 1 3  1 0
	gpio_test_pair_bank 0 19  1 1
	gpio_test_pair_bank 3 21  3 22
	gpio_test_pair_bank 3 19  3 17
	gpio_test_pair_bank 3 18  3 20

elif [ `grep i.MX8QM /sys/devices/soc0/soc_id` ]; then
	gpio_test_pair_bank 0 23 0 17
	gpio_test_pair_bank 4 0  3 31
	gpio_test_pair_bank 3 3  3 2
	# Disabling, GPIO3_4 is used by camera
	# gpio_test_pair_bank 3 4  3 5
	gpio_test_pair_bank 0 19 0 16
	gpio_test_pair_bank 1 8  1 9
	gpio_test_pair_bank 0 9  0 8
	gpio_test_pair_bank 3 15 3 13
	gpio_test_pair_bank 3 16 3 17

	# Set direction of SPI pins in the buffer
	gpio_set 2 4 0
	gpio_set 2 6 0
	gpio_set 2 5 1
	gpio_set 2 7 1

	# Open SPI buffer
	gpio_set 2 16 0

	gpio_test_pair_bank 3 21 3 24
	gpio_test_pair_bank 3 23 3 22

	# Free SPI buffer gpios
	gpio_free 2 4
	gpio_free 2 5
	gpio_free 2 6
	gpio_free 2 7
	gpio_free 2 16
fi

echo ==================================================
echo -e GPIO: ${STATUS}
