# Experiments.jl

L = "/Users/hapless/graph-symmetries/layouts"
G = "/Users/hapless/graph-symmetries/graphs"
S = "/Users/hapless/graph-symmetries/scores"
function setup_directories(name, dir, purpose; debug=false)
	ready = true
	debug && print("Checking if $dir exists as a directory... ")
	if !isdir(dir)
		ready = false
		debug && println("no!")
		if isfile(dir) 
			println("Fatal error: file $dir exists, but wanted to save $purpose in this location as a directory")
			return nothing
		end
		mkdir(dir)
	end
	if !ready || !isdir("$dir/$name")
		ready = false
		if isfile("$dir/$name")
			println("Fatal error: file $dir$name exists, but wanted to save $purpose in this location as a directory")
			return nothing
		end
		mkdir("$dir/$name")
		ready = true
	end
	ready
end

function try_to_load_layouts(name, g; n=100, LAYOUT_DIR="$L", debug=false, verbose=false)
	debug && enter("try_to_load_layouts")
	if !isdir(LAYOUT_DIR)
		debug && all_done("try_to_load_layouts with error: directory $L does not exist")	
		return nothing
	end
	if !isfile("$LAYOUT_DIR/$name/$(name)_layout$n.csv")
		debug && all_done("try_to_load_layouts with error: there are not $n layouts in $LAYOUT_DIR/$name")
		return nothing
	end
	(debug || verbose) && println("loading layouts...")
	ls = load_layouts("$LAYOUT_DIR/$name/$name", n=n)
	debug && all_done("try_to_load_layouts with success!")
	return ls
end

function load_or_generate_layouts(name, g; n=100, LAYOUT_DIR="$L", debug=false, verbose=false)
	debug && enter("load_or_generate_layouts(name=$name, g=$g")
	ready = setup_directories(name, LAYOUT_DIR, "layouts", debug=debug)
	if !ready
		return nothing
	end
	if isfile("$LAYOUT_DIR/$name/$(name)_layout$n.csv")
		(debug || verbose) && print("loading layouts... ")
		# (verbose || debug) && print("loading layouts... ")
		debug && all_done("load_or_generate_layouts")
		return load_layouts("$LAYOUT_DIR/$name/$name", n=n)
	else
		(debug || verbose) && print("generating layouts... ")
		# (verbose || debug) && print("generating layouts... ")
		ls = generate_n_layouts(g, n)
		save_layouts("$LAYOUT_DIR/$name/$name", ls)
		return ls
	end
	debug && all_done("load_or_generate_layouts")
end


# TODO: Evaluate effects of scaling
# function purchase_experiment(name, g, rendering="goldilocks"; 
function purchase_experiment(name, g; 
		rendering="goldilocks",
		verbose=false,
		debug=false,
		gold_n=5,
		n=100,
		TOLERANCE=TOLERANCE,
		GRAPH_DIR = "/Users/hapless/graph-symmetries/graphs",
		LAYOUT_DIR  = "/Users/hapless/graph-symmetries/layouts",
		SCORE_DIR  = "/Users/hapless/graph-symmetries/scores/purchase",
		typ="png",
		RENDER_DIR="/Users/hapless/graph-symmetries/$typ")

	if rendering == "all" && n > 10
		println("Warning: you are probably about to use up a lot of hard drive space!  \nIt is recommended that you use `goldilocks' rendering if you're looking at more than 10 layouts per graph ")
	end
	debug && enter("purchase_experiment(name=$(name), g=$(g)")
#	g = load_light_graph(name, GRAPH_DIR=GRAPH_DIR)
	ls = load_or_generate_layouts(name, g, n=n, verbose=false, debug=debug)
	if rendering == "all"
		render_layouts("$RENDER_DIR/$name", g, ls, typ=typ)
	end
	results = multi_purchase(g, ls, n=n, TOLERANCE=TOLERANCE, verbose=verbose, debug=debug)
	scores = [pr.score for pr in results]
	#g_idxs, g_scores = goldilocks(scores, gold_n)
	#if rendering == "goldilocks"
		#render_layouts("$RENDER_DIR/$name", g, ls, g_idxs, typ=typ)
	#end
	# save_scores("$SCORE_DIR/$name", 1:n, scores)
	save_scores_and_tolerance("$SCORE_DIR/$name", 1:n, scores, TOLERANCE)
	verbose && all_done("purchase_experiment")
	results
end

function scale_layouts(scale, ls)
	outs = copy(ls)
	for out in outs
		
	end
end

function scaling_stress_experiment(name;
		scales=0.5:0.5:20,
		verbose=false,
		debug=false,
		n=100,
		GRAPH_DIR = "/Users/hapless/graph-symmetries/graphs",
		LAYOUT_DIR  = "/Users/hapless/graph-symmetries/layouts",
		SCORE_DIR  = "/Users/hapless/graph-symmetries/scores/stress/scaling",
		typ="png",
		RENDER_DIR="/Users/hapless/graph-symmetries/$typ")

	verbose && enter("scaling_purchase_experiment")
	g = load_light_graph(name, GRAPH_DIR=GRAPH_DIR)
	ls = load_or_generate_layouts(name, g, n=n, verbose=verbose)
	scores = Array{Tuple{Int64,Float64,Float64},1}()
	for (i,l) in enumerate(ls)
		ls[i] = ((l[1]+1)/2, (l[2]+1)/2)
		# println("layout $i changed to $(ls[i])")
	end
	orig_ls = copy(ls)
	for scale in scales
		verbose && println("Scale $scale")
		for (i,l) in enumerate(orig_ls)
			ls[i] = (l[1]*scale, l[2]*scale)
			stress = quick_stress(g, ls[i])
			push!(scores, (i, scale, stress))
		end
	end
	scores = sort_by_first(scores)
	writedlm("$SCORE_DIR/$name.csv", scores, ',');
	verbose && println("Saved to $SCORE_DIR/$name.csv")
	verbose && all_done("scaling_purchase_experiment")
	scores
end

function scaling_purchase_experiment(name;
		scales=20:20:800,
		TOLERANCE=3,
		verbose=false,
		debug=false,
		n=100,
		GRAPH_DIR = "/Users/hapless/graph-symmetries/graphs",
		LAYOUT_DIR  = "/Users/hapless/graph-symmetries/layouts",
		SCORE_DIR  = "/Users/hapless/graph-symmetries/scores/purchase/scaling",
		typ="png",
		RENDER_DIR="/Users/hapless/graph-symmetries/$typ")

	verbose && enter("scaling_purchase_experiment")
	g = load_light_graph(name, GRAPH_DIR=GRAPH_DIR)
	println("Loaded light graph g, which has type of $(typeof(g))")
	ls = load_or_generate_layouts(name, g, n=n, verbose=verbose, debug=debug)
	scores = Array{Tuple{Int64,Float64,Float64},1}()
	for (i,l) in enumerate(ls)
		ls[i] = ((l[1]+1)/2, (l[2]+1)/2)
		# println("layout $i changed to $(ls[i])")
	end
	orig_ls = copy(ls)
	for scale in scales
		verbose && println("Scale $scale")
		for (i,l) in enumerate(orig_ls)
			ls[i] = (l[1]*scale, l[2]*scale)
		end
		results = multi_purchase(g, ls, n=n, verbose=verbose, debug=debug, TOLERANCE=TOLERANCE)
		round_scores = [pr.score for pr in results]
		for (i,score) in enumerate(round_scores)
			push!(scores, (i, scale, score))
		end
	end
	scores = sort_by_first(scores)
	writedlm("$SCORE_DIR/$name.csv", scores, ',');
	verbose && println("Saved to $SCORE_DIR/$name.csv")
	verbose && all_done("scaling_purchase_experiment")
	scores
end

function sort_by_first(scores::Array{Tuple{Int64,Float64,Float64},1})
	buckets = Array{Array{Tuple{Int64,Float64,Float64},1},1}()
	for entry in scores
		layout = entry[1]
		if layout > size(buckets,1)
			push!(buckets, Array{Tuple{Int64,Float64,Float64},1}())
		end
		push!(buckets[layout], entry)
	end
	out = Array{Tuple{Int64,Float64,Float64},1}()
	for bucket in buckets
		append!(out,bucket)
	end
	out
end

function sort_by_first(scores::Array{Tuple{Int64,Int64,Float64},1})
	buckets = Array{Array{Tuple{Int64,Int64,Float64},1},1}()
	for entry in scores
		layout = entry[1]
		if layout > size(buckets,1)
			push!(buckets, Array{Tuple{Int64,Int64,Float64},1}())
		end
		push!(buckets[layout], entry)
	end
	out = Array{Tuple{Int64,Int64,Float64},1}()
	for bucket in buckets
		append!(out,bucket)
	end
	out
end


function save_scores(name::String, idx_score_tuples)
	save_scores(name, idx_score_tuples[1], idx_score_tuples[2])
end

function save_scores_and_sizes(name::String, idxs, scores, ws, hs)
	output = Array{Tuple{Int64, Float64, Float64, Float64}, 1}()
	println("idxs:\n$idxs")
	println("size(scores): $(size(scores))")
	println("size(ws): $(size(ws))")
	println("size(hs): $(size(hs))")
	for (i, idx) in enumerate(idxs)
		push!(output, (idx, scores[i], ws[i], hs[i]))	
	end
	writedlm("$name.csv", output, ',')
end

function save_scores(name::String, idxs, scores)
	output = Array{Tuple{Int64, Float64}, 1}()
	for (i, idx) in enumerate(idxs)
		push!(output, (idx, scores[i]))
	end
	writedlm("$name.csv", output, ',')
end

function save_scores_and_tolerance(name::String, idxs, scores, TOLERANCE)
	output = Array{Tuple{Int64, Float64, Float64}, 1}()
	for (i, idx) in enumerate(idxs)
		push!(output, (idx, TOLERANCE, scores[i]))
	end
	open("$name.csv", "a") do f
		writedlm(f, output, ',')
	end
end

#function klapaukh_experiment_phase_1(g, name; 
#		n=100,
#		GRAPH_DIR    = "$G"
#		LAYOUT_DIR   = "$L"
#		KLAPAUKH_DIR = "../klapaukh")
#
#	g = load_light_graph(name, GRAPH_DIR=GRAPH_DIR)
#	ls = load_or_generate_layouts(name, g, n=n, LAYOUT_DIR=LAYOUT_DIR)
#	for i = 1:n
#		save_to_klapaukh("$KLAPAUKH/$(name)_layout$i")		
#	end
#	# hopefully we can make a system call...
#end

blacklist=[
	17,    # 36 edges, some layout resulted in hull of 3 pts w/ 4 corners
	103, 195, 368,   # not connected
	141,  # nodes too close together, hope to accommodate later
	210   # not sure, complaining, figure out why later
]

function all_stress_ugs(
		whitelist = [];
		starting=nothing,
		n=100,
		ne_max=25,
		rendering="goldilocks",
		override=false,
		debug=false, 
		verbose=false,
		GRAPH_DIR="$G",
		LAYOUT_DIR="$L",
		typ="png",
		RENDER_DIR="/Users/hapless/graph-symmetries/$typ",
		SCORE_DIR="/Users/hapless/graph-symmetries/scores/stress")
		
	println("--==[ Running minimized stress with $n layouts per graph and max $ne_max edges ]==--")
	if starting != nothing
		verbose && println("Starting with graph $starting")
	end
	tic()
	processed = []
	results = []
	for f in readdir(GRAPH_DIR)
		if contains(f,".csv") && contains(f,"ug")
			name = replace(f,".csv","")
			id = parse(match(r"[0-9]+",name).match)
			if whitelist != [] && !(id in whitelist)
				continue
			end
			if starting != nothing && "$id" < starting
				continue
			end
			if id in blacklist
				verbose && println("blacklisted")
				continue
			end
			g = load_light_graph(name)
			(debug || verbose) && println("Graph $name ($(g.ne) edges)...")
			if g.ne > ne_max && (whitelist == [] || !override)
				verbose && print(" > $ne_max edges")
				verbose && println("")
				continue
			end
			if has_self_loop(g)
				verbose && println("self-loop")
				continue
			end
			print("running experiment... ")
			tic()
			result = stress_experiment(name, g, rendering=rendering, n=n, debug=debug, verbose=verbose)
			if result == nothing
				println("stress experiment returned nothing")
				return nothing
			end
			elapsed = toq()
			verbose && println("$n layouts took $elapsed seconds")
			push!(processed, id)
			push!(results, result)
		end
	end
	elapsed = toq()
	println("--==[ Processed $(size(processed,1)) graphs in $elapsed seconds ]==--")
	processed, results
end

#function purchase_experiment(name, g, rendering="goldilocks"; 
#		verbose=false,
#		debug=false,
#		gold_n=5,
#		n=100,
#		GRAPH_DIR = "/Users/hapless/graph-symmetries/graphs",
#		LAYOUT_DIR  = "/Users/hapless/graph-symmetries/layouts",
#		typ="png",
#		RENDER_DIR="/Users/hapless/graph-symmetries/$typ")

function stress_experiment(name, g; 
		rendering="goldilocks", 
		n=100, 
		debug=false, 
		verbose=false, 
		gold_n=3, 
		SCORE_DIR  = "/Users/hapless/graph-symmetries/scores/stress",
		typ="png",
		RENDER_DIR = "/Users/hapless/graph-symmetries/$typ")
	(verbose || debug) && enter("stress_experiment")
	layouts = try_to_load_layouts(name, g, n=n, debug=debug, verbose=verbose)
	if layouts == nothing
		(verbose || debug) && println("Could not load layouts") &&  all_done("stress_experiment")
		return nothing
	end
	results = minimized_stresses(g,layouts)
	scores = [result[1] for result in results]
	ws = [result[2] for result in results]
	hs = [result[3] for result in results]
	g_idxs, g_scores = goldilocks(scores, gold_n)
	#if rendering == "goldilocks"
		#render_layouts("$RENDER_DIR/$name", g, layouts, g_idxs, typ=typ)
	#end
	save_scores("$SCORE_DIR/$name", 1:n, scores)
	# save_scores_and_sizes("$SCORE_DIR/$name", 1:n, scores, ws, hs)
	results
end



function write_stress_summary(name, stresses, idxs)
	open("$(name)_stress.txt", "w") do f
		write(f, "layout_id,stress\n")
		for i in idxs
			write(f, "$(i),$(stresses[i])\n")
		end
	end
end

function write_stress_html(name, ss, idxs)
	println("Inside write_stress_html, using name $(name)")
	open("$(name)_stress.html", "w") do f
		write(f, "<html>\n<head>\n<title>$(name)</title>\n")
		write(f, "<style>\n")
		write(f, ".layout { font-weight: bold; }\n")
		write(f, ".stress { color: red; }\n")
		write(f, "</style>\n")
		write(f, "</head>\n")
		write(f, "<body>\n<h1>$(name)</h1>\n")
		write(f, "<table>\n")
		for i in idxs
			write(f, "  <tr>\n")
			write(f, "    <td><span class='layout'>layout $i</span></td>\n")
			write(f, "    <td style='padding: 0 15px 0 15px'><span class='stress'>stress = $(ss[i])</span></td>\n")
			write(f, "    <td><img src='png/$(name)_layout$(i).png'></td>\n")
			write(f, "  </tr>\n")
		end
		write(f, "</table>")
		write(f, "<hr>Automatically generated by a script written by Eric Welch<br>$(Date(now()))</body></html>")
	end
end
