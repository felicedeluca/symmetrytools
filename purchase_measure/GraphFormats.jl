function save_to_klapaukh(name, g, layout)
	out = render_preamble()
	out = "$out $(to_klapaukh_main(g, layout)) -->\n"
	# later: actual SVG
	out = "$out </svg>"
	open("$(name).svg", "w") do f
		write(f, out)
	end
end

# TODO: Figure out if this matters
# TODO: Evaluate effects of scaling
function render_preamble(w=800,h=800)
out = """
<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN"
"http://www.w3.org/TR/2001/REC-SVG-2010904/DTD/svg10.dtd">
<svg xmlns="http://www.w3.org/2000/svg"
xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve"
width="$(w)"
height="$(h)"
viewBox = "0 0 $(w) $(h)"
zoomAndPan="disable">
<!--
elapsed: 1
filename: test.xml
width: 800
height: 800
iterations: 1
forcemode: 1
ke: 0
kh: 0
kl: 0
kw: 0
mass: 0
time: 0
coefficientOfRestitution: 0
mus: 0
muk: 0
kg: 0
wellMass: 0
edgeCharge: 0
finalKineticEnergy: 0
nodeWidth: 0
nodeHeight: 0
nodeCharge: 0
-
Start Graph:
"""
end

function to_klapaukh_main(g, layout)
	out = "$(size(layout[1],1))\n"
	for i in 1:size(adj_list,1)
		out = "$out $(layouts[1][1][i]) $(layouts[1][2][i])"
		for j in 1:size(adj_list,1)
			if j in adj_list[i]
				out = "$out 1"
			else
				out = "$out 0"
			end
		end
		out = "$(out)\n"
	end
	out
end
