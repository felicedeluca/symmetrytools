# tutteness.py
# measure how far each point that is not a leaf and is not on the hull is from being the barycenter of all its neighbors
# as a sum of squared differences from these ideal points
# possibly correlated with symmetry
#
# if called from the command line and provided a third argument, will append to that file
# may be convenient for batch files
# but watch out for producing huge files....
# 
# Eric Welch
# April 2017

from sys import argv
from convex_hull import *
import numpy as np

USAGE = "{0} edge-file layout-file [outfile]"

def parse_args(argv):
	if len(argv) < 3:
		print USAGE.format(argv[0])
		exit(1)
	elif len(argv) >= 4:
		outfile = argv[3]
	else:
		outfile = None
	edgefile = argv[1]
	layoutfile = argv[2]
	return edgefile, layoutfile, outfile

# File IO
def load_graph(edgefile):
	edges = []
	with open(efile, 'r') as f:
		elines = f.readlines()
	for line in elines:
		edge = map(int,line.strip().split(','))
		edge = map(lambda x: x-1, edge)
		edges.append(edge)
	return edges

def load_layout(layoutfile):
	with open(lfile, 'r') as f:
		llines = f.readlines()
	layout = []
	for line in llines:
		pos = map(float,line.strip().split(','))
		layout.append(pos)
	return layout


# Math

def tutteness(edges, layout):
	adjlist = [[] for i in range(len(layout))]
	for edge in edges:
		s,t = edge
		adjlist[s].append(t)
		adjlist[t].append(s)
	
	degrees = [0 for edge in edges]
	for edge in edges:
		s, t = edge
		degrees[s-1] += 1
		degrees[t-1] += 1
	
	leaves = []
	for i, node in enumerate(degrees):
		if node == 1:
			leaves.append(i)
		
	hull = convex_hull(layout)
	fixed = []
	for i, pos in enumerate(layout):
		if pos in leaves:
			fixed.append(i)
		elif pos in hull:
			fixed.append(i)
	

	laplacian = [[0 for n in range(len(degrees))] for n in range(len(degrees))]




		# t1: if i in fixed (hull or leaves), skip row; both hull and leaves "pull on" other nodes
		# t2: if i in fixed, skip row; leaves don't pull on other nodes
		# t3: if i in leaves, skip row; both hull and leaves pull on other nodes
		# t4: if i in leaves, skip row; leaves don't pull on other nodes
	for i, deg in enumerate(degrees):
		if i in fixed:
			continue
		laplacian[i][i] = deg
		for j in range(len(degrees)):
			if j in adjlist[i] and j not in leaves:
				laplacian[i][j] = -1
	M = np.array(laplacian)
	
	xs = np.array([pos[0] for pos in layout])
	ys = np.array([pos[1] for pos in layout])
	x_sums = np.dot(M,xs)
	y_sums = np.dot(M,ys)

	t = np.dot(x_sums,x_sums) + np.dot(y_sums, y_sums)
	return t





########
# MAIN #
########

if __name__ == "__main__":
	efile, lfile, outfile = parse_args(argv)
	edges = load_graph(efile)
	layout = load_layout(lfile)
	#print "Edges: {0}".format(edges)
	#print "Layout: {0}".format(layout)
	t = tutteness(edges, layout)
	if outfile == None:
		print t
	else:
		with open(outfile, 'a') as f:
			f.write("{0}\n".format(t))
