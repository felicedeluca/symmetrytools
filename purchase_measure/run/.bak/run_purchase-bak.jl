# purchase_metric.jl
# 
# Script to calculate Purchase metric for graph layouts
# Eric Welch, March 2017

FLAGS   = Dict{Char,String}(
	'v' => "verbose"
)

OPTIONS = Dict(
	't' => ["threshold", Float64]
)

function parse_args(ARGS)
	flags = Array{String,1}()
	options = Dict{String, Any}()
	raw_args = Array{String, 1}()
	parsing_flags_and_options = true
	skip = false

	for (i,arg) in enumerate(ARGS)
		println("* Argument $i: $arg")
		if skip
			skip = false
			println("  This was a value for an option, skipping")
			continue
		end
		if arg[1] == '-'
			if (f = get(FLAGS, arg[2], nothing)) != nothing
				println("    Got flag $(f)")
				if !parsing_flags_and_options
					println("  Warning: flags should not be interspersed with regular arguments")
				end
				println("    Pushing $f to flags")
				push!(flags, f)
				println("  flags = $flags")
			elseif (o_desc = get(OPTIONS, arg[2], nothing)) != nothing && i < length(ARGS)
				println("    Got value $(ARGS[i+1]) for option $arg")
				if !parsing_flags_and_options
					println("  Warning: options should not be interspersed with regular arguments")
				end
				opt_name = o_desc[1]
				opt_type = o_desc[2]
				opt_val = ARGS[i+1]
				println("    Adding $opt_name=$opt_val to options")
				if opt_type <: Number 
					opt_val = parse(opt_type, opt_val)
				end
				options[opt_name] = opt_val
				println("    Options: $(options)")
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



########
# MAIN #
########

flags, options, raw_args = parse_args(ARGS)
println("Flags: $flags\nOptions: $options\nRaw arguments: $raw_args")  
