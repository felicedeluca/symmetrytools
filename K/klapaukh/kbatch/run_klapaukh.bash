#!/bin/bash

if [[ $# -lt 3 ]] ; then
	echo "Usage: run_klapaukh graph layout scale"
	exit 1
fi

if [[ $# -ge 4 ]] ; then
	KEEP=$4
fi

G=$1
L=$2
S=$3

HERE=`pwd`
SCRIPT_DIR=${HERE}/../../scripts
KLAP_DIR=${HERE}/../klapaukh/GraphAnalyser-master/src

python $SCRIPT_DIR/format_for_klapaukh.py $G $L $S $KLAP_DIR/temp.svg
cd $KLAP_DIR
java main.GraphAnalyser temp.svg > out.csv
python get_refl_score.py out.csv

if [[ $KEEP != "" ]] ; then
	echo Keeping the SVG is not fully implemented -- you can just regenerated it using 
	echo python $SCRIPT_DIR/format_for_klapaukh.py $G $L $S 
else
	rm temp.svg
	rm out.csv
fi

cd $HERE
