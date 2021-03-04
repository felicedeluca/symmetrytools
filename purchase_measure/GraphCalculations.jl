	
function enter(func)
	println("\n-- Entering $func --")
end

function all_done(func)
	println("-- Exiting $func --\n")
end

function generate_n_layouts(g, n=100; alg="spring", debug=false)
	debug && enter("generate_n_layouts")
	if alg != "spring"
		println("Sorry, only spring layout is currently available")
	end
	debug && all_done("generate_n_layouts")
	[ spring_layout_undistorted(g) for i in 1:n ]
end

function ints(ary)
	map(x -> convert(Int, floor(x)), ary)
end
