#!/bin/bash
USAGE="$0 graph layouts... outfile"
if [[ $# -lt 3 ]] ; then
	echo $USAGE
	exit 1
fi

G=$1
OUTFILE=${@: -1}
OUT=""

for L in $@ ; do
	if [[ $L == $G ]] || [[ $L == $OUTFILE ]] ; then
		continue
	fi
#	LPRINT=`echo $L | sed -e 's/.*\///'`
	#THIS_ONE="$LPRINT"
	THIS_ONE="$L"
	for ALG in `seq 1 4`; do
		T=`python t.py $G $L $ALG`
		THIS_ONE="$THIS_ONE,$T"
	done
	OUT="$OUT$THIS_ONE\n"
done

printf $OUT > $OUTFILE
