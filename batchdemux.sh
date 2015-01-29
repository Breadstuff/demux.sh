#!/bin/bash
# demux all *.ts file if cutpoint file exists...

COMPATH=$PWD

for file in *.ts
  do
		NAME=$(basename "$file" .ts)
		if [ -f "$NAME.Xcl" ]
			then
				echo "$NAME"
				./tvheadend.sh "$file" "$COMPATH/$file" DVD 2
			else
				echo "no cutpoint file for $NAME"
		fi
	done 
