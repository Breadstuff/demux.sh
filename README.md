# demux.sh

(c) copyright 2014-2020 by lakeconstance78@wolke7.net

A scipt to demux and mux a mpeg-ts (DVB) stream and finally author a DVD without re-encode

Intruduction:
--------------

Since 2014 I'm using tvheadend (https://github.com/tvheadend) on my Raspberry Pi to record dvb-c streams.

Due the fact that the dvb-c (mpeg2-ts) streams are a little bit tricky to handle (and because I'm lazy) I
decided to write a script that demux, cut and mux my recordings and finnally author a DVD - without re-encoding.

The script runs well on raspbian and should run on other (debian)-distributions too.

Requirements: 
--------------
1. ProjectX 
2. comskip
3. mplex (from mjpegtools) 
4. dvdauthor.
5. optional: ffmpeg and mediainfo.

This script can be used stand-alone or as post-processing script for tv-headend.


Command line:
-------------
./demux.sh inputfilename.ts [/path/to/inputfilename.ts] [MODE] [AUDIO]


Tvheadend: 
-----------
./demux.sh %b %f [MODE] [AUDIO]

         		[] = optional
		        MODE = DVD, MPEG or DEMUX
		        AUDIO = AUTO, 1 or 2
