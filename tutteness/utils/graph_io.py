# File IO

def check_for_one_indexed(edges):
	for edge in edges:
		if edge[0] == 0 or edge[1] == 0:
			return False
	return True

def offset_values(edge, di):
	return map(lambda x: x+di, edge)

def ensure_zero_indexed(edges):
	is_one_indexed = check_for_one_indexed(edges)
	if not is_one_indexed:
		return edges
	adjusted_edges = map(lambda edge: offset_values(edge, -1), edges)
	return adjusted_edges

def load_graph(edgefile):
	edges = []
	with open(edgefile, 'r') as f:
		elines = f.readlines()
	is_one_indexed = check_for_one_indexed(elines)
	for line in elines:
		edge = map(int,line.strip().split(','))
		edges.append(edge)
	edges = ensure_zero_indexed(edges)
	return edges

def load_layout(layoutfile):
	with open(layoutfile, 'r') as f:
		llines = f.readlines()
	layout = []
	for line in llines:
		pos = map(float,line.strip().split(','))
		layout.append(pos)
	return layout

