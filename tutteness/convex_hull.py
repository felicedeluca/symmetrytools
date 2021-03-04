COLLINEAR = 0
CW = 1
CCW = 2

def convex_hull(pts):
	p = leftmost(pts)
	hull = [p]
	p0 = p
	q = find_next_in_hull(pts, p0)
	while not pt_eq(p0,q):
		hull_size_sanity_check(hull, pts)
		hull.append(q)
		p = q
		q = find_next_in_hull(pts, p)
	hull_size_sanity_check(hull, pts)
	out = []
	for pt in hull:
		out.append([pt[0], pt[1]])
	return out

def hull_size_sanity_check(hull, pts):
	if len(pts) < len(hull):
		exit()

def pt_eq(p,q):
	return p[0] == q[0] and p[1] == q[1]

def find_next_in_hull(pts, p, target_ortn=CCW):
	for i, q0 in enumerate(pts):
		candidate = True
		if pt_eq(q0, p):
			continue
		for r in pts:
			if pt_eq(r, q0) or pt_eq(r, p):
				continue
			ortn = orientation(p, q0, r)
			if ortn == 3-target_ortn: # stupid hack
				candidate = False
				break
			elif ortn == COLLINEAR:
				if sq_dist(p,q0) < sq_dist(p,r):
					candidate = False
		if candidate:
			return q0
	print "Error, returning None in find_next_in_hull"
	return None

def sq_dist(p,q):
	return (p[0]-q[0])*(p[0]-q[0]) + (p[1]-q[1])*(p[1]-q[1])
	
def leftmost(pts):
	x_min = pts[0][0]
	y = pts[0][1]
	for i in range(1,len(pts)):
		if pts[i][0] < x_min:
			x_min, y = pts[i]
		elif x_min == pts[i][0] and pts[i][1] < y:
			x_min,y = pts
	return x_min, y

def orientation(p, q, r, THRESHOLD = 0.0000001, WARN=0.0001):
	det = (q[1]-p[1]) * (r[0]-q[0]) - (q[0]-p[0]) * (r[1]-q[1])
	if abs(det) < THRESHOLD:
		return COLLINEAR
	return CW if det > 0 else CCW


########
# TEST #
########

def test_convex_hull():
	pts = [[i,j] for i in range(1,5) for j in range(1,5)]
	print "pts: {0}".format(pts)
	hull = convex_hull(pts)
	print "hull: {0}".format(hull)
