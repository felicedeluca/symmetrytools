# GraphIO.jl
# -----------
# utilities to save and load graphs and layouts using CSV format
# compatible with LightGraphs.jl and GraphPlot.jl
#
# Eric Welch
# October 2016

#############
# graph i/o #
#############


#function load_graph(filename, dlm=',')
#	bare = convert(Array{Int64,2}, readdlm(filename, dlm))
#	create_graph(bare)
#end

G="/Users/hapless/graph-symmetries/graphs"
L="/Users/hapless/graph-symmetries/layouts"

function read_edges(filename; debug=false)
	debug && println("reading edges from $filename")
	imported = readdlm(filename, ',')
	if isa(imported[1], SubString{String})
		println("you need to strip the header!")
		println("someday, I'll do it automatically, but that day is not today")
		println("see strip_header.py in \$GS/sanity-check/")
	end
	es = convert(Array{Int64,2}, imported)
	# es = convert(Array{Int64,2}, readdlm(filename, ','))
	[es[i,:] for i in 1:size(es,1)]
end

function load_light_graph(filename; GRAPH_DIR="$G", debug=false, addcsv=false)
	debug && enter("load_light_graph($filename)")
	# print("loading edges from directory $GRAPH_DIR, named $filename.csv")
	if addcsv
		filename = "$filename.csv"
	end
	if GRAPH_DIR != ""
		GRAPH_DIR = "$GRAPH_DIR/"
	end
	es = read_edges("$GRAPH_DIR$filename", debug=debug)
	create_light_graph(es)
end

function save_light_graph(filename, g)
	adj = g.fadjlist
	out = Array{Int64,2}(0,2)
	for i in 1:size(adj,1)
		for j in adj[i]
			if i < j
				out	= vcat(out, [i j])
			end
		end
	end
	writedlm(filename, out, ',')
end



#####################
# save/load layouts #
#####################

function load_layout(filename::String, dlm=','; debug=false)
	xys	= convert(Array{Float64, 2}, readdlm(filename, ','))
	n = size(xys, 1)
	debug && println("layout from file $filename has $n vertices: $xys")
	(xys[:,1], xys[:,2])
end

function load_layout(name::String, idx::Int; LAYOUT_DIR="$L", debug=false)
	load_layout("$LAYOUT_DIR/$name/$(name)_layout$idx.csv")
end

function load_layouts(filebase; n::Int=100)
	layouts = Array{Tuple{Array{Float64,1},Array{Float64,1}},1}(n)
	for i = 1:n
		layouts[i] = load_layout("$(filebase)_layout$(i).csv")
	end
	layouts
end


function save_layout(filename, layout)
	array = [layout[i][j] for j in 1:size(layout[1], 1), i in 1:2]
	writedlm(filename, array, ',')
end

# TODO: save into subdirectory with graph name
function save_layouts(basename, layouts)
	for i = 1:size(layouts,1)
		save_layout("$(basename)_layout$(i).csv", layouts[i])
	end
end
