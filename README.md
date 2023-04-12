# USB Stick Creation Instructions

## Using Host Computer

1. Create USB Stick image:

```
$ ./var-create-usb-img
```

2. Write image to USB stick:

```
$ zcat var_kit_test_usb_<commit id>.img.gz | sudo dd of=/dev/sdX bs=1M conv=fsync status=progress && sync
```

# Program EEPROM

## Using VAR-SOM-MX93 with Symphony Board

1. Plug USB drive into Symphony Board

2. Write SOM EEPROM Image and DDR table:

```
# /run/media/var_kit_test-sda1/mx93_vareeprom_dram.sh
```

3. Write SOM EEPROM configuration

```
# /run/media/var_kit_test-sda1/var_eeprom.sh
```

## Using VAR-SOM-AM62 with Symphony Board

1. Plug USB drive into Symphony Board

2. Write SOM EEPROM Image and DDR table:

```
# /run/media/var_kit_test-sda1/am62_vareeprom_dram.sh
```

3. Write SOM EEPROM configuration

```
# /run/media/var_kit_test-sda1/var_eeprom.sh
```
