#!/bin/bash
# demux.sh, by lakeconstance78@wolke7.net
#
# this script: 
# 				1. demux a MPEG-2 (TS) (using ProjectX).
#				2. mux video and existing languages to a MPEG-2 (PS) (using mplex).
#				4. author a DVD-video (using dvdauthor).
# 
# requirements: ProjectX, mplex (from mjpegtools) and dvdauthor.
#
# this script can be used stand-alone or as post-processing script for tv-headend.
#
# command line: ./demux.sh inputfilename.ts
#				
# todo
# - add batch mode
# - add documentation
# - simplify the adding of alternative languages
# - add tvheadend *.mkv support
# - cleanup script

# processing commandline for parameters
# http://openbook.rheinwerk-verlag.de/shell_programmierung/shell_005_007.htm
# http://www.shelldorado.com/goodcoding/cmdargs.html

AUDIO="2"
INPUTFILE=
while getopts af: opt
do
	case "$opt" in
		a)  AUDIO="1";;
		f)  INPUTFILE="$OPTARG";;
		?)  echo "usage: $0 [-a1] [-a2] [-f file] [file ...]"
		exit 1;;
	esac
done
shift `expr $OPTIND - 1`

# defines
#AUDIO="1"							# use minumum one audio track
LANGTAG1="de"						# standard tag for language 1
LANGTAG2="en"						# standard tag for language 2

COMPATH=$PWD						# alternative inputpath if not specified in the command line (=actual directory if not changed here)
WORKINGDIRECTORY=/media/usbstick	# a temporary directory

PROJECTX=$COMPATH/ProjectX.jar			# path to ProjectX
MPLEX=/usr/local/bin/mplex				# path to mplex
DVDAUTHOR=/usr/bin/dvdauthor			# path to dvdauthor
MEDIAINFO=/usr/bin/mediainfo			# path to mediainfo

# check if inputpath is correct. if not, correct inputpath -> keep for tvheadend conformity
if [ ! "$INPUTPATH" ] 
	then 
		INPUTPATH="$COMPATH/$INPUTFILE"
fi

NAME=$(basename "$INPUTFILE" .ts)		# delete ext of filename

OUTPUTDIRECTORY="$COMPATH/$NAME"		# the output directory is a subdirectory in the inputdirectory
LOG="$OUTPUTDIRECTORY/$NAME.log"		# the logfile is the inputfilename with ext log

# make outputdirectory, if not exist
if [ ! -d "$OUTPUTDIRECTORY" ]
	then
		mkdir "$OUTPUTDIRECTORY"
fi

# make log, if not exist
if [ ! -f "$LOG" ]; then touch "$LOG"; fi

echo "-----------------------------------" | tee -a "$LOG"
echo "demux to dvd script, 06.05.2015" | tee -a "$LOG"
echo "starttime:" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
echo "-----------------------------------" | tee -a "$LOG"
echo "inputfile: $INPUTFILE" | tee -a "$LOG"
echo "inputpath: $INPUTPATH" | tee -a "$LOG"
echo "name: $NAME" | tee -a "$LOG"
echo "completepath: $COMPATH" | tee -a "$LOG"
echo "workingpath: $WORKINGDIRECTORY" | tee -a "$LOG"
echo "logfile: $LOG" | tee -a "$LOG"

# debugging
#echo "Auch hiernach ein Kommentar."
#: <<KOMMENTARIO

echo "-----------------------------------" | tee -a "$LOG" echo "demux file $INPUTFILE" | tee -a "$LOG" /bin/date | tee -a "$LOG"
# check if inputfile is already demuxed
if [ -f "$WORKINGDIRECTORY/$NAME.m2v" ]
	then
		echo "demuxed video files already existing" | tee -a "$LOG"
	else
		# read mediainfo and write to log
		nice -n 19 $MEDIAINFO "$INPUTPATH" | tee -a "$LOG"
		
		# check if cut information is exising
		if [ -f "$COMPATH/$NAME.Xcl" ];
			then
				# use cut file
				echo "found cut file" | tee -a "$LOG"
				nice -n 19 java -jar "$PROJECTX" "$INPUTPATH" -out "$WORKINGDIRECTORY" -name "$NAME" -cut "$COMPATH/$NAME.Xcl" | tee -a "$LOG"
			else
				echo "not found any cut file" | tee -a "$LOG"
				nice -n 19 java -jar "$PROJECTX" "$INPUTPATH" -out "$WORKINGDIRECTORY" -name "$NAME" | tee -a "$LOG"
		fi
fi

# workaround first audio track
if [ -f "$WORKINGDIRECTORY/$NAME.mp2" ]; then mv "$WORKINGDIRECTORY/$NAME.mp2" "$WORKINGDIRECTORY/$NAME-01.mp2"; fi

if [ -f "$WORKINGDIRECTORY/$NAME-02.mp2" ]; then AUDIO="2"; fi

# set audio tracks
LANG1="$WORKINGDIRECTORY/$NAME-01.mp2"
LANG2="$WORKINGDIRECTORY/$NAME-02.mp2"

echo "Number of languages: $AUDIO" | tee -a "$LOG"
echo "$LANGTAG1 File: $LANG1" | tee -a "$LOG"
echo "$LANGTAG2 File: $LANG2" | tee -a "$LOG"
echo "-----------------------------------" | tee -a "$LOG"
/bin/date | tee -a "$LOG"

echo "mux in new file $NAME.mpg" | tee -a "$LOG"
if [ -f "$WORKINGDIRECTORY/$NAME.m2v" ]
	then
		if [ "$AUDIO" -eq 1 ]
			then
				nice -n 19 $MPLEX -f 8 -M -o "$WORKINGDIRECTORY/$NAME.mpg" "$WORKINGDIRECTORY/$NAME.m2v" "$LANG1" | tee -a "$LOG"
				#if [ $MODE != "MPEG" ]; then 
				$DVDAUTHOR -o "$OUTPUTDIRECTORY" -t "$WORKINGDIRECTORY/$NAME.mpg" -a mp2+$LANGTAG1 | tee -a "$LOG"
				#; fi
		elif [ "$AUDIO" -eq 2 ]
			then
				nice -n 19 $MPLEX -f 8 -M -o "$WORKINGDIRECTORY/$NAME.mpg" "$WORKINGDIRECTORY/$NAME.m2v" "$LANG1" "$LANG2"| tee -a "$LOG"
				#if [ $MODE != "MPEG" ]; then 
				$DVDAUTHOR -o "$OUTPUTDIRECTORY" -t "$WORKINGDIRECTORY/$NAME.mpg" -a mp2+$LANGTAG1,mp2+$LANGTAG2 | tee -a "$LOG"
				#; fi
		fi
	else 
		exit
fi

echo "-----------------------------------" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
if [ -f "$OUTPUTDIRECTORY/VIDEO_TS/" ]
	then
		echo "authoring dvd" | tee -a "$LOG"
		OUTPUTDIRECTORY
		export VIDEO_FORMAT=PAL
		#if [ "$MODE" != "MPEG" ]; then nice -n 19 
		$DVDAUTHOR -o "$OUTPUTDIRECTORY" -T | tee -a "$LOG"
		#; fi
	else
		exit
fi

# debugging
#KOMMENTARIO
# echo "Obendrueber war ein Kommentar."

# cleanup working directory
if [ -f "$OUTPUTDIRECTORY/VIDEO_TS/VIDEO_TS.IFO" ]; then echo rm -r "$WORKINGDIRECTORY/$NAME*"; fi

echo "-----------------------------------" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
echo "finnished!" | tee -a "$LOG"
echo "-----------------------------------" | tee -a "$LOG"
