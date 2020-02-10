#!/bin/sh

# GPIO test script for VAR-SOM-MX8M-NANO on Symphony carrier board

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

gpio_test_pairnum_memtool()
{
	if [ ! -d "/sys/class/gpio/gpio$1" ]; then
		echo $1 >  /sys/class/gpio/export
	fi
	
	if [ ! -d "/sys/class/gpio/gpio$2" ]; then
		echo $2 >  /sys/class/gpio/export
	fi
	
	echo in > /sys/class/gpio/gpio$2/direction
	echo out > /sys/class/gpio/gpio$1/direction

	# echo 0 > /sys/class/gpio/gpio$1/value
	/unit_tests/memtool 30230000=600020 >& /dev/null
	usleep 20000
	#cat /sys/class/gpio/gpio8/value
	grep -q 0 /sys/class/gpio/gpio$2/value || fail "set 0 gpio $1 -> $2 $FAIL"

	# echo 1 > /sys/class/gpio/gpio$1/value
	/unit_tests/memtool 30230000=608020 >& /dev/null
	grep -q 1 /sys/class/gpio/gpio$2/value || fail "set 1 gpio $1 -> $2 $FAIL"

	/unit_tests/memtool 30230000=600000 >& /dev/null
	echo $1 >  /sys/class/gpio/unexport
	echo $2 >  /sys/class/gpio/unexport
}

gpio_test_pair_bank()
{
	echo "Testing GPIO$1[$2] to GPIO$3[$4] raising and falling"
	gpio_test_pair_num $((($1-1)*32+$2)) $((($3-1)*32+$4))
}

gpio_test_pair_bank_memtool()
{
	echo "Testing GPIO$1[$2] to GPIO$3[$4] raising and falling"
	gpio_test_pairnum_memtool $((($1-1)*32+$2)) $((($3-1)*32+$4))
}

gpio_test_pair_bank 1 8  5 13
/unit_tests/memtool 30230000=20 >& /dev/null
usleep 10
gpio_test_pair_bank 5 10 5 11


/unit_tests/memtool  30330244=5 >& /dev/null
/unit_tests/memtool  30330248=5 >& /dev/null
gpio_test_pair_bank 5 3 5 26

gpio_test_pair_bank 5 3 5 27
gpio_test_pair_bank 5 24 5 25
gpio_test_pair_bank 4 23 4 25
/unit_tests/memtool 3033022c=5
gpio_test_pair_bank 5 20 5 9 
/unit_tests/memtool 3033022c=10 
gpio_test_pair_bank 4 24 4 26


echo ==================================================
echo -e GPIO: ${STATUS}
