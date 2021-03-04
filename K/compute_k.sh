#!/bin/bash
for f in svg/*.svg;
do
	svgfullpath=$(pwd)/$f
	filename="${svgfullpath##*/}"
	filename="${filename%.*}"
	outputfile=$(pwd)"/kcsv/"$filename".csv"
	echo $outputfile;
	java -jar $(pwd)"/kAnalyzer.jar" $svgfullpath > $outputfile
	python get_refl_score.py $outputfile "meas.txt"
done

