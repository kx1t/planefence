# PlaneFence
Collection of scripts using Socket30003 logs to create a list of aircraft that fly low over your location.
Copyright 2020 by Ramon F. Kolb - Licensed under GPL3.0 - see separate license file.

For an example, see http://planefence.ramonk.net

This documentation is for PlaneFence v3.11. For a summary of changes since v1, see at the end of this document. (There was no publicly released PlaneFence v2.)

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
3. You should have GIT installed on your Raspberry Pi. If you don't, you can add it by typing the following on the command line: `sudo apt install git` 
4. You should know how to use your Raspberry Pi's default text editor called `nano`. Most importantly, you should remember that you can save your edits with `CTRL-o` and exit from the editor with `CTRL-x`.

### Note - don't install as user `root`
I strongly recommend to install both `Dump1090.Socket30003` and `PlaneFence` as user `pi` on your Raspberry Pi, and NOT as user `root`. Reasons for this include general system security, but also - once you run PlaneFence as `root`, it will create files that cannot be read or overwritten by any other user, and this stops your ability to run `PlaneFence` as user `pi` in the future.

### Install Dump1090.Socket30003
`Dump1090.Socket30003` collects and stores data about all aircraft within reach in CSV files. We will use these CSV files to extract data about aircraft that fly over our location. Here's how.

To install `Dump1090.Socket30003`, [go here](https://github.com/tedsluis/dump1090.socket30003) and follow the installation instructions from the start **UP TO INCLUDING** the section about adding a [Cron Job](https://github.com/tedsluis/dump1090.socket30003#add-socket30003pl-as-a-crontab-job).
Make sure to check that your lat/long has been correctly set to your approximate location in the `[common]` section of `socket30003.cfg`. If they aren't, your PlaneFence won't work.

If you want to use PlaneFence as-is, then the instructions below will assume that you DON'T change the location or format of the log files. This means, that they are written as `/tmp/dump1090_127_0_0_1-yymmdd.txt` and `....log`.

### Install the scripts from this repository
Clone the repository. Log into you Raspberry Pi and give the following commands:

```
cd
mkdir git
cd git
git clone https://github.com/kx1t/planefence.git
cd planefence
```

### Make a planefence directory in your existing HTML directory
Under normal circumstances, your FlightAware or dump1090 maps are rendered in this directory:
`/usr/share/dump1090-fa/html/` or `/usr/share/dump1090/html/`
Find them - figure out which one you actually use, and then do this:

```
sudo mkdir /usr/share/dump1090-fa/html/planefence
sudo chmod a+rwx /usr/share/dump1090-fa/html/planefence
```

Remember the location of your **planefence directory** . You will need to use it a few times below. For the rest of the installation instructions, we're assuming it is `/usr/share/dump1090-fa/html/planefence`. You will have to substitute your **planefence directory** name if it is different.

### Copy the utilities to the execution directory
Let's make a target directory and move PlaneFence to there:
```
sudo mkdir /usr/share/planefence
sudo chmod a+rwx /usr/share/planefence
cp scripts/* /usr/share/planefence
cp jscript/* /usr/share/dump1090-fa/html/planefence 
chmod a+x /usr/share/planefence/*.sh /usr/share/planefence/*.py start_planefence
```

### Install the Python dependencies
Planefence uses Python2.7, which comes standard with your Raspberry Pi on Stretch and Buster. However, there are a few modules that we need to install.
Type the following:

```
sudo apt update
sudo apt upgrade
sudo apt install python-pip python-numpy python-pandas python-dateutil jq
sudo pip install tzlocal
```

### Edit the configuration files
## planefence.conf
Planefence.sh is the work horse of this project. It makes sure that everything is invoked and generated correctly, and corrects any issues or duplicates that the system may generated. You should make sure that the variables are set to appropriate values for your situation. These variables are stored in `planefence.conf`. Here's how to do that:

```
nano /usr/share/planefence/planefence.conf
```

- Read the instruction/commentary. Each parameter is described in this file. You should consider reviewing at least the following:
- `OUTFILEDIR` contains your *planefence directory* name. If you have a different name, change it there
- `PLANEFENCEDIR` contains the directory name where `planefence.py` is located. If you followed the instructions above, you won't need to change this.
- `MAXALT` contains the altitude ceiling in ft. `MAXALT=5000` means that only planes that are 5000 ft or lower are tracked
- `DIST` contains the radius around your station in (statute) miles. It relies on your location to be set accurately in `socket30003.conf` as described in the setup instructions for that software package.
- `LAT` and `LON` should be set to your approximate Latitude and Longitude. 

## start_planefence
This script is a wrapped for the PlaneFence Systemd Service (see below).
It invokes PlaneFence every approx. 2 minutes. I highly suggest not to change this, but if you must, then you can do so as follows:
```
nano /usr/share/planefence/start_planefence
```
The only parameter you could change here, is `LOOPTIME`, which contains the time between two runs of PlaneFence. I strongly suggest to make this no shorter than 60 seconds, to avoid overloading your system.

### Install the PlaneFence Systemd Service
PlaneFence uses SystemD to run as a daemon. Daemons are programs that run in the background without user interaction.
Perform the following:
```
sudo cp ~/git/planefence/systemd/planefence.service /lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable planefence
sudo systemctl start planefence
```
Later, you can control the PlaneFence service with one of the following commands:
`sudo systemctl stop planefence` -> stops the planefence service
`sudo systemctl disable planefence` -> won't restart the planefence service upon reboot
`systemctl status planefence` -> shows the status of the planefence service
`sudo systemctl start planefence` -> starts the planefence service after you stopped it
`sudo systemctl enable planefence` -> resumes the planefence service after reboot (after you disabled it)

If you want to do a clean, one-off run of PlaneFence from scratch for today, the recommended way of doing this is using the catchup script: `/usr/share/planefence/catchup.sh 1`. See below for more information.

## catchup.sh

This script will do a "catch-up" run. It will iterate through all `/tmp/dump1090*.txt` files and create PlaneFence pages for them.
Usage: `/usr/share/planefence/catchup.sh [days]`
Example: `/usr/share/planefence/catchup.sh 1`
The optional `days` argument indicates how many days of history the script will generate, with "1" being today, and "8" being today + the previous 7 days. The script will skip those days for which there is no data available.

# Seeing your PlaneFence page
Once you have run the app at least once, you can find it at `http://<address_of_rpi>/planefence`.
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
