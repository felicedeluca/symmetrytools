USAGE = "run_purchase.jl [-h] [-v] [-c config_file] [-t tolerance] graph_file layout_files...]"

FLAGS   = Dict{Char,String}(
	'v' => "verbose",
	'h' => "help",
	'r' => "human readable output"
)

OPTIONS = Dict(
	't' => ["tolerance", Float64],
	'c' => ["config", String],
	'o' => ["output", String],
	'p' => ["preprocess", String]
)

function get_tolerance(options)
	if get(options, "tolerance", nothing) == nothing
		println("Fatal error: no tolerance specified")
		exit(1)
	end
	options["tolerance"]
end



function ls(dir)
	split(chomp(readstring(`ls $dir`)),'\n')
end


function process_config_file(config_file)
	cfg = Dict()
	lines = ""
	open(config_file) do f
		lines = readlines(f)
	end
	cfg["graphs"] = Array{String,1}()
	cfg["layouts"] = Dict{String, Array{String,1}}()
	lines = map(strip, lines)
	for line in lines
		if ismatch(r":", line)
			param_name = match(r"(.*):",line)[1]
			if param_name == "t"
				param_vals = get_float_params(line)
			else
				param_vals = get_string_params(line)
				if param_name == "o"
					param_vals = param_vals[1]
				end
			end
			cfg[param_name] = param_vals
		else
			graph = split(line, ' ')[1]
			layouts =  split(line, ' ')[2:end]
			out_layouts = []
			for (i,l_name) in enumerate(layouts)
				if ismatch(r"\*",l_name)	
					ldir = match(r"(.*)\*", l_name)[1]
					if get(cfg,"LDIR",nothing) != nothing
						LDIR = cfg["LDIR"][1]
						ldir = "$LDIR/$ldir"
					end
					out_layouts = vcat(out_layouts, map(x -> "$ldir/$x", ls(convert(String,ldir)))) # warning: if $ldir="" you'll have problems...
				else
					out_layouts = vcat(out_layouts, [l_name])	
				end
			end
			if get(cfg,"GDIR",nothing) != nothing
				GDIR = cfg["GDIR"][1]
				graph = "$GDIR/$graph"
			end
			push!(cfg["graphs"],graph)
			cfg["layouts"][graph] = out_layouts
		end
	end
	cfg
end

function dict_has_key(d,k)
	if get(d,k,false) == false
		return false
	end
	true
end

function merge_configs(file_cfg, cmdline_cfg)
	# println("in merge_configs")
	required = ["graphs", "layouts", "t"]
	optional = ["p", "o"]
	out_cfg = Dict{String,Any}(
		"p" => "None",
		"o" => "__STDOUT__"
	)

	for field in required
		if dict_has_key(file_cfg, field)
			out_cfg[field] = file_cfg[field]
		elseif dict_has_key(cmdline_cfg, field)
			out_cfg[field] = cmdline_cfg[field]
		else
			println("Fatal error: field $field not specified in config file or on command line")
			exit(1)
		end
	end

	for field in optional
		if dict_has_key(file_cfg, field)
			println("optional field $field has value $(file_cfg[field]) in config file")
			out_cfg[field] = file_cfg[field]
		elseif dict_has_key(cmdline_cfg, field)
			println("optional field $field has value $(file_cfg[field]) in command file")
			out_cfg[field] = cmdline_cfg[field]
		end
	end
	out_cfg
end

# TODO: absorb into parse_args
function process_options(flags, options, raw_args)

	config_file = get(options, "config", nothing)
	if config_file == nothing
		if length(raw_args) < 2
			println("Error: if no config file is specified, then graph and layouts must be specified manually")
			println(USAGE)
			exit(1)
		end
		file_cfg = Dict()
	else
		file_cfg = process_config_file(config_file)
	end

	cmdline_cfg = Dict()
	if length(raw_args) > 0
		cmdline_cfg["graphs"]  = [ raw_args[1] ]
		if length(raw_args) > 1
			cmdline_cfg["layouts"] = [ raw_args[2:end] ]
		end
	end
	cmdline_cfg["t"] = [get(options, "tolerance", nothing)]
	cmdline_cfg["o"] = get(options, "output", nothing)
	cmdline_cfg["p"]  = get(options, "preprocess", nothing)
	for key in ["t","o","p"]
		if cmdline_cfg[key] == nothing
			delete!(cmdline_cfg,key)
		end
	end

	cfg = merge_configs(file_cfg, cmdline_cfg)
	verbose = "verbose" in flags
	readable = "human readable output" in flags
	
	cfg["graphs"], cfg["layouts"], cfg["t"], cfg["p"], cfg["o"], verbose, readable

end



function parse_float_array(ary)
	map(x->parse(Float64,x), ary)
end

function get_float_params(line)
	parse_float_array(split(strip(line),' ')[2:end])
end

function get_string_params(line)
	split(strip(line), ' ')[2:end]
end
