function gold_html(name, g, layouts, ss, idxs=1:size(layouts,1))
	open("$(name).html", "w") do f
		write(f,"<html>\n")
		write(f,"\t<head>\n")
		write(f,"\t\t<title>$(name)</title>\n")
		write(f,"\t\t<style>\n")
		write(f,"\t\t\tspan { padding: 0 10px 0 0 ; }\n")
		write(f,"\t\t</style>\n")
		write(f,"\t</head>\n\t<body>\n")
		write(f,"\t\t<h1>$(name)</h1>\n")
		write(f,"\t\t<table>\n")
		for idx in idxs
			render_layout("$(name)_lo$idx", g, layouts[idx])
			write(f,"\n\t\t\t<tr>\n")
			write(f,"\t\t\t\t<td><img width='200' src='$(name)_lo$(idx).svg'/></td>\n")
			write(f,"\t\t\t\t<td><p><span class='layout_id'>layout $(idx)</span></td>\n")
			write(f,"\t\t\t\t<td><span class='stress'>stress=$(ss[idx])</span></td>\n")
			write(f,"\t\t\t</tr>\n")
		end
		write(f,"\t\t</table>")
		write(f,"\t</body>\n</html>")
	end
end
