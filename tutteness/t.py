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
from utils.graph_io import *

USAGE = "{0} edge-file layout-file algorithm [outfile]"

def parse_args(argv):
	if len(argv) < 4:
		print USAGE.format(argv[0])
		exit(1)
	elif len(argv) >= 5:
		outfile = argv[4]
	else:
		outfile = None
	edgefile = argv[1]
	layoutfile = argv[2]
	algorithm = int(argv[3])
	return edgefile, layoutfile, algorithm, outfile


# Math

def tutteness(edges, layout, alg):
	adjlist = [[] for i in range(len(layout))]
	for edge in edges:
		s,t = edge
		adjlist[s].append(t)
		adjlist[t].append(s)
	
	degrees = [0 for node in adjlist]
	sc_degrees = [0 for node in adjlist]
	for i, edge in enumerate(edges):
		s, t = edge
		if not (edge in edges[:i] or [edge[1], edge[0]] in edges[:i]):  # reject duplicates
			degrees[s] += 1
			degrees[t] += 1

	pendants = []
	for node, deg in enumerate(degrees):
		if deg == 1:
			pendants.append(node)
		
	hull = convex_hull(layout)
	fixed = []
	for i, pos in enumerate(layout):
		if pos in pendants:
			fixed.append(i)
		elif pos in hull:
			fixed.append(i)
	
	laplacian = [[0 for n in range(len(degrees))] for n in range(len(degrees))]
	# difference between the four versions
	# t1 and t2: we don't penalize nodes in hull, nor the pendants
	# t3 and t4: we do penalize the hull, but still do not penalize the pendants
	# t2 and t4: the pendant nodes do not "pull on" the other nodes
	for i, deg in enumerate(degrees):
		if ((alg == 1 or alg == 2) and i in fixed) or ((alg == 3 or alg == 4) and i in pendants):
			continue
		laplacian[i][i] = deg
		for j in range(len(degrees)):
			if j in adjlist[i] and not ((alg == 2 or alg == 4) and j in pendants):
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
	efile, lfile, algorithm, outfile = parse_args(argv)
	edges = load_graph(efile)
	layout = load_layout(lfile)
	t = tutteness(edges, layout, algorithm)
	if outfile == None:
		print t
	else:
		with open(outfile, 'a') as f:
			f.write("{0}\n".format(t))
