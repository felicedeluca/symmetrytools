L = "/Users/hapless/graph-symmetries/"
l = load_layout("$L/ug_11/ug_11_layout98.csv")


function speedy_stress(g_no, l_no)
	g = load_light_graph("ug_$(g_no)")
	l = load_layout("/Users/hapless/graph-symmetries/layouts/ug_$(g_no)/ug_$(g_no)_layout$(l_no).csv")
	minimized_stress(g,l)
end

