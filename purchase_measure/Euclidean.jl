
	type LineSeg
		x0::Real
		y0::Real
		x1::Real
		y1::Real
	end

	type StdLine
		a::Real
		b::Real
		c::Real
	end

	function nrmlz!(l::StdLine)
		mag = sqrt(l.a^2 + l.b^2)
		if l.a < 0
			mag *= -1
		end
		l.a /= mag
		l.b /= mag
		l.c /= mag
		l
	end

	function angle_between(l::StdLine, m::StdLine)
		l_mag = sqrt(l.a^2 + l.b^2)
		la = l.a/l_mag
		lb = l.b/l_mag
		m_mag = sqrt(m.a^2 + m.b^2)
		ma = m.a/m_mag
		mb = m.b/m_mag
		acos(dot([la,lb],[ma,mb]))/pi*180
	end

	function create_sym_axis(p, q; debug=false)
		debug && println("** entered create_sym_axis($p,$q)")
		segment = LineSeg(p[1], p[2], q[1], q[2])
		perp_bis(segment)
	end

	function perp_bis(s::LineSeg)
		a = s.x0-s.x1
		b = s.y0-s.y1
		x2 = (s.x0 + s.x1)/2
		y2 = (s.y0 + s.y1)/2
		c = -a*x2 - b*y2
		StdLine(a,b,c)
	end
	
	function create_sym_axis(layout::Tuple{Array{Float64,1},Array{Float64,1}}, v1::Int, v2::Int)
		cxn = edge_segment(layout, v1, v2)
		perp_bis(cxn)
		#a = cxn.x0-cxn.x1 
		#b = cxn.y0-cxn.y1 
		#c = (cxn.x1-cxn.x0)*cxn.x1 + (cxn.y1-cxn.y0)*cxn.y1
		#Line(a,b,c)
	end

	function dist(p, q)
		sqrt((p[1]-q[1])^2+(p[2]-q[2])^2)
	end

	function dist(x0, y0, x1, y1)
		dist([x0,y0],[x1,y1])
	end

	function min_and_max(xs)
		l = xs[1]
		r = xs[1]
		for x in xs
			if x < l
				l = x
			elseif x > r
				r = x
			end
		end
		(l,r)
	end

	function width(layout::Tuple{Array{Float64,1},Array{Float64,1}})
		l,r = min_and_max(layout[1]) 
		r-l
	end

	function height(layout::Tuple{Array{Float64,1},Array{Float64,1}})
		t, b = min_and_max(layout[2])
		b-t
	end

	function rescale!(layout::Tuple{Array{Float64,1},Array{Float64,1}}, a::Real, b::Real)
		xs = layout[1]
		ys = layout[2]
		for i in 1:size(xs,1)
			xs[i] *= a
		end
		for i in 1:size(ys,1)
			ys[i] *= b
		end
	end

	function rescale!(layout::Tuple{Array{Float64,1},Array{Float64,1}}, c::Real)
		xs = layout[1]
		ys = layout[2]
		for i in 1:size(xs,1)
			xs[i] *= c
		end
		for i in 1:size(ys,1)
			ys[i] *= c
		end
	end

	# pt is an array or double
	function reflection(p, line::StdLine)
		# we have for a point on the line, (x,y)⋅(a,b) = -c
		# now for this new point, p⋅(a,b) = d
		# we want q such that (q⋅(a,b) + p⋅(a,b))/2 = -c
		# this q will satisfy q[1] = p[1] + a⋅m, q[2] = p[2] + b⋅m for some m
		# so, (p[1]+a⋅m, p[2]+b⋅m)⋅(a,b) = -2c - p⋅(a,b) = -2c-d
		# giving ap[1] + a^2m + bp[2]+b^2m = -2c-d
		# whence a^2+b^2m = -2c-d-ap[1]-bp[2] = -2c-2d
		# so we have m = (-2c-2d)/(a^2+b^2)
		a = line.a
		b = line.b
		c = line.c
		d = p[1]*a + p[2]*b
		m = (-2*c-2*d)/(a^2+b^2)
		[p[1] + a*m, p[2] + b*m]
	end



	
	function between(x, rng)
		return x > rng[1] && x < rng[2] || x > rng[2] && x < rng[1]
	end
	
	function slope(l)
		return (l.y0-l.y1)/(l.x0-l.x1)
	end

	function edge_segment(layout, v1, v2)
		edge_segment(layout, [v1 v2])
	end

	function edge_segment(layout, edge)
		# println("Want edge $edge from layout\n$layout")
		LineSeg(layout[1][edge[1]], layout[2][edge[1]], layout[1][edge[2]], layout[2][edge[2]])
	end

	
	function eval_at_x(l, x)
		m = slope(l)
		if m == Inf
			return nothing
		end
		return l.y0+m*(x-l.x0)
	end
	
	function vertical_intersection(v::LineSeg, l::LineSeg)
		y = eval_at_x(l, v.x0)
		if !between(y, [v.y0, v.y1])
			return nothing
		end
		return [v.x0, y]
	end
	
	function is_inf(x)
		return x == Inf || x == -Inf
	end
	
	function segment_intersection(l1::LineSeg, l2::LineSeg)
		# handle vertical line
		m1 = slope(l1)
		m2 = slope(l2)
		if is_inf(m1) && is_inf(m2)
			return nothing
		end
		if is_inf(m1)
			return vertical_intersection(l1, l2)
		end
		if is_inf(m2)
			return vertical_intersection(l2, l1)
		end
	
		# confirm the segments cross
		xs = sort([l1.x0, l1.x1, l2.x0, l2.x1])
		x = xs[2]
		ortn = eval_at_x(l1, x) > eval_at_x(l2, x)
		x = xs[3]
		if ortn == eval_at_x(l1, x) > eval_at_x(l2, x)
			return nothing
		end
	
		# method: l0 = l1-l2, find where l0's y values go to 0	
		l0 = LineSeg(l1.x0, l1.y0-eval_at_x(l2, l1.x0), l1.x1, l1.y1-eval_at_x(l2, l1.x1))
		y = max(l0.y0, l0.y1)
		m = (l0.y0-l0.y1)/(l0.x0-l0.x1)
		Δx = -y/m
		if y == l0.y0
		x = l0.x0
		else
		x = l0.x1
		end
		x_intcpt = x+Δx
	
		# make sure the intercept falls within the segments!
		if !between(x_intcpt, [l1.x0,l1.x1]) || !between(x_intcpt, [l2.x0, l2.x1])
			return nothing
		end
	
		return [x_intcpt, eval_at_x(l1, x_intcpt)]
	end

function find_all_intersections(segments::Array{LineSeg,1})
	xns = Array{LineSeg,1}()
	for i = 1:size(segments,1)
		for j = i+1: size(segments,1)
			xn = segment_intersection(segments[i],segments[j])
			if xn != nothing
				push!(xns, xn)
			end
		end
	end
	xns
end

function chop_line(l::StdLine, x_min=-1, x_max=1, y_min=-1, y_max=1)
	if l.b == 0
	return LineSeg(-l.c/l.a, y_min, -l.c/l.a, y_max)
	end
	m = -l.a/l.b
	b = -l.c/l.b
	y_left = m*x_min+b
	if y_left > y_max || y_left < y_min
		# y=mx+b -> x = (y-b)/m
		x1 = (y_min-b)/m
		x2 = (y_max-b)/m
		if x1 < x2
			x_left = x1
			y_left = y_min
		else
			x_left = x2
			y_left = y_max
		end
	else
		x_left = x_min
	end

	y_right = m*x_max + b
	if y_right > y_max || y_right < y_min
		x1 = (y_min-b)/m
		x2 = (y_max-b)/m
		if x1 > x2
			x_right = x1
			y_right = y_min
		else
			x_right = x2
			y_right = y_max
		end
	else
		x_right = x_max
	end
	LineSeg(x_left, y_left, x_right, y_right)
end

# just for debugging
function chop_line(a,b,c)
	chop_line(StdLine(a,b,c))
end
