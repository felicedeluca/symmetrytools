using GraphPlot
using Compose
# using Graphs

#############################
# for calculating crossings #
#############################

function create_segments(g, loc_x, loc_y)
	adj_mtx = Graphs.adjacency_matrix(g)
	segments = Array{LineSeg, 1}()
	for i = 1:size(adj_mtx,1)
		for j = i+1:size(adj_mtx,2)
			if adj_mtx[i,j]
				x0, y0 = loc_x[i], loc_y[i]
				x1, y1 = loc_x[j], loc_y[j]
				push!(segments,LineSeg(x0, y0, x1, y1))
			end
		end
	end
	segments
end

function create_segments(g, layout)
	create_segments(g, layout[1], layout[2])
end

function new_vertex!(g; verbose=false)
	n = size(g.vertices,1)
	n_test = size(g.fadjlist, 1)
	verbose && println("New vertex: going to have $(n+1) vertices now")
	if n_test != n
		println("WARNING: adjacency list has $n_test entries while graph has $n vertices!")
	end
	# n = size(g.fadjlist, 1)
	g.vertices = 1:n+1
	push!(g.fadjlist, Array{Int64,1}())
end

function new_edge!(g::LightGraphs.Graph, v1::Int, v2::Int)
	adjl = g.fadjlist
	push!(adjl[v1], v2)
	push!(adjl[v2], v1)
	g.ne += 1
end

function remove_edge!(g::LightGraphs.Graph, v1::Int, v2::Int)
	remove_edge!(g, [v1 v2])
end

function remove_edge!(g::LightGraphs.Graph, edge) # as [i j]
	adj_list = g.fadjlist
	i = edge[1]
	j = edge[2]
	adj_list[i] = without(adj_list[i], j)
	adj_list[j] = without(adj_list[j], i)
	g.fadjlist = adj_list
	g.ne -= 1
end



###################
# building graphs #
###################

# for manual construction 
function flatten(edges::Array{Array{Int,1},1})
	vs = Array{Int64, 1}()
	for e in edges
		for v in e
			if !(v in vs)
				push!(vs, v)
			end
		end
	end
	vs
end

# for reading from CSV
function flatten(edges::Array{Int,2})
	vs = Array{Int64, 1}()
	for i in 1:size(edges,1)
		e = edges[i,:]
		for v in e
			if !(v in vs)
				push!(vs, v)
			end
		end
	end
	vs
end


function create_graph(es::Array{Array{Int64,1},1}; verbose=false)
	vs = sort(flatten(es))
	vertices = construct_vertices(vs)
	adj_mtx = construct_adj_mtx(vs, es)
	edges = construct_edges(vertices, adj_mtx)
	g = graph(vertices, edges, is_directed=false)
	verbose && println("New graph has $(g.ne) edges, while size of edges is $(size(edges,1))")
	verbose && println("Note that number of edges as specified by adjacency list is $(sum(map(x->size(x,1), g.fadjlist)))")
end

# assumes vertices (vs) are 1:n
# old code, from when we used Graphs library
function construct_adj_mtx(vs, es)
	adj_mtx = falses(size(vs,1), size(vs, 1))
	for e in es
		adj_mtx[e[1], e[2]] = true
		adj_mtx[e[2], e[1]] = true
	end
	adj_mtx
end

function construct_adj_mtx(g::LightGraphs.Graph)
	adj_list = g.fadjlist
	n = size(adj_list,1)
	adj_mtx = falses(n,n)
	for i in 1:n
		for j in 1:n
			if j in adj_list[i]
				adj_mtx[i,j] = true
				adj_mtx[j,i] = true
			end
		end
	end
	adj_mtx
end


function construct_vertices(vs::Array{Int64,1})
	vertices = Array{ExVertex,1}()
	for v in vs
		vx = ExVertex(v, "")
		vx.attributes["type"] = "normal"
		push!(vertices, vx)
	end
	vertices
end

# for reading from CSV
function create_graph(es::Array{Int64,2})
	es = [es[i,:] for i in 1:size(es,1)]
	create_graph(es)
end

function create_light_graph(es::Array{Int64,2})
	es = [es[i,:] for i in 1:size(es,1)]
	create_light_graph(es)
end

function construct_edges(vertices, adj_mtx)
	edges = Array{Edge{ExVertex},1}()
	idx = 1
	for vi in 1:size(vertices,1)
		v1 = vertices[vi]
		for vj in vi:size(vertices,1)
			v2 = vertices[vj]
			if adj_mtx[v1.index, v2.index]
				push!(edges, Edge{ExVertex}(idx, v1, v2))
				idx += 1
			end
		end
	end
	edges
end



################
# Light Graphs #
################

function create_light_graph(es::Array{Array{Int64, 1}, 1}; debug=false)
	debug && enter("create_light_graph")
	vs = sort(flatten(es))
	g = LightGraphs.Graph(size(vs,1))
	for edge in es
		LightGraphs.add_edge!(g, edge[1], edge[2])
	end
	debug && println("created g, with typeof $(typeof(g))")
	g
end

function construct_distance_matrix(g::LightGraphs.Graph)
	n = size(g.fadjlist,1)
	d = Array{Float64,2}(n,0)
	for i = 1:n
		d = hcat(d, LightGraphs.dijkstra_shortest_paths(g,i).dists)
	end
	d
end

function segments_to_light_graph_and_layout(segs::Array{LineSeg,1})
	g = LightGraphs.Graph(2*size(segs,1))
	xs = Array{Float64,1}()
	ys = Array{Float64,1}()
	for (i,seg) in enumerate(segs)
		LightGraphs.add_edge!(g, 2*(i-1)+1, 2*(i-1)+2)	
		push!(xs, segs[i].x0)
		push!(ys, segs[i].y0)
		push!(xs, segs[i].x1)
		push!(ys, segs[i].y1)
	end
	layout = (xs,ys)
	(g, layout)
end


###########
# layouts #
###########


function assign_layout(g, layout)
	for v in g.vertices
		i = v.index
		v.attributes["x"] = layout[1][i]
		v.attributes["y"] = layout[2][i]
	end
end

function extract_layout(g)
	n = size(g.vertices,1)
	loc_x = Array{Float64,1}(n)
	loc_y = Array{Float64,1}(n)
	for vx in g.vertices
		idx = vx.index
		loc_x[idx] = vx.attributes["x"]
		loc_y[idx] = vx.attributes["y"]
	end
	loc_x, loc_y
end




# Connected Components #

function connected_components(edge_list; debug=false)
	debug && enter("connected_components")
	debug && println("edge_list: $edge_list")
	safe = map(copy, edge_list)
	temp = Array{Array{Int64,1},1}()
	out  = Array{Array{Int64,1},1}()
	for edge in safe
		found_a_place = false
		for sg in temp
			if edge[1] in sg || edge[2] in sg
				append!(sg, edge)
				found_a_place = true
				break
			end
		end
		if !found_a_place
			push!(temp, edge)
		end
	end
	for temp_sg in temp
		found_a_place = false
		for sg in out
			for v in temp_sg
				if v in sg
					append!(sg, temp_sg)
					found_a_place = true
					break
				end
			end
			if found_a_place
				break
			end
		end
		if !found_a_place
			push!(out, temp_sg)
		end
	end
	for sg in out
		for i in size(sg,1):-1:1
			if sg[i] in sg[1:i-1]
				deleteat!(sg,i)
			end
		end
	end
	out
end

function get_raw_points(layout, vertices; debug=false)
	debug && enter("get_raw_points")
	pts = Array{Array{Float64,1},1}()
	for v in vertices
		push!(pts, [layout[1][v],layout[2][v]])
	end
	pts
end
