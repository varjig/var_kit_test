#!/bin/sh

# GPIO test script on 'JIG' board, iMX6

RED="\\033[0;31m"
NOCOLOR="\\033[0;39m"
GREEN="\\033[0;32m"
GRAY="\\033[0;37m"
OK="${GREEN}OK$NOCOLOR"
FAIL="${RED}FAIL$NOCOLOR"
STATUS="PASS"

failed=0

fail()
{
	STATUS="FAIL";
	echo -e "$@"
	failed=1
	#exit 1
}

gpio_test_pair_num()
{
	if [ ! -d "/sys/class/gpio/gpio$1" ]; then
		echo $1 > /sys/class/gpio/export
	fi
	if [ ! -d "/sys/class/gpio/gpio$2" ]; then
		echo $2 > /sys/class/gpio/export
	fi

	for i in 1 2 3
	do
		echo in > /sys/class/gpio/gpio$2/direction
		echo out > /sys/class/gpio/gpio$1/direction

		echo 0 > /sys/class/gpio/gpio$1/value
		usleep 10000
		grep -q 0 /sys/class/gpio/gpio$2/value || fail "set 0 gpio $1 -> $2 $FAIL"

		echo 1 > /sys/class/gpio/gpio$1/value
		usleep 10000
		grep -q 1 /sys/class/gpio/gpio$2/value || fail "set 1 gpio $1 -> $2 $FAIL"
	done
#	let "EXPECTED = 1 << ($2 % 32)"
#	grep -q $EXPECTED /sys/class/gpio/gpio$2/value || fail "set 1 gpio $1 -> $2 $FAIL"

	echo in > /sys/class/gpio/gpio$1/direction
	echo in > /sys/class/gpio/gpio$2/direction
}

gpio_test_pair_bank()
{
	echo "Testing GPIO$1[$2] to GPIO$3[$4] raising and falling"
	gpio_test_pair_num $((($1-1)*32+$2)) $((($3-1)*32+$4))
}

gpio_test_pair_bank 5 1 3 6

echo out > /sys/class/gpio/gpio$(((5-1)*32+1))/direction
echo 1 > /sys/class/gpio/gpio$(((5-1)*32+1))/value

echo
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_GPIO1_IO03=5
gpio_test_pair_bank 1  3 1  2
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_GPIO1_IO03=3
echo

gpio_test_pair_bank 1  4 1 18

echo
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_CSI_DATA00=5
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_CSI_DATA01=5
gpio_test_pair_bank 4 21 4 22
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_CSI_DATA00=8
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_CSI_DATA01=8
echo

/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_GPIO1_IO08=5
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_GPIO1_IO09=5
gpio_test_pair_bank 1  9 1  8
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_GPIO1_IO08=8
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_GPIO1_IO09=8
echo

gpio_test_pair_bank 3 21 3 22
gpio_test_pair_bank 4 27 4 28
gpio_test_pair_bank 4 23 4 25
gpio_test_pair_bank 4 24 4 26
gpio_test_pair_bank 3 13 3 14
gpio_test_pair_bank 3  4 1 29
gpio_test_pair_bank 1 31 1 30
gpio_test_pair_bank 1 28 3  5

echo $STATUS
if [ $failed -ne 0 ]; then
	exit 1
fi
