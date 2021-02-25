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
	HAS_CAMERA=true
elif [ `grep MX6UL /sys/devices/soc0/soc_id` ]; then
	SOC=MX6UL
	ETHERNET_PORTS=2
	USB_DEVS=2
	IS_PCI_PRESENT=false
	HAS_RTC_IRQ=true
	HAS_CAMERA=false
	if [ `grep -c DART /sys/devices/soc0/machine` != 0 ]; then
		CARRIER=6ULCUSTOMBOARD
		# Even though DART-6UL has an RTC IRQ, set to false
		# because of the reboot issue on wakeup when display is connected
		HAS_RTC_IRQ=false
	else
		CARRIER=CONCERTOBOARD
	fi
elif [ `grep i.MX8MM /sys/devices/soc0/soc_id` ]; then
	SOC=MX8MM
	if grep -q DART /sys/devices/soc0/machine; then
		BOARD=DART-MX8MM
	else
		BOARD=VAR-SOM-MX8MM
	fi
	ETHERNET_PORTS=1
	USB_DEVS=3
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Demo_Reel_qHD_540p.mp4
	EMMC_DEV=/dev/mmcblk2
	HAS_RTC_IRQ=true
	HAS_CAMERA=true
	if [ $BOARD = "VAR-SOM-MX8MM" ]; then
		USB_DEVS=2
		HAS_RTC_IRQ=false
	fi
elif [ `grep i.MX8MN /sys/devices/soc0/soc_id` ]; then
	SOC=MX8MN
	ETHERNET_PORTS=1
	USB_DEVS=1
	USBC_PORTS=1
	IS_PCI_PRESENT=false
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Demo_Reel_qHD_540p.mp4
	EMMC_DEV=/dev/mmcblk2
	HAS_RTC_IRQ=false
	HAS_CAMERA=true
elif [ `grep i.MX8MP /sys/devices/soc0/soc_id` ]; then
	SOC=MX8MP
	if grep -q DART-MX8M-PLUS /sys/devices/soc0/machine; then
		BOARD=DART-MX8MP
	else
		BOARD=VAR-SOM-MX8MP
	fi
	ETHERNET_PORTS=2
	USB_DEVS=3
	USB3_DEVS=3
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Demo_Reel_qHD_540p.mp4
	EMMC_DEV=/dev/mmcblk2
	HAS_RTC_IRQ=true
	HAS_CAMERA=true
	if [ $BOARD = "VAR-SOM-MX8MP" ]; then
		USB_DEVS=2
		USB3_DEVS=1
		HAS_RTC_IRQ=false
	fi
elif [ `grep i.MX8M /sys/devices/soc0/soc_id` ]; then
	SOC=MX8M
	BOARD=DART-MX8M
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
	HAS_CAMERA=true
elif [ `grep i.MX8QX /sys/devices/soc0/soc_id` ]; then
	SOC=MX8X
	ETHERNET_PORTS=2
	USB_DEVS=2
	USB3_DEVS=1
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Demo_Reel_qHD_540p.mp4
	EMMC_DEV=/dev/mmcblk0
	HAS_RTC_IRQ=false
	HAS_CAMERA=true
elif [ `grep i.MX8QM /sys/devices/soc0/soc_id` ]; then
	SOC=MX8QM
	if grep -q SPEAR /sys/devices/soc0/machine; then
		BOARD=VAR-SPEAR-MX8
	else
		BOARD=VAR-SOM-MX8
	fi
	ETHERNET_PORTS=2

	if [ $BOARD = "VAR-SPEAR-MX8" ]; then
		USB_DEVS=3
	else
		USB_DEVS=2
	fi
	USB3_DEVS=1
	USBC_PORTS=1
	IS_PCI_PRESENT=true
	MAX_BACKLIGHT_VAL=100
	BACKLIGHT_STEP=10
	VIDEO=${SCRIPT_POINT}/Sony_Surfing_4K_Demo.mp4
	EMMC_DEV=/dev/mmcblk0
	HAS_RTC_IRQ=false
	HAS_CAMERA=true
else	#MX6
	SOC=MX6
	HAS_RTC_IRQ=false
	ETHERNET_PORTS=1
	HAS_CAMERA=true
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

mem_test()
{
	${SCRIPT_POINT}/mx8_mem_test.sh 30 >& /var/log/memtest.log
	if ! grep -q FAIL /var/log/memtest.log; then
		return 0
	else
		return 1
	fi
}

killall udhcpc &> /dev/null

# Run memory test on DART-MX8M-PLUS and VAR-SOM-MX8M-PLUS
if [ "$SOC" = "MX8MP" ]; then
	run_test "Memory" mem_test
fi

# Workaround for DART-MX8M-MINI without LVDS bridge
# Disable MIPI DSI bridge to fix suspend/resume sequence
if [ "$SOC" = "MX8MM" ]; then
  if [ $(i2cdetect -y 0 | grep ^20 | awk '{print $14}') != "UU" ]; then
     echo 32e10000.mipi_dsi > /sys/bus/platform/drivers/imx_sec_dsim_drv/unbind
  fi
fi

echo
echo "Hit Enter to test sound"
echo "***********************"
read
if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM" -o "$SOC" = "MX8MN" -o "$SOC" = "MX8X" -o "$SOC" = "MX8QM" ]; then
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
sleep 7
GATEWAY=`ip route | awk '/default/ { print $3 }' | tail -n 1`
run_test Ethernet ping -I eth0 -q -c 1 $GATEWAY

if [ $ETHERNET_PORTS -gt 1 ]; then
	echo
	echo "Testing Ethernet 2"
	echo "******************"
	ifconfig eth1 up
	ifconfig eth0 down
	sleep 7
	GATEWAY=`ip route | awk '/default/ { print $3 }' | tail -n 1`
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

if [ "$HAS_CAMERA" = "true" ]; then
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
	elif [ "$SOC" = "MX8MP" ]; then
		if [ "$BOARD" = "DART-MX8MP" ]; then
			gst-launch-1.0 v4l2src device=/dev/video1 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
			gst-launch-1.0 v4l2src device=/dev/video2 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
		else
			gst-launch-1.0 v4l2src device=/dev/video1 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
		fi
	elif [ "$SOC" = "MX8MM" -o "$SOC" = "MX8MN" ]; then
		gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
	elif [ "$SOC" = "MX8X" ]; then
		gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
		gst-launch-1.0 v4l2src device=/dev/video1 ! video/x-raw,width=1280,height=720,framerate=30/1  ! autovideosink &> /dev/null
	elif [ "$SOC" = "MX8QM" ]; then
		if [ "$BOARD" = "VAR-SPEAR-MX8" ]; then
			gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
			gst-launch-1.0 v4l2src device=/dev/video1 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
		else
			gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080,framerate=30/1 ! autovideosink &> /dev/null
		fi
	fi
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

if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM" -o "$SOC" = "MX8MN" -o "$SOC" = "MX8MP" -o "$SOC" = "MX8X" -o "$SOC" = "MX8QM" ]; then
	echo
	echo "Testing video playback"
	echo "**********************"
	if ! mount | grep -q sda1; then
		mkdir -p /run/media/sda1
		mount /dev/sda1 /run/media/sda1
	fi
	gplay-1.0 ${VIDEO} &> /dev/null

	if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MM"  -o "$SOC" = "MX8MN" -o "$SOC" = "MX8MP" ]; then
		echo
		echo "Testing GPIOs"
		echo "*************"
		if [ "$SOC" = "MX8M" ]; then
			#${SCRIPT_POINT}/dart-mx8m_kit_gpio_test.sh
			true
		elif [ "$SOC" = "MX8MM" ]; then
			if [ $BOARD != "VAR-SOM-MX8MM" ]; then
				#${SCRIPT_POINT}/dart-mx8m_kit_gpio_test.sh
				true
			else
				${SCRIPT_POINT}/var-som-mx8mm_kit_gpio_test.sh
			fi
		elif [ "$SOC" = "MX8MN" ]; then
			${SCRIPT_POINT}/var-som-mx8mn_kit_gpio_test.sh
		elif [ "$SOC" = "MX8MP" ]; then
			if [ $BOARD = "DART-MX8MP" ]; then
				${SCRIPT_POINT}/dart-mx8mp_kit_gpio_test.sh
			else
				${SCRIPT_POINT}/var-som-mx8mp_kit_gpio_test.sh
			fi
		fi

		echo

		if [ "$SOC" = "MX8M" ]; then
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-0060/regulator ]
			run_test I2C2 [ `i2cdetect -y 2 | cut -c 5-6 | grep -c 60` -eq 1 ]
		elif [ "$SOC" = "MX8MM" ]; then
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-004b/bd718xx-pmic.2.auto/driver -o -d /sys/bus/i2c/devices/0-004b/bd71837-pmic/driver ]
			if [ $BOARD != "VAR-SOM-MX8MM" ]; then
				run_test I2C1 [ -d /sys/bus/i2c/devices/1-0068/rtc/rtc0 ]
			fi
			run_test CAN0 [ -d /sys/class/net/can0 ]
		elif [ "$SOC" = "MX8MN" ]; then
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-004b/bd718xx-pmic.2.auto/driver -o -d /sys/bus/i2c/devices/0-004b/bd71837-pmic/driver ]
			run_test CAN0 [ -d /sys/class/net/can0 ]
		elif [ "$SOC" = "MX8MP" ]; then
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-0025/pca9450-pmic/driver ]
			if [ $BOARD = "DART-MX8MP" ]; then
				run_test I2C1 [ -d /sys/bus/i2c/devices/1-0068/rtc/rtc0 ]
				run_test CAN0 [ -d /sys/class/net/can0 ]
				run_test CAN1 [ -d /sys/class/net/can1 ]
				run_test CAN2 [ -d /sys/class/net/can2 ]
			else
				run_test I2C2 [ -d /sys/bus/i2c/devices/2-0068/rtc/rtc0 ]
				run_test CAN0 [ -d /sys/class/net/can0 ]
			fi
		fi
	fi

	if [ "$SOC" = "MX8X" ]; then
		echo
		echo "Testing GPIOs"
		echo "*************"
		${SCRIPT_POINT}/var-som-mx8x_kit_gpio_test.sh
		echo

		run_test I2C2 [ -d /sys/bus/i2c/devices/2-0068/rtc/rtc0 ]
	fi

	if [ "$SOC" = "MX8QM" ]; then
		if [ "$BOARD" = "VAR-SOM-MX8" ]; then
			echo
			echo "Testing GPIOs"
			echo "*************"
			${SCRIPT_POINT}/var-som-mx8x_kit_gpio_test.sh
			echo

			run_test I2C4 [ -d /sys/bus/i2c/devices/4-0068/rtc/rtc0 ]
		else
			run_test I2C0 [ -d /sys/bus/i2c/devices/0-0068/rtc/rtc0 ]
		fi
	fi

	if [ "$SOC" = "MX8M" -o "$SOC" = "MX8MP" -o "$SOC" = "MX8MM" ] && \
	   [ "$BOARD" != "VAR-SOM-MX8MM" -a "$BOARD" != "VAR-SOM-MX8MP" ]; then
		echo
		echo "Hit Enter to test LEDs"
		echo "**********************"
		read

		LED_GPIOS="99 110 100" #LED1 - LED3
		if [ "$SOC" = "MX8MP" ]; then
			LED_GPIOS="503 502 501" #LED1 - LED3
		fi

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
				if [ "$SOC" != "MX8MP" ]; then
					echo $val > /sys/bus/platform/drivers/leds-gpio/leds/leds/eMMC/brightness #LED4
					sleep 0.1
				fi
			done
		done

		for gpio in `echo $LED_GPIOS`
		do
			echo 1 > /sys/class/gpio/gpio${gpio}/value
			sleep 0.1
			echo $gpio > /sys/class/gpio/unexport
		done
		if [ "$SOC" != "MX8MP" ]; then
			echo 1 > /sys/bus/platform/drivers/leds-gpio/leds/leds/eMMC/brightness
		fi
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

	for f in `ls /etc/pm/sleep.d/`
	do
		/etc/pm/sleep.d/${f} suspend
	done

	rtcwake -m mem -s 2

	for f in `ls /etc/pm/sleep.d/`
	do
		/etc/pm/sleep.d/${f} resume
	done

	echo
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
