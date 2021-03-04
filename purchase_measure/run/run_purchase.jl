# purchase_metric.jl
#
# Script to calculate Purchase metric for graph layouts
# Eric Welch, March 2017
#
# TODO
# Decide what to do about config file tolerance and requirement that one be provided


include("../purchase.jl")
include("parse_args.jl")
include("rp_options.jl")
include("utils.jl")

G="."
L="."


function update()
	include("run_purchase.jl")
end


function print_help()
	USAGE = "run_purchase.jl [-h] [-v] [-c config_file] [-t tolerance graph_file layout_files...]"
	println(USAGE)
	# println("TODO: provide help")
end

function extend_output(g_name, l_name, tol, result, output, readable)
	if readable
		new_out = "Graph $g_name -- Layout $l_name -- Tolerance $tol -- Score $(result.score)\n"
	else
		new_out = "$g_name,$l_name,$tol,$(result.score)\n"
	end
	"$(output)$(new_out)"
end

function write_results(outfile, output)
	if outfile == "__STDOUT__"
		# println("\n\n\n\n\n****** PRINTING OUTPUT ****** \n\n\n\n")
		print(output)
	else
		# println("\n\n\n\n\n****** WRITING OUTPUT TO $outfile ****** \n\n\n\n")
		open(outfile, "w") do f
			write(f,output)
		end
	end
end


########
# MAIN #
########

flags, options, raw_args = parse_args(ARGS)
if "help" in flags
	print_help()
	exit(0)
end
graphs, layouts, tols, prep, outfile, verbose, readable = process_options(flags, options, raw_args)

# println("g:$graphs\nl:$layouts\nt:$tols\np:$prep\no:$outfile")

output = ""
for g_file in graphs
	g_name = strip_csv_extension(strip_dir_name(g_file))
	g_orig = load_light_graph(g_file, GRAPH_DIR="")
	#println("Graph $g has adjlist $(g.fadjlist)")
	for l_file in layouts[g_file]
		l_name = strip_layout_label(strip_csv_extension(l_file))
		l = load_layout(l_file)
		for tol in tols
			# println("one layout for $g_file is $l_file:\n$l")
			g = copy(g_orig)  # g is destructively edited during crossings promotion
			result = purchase(g,l,TOLERANCE=tol)
			if result.score == -1
				println("Error: Could not calculate score for layout $l_file")
				continue
			end
			# TODO: scrape directory names from g_file and l_name; also, scrape $(g_file)_ from l_name if present (which it should be)
			output = extend_output(g_name, l_name, tol, result, output, readable)
		end
	end
end

write_results(outfile, output)
