#!/bin/bash
# INSTALL_PLANEFENCE - a Bash shell script to render a HTML and CSV table with nearby aircraft
# based on socket30003
#
# Usage: ./uninstall_planefence.sh
# Or from your BASH command line on your Raspberry Pi:
# bash -c "$(wget -q -O - https://raw.githubusercontent.com/kx1t/planefence/master/uninstall_planefence.sh)"
#
# Developed/tested and Copyright 2020 Ramon F. Kolb.
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
echo "Welcome to PlaneFence Uninstall - version200617-1220"
echo "https://github.com/kx1t/planefence"
echo "Copyright 2020 by Ramón F. Kolb"
echo ""
echo "This script will attempt to uninstall PlaneFence."
echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "--> WARNING: UNINSTALLING PLANEFENCE IS IRREVOCABLE <--"
read -p "Are you sure you want to continue? (y/N) " choice
[ "${choice:0:1}" != "y" ] && exit -1
echo ""
read -p "Well then... press ENTER to start the uninstallation of PlaneFence"
echo ""
echo "--------------------------------------------------------------------"
echo ""

PLANEFENCELOC="/usr/share/planefence/planefence.sh"
# Find planefence.sh. We need this to read the location of the planefence.conf file
if [ ! -f "$PLANEFENCELOC" ]
then
  echo "Cannot find "$PLANEFENCELOC". Uninstall failed. No files were deleted."
  exit -1
fi 

# Get the location of planefence.conf
IFS=" =#" read -raa <<< $(grep -P '^(?=[\s]+[^#])[^#](PLANEFENCEDIR)' $PLANEFENCELOC)
PLANEFENCEDIR="${a[1]}"
[ "$PLANEFENCEDIR" == "" ] && PLANEFENCEDIR="/usr/share/planefence"

IFS=" =#" read -raa <<< $(grep -P '^(?=[\s]+[^#])[^#](PLANEFENCEDIR)' $PLANEFENCEDIR/planefence.conf)
OUTFILEDIR="${a[1]}"

echo -n "Stopping and deleting SystemD service... "
sudo systemctl stop planefence
sudo systemctl disable planefence
sudo rm -f /lib/systemd/system/planefence.service
echo "done!"

echo ""
echo -n "Removing $PLANEFENCEDIR... "
sudo rm -rf $PLANEFENCEDIR
echo "done!"

echo ""
echo "Your web directory, "$OUTFILEDIR""
echo "may contain valuable data collected by Planefence and NoiseCapt."
echo "We can save this data for you in $HOME/planefence-data."
read -p "Do you want to (s)ave this data, or (d)elete it? (S/d) " choice
if [ "${choice:0:1}" != "d" ]
then
  echo -n "Saving your data to $HOME/planefence-data... "
  [ ! -d "$HOME/planefence-data" ] && mkdir "$HOME/planefence-data"
  cp $OUTFILEDIR/*.csv $HOME/planefence-data
  cp /tmp/noicecapt-*.log $HOME/planefence-data
  echo "done!"
fi

echo ""
echo -n "Removing $OUTFILEDIR... "
sudo rm -rf $OUTFILEDIR
echo "done!"

echo ""
echo -n "Cleaning up the /tmp directory... "
sudo rm -f /tmp/dump1090-p* /tmp/planeheat* /tmp/dump1090-temp* /tmp/planefence* /tmp/planetweet* /tmp/tweets.log
echo "done!"

if [ -d "$HOME/git/planefence" ]
then
  echo ""
  echo "You cloned PlaneFence from GitHub to $HOME/git/planefence".
  read -p "Do you want to (D)elete this data, or (l)eave it alone? (D/l) " choice
  if [ "${choice:0:1}" != "l" ]
  then
    echo -n "Deleting $HOME/git/planefence... "
    sudo rm -f $HOME/git/planefence
    echo "done!"
  fi
fi

echo ""
echo "--------------------------------------------------------------------"
echo ""
echo "Done deleting PlaneFence. You can always re-install it later by going to http://github.com/kx1t/planefence."
echo "Thank you, see you again!"
