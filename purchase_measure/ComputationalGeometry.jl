COLINEAR = 0
CW = 1
CCW = 2
# determine if a sequence of three points has a CW or CCW orientation,
# or if the points are colinear

function dump_pts(filename, pts)
	println("\n** dumping points to $filename: $pts ** \n")
	writedlm("$filename.csv", pts, ',')
end

function orientation(p, q, r; debug=false, THRESHOLD=0.000000001, WARN=0.001)
	# debug && enter("orientation")
	det = (q[2]-p[2]) * (r[1]-q[1]) - (q[1]-p[1]) * (r[2]-q[2])
	debug && println("Determinant: $det")
	if abs(det) < THRESHOLD
		debug && all_done("orientation")
		return COLINEAR
	elseif abs(det) < WARN
		debug && println("* Warning * orientation determinant $det is very low but not so low as to be classified as a straight line")
	end
	# debug && all_done("orientation")
	det > 0 ? CW : CCW
end

function sq_dist(p, q)
	return (p[1]-q[1])^2+(p[2]-q[2])^2
end

function eliminate_duplicates(pts; TOL = 0.00001)
	out = []
	for (i,p) in enumerate(pts)
		include = true
		for (j,q) in enumerate(pts[i+1:end])
			if sqrt(sq_dist(p,q)) < TOL
				include = false
				break
			end
		end
		if include
			push!(out, p)
		end
	end
	out
end

# use Jarvis's algorithm 
function convex_hull(pts;debug=false)
	debug && enter("convex_hull")	
	debug && dump_pts("temp_for_hull_pre", pts)
	pts = eliminate_duplicates(pts)
	debug && dump_pts("temp_for_hull_post", pts)
	p = leftmost(pts)
	debug && println("leftmost = $p")
	hull = [p]
	p0 = p
	q = find_next_in_hull(pts, p)
	while q != p0 
		if q == nothing
			println("Got nothing as next point in hull! Up until now, hull was\n$hull\noptions were $pts")
			println("Assume we're just dealing with a straight line")
			return nothing
		end
		if size(pts,1) < size(hull,1)
			println("ERROR: HULL IS TOO BIG!")
			break
		end
		debug && println("next: $q")
		push!(hull,q)
		p = q
		q = find_next_in_hull(pts,p, debug=debug)
	end
	hull_size = size(hull,1)
	n = size(pts,1)
	debug && println("$n points -> hull of size $hull_size")
	if hull_size > n
		println("Fatal error: got more points in hull ($hull_size) than input points $n")
		return nothing
	end
	hull
end

function find_next_in_hull(pts, p, target_ortn=2; debug=false)
	debug && println("Seeking successor to $p from $pts")
	for (i, q0) in enumerate(pts)
		debug && println("Considering point $i = $q0")
		candidate = true
		if q0 == p
			continue
		end
		for r in pts
			debug && print("Examining orientation of ($p, $q0, $r): ")
			if r == q0 || r == p
				debug && println("Irrelevant")
				continue
			end
			ortn = orientation(p, q0, r)
			debug && print("$ortn ->")
			if ortn == 3-target_ortn  # stupid hack
				debug && println("reject $q0, going the wrong way\n")
				candidate = false
				break
			elseif ortn == 0 && dist(p,q0) < dist(p,r)
				debug && println("reject $q0, straight line but not furthest\n")
				candidate = false
				break
			else
				debug && println("continue")
			end
		end
		if candidate
			debug && println("Returning $q0\n")
			return q0
		end
	end
	return nothing
end

function leftmost(layout::Tuple{Array{Float64,1},Array{Float64,1}})
	leftmost(to_pt_array(layout))
end

function leftmost(pts)
	pts[leftmost_idx(pts)]
end

function leftmost_idx(pts)
	x_min = pts[1][1]
	y = pts[1][2]
	idx = 1
	for i in 2:size(pts,1)
		if pts[i][1] < x_min
			idx = i
			x_min = pts[i][1]
			y = pts[i][2]
		elseif x_min == pts[i][1]
			if pts[i][2] < y 
				y = pts[i][2]
				idx = i
			end
		end
	end
	idx
end

function to_pt_array(layout)
	[[layout[1][i],layout[2][i]] for i in 1:size(layout[1],1)]
end

# trivially returns a an array of triplets of points
function triangulate_convex_polygon(pts)
	[[pts[1],pts[i],pts[i+1]] for i in 2:size(pts,1)-1]
end

function triangle_area(tri; debug=false)
	a = dist(tri[1], tri[2])
	b = dist(tri[2], tri[3])
	c = dist(tri[1], tri[3])
	s = (a+b+c)/2
	debug && println("a=$a b=$b c=$c s=$s")
	sqrt(s*(s-a)*(s-b)*(s-c))
end

function area_of_convex_polygon(pts; debug=false)
	debug && enter("area_of_convex_polygon")
	triangles = triangulate_convex_polygon(pts)
	debug && begin
		println("triangles:")
		for (i, triangle) in enumerate(triangles)
			println("triangle $i: $triangle")
		end
	end
	sum(map(triangle_area,triangles))
end
