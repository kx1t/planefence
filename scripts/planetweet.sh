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
# If the VERBOSE variable is set to "1", then we'll write logs to LOGFILE.
# If you don't want logging, simply set  the VERBOSE=1 line below to VERBOSE=0
	VERBOSE=1
	LOGFILE=/tmp/planetweet.log
	TMPFILE=/tmp/planetweet.tmp
	VERSION=0.140520.1100
	TWEETON=yes
# -----------------------------------------------------------------------------------
# Open Issues, features, and bugs:
# - When the script tests the existence of a new aircraft, it will immediately tweet it
#   If we tweet before the plane leaves the tracking area, the minimum altitude/distance
#   may be understated as updated information becomes available. PlaneFence will cover this
#   updated information on the logfile, but the Tweet will already have been sent.
# - If multiple planes get into the coverage area in a short period of time, only the newest plant may
#   get tweeted. The time this race condition may exist is if multiple planes get added to PlaneFence
#   within 1 loop period of this PlaneTweet script ($SLEEPTIME + the time to execute the script).
#   There is no current plan to fix this -- "it's a feature, not a bug" in the sense that it prevents
#   tweet-storms with multiple planes in exchange for a risk of missing overflying aircraft. This is
#   acceptable because PlaneTweet is not a live-or-die service.
# -----------------------------------------------------------------------------------
# From here on, it is all about that code execution:

	# First create an function to write to the log
	LOG () { if [ "$VERBOSE" == "1" ]; then printf "%sv%s: %s\n" "`date +\"%Y%m%d-%H%M%S\"`" "$VERSION" "$1" >> $LOGFILE; fi; }

	# Here we go for real:
	LOG "-----------------------------------------------------"
	LOG "Starting up PlaneFence"
	# Upon startup, let's retrieve the last heard plane
	# We'll do a little trickery to avoid flow-over problems at midnight
	# First, we'll fill LASTPLANE with a fallback value:
	LASTPLANE=nothing
	# LASTPLANE contains the last plane that was tweeted. For convenience,
	# we save this to the $TMPFILE. If $TMPFILE doesn't exist, we'll fall back
	# to the last line of today's or yesterday's log.
	# If that one doesn't exist, we give up and keep the fallback value

	if [ -f $TMPFILE ];
	then
		LASTPLANE=$(tail -1 $TMPFILE)
		LOG "Init: Last plane heard (via tempfile): $LASTPLANE"
	elif [ -f $HTMLDIR/$TODAYCSV ];
	then
		LASTPLANE=$(tail -1 $HTMLDIR/$TODAYCSV)
		LOG "Init: Last plane heard (via today's file): $LASTPLANE"
	elif [ -f $HTMLDIR/$YSTRDAYCSV ];
	then
		LASTPLANE=$(tail -1 $HTMLDIR/$YSTRDAYCSV)
		LOG "Init: Last plane heard (via yesterday's file): $LASTPLANE"
	fi

	# if you need to test your setup to see if it tweets something after restart
	# uncomment the line below:
	# LASTPLANE=nothing; LOG "OJO LASTPLANE override to \"nothing\""; TWEETON=no

	# IFS is used by 'read' to determine the spearator to convert a string into an array
	IFS=','
	# Now loop forevah:
	while true
	do
		# Read the latest plane into the database. It only makes sense to do this if today's CSV file exists
		# This creates a race condition when there are multiple planes over your area in the short period that
		# the script loops ($SLEEPTIME + the time to execute the script). In this case, only the latest plane
		# will be tweeted about.
		# This is a bug and a feature at the same time - it prevents from tweet-blasting multiple planes in a 
		# short period of time.

		LOG "LASTPLANE tested: $LASTPLANE"
		if [ -f $HTMLDIR/$TODAYCSV ];
	        then
        	        NEWPLANE=$(tail -1 $HTMLDIR/$TODAYCSV)
			LOG "Newest plane (via today's file): $NEWPLANE"
	        elif [ -f $HTMLDIR/$YSTRDAYCSV ];
        	then
                	NEWPLANE=$(tail -1 $HTMLDIR/$YSTRDAYCSV)
			LOG "Newest plane (via yesterday's file): $NEWPLANE"
		else
			NEWPLANE=nothing
	        fi

		# Convert the CSV text line into a Bash String Array:
		read -raOLDPLN <<< "$LASTPLANE"
		read -raNEWPLN <<< "$NEWPLANE"

		# We compare only the first field to see if the old ICAO HEX code is different from the new one
		# If so, we must tweet!
		if [ "${OLDPLN[0]}" != "${NEWPLN[0]}" ] && [ "$NEWPLANE" != "nothing" ] ;
		then
			LOG "Tweeting..."
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
			LOG "Tweet msg body: $TWEET"
			if [ "$TWEETON" = "yes" ]; then $TWURLPATH/twurl -q -r "status=$TWEET" /1.1/statuses/update.json; fi
			LOG "Tweet sent!"

			# Last, set the LASTPLANE to the NEWPLANE and update the $TMPFILE
			LASTPLANE=$NEWPLANE
			printf "%s\n" "$NEWPLANE" > $TMPFILE
			LOG "NEWPLANE: $NEWPLANE"
		else
			LOG "Nothing to tweet (Old: ${OLDPLN[0]} New: ${NEWPLN[0]})"
		fi
		# And now go to sleep for $SLEEPTIME before we check again
		LOG "Sleeping $SLEEPTIME"
		sleep $SLEEPTIME
	done
