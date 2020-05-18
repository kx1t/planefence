#!/bin/bash
OUTFILEDIR=/usr/share/dump1090-fa/html/planefence
OUTFILEBASE=$OUTFILEDIR/planefence
OUTFILETODAY=$OUTFILEBASE-`date --date="today" '+%y%m%d'`.html
HTMLFOOTER=".html"
PLANEFENCEDIR=/usr/share/planefence

for t in /tmp/dump1090-127*.txt;
do [[ -e $t ]] | continue;
   OUTFILE=$OUTFILEBASE-${t:24:6}
   echo processing ${t:24:6}
   $PLANEFENCEDIR/planefence.py --logfile=$t --outfile=$OUTFILE --format=both --maxalt=5000 --verbose
   # ln -sf $OUTFILETODAY $OUTFILEDIR/index.html
   printf "<p><p style=\"font-size:10px\">History:\n" >> $OUTFILE.html
   printf "<p style=\"font-size:10px\"><a href=\"/planefence\">Latest</a> | " >> $OUTFILE.html
   echo Adding history to file $OUTFILE.html...
   for f in $OUTFILEBASE*.html;
	do [[ -e $f ]] | continue;
		printf "${f:52:2}/${f:54:2}/20${f:50:2} " >> $OUTFILE.html
		printf "<a href=\"planefence-${f:50:6}.html\" target=\"_blank\">html</a> " >> $OUTFILE.html
		printf "<a href=\"planefence-${f:50:6}.csv\" target=\"_blank\">csv</a> | " >> $OUTFILE.html
	done
   echo Done, cycling to the next file
done
echo All done. Sayonara!

