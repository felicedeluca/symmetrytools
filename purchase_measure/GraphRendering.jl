function render_layout(
	name::String, 
	g::LightGraphs.Graph, 
	layout::Tuple{Array{Float64,1},Array{Float64,1}};
	typ="svg", 
	x_dim=6inch, 
	y_dim=6inch, 
	nodesize=0.01, 
	nodefillc=colorant"turquoise", 
	edgestrokec=colorant"black",
	nodelabel=g.vertices) 
	if typ == "png"
		draw(
			PNG("$(name).$(typ)", x_dim, y_dim), 
			gplot(g, layout[1], layout[2], 
				nodelabel=nodelabel,
				nodesize=nodesize, 
				edgestrokec=edgestrokec, 
				nodefillc=nodefillc))
	else
		draw(
			SVG("$(name).$(typ)", x_dim, y_dim), 
			gplot(g, layout[1], layout[2], 
				nodelabel=nodelabel,
				nodesize=nodesize, 
				edgestrokec=edgestrokec,
				nodefillc=nodefillc))
	end
end

function render_layouts(filebase, g, layouts, rng=1:size(layouts,1); typ="svg", x_dim=6inch, y_dim=6inch)
	for i in rng
		render_layout("$(filebase)_layout$(i)", g, layouts[i], typ=typ, x_dim=x_dim, y_dim=y_dim)
	end
end


function quick_render(csv_file, outfile; typ="svg")
	g = load_graph(csv_file)
	layout = spring_layout_undistorted(g)
	render_layout(outfile, g, layout, typ=typ)
end


function render_layout_and_axes(filename, g, l, sym_axes::Array{StdLine,1}; typ="svg")
	n = size(g.fadjlist,1)
	ne = g.ne
	ax_g, ax_l = segments_to_light_graph_and_layout(map(chop_line, sym_axes))
	g_ = copy(g)
	append!(g_.fadjlist, ax_g.fadjlist)
	ax_n = size(ax_g.fadjlist,1)
	ax_ne= ax_g.ne
	g_.vertices = 1:(n+ax_n)
	g_.ne = ne + ax_ne
	l_ = map(copy,l)
	append!(l_[1], ax_l[1])
	append!(l_[2], ax_l[2])
	for sublist in g_.fadjlist[n+1:end]
		for (i, v) in enumerate(sublist)
			sublist[i] = v+n
		end
	end
	edgestrokec = append!([colorant"black" for i in 1:ne], [colorant"yellow" for j in 1:ax_ne])
	nodefillc = append!([colorant"turquoise" for i in 1:n], [RGBA(0.1,0.1,0.1,0.1) for j in 1:ax_n])
	nodesize = append!([1.0 for i in 1:n], [0.01 for i in 1:ax_n])
	render_layout(filename, g_, l_, typ=typ,nodefillc=nodefillc, edgestrokec=edgestrokec, nodesize=nodesize)
end

function render_layout_and_axes(filename, g, l; typ::String="svg", angle_tol=1, d_tol_ratio=0.1)
	sym_axes = construct_axis_set(g,l, angle_tol=angle_tol, d_tol_ratio=d_tol_ratio)
end
