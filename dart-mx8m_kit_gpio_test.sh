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

if [ `grep i.MX8MM /sys/devices/soc0/soc_id` ]; then
	SOC=MX8MM
elif [ `grep i.MX8M /sys/devices/soc0/soc_id` ]; then
	SOC=MX8M
else
	fail "Unsupported SOM"
	exit 1
fi

/unit_tests/memtool -32 30330240=5
/unit_tests/memtool -32 3033023C=5
gpio_test_pair_bank 5 25  5 24
/unit_tests/memtool -32 30330244=5
/unit_tests/memtool -32 30330248=5
gpio_test_pair_bank 5 26  5 27

# GPIO4_22 is used by SPIDEV CS in kernel 5.4.X
#gpio_test_pair_bank 4 22  3 20
gpio_test_pair_bank 4 21  3 19
gpio_test_pair_bank 4 23  3 21
gpio_test_pair_bank 4 25  3 22
gpio_test_pair_bank 4 24  3 23
gpio_test_pair_bank 4 26  3 24
gpio_test_pair_bank 4 27  3 25
gpio_test_pair_bank 4 16  4 00

# GPIO4_12 is used on DART-MX8M as reset pin of
# the second camera. Run only on DART-MX8M-MINI
if [ $SOC = "MX8MM" ]; then
	gpio_test_pair_bank 4 12  4 01
fi

if [ ! -d "/sys/class/gpio/gpio107" ]; then
	echo 107 > /sys/class/gpio/export
fi
if [ ! -d "/sys/class/gpio/gpio98" ]; then
	echo 98 > /sys/class/gpio/export
fi
echo out > /sys/class/gpio/gpio107/direction
echo out > /sys/class/gpio/gpio98/direction
echo 1 > /sys/class/gpio/gpio107/value
echo 1 > /sys/class/gpio/gpio98/value
usleep 100000

gpio_test_pair_bank 4 10  4 20

#gpio_test_pair_bank 4 11  4 02

#/unit_tests/memtool -32 303301EC=5
#/unit_tests/memtool -32 30330058=0
#gpio_test_pair_bank 5 04  1 12
#/unit_tests/memtool -32 303301E8=5
#/unit_tests/memtool -32 30330040=0
gpio_test_pair_bank 5 03  1 06
echo ==================================================
echo -e GPIO: ${STATUS}
