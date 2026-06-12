Phone Charge Controller

Overview

Phone Charge Controller is a Bash script that automatically manages charging for Android and iPhone devices connected through a USB hub that supports uhubctl.

The script monitors battery levels and controls USB power to keep devices within a defined charging range. This helps reduce unnecessary charging cycles and can be useful for testing devices, kiosk systems, device farms, and long-term charging environments.

Features

Automatically detects Android and iPhone devices connected to USB hubs.

Reads Android battery level using ADB.

Reads iPhone battery level using libimobiledevice.

Powers USB ports on when battery monitoring begins.

Charges devices only when battery level is below the configured minimum threshold.

Stops charging when the configured maximum battery level is reached.

Supports Android and iPhone simultaneously.

Automatically restarts usbmuxd to improve iPhone detection reliability.

Runs continuously in a monitoring loop.

Requirements

Linux system

uhubctl

ADB (Android Debug Bridge)

libimobiledevice

usbmuxd

Supported USB hub with per-port power switching

Installation

Install required packages.

Ubuntu/Debian example:

sudo apt install adb usbmuxd libimobiledevice-utils

Install uhubctl if it is not already available on your system.

Configuration

Edit the configuration variables in the script:

MIN_BAT=40
MAX_BAT=80
CHECK_INTERVAL=300

MIN_BAT

Battery percentage that triggers charging.

MAX_BAT

Battery percentage where charging stops.

CHECK_INTERVAL

Time in seconds before the next monitoring cycle.

How It Works

1. All supported USB ports are powered on.

2. The script waits for devices to initialize.

3. Android and iPhone ports are detected automatically.

4. Battery levels are collected.

5. If battery level is below MIN_BAT, charging continues.

6. Charging stops when battery level reaches MAX_BAT.

7. USB power for the corresponding port is turned off.

8. The script sleeps for CHECK_INTERVAL seconds and repeats the process.

Android Battery Detection

The script uses:

adb shell dumpsys battery

to retrieve the current battery level.

iPhone Battery Detection

The script uses:

ideviceinfo -q com.apple.mobile.battery

to retrieve the current battery level through libimobiledevice.

Logging

The script writes status messages through the internal log() function.

Example messages:

Controller started

Powering USB hubs ON

Android battery=35%

Android charging start

Android charging 80%

Android charging complete

Android power off

iPhone battery=42%

iPhone charging start

iPhone charging complete

iPhone power off

Limitations

The USB hub must support port power switching through uhubctl.

Android devices must have ADB access available.

iPhone devices must be recognized by usbmuxd and libimobiledevice.

Some USB hubs may report ports differently depending on firmware and chipset.

Use Cases

Device charging stations

Mobile testing labs

Device farms

Kiosk systems

Development environments

Long-term battery maintenance

License

Use and modify freely according to your project's license requirements.

