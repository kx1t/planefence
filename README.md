# PlaneFence
Collection of scripts using Socket30003 logs to create a list of aircraft that fly low over your location.
Copyright 2020 by Ramon F. Kolb - Licensed under GPL3.0 - see separate license file.

For an example, see http://planefence.ramonk.net

This documentation is for PlaneFence v3.12. For a summary of changes since v1, see at the end of this document. (There was no publicly released PlaneFence v2.)

## Attributions, inclusions, and prerequisites

1. You must have a Raspberry Pi with a working version of dump1090, dump1090-fa, dump1090-mutability, or the equivalent dump978 versions installed. If you don't have this, stop right here. It makes no sense to continue unless you understand the basic functions of the ADSB receiver for Raspberry Pi
2. The scripts in this repository rely on [dump1090.socket30003](https://github.com/tedsluis/dump1090.socket30003), used and distributed under the GPLv3.0 license. 
3. The instructions below err on the side of completeness. It may look a bit overwhelming, but if you follow each step to the letter, you should be able to set this up in 30 minutes or less.

What does this mean for you? Follow the installation instructions and you should be good :)

## Installation

Follow the following steps in order.

### Prerequisites
1. These instructions assume that you already have a relatively standard installation of dump1090, dump1090-fa, dump1090-mutability, or the equivalent dump978 on your Raspberry Pi. If you don't have this, Google "FlightAware feeder", "Radarbox24 feeder", or something similar to get started. Get a RPi 3B+ or 4, an RTL-SDR dongle, an antenna, and come back here when you can access a map with aircraft flying over your home.
2. You should feel somewhat comfortable installing and configuring software on a Raspberry Pi or a similar Linux system using Github. You will be making modifications to your system, and there is a chance you screw things up. You do so at your own risk.
3. Feel free to inspect the installation scripts. It's generally a good security practice to make sure you understand and agree what they are doing, before you run a script written by a stranger on your machine. 


### Note - don't (ever!) install as user `root`
When you follow the instructions below, I strongly recommend to install all software and scripts as user `pi` and NOT as user `root`. Reasons for this include general system security, but also - once you run PlaneFence as `root`, it will create files that cannot be read or overwritten by any other user, and this stops your ability to run `PlaneFence` as user `pi` in the future.
So, please stick with user `pi`.


### AUTO-INSTALL (UNTESTED/DO AT YOUR OWN RISK)
You can automatically install and configure PlaneFence by logging into your Raspberry Pi as user `pi`, and then copying / pasting the following line:

```
bash -c "$(wget -q -O - https://raw.githubusercontent.com/kx1t/planefence/master/install_planefence.sh)"
```

Note -- if `dump1090.socket30003` isn't already installed in one of the most common locations, this install script will also attempt to install that file

Again -- if you come across any errors, please let us know. You can resolve them by following the manual instructions described in README-manual-install.md

## catchup.sh

This script will do a "catch-up" run. You should use this sparingly - under normal circumstances, you will never need it. It will iterate through all `/tmp/dump1090*.txt` files and create PlaneFence pages for them.
Usage: `/usr/share/planefence/catchup.sh [days]`
Example: `/usr/share/planefence/catchup.sh 1`
The optional `days` argument indicates how many days of history the script will generate, with "1" being today, and "8" being today + the previous 7 days. The script will skip those days for which there is no data available.

# Seeing your PlaneFence page
Once the app is running, you can find the results at `http://<address_of_rpi>/planefence`. Give it a few minutes after installation!
Replace `<address_of_rpi>` with whatever the address is you normally use to get to the SkyAware or Dump1090 map.
For reference, see (http://planefence.ramonk.net).

# Optional - Tweeting Your Updates
Once you have PlaneFence completely up and running, you can add an option to send a Tweet for every overflying plane.
The setup of this is a bit complicated as you will have to register your own Twitter Developer Account, and get a 
App Key for your application.
Detailed installation instructions can be accessed here:
https://github.com/kx1t/planefence/blob/master/README-twitter.md

If you want to see an example of how this works, go here: https://twitter.com/PlaneBoston

# Known Issues
- Planes that are seen multiple times during consecutive runs, may show up multiple times
- The script hasn't been thoroughly tested. Please provide feedback and exerpts of /tmp/planefence.log that show the activites around the time the issues occurred.
- The code is a bit messy and at times, disorganized. However, it's overly documented and should be easy to understand and adapt.

# Summary of License Terms
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Release History
- v1: PlaneFence based on BASH and Python scripts. Iterates through all logs every time it is invoked
- v1: Using CRON to invoke script every 2 minutes
- v2: never publicly released
- v3.0: total rewrite of planefence.sh and major simplification of planefence.py
- v3.0: only iterates through the socket30003 log lines that weren't processed previously. Reduced execution time dramatically, from ~1 minute for 1M lines, to an average of ~5 seconds between two runs that are 2 minutes apart.
- v3.0: uses Systemd to run planefence as a daemon; removed need for cronjob.
- v3.11: clean-up, minor fixes, updated documentation, etc.
- v.3.12: added auto-install script
