include("../purchase.jl")
include("parse_args.jl")
include("rp_options.jl")
include("utils.jl")

# function update()
# 	include("run_purchase.jl")
# end
#
function extend_output(g_name, l_name, tol, result, output, readable)
	if readable
		new_out = "Graph $g_name -- Layout $l_name -- Tolerance $tol -- Score $(result.score)\n"
	else
		new_out = "$g_name,$l_name,$tol,$(result.score)\n"
	end
	"$(output)$(new_out)"
end
#
# function write_results(outfile, output)
# 	if outfile == "__STDOUT__"
# 		# println("\n\n\n\n\n****** PRINTING OUTPUT ****** \n\n\n\n")
# 		print(output)
# 	else
# 		# println("\n\n\n\n\n****** WRITING OUTPUT TO $outfile ****** \n\n\n\n")
# 		open(outfile, "w") do f
# 			write(f,output)
# 		end
# 	end
# end


########
# MAIN #
########

graph_folder = "/Users/felicedeluca/Downloads/e/graphs"
layout_folder = "/Users/felicedeluca/Downloads/e/layouts"

graphs = filter(r".csv$", readdir(graph_folder))
layouts = filter(r".csv$", readdir(layout_folder))


output = ""

for g_file in graphs

	l_file = replace(g_file, "_graph.csv" => "_layout.csv")

	g_name = strip_csv_extension(strip_dir_name(g_file))
	l_name = strip_csv_extension(strip_dir_name(l_file))

	full_graph_path = "$graph_folder/$g_file"
	full_layout_path = "$layout_folder/$l_file"

	g_orig = load_light_graph(full_graph_path, GRAPH_DIR="")

	g = copy(g_orig)
	l = load_layout(full_layout_path)

	tol=2

	try
		result = purchase(g,l,TOLERANCE=tol)

		# 			if result.score == -1
		# 				println("Error: Could not calculate score for layout $l_file")
		# 				continue
		# 			end

		output = extend_output(g_name, l_name, tol, result, output, false)
	catch
		output = "$(output)$g_name,$l_name,$tol,ERROR\n"
	end

end

print(output)
