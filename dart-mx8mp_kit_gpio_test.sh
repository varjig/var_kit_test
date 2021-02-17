#!/bin/sh

# GPIO test script for iMX8M

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

gpio_test_legacy_carrier()
{
	/unit_tests/memtool -32 3033022C=5 > /dev/null
	/unit_tests/memtool -32 30330228=5 > /dev/null
	gpio_test_pair_bank 5 25 5 24

	/unit_tests/memtool -32 30330230=5 > /dev/null
	/unit_tests/memtool -32 30330234=5 > /dev/null
	gpio_test_pair_bank 5 26 5 27

	gpio_test_pair_bank 4 22 3 20
	gpio_test_pair_bank 4 21 3 19
	gpio_test_pair_bank 4 23 3 21

	/unit_tests/memtool -32 30330138=5 > /dev/null
	/unit_tests/memtool -32 303301AC=5 > /dev/null
	gpio_test_pair_bank 4 25 3 22

	/unit_tests/memtool -32 3033013C=5 > /dev/null
	/unit_tests/memtool -32 303301A8=5 > /dev/null
	gpio_test_pair_bank 4 24 3 23

	/unit_tests/memtool -32 303301B0=5 > /dev/null
	/unit_tests/memtool -32 30330140=5 > /dev/null
	gpio_test_pair_bank 4 26 3 24

	/unit_tests/memtool -32 303301B4=5 > /dev/null
	/unit_tests/memtool -32 30330144=5 > /dev/null
	gpio_test_pair_bank 4 27 3 25

	gpio_test_pair_bank 4 1 4 0

	gpio_test_pair_bank 5 3 5 4
	gpio_test_pair_bank 5 3 1 6
	gpio_test_pair_bank 1 11 1 8

	if [ ! -d "/sys/class/gpio/gpio98" ]; then
		echo 98 > /sys/class/gpio/export
	fi
	echo out > /sys/class/gpio/gpio98/direction
	echo 0 > /sys/class/gpio/gpio98/value
	usleep 20000

	gpio_test_pair_bank 4 16 4 20
	gpio_test_pair_bank 4 16 4 11

	gpio_test_pair_bank 4 3 4 10
	gpio_test_pair_bank 4 3 5 29
}

gpio_test_new_carrier()
{
	#---------J12------------------
	/unit_tests/memtool -32 3033022C=5 > /dev/null
	/unit_tests/memtool -32 30330228=5 > /dev/null
	gpio_test_pair_bank 5 25 5 24

	/unit_tests/memtool -32 30330230=5 > /dev/null
	/unit_tests/memtool -32 30330234=5 > /dev/null
	gpio_test_pair_bank 5 26 5 27

	#---------J16------------------
	gpio_test_pair_bank 3 20 3 19
	gpio_test_pair_bank 3 21 3 22
	gpio_test_pair_bank 3 23 3 24

	# triple short
	/unit_tests/memtool -32 303301A8=5 > /dev/null
	/unit_tests/memtool -32 303301B0=5 > /dev/null
	/unit_tests/memtool -32 303301B4=5 > /dev/null
	gpio_test_pair_bank 4 24 4 26
	gpio_test_pair_bank 4 27 4 26

	#---------J25------------------
	/unit_tests/memtool -32 30330148=5 > /dev/null
	/unit_tests/memtool -32 3033014C=5 > /dev/null
	gpio_test_pair_bank 4 0 4 1

	# triple short
	gpio_test_pair_bank 4 2 4 20
	gpio_test_pair_bank 1 0 4 20

	#---------J14------------------
	/unit_tests/memtool -32 303302a0=C0
	gpio_test_pair_bank 1 11 1 15

	# triple short
	gpio_test_pair_bank 5 5 1 8
	gpio_test_pair_bank 5 5 1 9

	#---------J41------------------
	gpio_test_pair_bank 3 14 3 9
	gpio_test_pair_bank 3 0 3 1

	#triple short
	gpio_test_pair_bank 3 8 3 7
	gpio_test_pair_bank 3 6 3 7

	#---------OV5640 shorts--------

	# enable camera buffer
	echo 497 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio497/direction
	echo 0 >/sys/class/gpio/gpio497/value

	# triple short
	/unit_tests/memtool -32 30330238=5 > /dev/null
	/unit_tests/memtool -32 3033023C=5 > /dev/null
	/unit_tests/memtool -32 30330154=5 > /dev/null
	gpio_test_pair_bank 4 3 5 29
	gpio_test_pair_bank 4 3 5 28

	# triple short
	/unit_tests/memtool -32 30330194=5 > /dev/null
	/unit_tests/memtool -32 3033019C=5 > /dev/null
	/unit_tests/memtool -32 303301A4=5 > /dev/null
	gpio_test_pair_bank 4 19 4 21
	gpio_test_pair_bank 4 19 4 23

	# free camera buffer gpio
	echo 497 > /sys/class/gpio/unexport
}

gpio_test_new_carrier

echo ==================================================
echo -e GPIO: ${STATUS}
