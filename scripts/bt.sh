#!/bin/bash

device_address="74:45:CE:A1:6F:C4"

# Check if the device is connected
connected=$(bluetoothctl info $device_address | grep "Connected: yes")

if [ -n "$connected" ]; then
    # Device is connected, disconnect
    echo "Disconnecting from $device_address"
    bluetoothctl disconnect $device_address
else
    # Device is not connected, connect
    echo "Connecting to $device_address"
    bluetoothctl connect $device_address
fi
