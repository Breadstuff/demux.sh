#!/bin/bash
# demux.sh, by exzessiv@posteo.de
#
# this script: 
# 				1. demux a MPEG-2 (TS) (using ProjectX).
#				2. detect commercials using comskip
#				3. mux video and wanted languages to a MPEG-2 (PS) (using mplex).
#				4. author a DVD-video (using dvdauthor).
# 
# requirements: ProjectX, comskip, mplex (from mjpegtools) and dvdauthor.
# optional: ffmpeg and mediainfo.
#
# this script can be used stand-alone or as post-processing script for tv-headend.
#
# command line: ./demux.sh inputfilename.ts [/path/to/inputfilename.ts] [MODE] [AUDIO]
# 		[] = optional
#		MODE = DVD, MPG or DEMUX
#		AUDIO = AUTO, 1 or 2
#
# todo
# - add documentation
# - simplify the adding of alternative languages
# - add subtitel support
# - add comskip support
# - add more parameters
# - add tvheadend *.mkv support
# - cleanup script


#parameters
INPUTFILE=$1					# parameter 1 is the input filename
INPUTPATH=$2					# parameter 2 is the input path and filename
MODE=$3   						# parameter 3 for DVD, MPEG or only demux mode
AUDIO=$4						# parameter 4 for AUTO choose (below defined) languages or 1 or 2 languages
COMSKIP=$5						# parameter 5 for use comskip...write anything to active

# defines
COMPATH=$PWD						# alternative inputpath if not specified in the command line (=actual directory if not changed here)
WORKINGDIRECTORY=/media/usbstick	# a temporary directory

PROJECTX=$COMPATH/ProjectX.jar			# path to ProjectX
MPLEX=/usr/local/bin/mplex				# path to mplex
DVDAUTHOR=/usr/bin/dvdauthor			# path to dvdauthor
MEDIAINFO=/usr/bin/mediainfo			# path to mediainfo
FFMPEG=/usr/bin/ffmpeg					# path to ffmpeg

# check if inputfile is specified
if [ ! "$INPUTFILE" ]
	then
		echo "usage: ./demux.sh file [fullpath to file] [MODE=DVD/MPEG/DEMUX] [AUDIO=AUTO/1/2] [COMSKIP]"
		exit
fi

# check if inputpath is correct. if not, correct inputpath
if [ ! "$INPUTPATH" ] 
	then 
		INPUTPATH="$COMPATH/$INPUTFILE"
fi

#if inputfile *.mkv copy to *ts using ffmpeg
if [ -f "$INPUTFILE.mkv" ]
	then
		NAME=$(basename "$INPUTFILE" .mkv)		# delete ext of filename
		$FFMPEG -i "$INPUTFILE" -acodec copy -vcodec copy -f mpegts "$NAME.ts" | tee -a "$LOG"
	else
		NAME=$(basename "$INPUTFILE" .ts)		# delete ext of filename
fi

OUTPUTDIRECTORY="$COMPATH/$NAME"		# the output directory is a subdirectory in the inputdirectory
LOG="$OUTPUTDIRECTORY/$NAME.log"		# the logfile is the inputfilename with ext log
MEDIASAVE="$WORKINGDIRECTORY/$NAME.med"	#| tee -a "$LOG" # the media infofile is the inputfilename with ext med

# make outputdirectory, if not exist
if [ ! -d "$OUTPUTDIRECTORY" ]
	then
		mkdir "$OUTPUTDIRECTORY"
fi

# make log, if not exist
if [ ! -f "$LOG" ]; then touch "$LOG"; fi

echo "-----------------------------------" | tee -a "$LOG"
echo "demux to dvd script, 21.01.2015" | tee -a "$LOG"
echo "starttime:" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
echo "-----------------------------------" | tee -a "$LOG"
echo "inputfile: $INPUTFILE" | tee -a "$LOG"
echo "inputpath: $INPUTPATH" | tee -a "$LOG"
echo "name: $NAME" | tee -a "$LOG"
echo "completepath: $COMPATH" | tee -a "$LOG"
echo "workingpath: $WORKINGDIRECTORY" | tee -a "$LOG"
echo "logfile: $LOG" | tee -a "$LOG"

if [ ! -f "$COMPATH/$NAME.Xcl" && $COMSKIP ]
	then
		echo "-----------------------------------" | tee -a "$LOG"
		/bin/date | tee -a "$LOG"
		echo "run comskip for $INPUTFILE" | tee -a "$LOG"
		comskip -t --ini=tveurope.ini $INPUTFILE | tee -a "$LOG"
		cp "$NAME.ts.Xcl" "$COMPATH/$NAME.Xcl" #workourround wrong ext
fi

echo "-----------------------------------" | tee -a "$LOG"
echo "demux file $INPUTFILE" | tee -a "$LOG"
/bin/date | tee -a "$LOG"

# check if inputfile is already demuxed
if [ -f "$WORKINGDIRECTORY/$NAME.m2v" ]
	then
		echo "demuxed video files already existing" | tee -a "$LOG"
	else
		# read mediainfo and write to log
		$MEDIAINFO "$INPUTPATH" | tee -a "$LOG"
		
		# check if cut information is exising
		if [ -f "$COMPATH/$NAME.Xcl" ];
			then
				# use cut file
				echo "found cut file" | tee -a "$LOG"
				java -jar $COMPATH/ProjectX.jar "$INPUTPATH" -out "$WORKINGDIRECTORY" -name "$NAME" -cut "$COMPATH/$NAME.Xcl" | tee -a "$LOG"
			else
				echo "not found any cut file" | tee -a "$LOG"
				java -jar $COMPATH/ProjectX.jar "$INPUTPATH"  -out "$WORKINGDIRECTORY" -name "$NAME" | tee -a "$LOG"
		fi
fi

# workaround first audio track
if [ -f $WORKINGDIRECTORY/$NAME.mp2 ]; then mv $WORKINGDIRECTORY/$NAME.mp2 $WORKINGDIRECTORY/$NAME-01.mp2; fi 


#look for audio tracks in audio AUTO mode
if [ "$AUDIO" = "AUTO" ]
	then
		echo "-----------------------------------" | tee -a "$LOG"
		if [ -f "$MEDIASAVE" ]; then rm "$MEDIASAVE"; fi
		 #workarround ersten  3 sprachen übernehmen
		if [ -f "${WORKINGDIRECTORY}/${NAME}_log.txt" ]; then grep "Audio:" -A 3 "${WORKINGDIRECTORY}/${NAME}_log.txt" -m 1 >>"$MEDIASAVE"; fi

		#define languages
		GER=`(grep "ger" $MEDIASAVE -n | cut -d":" -f1)`
		ENG=`(grep "eng" $MEDIASAVE -n | cut -d":" -f1)`
		FRA=`(grep "fra" $MEDIASAVE -n | cut -d":" -f1)`
		#MIS=`(grep "mis" $MEDIASAVE -n | cut -d":" -f1)`

		LANG=0
		echo $GER
		echo $ENG
		echo $FRA
		#echo $MIS

		if [ $GER ]
			 then
			 ((LANG++))
			 ((GER--))
			 LANGTAG1="de"
			 LANG1=$WORKINGDIRECTORY/$NAME-0$GER.mp2
		fi
		if [ $ENG ]
			 then
			 ((LANG++))
			 ((ENG--))
			 LANGTAG2="en"
			 LANG2=$WORKINGDIRECTORY/$NAME-0$ENG.mp2
		fi
		if [ $FRA ]
			 then
			 ((LANG++))
			 ((FRA--))
			 LANGTAG3="fr"
			 LANG3=$WORKINGDIRECTORY/$NAME-0$FRA.mp2
		fi

		elif [ "$AUDIO" = "1" ]
	then
		LANG=1
		LANGTAG1="de"
		LANG1=$WORKINGDIRECTORY/$NAME-01.mp2
elif [ "$AUDIO" = "2" ]
	then
		LANG=2
		LANGTAG1="de"
		LANG1=$WORKINGDIRECTORY/$NAME-01.mp2

		LANGTAG2="fr"
		LANG2=$WORKINGDIRECTORY/$NAME-02.mp2
else
	echo "exit: no language available" | tee -a "$LOG"
	exit
fi

echo "Number of languages: $LANG" | tee -a "$LOG"
echo "German File: $LANG1" | tee -a "$LOG"
echo "English File: $LANG2" | tee -a "$LOG"
echo "French File: $LANG3" | tee -a "$LOG"
echo "Misc File: $LANG3" | tee -a "$LOG"

echo "-----------------------------------" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
echo "mux in new file $NAME.mpg" | tee -a "$LOG"

if [ "$LANG" -eq 1 ]
	then
		$MPLEX -f 8 -M -o "$WORKINGDIRECTORY/$NAME.mpg" "$WORKINGDIRECTORY/$NAME.m2v" "$LANG1" | tee -a "$LOG"
		if [ $MODE != MPEG ]; then $DVDAUTHOR -o "$OUTPUTDIRECTORY" -t "$WORKINGDIRECTORY/$NAME.mpg" -a mp2+$LANGTAG1 | tee -a "$LOG"; fi
elif [ "$LANG" -eq 2 ]
	then
		$MPLEX -f 8 -M -o "$WORKINGDIRECTORY/$NAME.mpg" "$WORKINGDIRECTORY/$NAME.m2v" "$LANG1" "$LANG2"| tee -a "$LOG"
		if [ $MODE != MPEG ]; then $DVDAUTHOR -o "$OUTPUTDIRECTORY" -t "$WORKINGDIRECTORY/$NAME.mpg" -a mp2+$LANGTAG1,mp2+$LANGTAG2 | tee -a "$LOG"; fi
elif [ "$LANG" -eq 3 ]
	then
		$MPLEX -f 8 -M -o "$WORKINGDIRECTORY/$NAME.mpg" "$WORKINGDIRECTORY/$NAME.m2v" "$LANG1" "$LANG2" "$LANG3"| tee -a "$LOG"
		if [ $MODE != MPEG ]; then $DVDAUTHOR -o "$OUTPUTDIRECTORY" -t "$WORKINGDIRECTORY/$NAME.mpg" -a mp2+$LANGTAG1,mp2+$LANGTAG2,mp2+$LANGTAG3 | tee -a "$LOG"; fi
else 
	echo "exit: no language file to mux" | tee -a "$LOG"
	exit
fi
 
echo "-----------------------------------" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
echo "authoring dvd" | tee -a "$LOG"
export VIDEO_FORMAT=PAL
if [ "$MODE" != "MPEG" ]; then $DVDAUTHOR -o "$OUTPUTDIRECTORY" -T | tee -a "$LOG"; fi

echo "-----------------------------------" | tee -a "$LOG"
/bin/date | tee -a "$LOG"
echo "finnished!" | tee -a "$LOG"
echo "-----------------------------------" | tee -a "$LOG"
