#!/bin/sh

# iMX board test script

RED="\\033[0;31m"
NOCOLOR="\\033[0;39m"
GREEN="\\033[0;32m"
GRAY="\\033[0;37m"
OK="${GREEN}OK$NOCOLOR"
FAIL="${RED}FAIL$NOCOLOR"

#readonly ABSOLUTE_FILENAME=`readlink -e "$0"`
#readonly ABSOLUTE_DIRECTORY=`dirname ${ABSOLUTE_FILENAME}`
#readonly SCRIPT_POINT=${ABSOLUTE_DIRECTORY}
SCRIPT_POINT="/run/media/sda1"

CARRIER=""
MAX_BACKLIGHT_VAL=7
BACKLIGHT_STEP=1
USB3_DEVS=0
USBC_PORTS=0

if [ `grep MX7 /sys/devices/soc0/soc_id` ]; then
	SOC=MX7
	ETHERNET_PORTS=2
	USB_DEVS=2
	IS_PCI_PRESENT=true
	HAS_RTC_IRQ=false
elif [ `grep MX6UL /sys/devices/soc0/soc_id` ]; then
	SOC=MX6UL
	ETHERNET_PORTS=2
	USB_DEVS=2
	IS_PCI_PRESENT=false
	HAS_RTC_IRQ=true
	if [ `grep -c DART /sys/devices/soc0/machine` != 0 ]; then
		CARRIER=6ULCUSTOMBOARD
	else
		CARRIER=CONCERTOBOARD
	fi
elif [ `grep i.MX8MM /sys/devices/soc0/soc_id` ]; then
	SOC=MX8MM
	ETHERNET_PORTS=1
	USB_DEVS=3
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Demo_Reel_HD_1080p.mp4
	EMMC_DEV=/dev/mmcblk2
	HAS_RTC_IRQ=true
elif [ `grep i.MX8M /sys/devices/soc0/soc_id` ]; then
	SOC=MX8M
	ETHERNET_PORTS=1
	USB_DEVS=3
	USB3_DEVS=3
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Sony_Surfing_4K_Demo.mp4
	EMMC_DEV=/dev/mmcblk0
	HAS_RTC_IRQ=true
elif [ `grep i.MX8QX /sys/devices/soc0/soc_id` ]; then
	SOC=MX8X
	ETHERNET_PORTS=2
	USB_DEVS=2
	USB3_DEVS=1
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Demo_Reel_HD_1080p.mp4
	EMMC_DEV=/dev/mmcblk0
	HAS_RTC_IRQ=false
else	#MX6
	SOC=MX6
	HAS_RTC_IRQ=false
	ETHERNET_PORTS=1
	if [ `grep -c SoloCustomBoard /sys/devices/soc0/machine` != 0 ]; then
		# CARRIER=SOLOCB
		USB_DEVS=2
		IS_PCI_PRESENT=false
	elif [ `grep -c VAR-DART /sys/devices/soc0/machine` != 0 ]; then
		# CARRIER=DT6
		USB_DEVS=2
		IS_PCI_PRESENT=true
	else
		# CARRIER=MX6CB
		USB_DEVS=4
		IS_PCI_PRESENT=true
	fi
fi

run_test()
{
	name="$1"
	shift
	echo -n -e "$name: "
	eval "$@" > /dev/null && echo -e "$OK" || echo -e "$FAIL"
}

run_test_verbose()
{
	name="$1"
	shift
	echo -n -e "$name: "
	eval "$@" && echo -e "$OK" || echo -e "$FAIL"
}

run()
{
	# just to avoid piping after each command
	"$@" >> /var/log/test.log 2>&1
}

killall udhcpc &> /dev/null

echo
echo "Hit Enter to test sound"
echo "***********************"
read
if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM" -o "$SOC" = "MX8X" ]; then
	run amixer set Headphone 63
else
	run amixer set Master 125
	run amixer set 'Output Mixer HiFi' on
fi
run aplay /usr/share/sounds/alsa/Front_Center.wav

echo "Testing Ethernet"
echo "****************"
ifconfig eth0 up
if [ $ETHERNET_PORTS -gt 1 ]; then
	ifconfig eth1 down
fi
sleep 4
if [ "$SOC" != "MX8M" -a "$SOC" != "MX8MM" -a "$SOC" != "MX8X" ]; then
	run udhcpc -n -i eth0
	sleep 3
fi
GATEWAY=`ip route | awk '/default/ { print $3 }'`
run_test Ethernet ping -I eth0 -q -c 1 $GATEWAY

if [ $ETHERNET_PORTS -gt 1 ]; then
	echo
	echo "Testing Ethernet 2"
	echo "******************"
	ifconfig eth1 up
	ifconfig eth0 down
	sleep 4
	if [ "$SOC" != "MX8M" -a "$SOC" != "MX8MM" -a "$SOC" != "MX8X" ]; then
		run udhcpc -n -i eth1
		sleep 3
	fi
	GATEWAY=`ip route | awk '/default/ { print $3 }'`
	run_test Ethernet_2 ping -I eth1 -q -c 1 $GATEWAY
fi

echo
echo "Testing WiFi"
echo "************"
ifconfig wlan0 up
ifconfig eth0 down
if [ $ETHERNET_PORTS -gt 1 ]; then
	ifconfig eth1 down
fi
connmanctl disable wifi &> /dev/null
nmcli radio wifi off &> /dev/null
killall wpa_supplicant &> /dev/null
sleep 0.6

run wpa_supplicant -B -Dnl80211 -iwlan0 -c${SCRIPT_POINT}/wpa_variscite.conf
sleep 3
run udhcpc -n -i wlan0
sleep 4

run_test "WiFi Association" "dmesg | grep -q 'IPv6: ADDRCONF(NETDEV_CHANGE): wlan0: link becomes ready'"
run_test "WiFi ping" ping -I wlan0 -q -c 1 192.168.2.254

echo
echo "Testing bluetooth"
echo "*****************"
HCI_DEV=`hciconfig | grep UART | cut -d ':' -f 1`
hciconfig $HCI_DEV up
run_test "Bluetooth scan" hcitool scan
run_test "Bluetooth ping" l2ping -c 1 5C:EA:1D:61:88:BE
hciconfig $HCI_DEV down

echo
if [ "$IS_PCI_PRESENT" = "true" ]; then
	run_test PCI "lspci | grep ''"
fi

echo
run_test USB "[ `lsusb -t | grep 'Class=Mass Storage' | grep -c 480M` = $USB_DEVS ]"
echo Working USB ports:
lsusb -t | grep 'Class=Mass Storage' | grep '480M'

if [ $USBC_PORTS -gt 0 ]; then
	sync
	umount /dev/sd* &> /dev/null

	echo
	echo "Flip the USB type C cable in the receptacle and hit Enter to continue"
	echo "*********************************************************************"
	read
	run_test USB "[ `lsusb -t | grep 'Class=Mass Storage' | grep -c 480M` = $USB_DEVS ]"
	echo Working USB ports:
	lsusb -t | grep 'Class=Mass Storage' | grep '480M'
fi

if [ $USB3_DEVS -gt 0 ]; then
	sync
	umount /dev/sd* &> /dev/null

	echo
	echo "Replace the USB2 disks with USB3 disks and hit Enter to continue"
	echo "****************************************************************"
	read
	run_test USB3 "[ `lsusb -t | grep 'Class=Mass Storage' | grep -c 5000M` = $USB3_DEVS ]"
	echo Working USB3 ports:
	lsusb -t | grep 'Class=Mass Storage' | grep '5000M'

	if [ $USBC_PORTS -gt 0 ]; then
		sync
		umount /dev/sd* &> /dev/null

		echo
		echo "Flip the USB type C cable in the receptacle and hit Enter to continue"
		echo "*********************************************************************"
		read
		run_test USB3 "[ `lsusb -t | grep 'Class=Mass Storage' | grep -c 5000M` = $USB3_DEVS ]"
		echo Working USB3 ports:
		lsusb -t | grep 'Class=Mass Storage' | grep '5000M'
	fi
fi

echo
run_test Clock hwclock
if [ "$HAS_RTC_IRQ" = "true" ]; then
	echo
	echo "Hit Enter to sleep for 1 second - make sure the board wakes up after 1 second"
	echo "*****************************************************************************"
	read
	echo enabled > /sys/class/rtc/rtc0/device/power/wakeup
	rtcwake -m mem -s 1
	echo
fi

echo
echo "Hit Enter to test backlight"
echo "***************************"
read
for f in /sys/class/backlight/backlight*/brightness
do
	for i in `seq $MAX_BACKLIGHT_VAL -$BACKLIGHT_STEP 0`;
	do
		echo $i > $f
		sleep 0.05
	done
	for i in `seq 1 $BACKLIGHT_STEP $MAX_BACKLIGHT_VAL`;
	do
		echo $i > $f
		sleep 0.05
	done
done

ifconfig wlan0 down &>/dev/null
killall wpa_supplicant &>/dev/null
killall udhcpc &>/dev/null
ifconfig eth0 up &>/dev/null
if [ $ETHERNET_PORTS -gt 1 ]; then
	ifconfig eth1 up &>/dev/null
fi

echo
echo "Testing camera"
echo "**************"
export DISPLAY=:0
if [ "$SOC" = "MX6" ]; then
	gst-launch-1.0 imxv4l2videosrc imx-capture-mode=5 ! imxeglvivsink
elif [ "$SOC" = "MX7" ]; then
	gst-launch-1.0 imxv4l2videosrc device=/dev/video1  imx-capture-mode=3 ! imxpxpvideosink
	xinput_calibrator &> /dev/null & sleep 0.01; killall xinput_calibrator
elif [ "$SOC" = "MX8M" ]; then
	gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
	gst-launch-1.0 v4l2src device=/dev/video1 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
elif [ "$SOC" = "MX8MM" -o "$SOC" = "MX8X" ]; then
	gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
fi

if [ "$SOC" = "MX6UL" ]; then
	echo "Verify the LED is blinking and hit Enter"
	echo "****************************************"
	for f in /sys/devices/soc0/leds/leds/*/trigger
	do
		echo heartbeat > $f
	done
	read
	echo

	if [ "$CARRIER" = "CONCERTOBOARD" ]; then
		echo "Testing GPIOs"
		echo "*************"
		run_test_verbose GPIO: ${SCRIPT_POINT}/var-som-6ul_kit_gpio_test.sh
		echo
	fi
fi

if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM" -o "$SOC" = "MX8X" ]; then
	echo
	echo "Testing video playback"
	echo "**********************"
	gplay-1.0 ${VIDEO} &> /dev/null

	if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM" ]; then
		echo
		echo "Testing GPIOs"
		echo "*************"
		${SCRIPT_POINT}/iMX8M_gpio_test
		echo

		if [ "$SOC" = "MX8M" ]; then
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-0060/regulator ]
			run_test I2C2 [ `i2cdetect -y 2 | cut -c 5-6 | grep -c 60` -eq 1 ]
		elif [ "$SOC" = "MX8MM" ]; then
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-004b/bd71837-pmic ]
			run_test I2C1 [ -d /sys/bus/i2c/devices/1-0068/rtc/rtc0 ]
		fi
	fi

	if [ "$SOC" = "MX8X" ]; then
		run_test I2C2 [ -d /sys/bus/i2c/devices/2-0068/rtc/rtc0 ]
	fi

	if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM" ]; then
		echo
		echo "Hit Enter to test LEDs"
		echo "**********************"
		read

		LED_GPIOS="99 110 100" #LED1 - LED3

		for gpio in `echo $LED_GPIOS`
		do
			echo $gpio > /sys/class/gpio/export
			echo out > /sys/class/gpio/gpio${gpio}/direction
		done

		for i in `seq 1 2`
		do
			for val in `echo 1 0`
			do
				for gpio in `echo $LED_GPIOS`
				do
					echo $val > /sys/class/gpio/gpio${gpio}/value
				done
				echo $val > /sys/bus/platform/drivers/leds-gpio/leds/leds/eMMC/brightness #LED4
				sleep 0.1
			done
		done

		for gpio in `echo $LED_GPIOS`
		do
			echo 1 > /sys/class/gpio/gpio${gpio}/value
			sleep 0.1
			echo $gpio > /sys/class/gpio/unexport
		done
		echo 1 > /sys/bus/platform/drivers/leds-gpio/leds/leds/eMMC/brightness
	fi
fi

killall evtest &> /dev/null
echo
echo "Click on all buttons to test them (be carefull with the reset button)"
echo "*********************************************************************"
echo
for i in `ls  /dev/input/by-path/*key*`;
do
	evtest $i &
done

umount /dev/sd* &> /dev/null
sync
