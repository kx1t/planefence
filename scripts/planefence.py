#!/usr/bin/python

import sys, getopt, csv, os, HTMLParser
import pandas as pd 
import numpy as  np 
from datetime import datetime
from datetime import datetime 
from pytz import timezone
from tzlocal import get_localzone


def main(argv):

   inputfile = ''
   outputfile = ''
   lat = 42.3966
   lon = -71.1773
   dist = 2
   verbose = 0
   maxalt = 99999
   logfile = ''
   outfile = '/dev/stdout'
   outformat = ''
   tday = False

   now_utc = datetime.now(timezone('UTC'))
   now = now_utc.astimezone(get_localzone())

   try:
      opts, args = getopt.getopt(argv,'',["h","help","?","distance=","dist=","log=","logfile=","v","verbose","outfile=","maxalt=","format=","today"])
   except getopt.GetoptError:
      print 'ERROR. Usage: distance.py [--verbose] --distance=<distance_in_km> --logfile=/path/to/logfile'
      sys.exit(2)
   for opt, arg in opts:
      if opt in ("-h", "-?", "--help", "--?") :
         print 'Usage: distance.py [--verbose] --distance=<distance_in_statute_miles> --logfile=/path/to/logfile [--outfile=/path/to/outputfile] [--maxalt=maximum_altitude_in_ft] [--format=csv|html|both]'
         # print 'If lat/long is omitted, then Belmont, MA (town hall) is used.'
	 print 'If distance is omitted, then 2 miles is used.'
	 print 'If outfile is omitted, then output is written to stdout. Note - if you intend to capture stdout for processing, make sure that --verbose=1 is not used.'
         print 'Also, format is NOT defined, and outfile has the extention .htm or .html, the output will be written as an html table. Any other outfile extension will be written as CSV'
	 print 'If format is defined, it will add the appropriate extention(s) to outfile.'
	 print 'If --today is used, the logfile is assumed to be the base format for logs, and we will attempt to oick today\'s log.'
      # elif opt == "--lat":
         # lat = arg
      # elif opt =="--lon":
         # lon = arg
      elif opt in ("--logfile", "--log"):
         logfile = arg
      elif opt in ("--distance", "--dist"):
         dist = float(arg)
      elif opt in ("--v", "--verbose"):
	 verbose = 1
      elif opt == "--outfile":
	 outfile = arg
      elif opt == "--maxalt":
	 maxalt = float(arg)
      elif opt == "--format":
	 outformat = arg
      elif opt == "--today":
	 tday = True
 

   if verbose == 1:
      # print 'lat = ', lat
      # print 'lon = ', lon
      print 'max distance = ', dist, "statute miles"
      print 'max altitude = ', maxalt, "ft"
      print 'output is written to ', outfile

   if logfile == '':
      print "ERROR: Need logfile parameter"
      sys.exit(2)

   if tday:
      logfile = logfile + now.strftime("%y%m%d") +".txt"
      outfile = outfile + "-" + now.strftime("%y%m%d")

   if verbose == 1:
      print 'input is read from ', logfile

   if outformat not in ("html", "csv", "both", ""):
      print "Error: format not understood"
      sys.exit(2)

   # figure out the outformat if not defined:
   if outformat == '':
      if outfile[-4:].lower() == '.htm'or outfile[-5:].lower() == '.html':
	 outformat = 'html'
      elif outfile[-4:].lower() == '.csv':
	 outformat = 'csv'
      else:
	 outformat = 'both'

# now we open the logfile
# and we parse through each of the lines
#
# format of logfile is 0-ICAO,1-altitude(meter),2-latitude,3-longitude,4-date,5-time,6-angle,7-distance(kilometer),8-squawk,9-ground_speed(kilometerph),10-track,11-callsign
# format of airplaneslist is [[0-ICAO,11-FltNum,4/5-FirstHeard,4/5-LastHeard,1-LowestAlt,7-MinDistance,FltLink)]
   with open(logfile, "rb") as f:
     # the line.replace is because sometimes the logfile is corrupted and contains zero bytes. Python pukes over this.
     reader = csv.reader( (line.replace('\0','') for line in f) )
     records = np.array(["ICAO","Flight Number","In-range Date/Time","Out-range Date/Time","Lowest Altitude","Minimal Distance","Flight Link"], dtype = 'object')
     counter = 0
     for row in reader:

       # first safely convert the distance and altitude values from the row into a float.
       # if we can't convert it into a number (e.g., it's text, not a number) then substitute it by some large number
       try:
          rowdist=float(row[7]) * 1.15078
       except:
          rowdist=float("999999")
       try:
	  rowalt=float(row[1])
       except:
	  rowalt=float("999999")

       # print rowdist
       # now check if it's a duplicate that is in range
       if row[0] in records and rowdist <= dist and rowalt <= maxalt:
	  # first check if we already have a flight number. If we don't, there may be one in the updated record we could use?
          if records[np.where(records == row[0])[0][0]][1] == "" and row[11].strip() != "":
	     records[np.where(records == row[0])[0][0]][1] = row[11].strip()
             # records[np.where(records == row[0])[0][0]][6] = 'https://flightaware.com/live/flight/' + row[11].strip() + '/history'
             records[np.where(records == row[0])[0][0]][6] = 'https://flightaware.com/live/modes/' + row[0].lower() + '/ident/' + row[11].strip() + '/redirect'
	  # replace "LastHeard" by the time in this row:
          records[np.where(records == row[0])[0][0]][3] = row[4] + ' ' + row[5][:8]
          # only replace the lowest altitude if it's smaller than what we had before
	  if rowalt < float(records[np.where(records == row[0])[0][0]][4]):
             records[np.where(records == row[0])[0][0]][4] = row[1]
	  # only replace the smallest distance if it's smaller than what we had before
	  if rowdist < float(records[np.where(records == row[0])[0][0]][5]):
	     records[np.where(records == row[0])[0][0]][5] =  "{:.1f}".format(rowdist)

       elif rowdist <= dist and rowalt <= maxalt:
	   # it must be a new record. First check if it's in range. If so, write a new row to the records table:
	   if verbose == 1:
              print counter, row[0], row[11].strip(), "(", rowdist, "<=", dist, ", alt=", rowalt, "): new"
	      counter = counter + 1
           # records=np.vstack([records, np.array([row[0],row[11].strip(), row[4] + ' ' + row[5][:8], row[4] + ' ' + row[5][:8],row[1],"{:.1f}".format(rowdist),'https://flightaware.com/live/flight/' + row[11].strip() + '/history' if row[11].strip()<>"" else ''])])    
           records=np.vstack([records, np.array([row[0],row[11].strip(), row[4] + ' ' + row[5][:8], row[4] + ' ' + row[5][:8],row[1],"{:.1f}".format(rowdist),'https://flightaware.com/live/modes/' + row[0].lower() + '/ident/'+ row[11].strip() + '/redirect' if row[11].strip()<>"" else ''])])    

     # Now, let's start writing everything to a CSV and/or HTML file:
     # Step zero - turn string truncation off
     pd.set_option('display.max_colwidth', -1)

     # First CSV - least hassle as we don't need to reformat record rows with HTML code:
     if outformat in ('csv', 'both'):
        # make sure that the file has the correct extension
        if outfile[-4:].lower() != '.csv':
	     outfilecsv = outfile + '.csv'
	else:
	     outfilecsv = outfile

        # Now write the table to a file as a CSV file
        with open(outfilecsv, 'w') as file:
             writer = csv.writer(file, delimiter=',')
             writer.writerows(records.tolist())

     # Next, figure out if we need to write HTML format
     if outformat in ('html', 'both'):
	# first make sure we know what to call the output file:
        if outfile[-4:].lower() != '.htm' and outfile[-5:].lower() != '.html':
		outfilehtml = outfile + '.html'
	else:
		outfilehtml = outfile

	# turn string truncation off
	pd.set_option('display.max_colwidth', -1)
	# now rewrite the last field into a real link in the second field:
	for row in range(1,np.shape(records)[0]):
		if records[row][6] != '':
		   records[row][1] = "<a href=%s target=\"_blank\">%s</a>" % (records[row][6],records[row][1])
		records[row][4] = "{:,} ft".format(int(records[row][4]))
		records[row][5] = records[row][5] + " miles"
		records[row][6] = ""
		# print records[row]
	
	# now go from Numpy array -> Panda DataFrame, remove last (empty) column, then -> HTML and write it to Outfile
	
	recordsframe = pd.DataFrame(np.roll(np.flip(records, axis=0),1, axis=0))
	recordsframe.drop(recordsframe.columns[len(recordsframe.columns)-1], axis=1, inplace=True)
	with open(outfilehtml, 'w') as file:
	     # now = datetime.now()
	     file.write("<html><head><title>PlaneFence</title></head>")
	     file.write("<h1>PlaneFence</h1>")
	     file.write("<h2>Show aircraft in range of ADS-B PiAware station for a specific day</h2>")
	     # file.write("<p>")
	     file.write("<ul><li>Last update: " + now.strftime("%b %d, %Y %H:%M:%S %z"))
	     file.write("<li>Maximum distance from <a href=\"https://www.openstreetmap.org/?mlat=%s&mlon=%s#map=14/%s/%s&layers=H\" target=_blank>%sN %sE</a>: %s miles" % (lat, lon, lat, lon, lat, lon, dist))
	     file.write("<li>Only aircraft below %s ft are reported." % (maxalt))
	     file.write("</ul><p>")
	     recordsframe.to_html(file,escape = False, header = False)


     # That's all, folks!


# this invokes the main function defined above:
if __name__ == "__main__":
   main(sys.argv[1:])


