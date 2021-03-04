# purchase_metric.jl
# 
# Script to calculate Purchase metric for graph layouts
# Eric Welch, March 2017
#
# TODO
# Decide what to do about config file tolerance and requirement that one be provided


include("../purchase.jl")

G="."
L="."

USAGE = "run_purchase.jl [-v] [-c config_file] [-t tolerance graph_file layout_files...]"

function update()
	include("run_purchase.jl")
end

FLAGS   = Dict{Char,String}(
	'v' => "verbose"
)

OPTIONS = Dict(
	't' => ["tolerance", Float64]
	'c' => ["config", String]
)

function parse_args(ARGS)
	flags = Array{String,1}()
	options = Dict{String, Any}()
	raw_args = Array{String, 1}()
	parsing_flags_and_options = true
	skip = false

	for (i,arg) in enumerate(ARGS)
		if skip
			skip = false
			continue
		end
		if arg[1] == '-'
			if (f = get(FLAGS, arg[2], nothing)) != nothing
				if !parsing_flags_and_options
					println("  Warning: flags should not be interspersed with regular arguments")
				end
				push!(flags, f)
			elseif (o_desc = get(OPTIONS, arg[2], nothing)) != nothing && i < length(ARGS)
				if !parsing_flags_and_options
					println("  Warning: options should not be interspersed with regular arguments")
				end
				opt_name = o_desc[1]
				opt_type = o_desc[2]
				opt_val = ARGS[i+1]
				if opt_type <: Number 
					opt_val = parse(opt_type, opt_val)
				end
				options[opt_name] = opt_val
				skip = true
			else
				println("    Unknown flag or option $(arg), skipping.")
			end
		else
			parsing_flags_and_options = false
			push!(raw_args, arg)
		end
	end

	return flags, options, raw_args
end


function get_tolerance(options)
	if get(options, "tolerance", nothing) == nothing
		println("Fatal error: no tolerance specified")
		exit(1)
	end
	options["tolerance"]
end

########
# MAIN #
########

flags, options, raw_args = parse_args(ARGS)
# println("Flags: $flags\nOptions: $options\nRaw arguments: $raw_args")  

tolerance = get_tolerance(options)
config = get(options, "config", nothing)
if config == nothing
	graphs  = [ raw_args[1] ]
	layouts = [raw_args[2:end]]
	tolerances = [ tolerance]
else
	graphs, layouts, tolerances = process_config(config)
end
verbose = "verbose" in flags

println("tol: $tolerance\nverbose: $verbose")
