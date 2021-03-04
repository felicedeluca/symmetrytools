#!/bin/bash
USAGE="$0 graph layouts..."
if [[ $# -lt 3 ]] ; then
	echo $USAGE
	exit 1
fi

G=$1
OUT=""
for L in $@ ; do
	if [[ $L == $G ]] ; then
		continue
	fi
	T=`python t2.py $G $L`
	OUT="$OUT$L,$T\n"
done

printf $OUT
