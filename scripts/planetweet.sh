#!/bin/bash
# PLANETWEET - a Bash shell script to render heatmaps from modified sock30003
# heatmap data
#
# Usage: ./planetweet.sh
#
# Note: this script is meant to be run as a daemon using SYSTEMD
# If run manually, it will continuously loop to listen for new planes
#
# This script is distributed as part of the PlaneFence package and is dependent
# on that package for its execution.
#
# Copyright 2020 Ramon F. Kolb - licensed under the terms and conditions
# of GPLv3. The terms and conditions of this license are included with the Github
# distribution of this package, and are also available here:
# https://github.com/kx1t/planefence
#
# The package contains parts of, and modifications or derivatives to the following:
# - Dump1090.Socket30003 by Ted Sluis: https://github.com/tedsluis/dump1090.socket30003
# - Twurl by Twitter: https://github.com/twitter/twurl and https://developer.twitter.com
# These packages may incorporate other software and license terms.
# -----------------------------------------------------------------------------------
# Feel free to make changes to the variables between these two lines. However, it is
# STRONGLY RECOMMENDED to RTFM! See README.md for explanation of what these do.

# These are the input and output directories and file names
# HTMLDIR indicates where we can find the CSV files that PlaneFence produces:
	HTMLDIR=/usr/share/dump1090-fa/html/planefence
# HEADR determines the tags for each of the fields in the Tweet:
	HEADR=("ICAO" "FLIGHT" "START TIME" "END TIME" "MIN ALT (ft)" "MIN DIST (miles)" "LINK")
# CSVFILE termines which file name we need to look in. We're using the 'date' command to
# get a filename in the form of 'planefence-200504.csv' where 200504 is yymmdd
	TODAYCSV=$(date -d today +"planefence-%y%m%d.csv")
	YSTRDAYCSV=$(date -d yesterday +"planefence-%y%m%d.csv")
# TWURLPATH is where we can find TWURL. This only needs to be filled in if you can't get it
# as part of the default PATH:
	if [ ! `which twurl` ]; then TWURLPATH=/home/pi/.rbenv/shims ; fi
# SLEEPTIME determine how long (in seconds) we wait after checking and (potentially) tweeting
# before we check again:
	SLEEPTIME=60
# -----------------------------------------------------------------------------------
# From here on, it is code execution:

	# Upon startup, let's retrieve the last heard plane
	# We'll do a little trickery to avoid flow-over problems at midnight
	# First, we'll fill LASTPLANE with a fallback value:
	LASTPLANE=nothing
	# Then, if today's CSV file exists, we'll get the last line from that file
	# If it doesn't exist, we'll try yesterday's file.
	# If that one doesn't exist, we give up and keep the fallback value
	if [ -f $HTMLDIR/$TODAYCSV ];
	then
		LASTPLANE=$(tail -1 $HTMLDIR/$TODAYCSV)
	elif [ -f $HTMLDIR/$YSTRDAYCSV ];
	then
		LASTPLANE=$(tail -1 $HTMLDIR/$YSTRDAYCSV)
	fi

# if you need to test your setup to see if it tweets something after restart
# uncomment the line below:
#	LASTPLANE=nothing

	# IFS is used by 'read' to determine the spearator to convert a string into an array
	IFS=','
	# Now loop forevah:
	while true
	do
		# Read the latest plane into the database. It only makes sense to do this if today's CSV file exists
		# This creates a race condition where we log a plane in that flies through the area during the last few seconds
		# before midnight, and we will miss this plane because there's no new file for the next day.
		# So be it -- it's an edge case, and there's no life-or-death dependency on this script.
		NEWPLANE=nothing
		[ -f $HTMLDIR/$TODAYCSV ] && NEWPLANE=$(tail -1 $HTMLDIR/$TODAYCSV)

		# Convert the CSV text line into a Bash String Array:
		read -raOLDPLN <<< "$LASTPLANE"
		read -raNEWPLN <<< "$NEWPLANE"

		# We compare only the first field to see if the old ICAO HEX code is different from the new one
		# If so, we must tweet!
		if [ "${OLDPLN[0]}" != "${NEWPLN[0]}" ] && [ "$NEWPLANE" != "nothing" ] ;
		then
			# Create a Tweet with the first 6 fields, each of them followed by a Newline character
			TWEET=""
			for i in {0..5}
			do
				TWEET="$TWEET${HEADR[i]}: ${NEWPLN[i]}%0A"
			done
			# Now add the last field without title or training Newline
			# Reason: this is a URL that Twitter reinterprets and previews on the web
			# Also, the Newline at the end tends to mess with Twurl
			TWEET="$TWEET${NEWPLN[6]}"
			$TWURLPATH/twurl -q -r "status=$TWEET" /1.1/statuses/update.json
			# Last, set the LASTPLANE to the NEWPLANE
			LASTPLANE=$NEWPLANE
		fi
		# And now go to sleep for $SLEEPTIME before we check again
		sleep $SLEEPTIME
	done
