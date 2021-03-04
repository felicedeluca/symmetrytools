#!/bin/bash
java main.GraphAnalyser $1 > temp.csv
python get_refl_score.py temp.csv
rm temp.csv
