# demux.sh

(c) copyright 2014-2015 by exzessiv@posteo.de

A scipt to demux and mux a mpeg-ts (DVB) stream and finally author a DVD without re-encode

Intruduction:

Since 2014 I'm using tvheadend (https://github.com/tvheadend) on my Raspberry Pi to record dvb-c streams.

Due the fact that the dvb-c (mpeg2-ts) streams are a little bit tricky to handle (and because I'm lazy) I
decided to write a script that demux, cut and mux my recordings and finnally author a DVD - without re-encoding.

The script runs well on raspbian and should run on other (debian)-distributions too.
