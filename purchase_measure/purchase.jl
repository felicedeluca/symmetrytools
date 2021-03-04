using Colors
include("Euclidean.jl")
include("GraphLayout.jl")
include("GraphManipulation.jl")
include("GraphCalculations.jl")
include("Experiments.jl")
include("GraphFamous.jl")
include("GraphRendering.jl")
include("Metrics.jl")
include("GraphIO.jl")
include("ComputationalGeometry.jl")
G="."
L="."

#G="/Users/hapless/graph-symmetries/graphs"
#L="/Users/hapless/graph-symmetries/layouts"
#
#function update()
#	include("purchase.jl")
#end

function without(array, element)
	temp = Array{typeof(array[0]),1}()
	for el in array
		if el != element
			push!(temp,el)
		end
	end
	temp
end

function crosses_promotion!(g, layout; debug=false)
	debug && enter("crosses_promotion!")
	done = false
	reset = false
	adj_list = g.fadjlist
	n = size(adj_list,1)
	original_n = n
	promoted = Array{Int64,1}()
	while !done
		for i = 1:n, j in adj_list[i]
			# println("Looking for intersections with edge [$i $j]")
			ls1 = edge_segment(layout, i, j)
			for s = i+1:n
				# println("Looking at adjacency list for $s")
				if s == j
					continue
				end
				for t in adj_list[s]
					if t == j || t == i
						continue
					end
					# println("Considering edge [$s $t]")
					ls2 = edge_segment(layout, s, t)
					pt = segment_intersection(ls1, ls2)
					if pt != nothing
						# println("** Intersection at $pt **")
						n = n+1
						new_vertex!(g)
						if n > original_n * 3
							return nothing
						end
						push!(layout[1], pt[1])
						push!(layout[2], pt[2])
						# println("About to remove old edges and add four more")
						# println("Currently, $(g.ne) edges)")
						remove_edge!(g, i, j)
						remove_edge!(g, s, t)
						new_edge!(g, i, n)
						new_edge!(g, j, n)
						new_edge!(g, s, n)
						new_edge!(g, t, n)
						# println("After removing two edges and adding four more, we have $(g.ne) edges")
						push!(promoted, n)
						reset = true
						break
					end # of if pt != nothing
					if reset
						break
					end
				end # of loop over t
				if reset
					break
				end
			end # of loop over s
			if reset
				break
			end
		end # of loop over i and j
		if reset
			reset = false
			continue
		end
		done = true
	end
	# println("Graph at end:")
	# println("$(g.fadjlist)")
	debug && all_done("-- Exiting crosses_promotion! --")
	promoted
end

# deprecated, do not use!
function construct_axis_set(g::LightGraphs.Graph, layout; angle_tol=1, d_tol_ratio=0.1)
	enter("construct_axis_set")
	raw_axes = extract_symmetric_axes(g, layout, debug=true)
	axis_set = Array{StdLine,1}()
	h = height(layout)
	w = width(layout)
	d_tol = sqrt(h*w) * d_tol_ratio
	while size(raw_axes,1) > 0
		for i in size(raw_axes,1):-1:2
			if angle_between(raw_axes[1], raw_axes[i]) < angle_tol && abs(raw_axes[1].c-raw_axes[i].c) < d_tol
				deleteat!(raw_axes, i)
			end
		end
		push!(axis_set, raw_axes[1])
		deleteat!(raw_axes,1)
	end
	done("construct_axis_set")
	axis_set
end
	
function extract_symmetric_axes(g::LightGraphs.Graph, layout; debug=false)
	debug && enter("extract_symmetric_axes")
	debug && println("adjlist: $(g.fadjlist)")
	axes = Array{StdLine,1}()
	for i in 1:size(g.fadjlist,1)
		for j in i+1:size(g.fadjlist,1)
			axis = create_sym_axis(layout, i, j)
			push!(axes, nrmlz!(axis))
		end
	end
	debug && all_done("extract_symmetric_axes")
	axes
end

# c_sgs, c_uas, sgs = consolidate_subgraphs(sgs, uas)
# TODO: fix bug with ug_58 layout 3
# this function produces three forms of output:
# 1) c_sgs contains only unique edges
# 2) c_uas contains the axes that generated these edges
# 3) final_raw_sgs is the raw subgraph originally found, which we keep
#    so that later we can calculate scores based on crossings promotions
function consolidate_subgraphs(sgs, used_axes; debug=false, verbose=false)
	(debug || verbose) && enter("consolidate_subgraphs")
	temp = []
	temp_axes = []
	out = []                        # c_sgs
	out_axes = Array{StdLine,1}()   # c_uas

	# Phase 1:
	# each subgraph: remove duplicate axes
	# remove any subgraph with only one edge
	phase1_raw_sgs = []
	final_raw_sgs = []
	for (i,sg) in enumerate(sgs)
		debug && println("subgraph $i = $sg")
		sg_prime = consolidate_subgraph(sg)
		debug && println("consolidated subgraph $i = $sg_prime")
		if size(sg_prime,1) > 1
			push!(phase1_raw_sgs, sg)
			push!(temp, sg_prime)
			push!(temp_axes, used_axes[i])
		end
	end	
	debug && println("consolidated subgraphs after phase 1: $temp")

	for (i,sg_i) in enumerate(temp)
		incl = true
		for (j,sg_j) in enumerate(temp)
			if i == j
				continue   # could change to break, right?
			end

			if is_subgraph(sg_i, sg_j)
				if !is_subgraph(sg_j, sg_i)  # proper subgraph -> skip
					incl = false
				else
					# same subgraph, include only once
					for sg in out
						if is_subgraph(sg_i, sg) && is_subgraph(sg, sg_i)
							incl = false
						end
					end
				end
			end

		end
		if incl
			push!(final_raw_sgs, phase1_raw_sgs[i])
			push!(out, sg_i)
			push!(out_axes, temp_axes[i])
		end
	end
	(debug || verbose) && all_done("consolidate_subgraphs")
	out, out_axes, final_raw_sgs
end

function consolidate_subgraph(sg)
	out = []
	for edge in sg
		if edge in out || [edge[2],edge[1]] in out
			continue
		end
		push!(out,edge)
	end
	out
end

# test if g1 is a subgraph of g2
# we're just using an array of [i,j] pairs
function is_subgraph(g1, g2)
	for e1 in g1
		found = false
		for e2 in g2
			if e1 == e2 || e1 == [e2[2],e2[1]]
				found = true
			end
		end
		if !found
			return false
		end
	end
	true
end
	

# for debugging
function save_promotion_result(name, g, layout, promoted, i=0)
	save_light_graph("$G/$(name)_promoted.csv", g)
	save_layout("$L/$(name)_promoted_layout$(i).csv")
	save_promotions("$L/$(name)_promotions$(i).csv", promoted)
end

function save_promotions(filename, promoted)
	writedlm(filename, promoted, ',')
end

function find_sym_subgraphs(g, l, axes; TOLERANCE=0.1, debug=false, verbose=false)
	debug && enter("find_sym_subgraphs")
	(verbose || debug) && println("Using TOLERANCE=$TOLERANCE")
	raw_subgraphs = []
	used_axes = []
	for axis in axes
		#println("axis: $axis")
		subgraph = []
		for i in g.vertices
			p = (l[1][i], l[2][i])
			refl_p = reflection(p, axis)
			debug && println("reflecting $p across $axis yielded refl_p $refl_p")
			for ii in g.vertices
				q = (l[1][ii], l[2][ii])
				d = dist(refl_p, q)
				debug && println("distance from $refl_p to $q is $d")
				if abs(d) < TOLERANCE
					for j in g.fadjlist[i]
						if i > j
							continue
						end
						p2 = (l[1][j], l[2][j])
						refl_p2 = reflection(p2, axis)
						for jj in g.fadjlist[ii]
							q2 = (l[1][jj], l[2][jj])
							d2 = dist(refl_p2, q2)
							if abs(d2) < TOLERANCE
								append!(subgraph, [[i,j],[ii,jj]])  # they appear in pairs
							end
						end
					end
				end
			end
		end

		if size(subgraph,1) > 0
			push!(raw_subgraphs, subgraph)
			push!(used_axes, axis)
		end
	end
	debug && all_done("find_sym_subgraphs")
	raw_subgraphs, used_axes
end


function subgraph_symmetry(
		g::LightGraphs.Graph, 
		l::Tuple{Array{Float64,1},Array{Float64,1}},
		sg::Array, 
		c_sg::Array, 
		cps::Array; 
		FRACTION=0.5,
		debug=false
	)
	TOTAL = 0
	seen_edges = []
	for pair_idx in 1:2:size(sg,1)
		e1 = sg[pair_idx]
		e2 = sg[pair_idx+1]
		if e1 in seen_edges || [e1[2],e1[1]] in seen_edges
			continue
		end
		push!(seen_edges, e1)
		push!(seen_edges, e2)
		P = 1
		Q = 1
		if (e1[1] in cps && !(e2[1] in cps)) || (e2[1] in cps && !(e1[1] in cps))
			P = FRACTION
		end
		if (e1[2] in cps && !(e2[2] in cps)) || (e2[2] in cps && !(e1[2] in cps))
			Q = FRACTION
		end
		debug && println("edges $(e1) and $(e2) and cps $cps resulted in $(P*Q)")
		TOTAL += P*Q
	end
	subscore = TOTAL / (size(seen_edges,1)/2)
	debug && println("Out of $(size(seen_edges,1)) edges, we get symmetry score $(subscore)")
	subscore
end

function area_of_entire_graph(g,l;debug=false)
	debug && enter("area_of_entire_graph")
	all_pts = get_raw_points(l,g.vertices)
	H = convex_hull(all_pts,debug=debug)
	if H == nothing
		return 0
	end
	debug && all_done("area_of_entire_graph")
	area_of_convex_polygon(H)
end

function subgraph_area(g,l,sg;debug=false)
	debug && enter("subgraph_area")
	debug && println("\n---\nsubgraph:")
	area = 0
	cc = connected_components(sg,debug=debug)
	debug && println("g:$g\nl:$l\ncc:$cc")
	for c in cc
		debug && println("Looking at component c = $c")
		pts = get_raw_points(l,c)
		debug && println("raw points: $pts")
		h = convex_hull(pts)
		debug && println("convex hull: $h")
		if h == nothing
			return nothing
		end
		area += area_of_convex_polygon(h, debug=debug)
	end
	area
end


# TODO: push this up so that it include subgraph calculation
function purchase_score(g,l,sgs, c_sgs, cps; 
		FRACTION=0.5,
		debug=false,
		verbose=false)

	debug && enter("purchase_score")
	debug && println("g:$g\nl:$l")
	subscores = Array{Float64,1}()
	subareas = Array{Float64,1}()
	TOTAL_SYM = 0
	TOTAL_AREA = 0
	for (i,c_sg) in enumerate(c_sgs)
		SUB_SYM = subgraph_symmetry(g, l, sgs[i], c_sg, cps, FRACTION=0.5, debug=debug)
		verbose && println("SUB_SYM: $SUB_SYM")
		SUB_AREA = subgraph_area(g,l,c_sg,debug=debug)
		if SUB_AREA == nothing
			# return (-1, nothing, nothing)
			SUB_AREA = 0
		end
		verbose && println("SUB_AREA $SUB_AREA")
		TOTAL_AREA += SUB_AREA
		TOTAL_SYM += SUB_SYM * SUB_AREA
		push!(subscores, SUB_SYM)
		push!(subareas, SUB_AREA)
	end
	WHOLE_AREA = area_of_entire_graph(g,l)
	debug && println("Area of entire graph: $WHOLE_AREA")
	if WHOLE_AREA == nothing
		return nothing
	end
	verbose && println("TOTAL_SYM: $TOTAL_SYM")
	verbose && println("WHOLE_AREA: $WHOLE_AREA")
	verbose && println("TOTAL_AREA: $TOTAL_AREA")
	push!(subareas, max(WHOLE_AREA, TOTAL_AREA))
	final_score = TOTAL_SYM / max(WHOLE_AREA, TOTAL_AREA)
	push!(subscores, final_score)
	final_score, subscores, subareas
end



# test case
#function test()
#	g = load_light_graph("$G/sunglasses")
#	ls = load_layouts("$L/sunglasses")
#	ss = minimized_stresses(g,ls)
#	g_idx, g_ss = goldilocks(ss)
#	l = ls[g_idx[1]]
#	axes = extract_symmetric_axes(g, l)
#	sgs, used_axes = find_sym_subgraphs(g,l,axes,TOLERANCE=0.1)
#	c_sgs, c_uas = consolidate_subgraphs(sgs, used_axes)
#end
#test()

"""
select graph
	Option 1) load graph 					[load_light_graph(filename)
	Option 2) describe a graph		[create_light_graph(array_of_edge_pairs]
select layouts
	Option 1) Compute a single layout                   [spring_layout]
	Option 2) Load layout/s you already care about	    [load_layout/s]
  Option 3) Generate many layouts									    [compute_n_layouts]
		Option 3a) select just a few
		           eg, compute stresses 								  [minimized_stresses]
							 eg, determine min/med/max stresses		  [goldilocks]
		Option 3b) use all computed layouts
for each layout, 
	do crossings promotion 											        [crosses_promotion!]
	determine axes															        [extract_symmetric_axes]
	for each axis, find symmetric subgraph              [find_sym_subgraphs]
	consolidate subgraphs to eliminate duplicate edges  [consolidate_subgraphs]
	determine score from graph, layout, and subgraphs   [purchase_score]
"""


function purchase_sanity(name::String, li=1; BASEDIR= "/Users/hapless/graph-symmetries/", SUBDIR="sanity-check/", save_axes=true, TOLERANCE=0.1, debug=false)
	pr = purchase(name, li, BASE_DIR="$(BASEDIR)$(SUBDIR)", TOLERANCE=TOLERANCE, debug=debug)
	if(save_axes)
		export_axes("$(BASEDIR)/$(SUBDIR)/axes/$(name)_layout$(li).csv", pr.c_uas)           # consolidated used axes
		export_subgraphs("$(BASEDIR)/$(SUBDIR)/subgraphs/$(name)_layout$(li).csv", pr.c_sgs) # consolidated subgraphs
		export_promoted_graph("$(BASEDIR)/$(SUBDIR)/graphs-promoted/",   name, li, pr.g)
		export_promoted_layout("$(BASEDIR)/$(SUBDIR)/layouts-promoted/", name, li, pr.l)
		export_subscores("$(BASEDIR)/$(SUBDIR)/subscores/", name, li, pr.subscores)
		export_subareas("$(BASEDIR)/$(SUBDIR)/subareas/", name, li, pr.subareas)
	end
	println("Graph $(name)   Layout $(li)   Score = $(pr.score)")
	#println("Axes:      $(pr.c_uas)")
	#println("Subgraphs: $(pr.c_sgs)")
	return pr
end


function export_subareas(basedir, name, li, subareas)
	if !isdir("$(basedir)$name")
		mkdir("$(basedir)$name")
	end
	filename = "$(basedir)$(name)/$(name)_layout$(li).csv"
	out = []
	push!(out, ("axis_id", "subarea"))
	for (i, subarea) in enumerate(subareas)
		push!(out, (i-1, subarea))
	end
	writedlm(filename, out, ',')
end

# will only be used by Processing
function export_subscores(basedir, name, li, subscores)
	if !isdir("$(basedir)$name")
		mkdir("$(basedir)$name")
	end
	filename = "$(basedir)$(name)/$(name)_layout$(li).csv"
	out = []
	push!(out, ("axis_id", "subscore"))
	for (i, subscore) in enumerate(subscores)
		push!(out, (i-1, subscore))
	end
	writedlm(filename, out, ',')
end

# will only be used by Processing
function export_promoted_graph(basedir, name, li, g)
	if !isdir("$(basedir)$name")
		mkdir("$(basedir)$name")
	end
	filename = "$(basedir)$(name)/$(name)_layout$(li).csv"
	out = []
	push!(out, ("s", "t"))
	for v1 in g.vertices
		for v2 in g.fadjlist[v1]
			if v2 > v1
				push!(out, (v1-1, v2-1))
			end
		end
	end
	writedlm(filename, out, ',')
end

function export_promoted_layout(basedir, name, li, l)
	if !isdir("$(basedir)$name")
		mkdir("$(basedir)$name")
	end
	filename = "$(basedir)$(name)/$(name)_layout$(li).csv"
	out = []
	push!(out, ("x","y"))
	for i in 1:size(l[1], 1)
		x = l[1][i]
		y = l[2][i]
		push!(out, (x,y))
	end
	writedlm(filename, out, ',')
end

function export_axes(filename, c_uas)
	out = []
	push!(out, ("a", "b", "c"))

	for axis in c_uas
		push!(out, (axis.a, axis.b, axis.c))
	end
	writedlm(filename, out, ',')
end


# zero-based indices since we will only use these in Processing
function export_subgraphs(filename, c_sgs)
	out = []
	push!(out, ("axis_id", "s", "t"))
	for (i, subgraph) in enumerate(c_sgs)
		for edge in subgraph
			# println("Edge: $(edge[1]), $(edge[2])")
			push!(out, (i-1, edge[1]-1, edge[2]-1))
		end
		writedlm(filename, out, ',')
	end
end

function purchase(name::String, li=1; 
									TOLERANCE=0.1,
									debug=false,
									verbose=false,
                  BASE_DIR::String="/Users/hapless/graph-symmetries/", 
									GRAPH_SUBDIR="graphs/",
									LAYOUT_SUBDIR="layouts/",
									AXIS_SUBDIR="axes/",
									SUBGRAPH_SUBDIR="subgraphs/")

	debug && println("\n\nRunning purchase on graph $(name)\n\n")
	g = load_light_graph(name; GRAPH_DIR="$(BASE_DIR)$(GRAPH_SUBDIR)")
	l = load_layout("$(BASE_DIR)$(LAYOUT_SUBDIR)$(name)/$(name)_layout$(li).csv")
	purchase(g,l,TOLERANCE=TOLERANCE, verbose=verbose, debug=debug)
end

function purchase(g,l; debug=false, verbose=false, TOLERANCE=0.1)
	cps = crosses_promotion!(g,l)
	# debug && println("After crosses promotion:\ng: $g\nl: $l")
	# debug && render_layout("temp", g, l)

	axes = extract_symmetric_axes(g,l)
	sgs, uas = find_sym_subgraphs(g, l, axes; TOLERANCE=TOLERANCE) 
	# debug && println("Original subgraphs: $sgs")

	c_sgs, c_uas, sgs = consolidate_subgraphs(sgs, uas)
	# debug && println("Consolidated subgraphs: $c_sgs")
	# debug && println("Retained raw subgraphs: $sgs")

	score, subscores, subareas = purchase_score(g, l, sgs, c_sgs, cps, debug=debug)
	if score == nothing
		println("** Error calculating score, returning -1 **")
		score = -1
		subscores
	end
	debug && println("** score: $score **")
	PurchaseResult(g,l,axes,sgs,uas,c_sgs,c_uas,score, subscores, subareas)
end

function multi_purchase(g,ls; n=100, debug=false, verbose=false, TOLERANCE=0.1)
	(verbose || debug) && enter("multi_purchase(g=$g, TOLERANCE=$TOLERANCE)")
	results = Array{PurchaseResult}(n)
	for (i,l) in enumerate(ls)
		g2 = copy(g)
		if debug
			println("\n\n\n\n\n\n** Layout $i **\n\n\n\n\n\n")
		else
		# elseif verbose
			print("Layout $i: ")
		end
		tic()
		results[i] = purchase(g2,l,verbose=verbose,debug=debug, TOLERANCE=TOLERANCE)
		elapsed = toq()
		if results[i].score == -1
			println("Could not calculate score for layout $i")
		end
		if debug
			println("** Score for layout $i: $(results[i].score) ** \n\n")
		# elseif verbose 
		else
			println("$(results[i].score) ($elapsed s)") 
		end
	end
	results
end

type PurchaseResult
	g::LightGraphs.Graph
	l::Tuple{Array{Float64,1},Array{Float64,1}}
	#axes::Array{StdLine,1}
	axes::Array
	#sgs::Array{Array{Int64,1},1}
	sgs::Array
	#uas::Array{StdLine,1}
	uas::Array
	#c_sgs::Array{Array{Int64,1},1}
	c_sgs::Array
	#c_uas::Array{StdLine,1}
	c_uas::Array
	score::Float64
	subscores::Array{Float64,1}
	subareas::Array{Float64,1}
end

function has_self_loop(g)
	for i in g.fadjlist
		for j in g.fadjlist[i]
			if i == j
				return true
			end
		end
	end
	return false
end


# returns list of id's and results for this id's
function run_all_ug(
	whitelist=[];
	starting=nothing,
	n=100,
	ne_max=20,
	rendering="goldilocks",
	override=false, #include graph with more than ne_max edges, if in whitelist
	blacklist= [
		17,    # 36 edges, some layout resulted in hull of 3 pts w/ 4 corners
		103, 195, 368,   # not connected
		141,  # nodes too close together, hope to accommodate later
		210   # not sure, complaining, figure out why later
	],
	debug=false, 
	verbose=false,
	#TOLERANCE=0.1,
	GRAPH_DIR="$G")

	debug && enter("run_all_ug")
	verbose && println("--==[ Running Purchase symmetry detection algorithm with $n layouts per graph and max $ne_max edges ]==--")
	debug && println("\n\nLoading graphs from $GRAPH_DIR")
	if starting != nothing
		verbose && println("Starting with graph $starting")
	end
	tic()
	processed = []
	results = []
	for f in readdir(GRAPH_DIR)
		if contains(f, ".csv") && contains(f,"ug") 
			name = replace(f,".csv","")
			id = parse(match(r"[0-9]+", name).match)

			# skip anything we're not interested in 
			if whitelist != [] && !(id in whitelist)
				continue
			end
			if starting != nothing
				if "$id" < starting 
					continue
				end
			end
			if id in blacklist
				println("blacklisted")
				continue
			end

			g = load_light_graph(name, debug=debug)
			#if g.ne == size(g.fadjlist,1)-1
		#		verbose && println("probably a star")
	#			continue
	#		end

			(debug || verbose) && print("Graph $name ($(g.ne) edges)...")
			if g.ne > ne_max && (whitelist == [] || !override)
				verbose && print(" > $ne_max edges")
				verbose && println("")
				continue
			end
			if has_self_loop(g)
				verbose && println("self-loop")
				continue
			end
			tic()
			for TOLERANCE in 0.03:0.0005:0.04
				println("\nRunning purchase experiment on graph $name ($(size(g.fadjlist,1)) vertices, $(g.ne) edges) with TOLERANCE=$TOLERANCE")
				result = purchase_experiment(name, g, rendering="goldilocks", n=n, debug=debug, TOLERANCE=TOLERANCE, debug=debug)
				push!(results, result) 
			end
			push!(processed, id)
			elapsed = toq()
			println("-- Graph $name took $elapsed seconds --")
		end
	end
	elapsed = toq()
	println("--==[ Processed $(size(processed,1)) graphs in $elapsed seconds ]==--")
#	processed, results
end




########
# MAIN # 
########


