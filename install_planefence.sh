#!/bin/bash
# INSTALL_PLANEFENCE - a Bash shell script to render a HTML and CSV table with nearby aircraft
# based on socket30003
#
# Usage: ./install_planefence.sh
# Or from your BASH command line on your Raspberry Pi:
# bash -c "$(wget -q -O - https://raw.githubusercontent.com/kx1t/planefence/master/install_planefence.sh)"
#
# Copyright 2020 by Ramón F. Kolb, with collaborations by Rodney Yeo
#
# This software may be used under the terms and conditions of the GPLv3 license. 
# The terms and conditions of this license are included with the Github
# distribution of this package, and are also available here:
# https://raw.githubusercontent.com/kx1t/planefence/master/LICENSE
#
# The package contains parts of, and modifications or derivatives to the following:
# Dump1090.Socket30003 by Ted Sluis: https://github.com/tedsluis/dump1090.socket30003
# These packages may incorporate other software and license terms.
#
# Summary of License Terms
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see https://www.gnu.org/licenses/.
clear
echo "Welcome to PlaneFence Setup - version200618-1600"
echo "https://github.com/kx1t/planefence"
echo "Copyright 2020 by Ramón F. Kolb, with collaborations by Rodney Yeo"
echo ""
echo "This script will attempt to install and configure PlaneFence."
echo ""
echo "--------------------------------------------------------------------"

# Let's start checking if we're running as user=PI. If not, throw a bunch of warnings
if [ "$USER" != "pi" ]
then
	echo "WARNING... You should really run this script as user \"pi\"."
	echo "Instead, you are running it as user \""$USER"\"."
	echo ""
	read -p "Are you sure you want to continue? (y/N) " choice
	[ "${choice:0:1}" != "y" ] && exit -1
	echo "--------------------------------------------------------------------"
fi
if [ "$USER" == "root" ]
then
	echo "Sorry to bother again. You should REALLY NOT run this script as user \"root\"."
	echo "Did you invoke the script with \"sudo\"? Then please run it without \"sudo\"."
	echo ""
	echo "Installing the software as \"root\" will cause all kind of security issues later."
	echo ""
	echo "--> We strongly recommend you answer \"NO\" below. <--"
	echo ""
	read -p "Are you sure you want to continue? (y/N) " choice
	[ "${choice:0:1}" != "y" ] && exit -1
	echo "Ok then, you have been warned. Don't blame us..."
	echo "--------------------------------------------------------------------"
fi

# Let's find out what the dump1090 directory is
echo "Figuring out where your dump1090 directory is..."
if [ -d "/usr/share/dump1090-fa" ] && [ -d "/usr/share/dump1090" ]
then
	echo "It appears that both \"/usr/share/dump1090-fa\" and \"/usr/share/dump1090\" exist on your system.
	echo "Which one would you like to use for your PlaneFence installation?
	echo "1) /usr/share/dump1090-fa"
	echo "2) /usr/share/dump1090"
	a=""
	while [ "$a" == "" ]
	do
		read -p "Please enter 1 or 2, or enter a custom directory name: " a
		[ "$a" == "1" ] && DUMPDIR="/usr/share/dump1090-fa"
		[ "$a" == "2" ] && DUMPDIR="/usr/share/dump1090"
	done
elif [ -d "/usr/share/dump1090-fa" ]
then
	DUMPDIR="/usr/share/dump1090-fa"
	echo "We found $DUMPDIR."
	read -p "Press ENTER to use this, or type a custom directory name: " a
	[ "$a" != "" ] && DUMPDIR="$a"
elif [ -d "/usr/share/dump1090" ]
then
	DUMPDIR="/usr/share/dump1090"
	echo "We found $DUMPDIR."
	read -p "Press ENTER to use this, or type a custom directory name: " a
	[ "$a" != "" ] && DUMPDIR="$a"
elif [ -d "/usr/share/dump1090-mutability" ]
then
	DUMPDIR="/usr/share/dump1090-mutability"
	echo "We found $DUMPDIR."
	read -p "Press ENTER to use this, or type a custom directory name: " a
	[ "$a" != "" ] && DUMPDIR="$a"
else
	echo "We cannot find any dump1090 installation."
	echo "Are you sure FlightAware or Dump1090 is correctly installed?"
	echo "If you are sure and know the directory name, type it here."
	read -p "Otherwise, please press ENTER to exit the installation script: " a
	if [ "$a" != "" ]
	then
		DUMPDIR="$a"
	else
		echo "To install dump1090-fa, you can find easy to follow instructions at:"
		echo "https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-dump1090-fa"
		exit -1
	fi
fi

echo "--------------------------------------------------------------------"
echo "Now, we will install a number of dependencies. Some packages may already be installed"
echo "so you can safely ignore any warning about this."
echo ""
echo "This will take while - initial installation may take 15 - 30 minutes."
echo "Go get some coffee. Or tea. Or beer. Or pizza. Or, if you want to be boring, a drink of water!"
echo ""
read -p "Press enter to start."

sudo apt update -y
sudo apt upgrade -y
sudo apt install -y python-pip python-numpy python-pandas python-dateutil jq bc gnuplot git
sudo pip install tzlocal

echo "--------------------------------------------------------------------"
echo "Done installing the dependencies. Let's get PlaneFence!"

# Now we are going to make the GIT directory and clone PlaneFence into it:
[ ! -d "$HOME/git" ] && mkdir $HOME/git
cd $HOME/git
if [ ! -d "planefence" ]
then
	git clone https://github.com/kx1t/planefence.git
	cd planefence
else
	cd planefence
	git pull
fi

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Now installing PlaneFence..."
# Now make some directories and ensure that the right owners and modes are set
[ ! -d "/usr/share/planefence" ] && sudo mkdir /usr/share/planefence
[ ! -d "/usr/share/dump1090-fa/html/planefence" ] && sudo mkdir /usr/share/dump1090-fa/html/planefence
sudo chown pi:pi /usr/share/planefence "$DUMPDIR"/html/planefence
chmod u+rwx,go+rx-w /usr/share/planefence "$DUMPDIR"/html/planefence

# Copy the scipts and other files into their location
cp scripts/* /usr/share/planefence
cp jscript/* "$DUMPDIR"/html/planefence
cp systemd/start_* /usr/share/planefence
sudo cp systemd/*.service /lib/systemd/system

chmod a+x /usr/share/planefence/*.sh
chmod a+x /usr/share/planefence/*.py
chmod a+x /usr/share/planefence/*.pl
chmod a+x /usr/share/planefence/start_*

echo ""
echo "--------------------------------------------------------------------"
echo "The installation is now complete. Let's configure PlaneFence so you are ready to go!"
echo ""
a=""
while [ "$a" != "y" ]
do
	LATITUDE="$(cat /etc/default/dump1090* | grep -oP '(?<=lat )[^ ]*')"
	LONGITUDE="$(cat /etc/default/dump1090* | grep -oP '(?<=lon )[^ ]*')"
	[ "$LATITUDE$LONGITUDE" != "" ] && echo "We found your Lat/Lon in your dump1090 setup as $LONGITUDE N/$LATITUDE E".
	echo -n "Enter your latitude in decimal degrees N, "
	[ "$LATITUDE$LONGITUDE" != "" ] && read -p "or press enter to keep $LATITUDE: " b || read -p "for example 42.39663: " b
	[ "$b" != "" ] && $LATITUDE="$b"
	if [ "$LATITUDE" == "" ]
	then
		echo "You must enter a Latitude to continue. Try again!"
		continue;
	fi	
	echo "Your station latitute is $LATITUDE"
	echo ""
	
	echo -n "Enter your longitude in decimal degrees E, "
	[ "$LATITUDE$LONGITUDE" != "" ] && read -p "or press enter to keep $LONGITUDE: " b || read -p "for example -71.1772: " b
	[ "$b" != "" ] && $LONGITUDE="$b"
	if [ "$LONGITUDE" == "" ]
	then
		echo "You must enter a Longitude to continue. Try again!"
		continue;
	fi	
	echo "Your station longitude is $LONGITUDE"
	echo ""
	echo "Let's establish some range parameters."
	echo "Please note that the default units are those that you set in socket30003."
	echo "If you like to keep the default values, simply press ENTER for each question."
	
	MAXALT=5000
	echo ""
	read -p "Maximum in-range altitude ["$MAXALT"]: " b
	[ "$b" != "" ] && MAXALT="$b"

	DIST=1.73795
	echo ""
	read -p "Maximum radius around your Long/Lat ["$DIST"]: " b
	[ "$b" != "" ] && DIST="$b"
	
	MY="my"
	echo ""
	read -p "What is the name you want to put in the webpage title? ["$MY"]: " b
	[ "$b" != "" ] && MY="$b"

	echo ""
	echo Check if your answers are correct. Do you want to continue?""
	read -p "(Answering \"N\" will allow you to re-enter your data.) (y/N) " a
done

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "NEXT - SOCKET30003 INSTALLATION"
if [ "$(crontab -l |grep socket30003 | wc -l)" -gt "0" ]
then
	echo "We think that Socket30003 has already been installed here:"
	read -raa <<< $(crontab -l |grep socket30003)
	SOCKDIR=$(dirname ${a[6]})
	echo $SOCKDIR
	unset a
	read -p "Press ENTER to use this, or type a custom directory name: " a
	[ "$a" != "" ] && SOCKDIR="$a"
else
	echo "We cannot find any socket30003 installation."
	echo "Are you sure Socket30003 is correctly installed?"
	echo "If you are sure and know the directory name, type it here."
	read -p "Otherwise, please press ENTER to INSTALL Socket30003: " a
	[ "$a" != "" ] && SOCKDIR="$a" || bash -c "$(wget -q -O - https://raw.githubusercontent.com/kx1t/planefence/master/install_socket30003.sh)" install_socket30003.sh $LATITUDE $LONGITUDE
	if [ "$SOCKDIR" == "" ]
	then
		read -raa <<< $(crontab -l |grep socket30003)
		SOCKDIR=$(dirname ${a[6]})
	fi
fi
echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Configuration summary:"
echo "Latitude (N): "$LATITUDE""
echo "Longitude (E): "$LONGITUDE""
echo "Maximum in-range altitude: "$MAXALT""
echo "Maximum in-range distance from $LATITUDE N / $LONGITUDE E: "$DIST""
echo "Socket30003 directory: "$SOCKDIR""
echo "Dump1090 directory: "$DUMPDIR""
read -p "Press ENTER to continue or CTRL-C to abort..."

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Writing configuration values..."

# First escape all forward slashes in DUMPDIR and SOCKDIR:
DUMPDIR=$(echo $DUMPDIR|sed 's;/;\\/;g')
SOCKDIR=$(echo $SOCKDIR|sed 's;/;\\/;g')

sed -i 's/\(^\s*LAT=\).*/\1'"$LATITUDE"'/' /usr/share/planefence/planefence.conf
sed -i 's/\(^\s*LON=\).*/\1'"$LONGITUDE"'/' /usr/share/planefence/planefence.conf
sed -i 's/\(^\s*MAXALT=\).*/\1'"$MAXALT"'/' /usr/share/planefence/planefence.conf
sed -i 's/\(^\s*DIST=\).*/\1'"$DIST"'/' /usr/share/planefence/planefence.conf
sed -i 's/\(^\s*SOCKETCONFIG=\).*/\1'"$SOCKDIR"'/' /usr/share/planefence/planefence.conf
sed -i 's/\(^\s*MY=\).*/\1'"$MY"'/' /usr/share/planefence/planefence.conf
sed -i 's/\(^\s*OUTFILEDIR=\).*/\1'"$DUMPDIR\/html\/planefence"'/' /usr/share/planefence/planefence.conf

sed -i 's/\(^\s*LAT=\).*/\1'"$LATITUDE"'/' /usr/share/planefence/planeheat.sh
sed -i 's/\(^\s*LON=\).*/\1'"$LONGITUDE"'/' /usr/share/planefence/planeheat.sh
sed -i 's/\(^\s*MAXALT=\).*/\1'"$MAXALT"'/' /usr/share/planefence/planeheat.sh
sed -i 's/\(^\s*DIST=\).*/\1'"$DIST"'/' /usr/share/planefence/planeheat.sh

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Starting PlaneFence service..."

sudo systemctl daemon-reload
sudo systemctl enable planefence
sudo systemctl start planefence

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Done!"
echo "You can find more settings in /usr/share/planefence/planefence.conf
echo "Feel free to look at those and change them to your liking."
echo ""
echo "Sayonara! Best regards 
