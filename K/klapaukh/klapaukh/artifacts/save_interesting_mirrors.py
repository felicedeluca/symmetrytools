import os
import sys
from subprocess import call, Popen, PIPE
#!/bin/bash

# later I can directly specify
#for scale in "$@" ; do 
#echo $scale
#done
#exit

DK                 = "/Users/hapless/graph-symmetries/detection/klapaukh/GraphAnalyser-master/src"
MIRROR_DIR         = "/Users/hapless/graph-symmetries/detection/klapaukh/GraphAnalyser-master/results/klapaukh/mirrors"
INTERESTING_DIR    = "/Users/hapless/graph-symmetries/detection/klapaukh/GraphAnalyser-master/results/klapaukh/interesting"
LAYOUT_DIR         = "/Users/hapless/graph-symmetries/layouts/"
DETECTION_KLAPAUKH = "/Users/hapless/graph-symmetries/detection/klapaukh/GraphAnalyser-master/src"

with open(INTERESTING_DIR + '/interesting.csv', 'r') as f:
	lines = f.readlines()

for line in lines:
	gi, li = map(int,line.strip().split(','))
	for scale in range(20,801,20):
		print "graph: {0}    layout: {1}    scale: {2}".format(gi,li,scale)
		os.chdir(LAYOUT_DIR)
		call(['python','../scripts/to_scaled_klapaukh.py', 'ug_{0}'.format(gi), str(li), str(scale), DK + '/temp_{0}.svg'.format(scale)])
		os.chdir(DETECTION_KLAPAUKH)
		# call(['cat','temp'])
		resultfile="{0}_{1}_{2}".format(gi,li,scale)
		p=Popen(['java','main/GraphAnalyser','temp_{0}.svg'.format(scale)],stdout=PIPE, stderr=PIPE)
#		print "\nErrors:"
		errors = p.stderr.read()
		if len(errors) != 0:
			print errors

		# call('pwd')
		#print "calling os.listdir('.')"
		#files = os.listdir('.')
		#for f in files:
	#		if f[0] == "m":
#				print f
		call(['mv','mirror.svg','{0}/{1}.svg'.format(MIRROR_DIR,resultfile)])
	#os.chdir(MIRROR_DIR)
#	call('python','construct_html.py', str(gi), str(li))
