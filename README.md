# MX93 Instructions

## Using Host Computer

1. Create USB Stick image:

```
$ ./var-create-usb-img
```

2. Write image to USB stick:

```
$ zcat imx_kit_test_usb_<commit id>.img.gz | sudo dd of=/dev/sdX bs=1M conv=fsync status=progress && sync
```

## Using VAR-SOM-MX93 with Symphony Board

1. Plug USB drive into Symphony Board

2. Write SOM EEPROM Image and DDR table:

```
# /run/media/imx_kit_test-sda1/mx93_vareeprom_dram.sh
```

3. Write SOM EEPROM configuration

```
# /run/media/imx_kit_test-sda1/var_eeprom.sh
```
