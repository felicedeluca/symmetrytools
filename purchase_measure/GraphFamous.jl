function make_k4()
	create_light_graph([1 2; 1 3 ; 1 4 ; 2 3 ; 2 4 ; 3 4 ])
end

function k(n::Int)
	ne = convert(Int64,n*(n-1)/2)
	es = convert(Array{Int64,2},zeros(ne,2))
	c = 1
	for i in 1:n, j in i+1:n
		es[c,:] = [i j]
		c += 1
	end
	create_light_graph(es)
end

