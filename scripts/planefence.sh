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
# -----------------------------------------------------------------------------------
# Feel free to make changes to the variables between these two lines. However, it is
# STRONGLY RECOMMENDED to RTFM! See README.md for explanation of what these do.
# These are the input and output directories and file names:
	OUTFILEDIR=/usr/share/dump1090-fa/html/planefence
	PLANEFENCEDIR="/home/pi/planefence/"
	MAXALT=5000
	DIST=2.5
	LAT=42.39663
	LON=-71.17726
#
#
# Only change the variables below if you know what you are doing.
# Specifically
	OUTFILEBASE=$OUTFILEDIR/planefence
	HTMLFOOTER=".html"
	OUTFILETODAY=$OUTFILEBASE-`date --date="today" '+%y%m%d'`$HTMLFOOTER
	LOGFILEBASE=/tmp/dump1090-127_0_0_1-
#	VERBOSE="--verbose"
	VERBOSE=""
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------

# First, run planefence.py to create the HTML and CSV files:
   $PLANEFENCEDIR/planefence.py --logfile=$LOGFILEBASE --today --outfile=$OUTFILEBASE --format=both --maxalt=$MAXALT --dist=$DIST --lat=$LAT --lon=$LON $VERBOSE

# Now link index.html to today's file:
   if [ -f "$OUTFILETODAY" ]
   then
	# Add the historical files to the bottom of the HTML document:
   	printf "<p><p style=\"font-size:10px\">History:</p>\n" >> $OUTFILETODAY
	printf "<p style=\"font-size:10px\"><a href=\"/planefence\">Latest</a>" >> $OUTFILETODAY
   	for f in `ls -1 -r $OUTFILEBASE*.html | head -7`;
		do [[ -e $f ]] | continue;
			# printf "Processing %s (%s)\n..." $f "`ls -1 $f | rev | sed -r  's/^[^0-9]*([0-9]+).*/\1/' | rev | date -f - +\"%d-%b-%Y\"` "
			printf " | `ls -1 $f | rev | sed -r  's/^[^0-9]*([0-9]+).*/\1/' | rev | date -f - +\"%d-%b-%Y\"` " >> $OUTFILETODAY
			printf "<a href=\"planefence-%s.html\" target=\"_blank\">html</a> " "`ls -1 $f | rev | sed -r  's/^[^0-9]*([0-9]+).*/\1/' |rev | date -f - +\"%y%m%d\"`" >> $OUTFILETODAY
			printf "<a href=\"planefence-%s.csv\" target=\"_blank\">csv</a> " "`ls -1 $f | rev | sed -r  's/^[^0-9]*([0-9]+).*/\1/' |rev | date -f - +\"%y%m%d\"`" >> $OUTFILETODAY
		done
	printf "<br>More history files may be available by manually browsing to 'planefence-yymmdd.html'." >>$OUTFILETODAY
   	printf "</p>\n" >>$OUTFILETODAY
   	printf "<p style=\"font-size:10px\">" >>$OUTFILETODAY
   	printf "PlaneFence is Copyright 2020 by Ram&oacute;n F. Kolb and is licensed under GPLv3.0. License terms and conditions and source code are available on <a href=\"https://github.com/kx1t/planefence\" target=\"_blank\">GitHub</a>.</p>" >>$OUTFILETODAY
   	printf "</body></html>" >> $OUTFILETODAY
	ln -sf $OUTFILETODAY $OUTFILEDIR/index.html
   fi
# That's all
# This could probably have been done more elegantly. If you have changes to contribute, I'll be happy to consider them for addition
# to the GIT repository! --Ramon
