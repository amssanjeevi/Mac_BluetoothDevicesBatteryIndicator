#!/bin/sh

#  BluetoothDeviceStatus.sh
#  Battery Indicator
#
#  Created by admin on 30/07/19.
#  Copyright © 2019 admin. All rights reserved.

output=$(ioreg -r -l -n AppleHSBluetoothDevice | egrep '"BatteryPercent" = |  \|   "Bluetooth Product Name" = ')
echo $output
