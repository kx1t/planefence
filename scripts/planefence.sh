#!/bin/bash
# PLANEFENCE - a Bash shell script to render a HTML and CSV table with nearby aircraft
# based on socket30003
#
# Usage: ./planefence.sh
#
# Copyright 2020 Ramon F. Kolb - licensed under the terms and conditions
# of GPLv3. The terms and conditions of this license are included with the Github
# distribution of this package, and are also available here:
# https://github.com/kx1t/planefence/
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
# -----------------------------------------------------------------------------------
# Feel free to make changes to the variables between these two lines. However, it is
# STRONGLY RECOMMENDED to RTFM! See README.md for explanation of what these do.
# These are the input and output directories and file names:
	OUTFILEDIR=/usr/share/dump1090-fa/html/planefence # the web directory you want PlaneFence to write to
	PLANEFENCEDIR=/usr/share/planefence # the directory where this file and planefence.py are located
	MAXALT=5000 # only planes below this altitude are reported. Must correspond to your socket30003 altitude unit
	DIST=2.5 # only planes closer than this distance are reported. If CALCDIST (below) is set to "--calcdist", then the distance is in statute miles
#		   if CALCDIST="", then the unit is whatever you used in your socket30003 setup
	LAT=42.39663 # Latitude of the center point of the map. *** SEE BELOW
	LON=-71.17726 # Longitude of the center point of the map. *** SEE BELOW
	HISTTIME=7 # number of days shown in the history section of the website
#	CALCDIST="" # if this variable is set to "", then planefence.py will use the reported distance from your station instead of recalculating it
	CALCDIST="--calcdist" # if this variable is set to "--calcdist", then planefence.py will calculate the distance relative to LAT and LON as defined above
#
# *** SPECIAL CONSIDERATION OF LON and LAT
# Only if CALCDIST="--calcdist", PlaneFence will recalculate every entry to see if it is within DIST of the defined LON/LAT.
# If you set CALCDIST to "", then it will use the reported distance as configured in socket30003.cfg (see the documentation of that package).
# Recalculating the distances is a bit more processor-intensive than using the reported values, so ONLY set CALCDIST="--calcdist" if
# you want the center-point of PlaneFence to be somewhere that is not your station's exact LAT/LON.
# Note that the link in the HTML page headings always uses the LAT/LON as defined above. You can use that to obfuscate your exact location.
# -----------------------------------------------------------------------------------
# Only change the variables below if you know what you are doing.
	if [ "$1" != "" ] && [ "$1" != "reset" ]
	then # $1 contains the date for which we want to run PlaneFence
		FENCEDATE=$(date --date="$1" '+%y%m%d')
	else
		FENCEDATE=$(date --date="today" '+%y%m%d')
	fi

	TMPDIR=/tmp
	LOGFILEBASE=$TMPDIR/dump1090-127_0_0_1-
	OUTFILEBASE=$OUTFILEDIR/planefence
	OUTFILEHTML=$OUTFILEBASE-$FENCEDATE.html
	OUTFILECSV=$OUTFILEBASE-$FENCEDATE.csv
	OUTFILETMP=$TMPDIR/dump1090-pf-temp.csv
	INFILETMP=$TMPDIR/dump1090-pf.txt
	TMPLINES=$TMPDIR/dump1090-pf-temp-$FENCEDATE.tmp
	VERBOSE="--verbose"
#	VERBOSE=""
	HISTORY=history.html
	HISTFILE=$OUTFILEDIR/$HISTORY
	VERSION=3.0
	LOGFILE=/tmp/planefence.log
#	LOGFILE=/dev/stdout
	CURRENT_PID=$$
	PROCESS_NAME=$(basename $0)

# -----------------------------------------------------------------------------------
#
# Functions
#
# First create an function to write to the log
LOG ()
{
	if [ -n "$1" ]
	then
	      IN="$1"
	else
	      read IN # This reads a string from stdin and stores it in a variable called IN
	fi

	if [ "$VERBOSE" != "" ]
	then
		# set the color scheme in accordance to the log level urgency
		if [ "$2" == "1" ]; then
			COLOR="${blue}"
		elif [ "$2" == "2" ]; then
			COLOR="${red}"
		else
			COLOR=""
		fi
		printf "%s-%s[%s]v%s: %s%s${normal}\n" "$(date +"%Y%m%d-%H%M%S")" "$PROCESS_NAME" "$CURRENT_PID" "$VERSION" "$COLOR" "$IN" >> $LOGFILE
#		if [ "$VERBOSE" == "--verbose" ]
#		then
#			printf "Press any key..."
#			read -n 1 -s
#		fi
	fi
}
LOG "-----------------------------------------------------"
# Function to write an HTML table from a CSV file
LOG "Defining WRITEHTMLTABLE"
WRITEHTMLTABLE () {
	# -----------------------------------------
	# Next create an HTML table from the CSV file
	# Usage: WRITEHTMLTABLE INPUTFILE OUTPUTFILE [standalone]
	LOG "WRITEHTMLTABLE $1 $2 $3"
	if [ "$3" == "standalone" ]
	then
		printf "<html>\n<body>\n" >>"$2"
	fi
	cat <<EOF >>"$2"
	<table border="1" class="planetable">
	<tr>
	<th>No.</th>
	<th>Transponder ID</th>
	<th>Flight</th>
	<th>Time First Seen</th>
	<th>Time Last Seen</th>
	<th>Min. Altitude</th>
	<th>Min. Distance</th>
	</tr>
EOF

	# Now write the table
	COUNTER=0
	if [ -f "$1" ]
	then
	  while read -r NEWLINE
	  do
	    if [ "$NEWLINE" != "" ]
	    then
		(( COUNTER = COUNTER + 1 ))
		IFS=, read -ra NEWVALUES <<< "$NEWLINE"
		printf "<tr>\n" >>"$2"
		printf "<td>%s</td>" "$COUNTER" >>"$2"
		printf "<td>%s</td>\n" "${NEWVALUES[0]}" >>"$2"
		printf "<td><a href=\"%s\" target=\"_blank\">%s</a></td>\n" "${NEWVALUES[6]}" "${NEWVALUES[1]}" >> "$2"
		printf "<td>%s</td>\n" "${NEWVALUES[2]}" >>"$2"
		printf "<td>%s</td>\n" "${NEWVALUES[3]}" >>"$2"
		printf "<td>%s ft</td>\n" "${NEWVALUES[4]}" >>"$2"
		printf "<td>%s mi</td>\n" "${NEWVALUES[5]}" >>"$2"
		printf "</tr>\n" >>"$2"
	    fi
	  done < "$1"
	fi
	printf "</table>\n" >>"$2"
	if [ "$COUNTER" == "0" ]
	then
		printf "<p>No flights in range!</p>" >>"$2"
	fi
        if [ "$3" == "standalone" ]
        then
                printf "</body>\n</html>\n" >>"$2"
        fi
}

# Function to write the PlaneFence history file
LOG "Defining WRITEHTMLHISTORY"
WRITEHTMLHISTORY () {
	# -----------------------------------------
	# Write history file from directory
	# Usage: WRITEHTMLTABLE PLANEFENCEDIRECTORY OUTPUTFILE [standalone]
	LOG "WRITEHTMLHISTORY $1 $2 $3"
        if [ "$3" == "standalone" ]
        then
                printf "<html>\n<body>\n" >>"$2"
        fi

	cat <<EOF >>"$2"
		<p class="history">
		Historical data: Latest: <a href="index.html" target="_top">html</a> - <a href="planefence-$FENCEDATE.csv" target="_top">csv</a>
EOF

	# loop through the existing files. Note - if you change the file format, make sure to yodate the arguments in the line
	# right below. Right now, it lists all files that have the planefence-20*.html format (planefence-200504.html, etc.), and then
	# picks the newest 7 (or whatever HISTTIME is set to), reverses the strings to capture the characters 6-11 from the right, which contain the date (200504)
	# and reverses the results back so we get only a list of dates in the format yymmdd.
	for d in $(ls -1 "$1"/planefence-*[!e].html | tail -$HISTTIME | rev | cut -c6-11 | rev | sort -r)
	do
	       	printf " | %s" "$(date -d "$d" +%d-%b-%Y): " >> "$2"
		printf "<a href=\"%s\" target=\"_top\">html</a> - " "planefence-$(date -d "$d" +"%y%m%d").html" >> "$2"
		printf "<a href=\"%s\" target=\"_top\">csv</a>" "planefence-$(date -d "$d" +"%y%m%d").csv" >> "$2"
	done
	printf "</p>\n" >> "$2"
	printf "<p class=\"history\">Additional dates may be available by browsing to planefence-yymmdd.html in this directory.</p>" >> "$2"

	# and print the footer:
        if [ "$3" == "standalone" ]
        then
                printf "</body>\n</html>\n" >>"$2"
        fi
}


# Here we go for real:
LOG "Initiating PlaneFence"
LOG "FENCEDATE=$FENCEDATE"
# First - if there's any command line argument, we need to do a full run discarding all cached items
if [ "$1" != "" ]
then
	rm "$TMPLINES"  2>/dev/null
	rm "$OUTFILEHTML"  2>/dev/null
	rm "$OUTFILECSV"  2>/dev/null
	rm $OUTFILEBASE-"$FENCEDATE"-table.html  2>/dev/null
	rm $OUTFILETMP  2>/dev/null
	rm $TMPDIR/dump1090-pf*  2>/dev/null
	LOG "File cache reset- doing full run for $FENCEDATE"
fi

# find out the number of lines previously read
if [ -f "$TMPLINES" ]
then
	read -r READLINES < "$TMPLINES"
else
	READLINES=0
fi

# delete some of the existing TMP files, so we don't leave any garbage around
# this is less relevant for today's file as it will be overwritten below, but this will
# also delete previous days' files that may have left behind
rm "$TMPLINES" 2>/dev/null
rm "$OUTFILETMP" 2>/dev/null

# before anything else, let's determine our current line count and write it back to the temp file
# We do this using 'wc -l', and then strip off all character starting at the first space
CURRCOUNT=$(wc -l $LOGFILEBASE"$FENCEDATE".txt |cut -d ' ' -f 1)

# Now write the $CURRCOUNT back to the TMP file for use next time PlaneFence is invoked:
echo "$CURRCOUNT" > "$TMPLINES"

LOG "Current run starts at line $READLINES of $CURRCOUNT"

# Now create a temp file with the latest logs
tail +$READLINES $LOGFILEBASE"$FENCEDATE".txt > $INFILETMP

# First, run planefence.py to create the CSV file:
$PLANEFENCEDIR/planefence.py --logfile=$INFILETMP --outfile=$OUTFILETMP --maxalt=$MAXALT --dist=$DIST --lat=$LAT --lon=$LON $VERBOSE $CALCDIST 2>&1 | LOG

# Now we need to combine any double entries. This happens when a plane was in range during two consecutive Planefence runs
# A real simple solution could have been to use the Linux 'uniq' command, but that won't allow us to easily combine them

# Compare the last line of the previous CSV file with the first line of the new CSV file and combine them if needed
# Only do this is there are lines in both the original and the TMP csv files
if [ -f "$OUTFILETMP" ] && [ -f "$OUTFILECSV" ]
then
	# Read the last line of $OUTFILECSV and compare it to the top line of $OUTFILETMP
	LASTLINE=$(tail -n 1 "$OUTFILECSV")
	FIRSTLINE=$(head -n 1 "$OUTFILETMP")

	LOG "Before: CSV file has $(wc -l "$OUTFILECSV" |cut -d ' ' -f 1) lines"
	LOG "Before: Last line of CSV file: $LASTLINE"
        LOG "Before: New PlaneFence file has $(wc -l "$OUTFILETMP" |cut -d ' ' -f 1) lines"
        LOG "Before: First line of PF file: $FIRSTLINE"

	# Convert these into arrays so we can compare:
	unset $LASTVALUES
	unset $FIRSTVALUES
	IFS=, read -ra LASTVALUES <<< "$LASTLINE"
	IFS=, read -ra FIRSTVALUES <<< "$FIRSTLINE"

	# Now, if the ICAO of the two lines are the same, then combine and write the files:
	if [ "${LASTVALUES[0]}" == "${FIRSTVALUES[0]}" ]
	then
		LOG "Oldest new plane = newest old plane. Fixing..."
		# remove the first line form the $OUTFILETMP:
		tail --lines=+2 "$OUTFILETMP" > "$TMPDIR/pf-tmpfile" && mv "$TMPDIR/pf-tmpfile" "$OUTFILETMP"
		LOG "Adjusted linecount of New PF file to: $(wc -l $OUTFILETMP |cut -d ' ' -f 1) lines"
		# write all but the last line of $OUTFILECSV:
		head --lines=-1 "$OUTFILECSV" > "$TMPDIR/pf-tmpfile" && mv "$TMPDIR/pf-tmpfile" "$OUTFILECSV"

		# write the updated line:
		printf "%s," "${LASTVALUES[0]}" >> "$OUTFILECSV"
		printf "%s," "${LASTVALUES[1]}" >> "$OUTFILECSV"

		# print the earliest start time:
		if [ "$(date -d "${LASTVALUES[2]}" +"%s")" -lt "$(date -d "${FIRSTVALUES[2]}" +"%s")" ]
		then
			printf "%s," "${LASTVALUES[2]}" >> "$OUTFILECSV"
		else
			printf "%s," "${FIRSTVALUES[2]}" >> "$OUTFILECSV"
		fi

		# print the latest end date:
                if [ "$(date -d "${FIRSTVALUES[3]}" +"%s")" -gt "$(date -d "${LASTVALUES[3]}" +"%s")" ]
                then
                        printf "%s," "${FIRSTVALUES[3]}" >> "$OUTFILECSV"
                else
                        printf "%s," "${LASTVALUES[3]}" >> "$OUTFILECSV"
                fi

                # print the lowest altitude:
                if [ "${LASTVALUES[4]}" -lt "${FIRSTVALUES[4]}" ]
                then
                        printf "%s," "${LASTVALUES[4]}" >> "$OUTFILECSV"
                else
                        printf "%s," "${FIRSTVALUES[4]}" >> "$OUTFILECSV"
                fi

                # print the lowest distance. A bit tricky because altitude isn't an integer:
                if [ "$(bc <<< "${LASTVALUES[5]} < ${FIRSTVALUES[5]}")" -eq 1 ]
                then
                        printf "%s," "${LASTVALUES[5]}" >> "$OUTFILECSV"
                else
                        printf "%s," "${FIRSTVALUES[5]}" >> "$OUTFILECSV"
                fi

		# print the last line (link):
		printf "%s\n" "${LASTVALUES[6]}" >> "$OUTFILECSV"
	else
		LOG "No match, continuing..."
	fi
else
	LOG "Before: CSV file has $(wc -l "$OUTFILECSV" |cut -d ' ' -f 1) lines"
	LOG "Before: last line of CSV file: $LASTLINE"
	LOG "No new entries to be processed..."
fi

LOG "After: CSV file has $(wc -l "$OUTFILECSV" |cut -d ' ' -f 1) lines"
LOG "After: last line of CSV file: $(tail -lines=1 "$OUTFILECSV")"

# now we can stitching the CSV file together:
if [ -f "$OUTFILETMP" ]
then
	LOG "After: New PlaneFence file has $(wc -l "$OUTFILETMP" |cut -d ' ' -f 1) lines"
	LOG "After: last line of PF file: $LASTLINE"
	cat $OUTFILETMP >> "$OUTFILECSV"
	rm $OUTFILETMP
	LOG "Concatenated $OUTFILETMP to $OUTFILECSV"
else
	LOG "After: No New PlaneFence file as there were no new aircraft in reach"
fi


# We also need an updated history file that can be loaded into an IFRAME:
# print HTML headers first, and a link to the "latest":


# Next, we are going to print today's HTML file:
# Note - all text between 'cat' and 'EOF' is HTML code:

cat <<EOF >"$OUTFILEHTML"
<!DOCTYPE html>
<html>
<!--
# Copyright 2020 Ramon F. Kolb - licensed under the terms and conditions
# of GPLv3. The terms and conditions of this license are included with the Github
# distribution of this package, and are also available here:
# https://github.com/kx1t/planefence/
#
# The package contains parts of, links to, and modifications or derivatives to the following:
# Dump1090.Socket30003 by Ted Sluis: https://github.com/tedsluis/dump1090.socket30003
# OpenStreetMap: https://www.openstreetmap.org
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
-->
<head>
    <title>ADS-B 1090 MHz PlaneFence</title>
    <style>
        body { font: 16px/1.4 "Helvetica Neue", Arial, sans-serif; }
        a { color: #0077ff; }
	h1 {text-align: center}
	h2 {text-align: center}
	.planetable { border: 1; margin: 0; padding: 0; font: 12px/1.4 "Helvetica Neue", Arial, sans-serif; text-align: center }
	.history { border: none; margin: 0; padding: 0; font: 12px/1.4 "Helvetica Neue", Arial, sans-serif; }
	.footer{ border: none; margin: 0; padding: 0; font: 8px/1.4 "Helvetica Neue", Arial, sans-serif; text-align: center }
    </style>
</head>

<body>
<h1>PlaneFence</h1>
<h2>Show aircraft in range of ADS-B PiAware station for a specific day</h2>
<ul>
   <li>Last update: $(date +"%b %d, %Y %R:%S %Z")
   <li>Maximum distance from <a href="https://www.openstreetmap.org/?mlat=$LAT&mlon=$LON#map=14/$LAT/$LON&layers=H" target=_blank>$LAT $LON</a>: $DIST miles
   <li>Only aircraft below $MAXALT ft are reported.
EOF

WRITEHTMLTABLE "$OUTFILECSV" "$OUTFILEHTML"
WRITEHTMLHISTORY $OUTFILEDIR "$OUTFILEHTML"

cat <<EOF >>"$OUTFILEHTML"
<div class="footer">
PlaneFence is based on <a href="https://github.com/kx1t/planefence" target="_blank">KX1T's PlaneFence Open Source Project</a>, available on GitHub.
&copy; Copyright 2020 by Ram&oacute;n F. Kolb
</div>
</body>
</html>
EOF

# Last thing we need to do, is repoint INDEX.HTML to today's file
ln -sf "$OUTFILEHTML" $OUTFILEDIR/index.html

# That's all
# This could probably have been done more elegantly. If you have changes to contribute, I'll be happy to consider them for addition
# to the GIT repository! --Ramon
LOG "Finishing PlaneFence... sayonara!"
