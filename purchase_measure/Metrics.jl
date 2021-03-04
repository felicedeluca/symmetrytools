##########
# Stress #
##########

function stress(l::Tuple{Array{Float64,1},Array{Float64,1}}, d::Array{Float64,2}, w=nothing)
	X = [[l[1][i] l[2][i]] for i in 1:size(l[1],1)]
	s = 0.0
	n = size(X,1)
	if w == nothing
		w = d.^-2
		w[!isfinite(w)] = 0
	end
	if !(n==size(d,1) == size(d,2) == size(w,1) == size(w,2))
		println("Fatal error while computing stress for layout $l")
		println("n: $n\nsize of d: $(size(d))\nsize of w: $(size(w))")
	end
	@assert n == size(d,1) == size(d,2) == size(w,1) == size(w,2)
	for j=1:n,i=1:j-1
		s += w[i,j] * (norm(X[i,:]-X[j,:]) - d[i,j])^2
	end
	@assert isfinite(s)
	s
end

function quick_stress(g::LightGraphs.Graph, layout::Tuple{Array{Float64,1},Array{Float64,1}})
	d = construct_distance_matrix(g)
	stress(layout, d)
end

function quick_stresses(g, layouts)
	d = construct_distance_matrix(g)
	map(l->stress(l,d), layouts)
end

function minimized_stresses(g, layouts)
  out = map(l->minimized_stress(g,l), layouts)
	# println("output of minimized_stresses:\n$out")
  out
end

# todo: this could be more efficient if we calculated d and passed it on to minimzed_stress
function rank_by_minimized_stress(g, layouts)
	ss = minimized_stresses(g,layouts)
	sorted_idxs = sortperm(ss)
	sorted_idxs, ss[sorted_idxs]
end
	
# TODO: prevent bad measurements in the first place
function goldilocks(measures, n=3)
	idxs_of_interest = ints(linspace(1, size(measures,1), n))
	sorted_idxs = sortperm(measures)
	if measures[sorted_idxs[1]] == -1
		println("Warning: bad measurement")
	end
	(sorted_idxs[idxs_of_interest], measures[sorted_idxs[idxs_of_interest]])
end

function generate_caricatures(g, n = 3, N=100)
	d = construct_distance_matrix(g)
	layouts = generate_n_layouts(g, N, "spring")
	stresses = map(l -> stress(l, d), layouts)
	sorted_idxs = sortperm(stresses)
	# stresses[sorted_idxs[1]] contains minimum stress
	idxs_of_interest = ints(linspace(1,N,n))
	(layouts[sorted_idxs[idxs_of_interest]], stresses[sorted_idxs[idxs_of_interest]])
end

function minimized_stress(g, layout,curr_depth=0; min_w=0.01, max_w=100, max_depth=15, verbose=false, debug=false)
	if curr_depth == max_depth
		out = quick_stress(g, layout)
		if(verbose)
			println("Reached max depth $max_depth, returning stress $out at width $(width(layout))")
		end
		return out, width(layout), height(layout)
	end
	n = size(layout[1], 1)
	orig_w = width(layout)
	mid_w = (min_w+max_w)/2
	rescale!(layout, min_w/orig_w)
	if(size(layout[1], 1) != n)
		println("Error: Size of layout changed from $n to $(size(layout[1],1))")
	end
	s1 = quick_stress(g,layout)
	rescale!(layout, max_w/min_w)
	if(size(layout[1], 1) != n)
		println("Error: Size of layout changed from $n to $(size(layout[1],1))")
	end
	s2 = quick_stress(g,layout)
	if s1 < s2
		if(verbose)
			println("Prefer width $min_w -> stress $s1 over width $max_w -> stress $s2")
		end
		out, w, h = minimized_stress(g, layout, curr_depth+1, min_w=min_w, max_w=mid_w,  max_depth=max_depth)
	else
		if(verbose)
			println("Prefer width $max_w -> stress $s2 over width $min_w -> stress $s1")
		end
		out, w, h = minimized_stress(g, layout, curr_depth+1, min_w=mid_w, max_w=max_w,  max_depth=max_depth)
	end
	if curr_depth == 0
		rescale!(layout, orig_w/width(layout))
		if(size(layout[1], 1) != n)
			println("Error: Size of layout changed from $n to $(size(layout[1],1))")
		end
		# debug && println("Sanity check: exit dimensions are $(width(layout))x$(height(layout))")
	end
	out, w, h
end
		
function cf_min_stress(gname, lis)
	g = load_light_graph(gname)
	li = lis[1]
	l = load_layout(gname, li)
	msr1 = minimized_stress(g,l)
	li = lis[2]
	l = load_layout(gname, li)
	msr2 = minimized_stress(g,l)
	results = [ [gname[4:end], lis[1], msr1[1]], [gname[4:end],lis[2], msr2[1]]]
	results
end
	
function read_idx_pairs(infile)
	ids=readdlm(infile, ',')
	args = []
	for i in 1:2:size(ids,1)
		push!(args, ["ug_$(ids[i,1])", [ids[i,2],ids[i+1,2]]])
  end
	args
end

function cf_many_min_stresses(args)
	for (gname,lis) in args
		results = vcat(results, cf_min_stress(gname, lis))
	end
	results
end
