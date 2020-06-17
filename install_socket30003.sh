#!/bin/bash
# INSTALL_SOCKET30003 - a Bash shell script to install Ted Sluis's socket30003
# based on socket30003
#
# Usage: ./install_socket30003.sh [lat lon]
# Or from your BASH command line on your Raspberry Pi:
# bash -c "$(wget -q -O - https://raw.githubusercontent.com/kx1t/planefence/master/install_socket30003.sh)"
#
# Developed/tested and Copyright 2020 Ramon F. Kolb, with contributions and collaboration by Rodney Yeo.
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
echo "Welcome to Socket30003 Setup - version 200617-1600"
echo "https://github.com/kx1t/planefence"
echo "Copyright 2020 by Ramón F. Kolb"
echo ""
echo "This script will attempt to install and configure socket30003."
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

echo "--------------------------------------------------------------------"
echo "Now, we will install a number of dependencies. Some packages may already be installed"
echo "so you can safely ignore any warning about this."
echo ""
read -p "Press enter to start."

sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git perl

echo "--------------------------------------------------------------------"
echo "Done installing the dependencies. Let's get Socket30003!"

# Now we are going to make the GIT directory and clone PlaneFence into it:
[ ! -d "$HOME/git" ] && mkdir $HOME/git
cd $HOME/git
if [ ! -d "dump1090.socket30003" ]
then
	git clone https://github.com/tedsluis/dump1090.socket30003.git
	cd dump1090.socket30003
else
	cd dump1090.socket30003
	git pull
fi

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Now installing configuring Socket30003..."

[ ! -z "$1" ] && LATITUDE="$1"
[ ! -z "$2" ] && LONGITUDE="$2"

a=""
while [ "$a" != "y" ]
do
	if [ ! -z "$LATITUDE" ]
	then
		echo "You indicated that your station latitude is $LATITUDE."
	else
		read -p "Enter your latitude in decimal degrees N, for example 42.39663: " LATITUDE
	fi
	echo "Your station latitute is $LATITUDE"

	echo ""
	if [ ! -z "$LONGITUDE" ]
	then
		echo "You indicated that your station latitude is $LONGITUDE."
	else
		read -p "Enter your longitude in decimal degrees E, for example -71.17726: " LONGITUDE
	fi
	echo "Your station longitude is $LONGITUDE"
	echo ""
	read "Please confirm that these coordinates are correct? (Y/n): " a
	[ "$a" == "n" ] && continue
	
	echo ""
	echo "Let's establish some range parameters."
	echo "Please note that the default units are those that you set in socket30003."
	echo "If you like to keep the default values, simply press ENTER for each question."
	
	DISTUNIT="kilometer"
  	ALTUNIT="meter"
  	SPEEDUNIT="kilometerph"
  	INSTALLDIRECTORY="/usr/share/socket30003"
	echo ""
  	echo "DISTANCE"
  	echo "Default: $DISTUNIT - press enter to keep this value"
  	echo "1) kilometer"
  	echo "2) nauticalmile"
  	echo "3) mile"
  	echo "4) meter"
	read -p "Enter 1-4: " b
  	case "$b" in
  	  1)
 	     DISTUNIT="kilometer"
	     ;;
	  2)
      	     DISTUNIT="nauticalmile"
      	     ;;
    	  3)
      	     DISTUNIT="mile"
      	     ;;
 	  4)
      	     DISTUNIT="meter"
   	esac
   
  	echo ""
  	echo "ALTITUDE"
  	echo "Default: $ALTUNIT - press enter to keep this value"
	echo "1) meter"
	echo "2) feet"
	read -p "Enter 1-2: " b
  	case "$b" in
    	   1)
      		ALTUNIT="meter"
      		;;
    	   2)
      		ALTUNIT="feet"
   	esac
   
  	echo ""
  	echo "SPEED"
  	echo "Default: $SPEEDUNIT - press enter to keep this value"
	echo "1) kilometer per hour"
  	echo "2) knot per hour"
  	echo "3) mile per hour"
  	read -p "Enter 1-3: " b
  	case "$b" in
    		1)
      			SPEEDUNIT="kilometerph"
      			;;
    		2)
      			SPEEDUNIT="knotph"
      			;;
    		3)
      			SPEEDUNIT="mileph"
  	esac
   
  	echo ""
  	echo "INSTALL DIRECTORY"
	echo "Default: $INSTALLDIRECTORY"
  	read -p "Press Enter to keep this, or type an installation directory below: " b
  	[ ! -z "$b" ] && INSTALLDIRECTORY="$b"
   
  	echo ""
  	echo "--------------------------------------------------------------------"
  	echo ""
  	echo "Check if your answers are correct. Do you want to continue?"
  	read -p "(Answering \"N\" will allow you to re-enter your data.) (y/N) " a
done

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Writing these values to the config file..."

INSTALLDIRX=$(echo $INSTALLDIRECTORY|sed 's;/;\\/;g')
cp socket30003.cfg socket30003.cfg.org
sed -i 's/\(^\s*latitude=\).*/\1'"$LATITUDE"'/' socket30003.cfg
sed -i 's/\(^\s*longitude=\).*/\1'"$LONGITUDE"'/' socket30003.cfg
sed -i 's/\(^\s*distanceunit=\).*/\1'"$DISTUNIT"'/' socket30003.cfg
sed -i 's/\(^\s*altitudeunit=\).*/\1'"$ALTUNIT"'/' socket30003.cfg
sed -i 's/\(^\s*speedunit=\).*/\1'"$SPEEDUNIT"'/' socket30003.cfg
sed -i 's/\(^\s*installdirectory=\).*/\1'"$INSTALLDIRX"'/' socket30003.cfg

echo "done!"
echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Invoking socket30003.pl installation script..."

# First create the install directory. This is needed because the install script attempts to do this as user=PI
# When using the default /usr/share/socket30003 target, this will fail because of permissions.
# So we need to pre-empt this:

[ ! -d "$INSTALLDIRECTORY" ] && sudo mkdir "$INSTALLDIRECTORY"
sudo chown pi:pi "$INSTALLDIRECTORY"
chmod u+rwx,go+rx-w "$INSTALLDIRECTORY"

./install.pl -install "$INSTALLDIRECTORY"

chmod a+x "$INSTALLDIRECTORY"/*.pl

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Writing crontab..."

#write out current crontab
crontab -l > /tmp/mycron 2>/dev/null
#echo new cron into cron file
echo "*/5 * * * * sudo $INSTALLDIRECTORY/socket30003.pl" >> /tmp/mycron
#install new cron file
crontab /tmp/mycron
rm /tmp/mycron

echo "Done installing socket30003, goodbye!"
echo ""
echo "--------------------------------------------------------------------"
echo ""
