# multiscale_klapaukh.bash
#
# Run the Klapaukh measure on a layout rendered at a specified series of scales
# Maybe one day we'll know how to choose an appropriate scale
# Until then, there's multiscale_klapaukh.bash
#
# Eric Welch
# April 2017

#!/bin/bash

USAGE="multiscale_klapaukh.bash graph layout scale_start scale_step scale_stop"

if [[ $# -ne 5 ]] ; then
	echo $USAGE
	exit 1
fi

G=$1
L=$2
S_START=$3
S_STEP=$4
S_STOP=$5

for s in `seq $S_START $S_STEP $S_STOP` ; do
  echo "$s: `./run_klapaukh.bash $G $L $s`"
done
