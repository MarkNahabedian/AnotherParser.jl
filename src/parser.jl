export ParseFailure, Parser, recognize1


"""

A `ParseFailure` is noted in the `parse_failures` filed of a
[`Parser`](@ref) for each syntax mismatch.  Its fields are:

* `failing_index`: the index into input where the mismatch occurred.
* `failing_node`: The node that the input did not match.
* `failing_reason`: a String explaining the failure.
"""
struct ParseFailure
    failing_index::Int    # the position in input that failed to match failing_node
    failing_node::BNFNode
    failing_reason::AbstractString
end

function Base.string(pf::ParseFailure)
    join(["Parse failure",
          "@$(pf.failing_index)",
          pf.failing_node,     # path_to_node(pf.failing_node),
          pf.failing_reason],
         " ")
end

mutable struct Parser
    # debug_bnfnodes is a list of the node uid's of nodes that should
    # be `@info` logged when they match the current input at the
    # specified index.
    debug_bnfnodes::Vector{<:AbstractString}
    call_counter::Int
    recognize1_cache::Dict
    pending_parse_token
    # Try to give the user a hint of where the parse is failing:
    parse_failures::Set{ParseFailure}

    Parser() =
        new(Vector{String}(), 1, Dict(), gensym(), Set{ParseFailure}([]))

    Parser(debug_bnfnodes::Vector{<:AbstractString}) =
        new(debug_bnfnodes, 1, Dict(), gensym(), Set{ParseFailure}([]))
end

function parse_failed_at(parser::Parser, failing_index::Int, failing_node::BNFNode,
                         reason::AbstractString)
    parse_failed_at(parser, ParseFailure(failing_index, failing_node, reason))
end

function parse_failed_at(parser::Parser, pf::ParseFailure)
    best_so_far = maximum(pf -> pf.failing_index,
                          parser.parse_failures;
                          init = 1)
    if pf.failing_index < best_so_far
        # Ignore.  We've already done better.
        return
    end
    if pf.failing_index == best_so_far
        push!(parser.parse_failures, pf)
    else
        empty!(parser.parse_failures)
        push!(parser.parse_failures, pf)
    end
    nothing
end


"""
    parse(n::BNFNode, input::AbstractString; index = firstindex(input), finish = lastindex(input), parser::Parser = Parser(), context = nothing, report_file::AbstractString="")

`parse` is the preferred entry point for invoking the parser.  This is
where all of the argument defaulting happens.

Do not confuse `parse` with `Base.parse`.

`parse` returns four values: a boolean indicating if the parse was
successful; the value that was read; the next index into the input;
and the `Parserr` object.

The `parse_failures` field of that `Parser` has a `Set` of
[`ParseFailure`](@ref) objects which expose unsuccessful paths through
the node tree.

DEBUGGING:

If report_file is provided it should name an HTML file to be written.
It will present the log of node invocations and results.  You can use
the `parser` keyarg to provide a [`Parser`](@reg) that has been told
which nodes should be logged.  You can use
[`note_nodes_to_debug`](@ref) to tell that parser which nodes to log
based on a predicate function.  It's probably best to just log all
nodes.  The function [`should_enable_debug_logging_for`](@ref) is
provided to not include some of the noisier nodes from logging.
"""
function parse(node::BNFNode, input::AbstractString;
               index = firstindex(input), finish = lastindex(input), 
               parser::Parser = Parser(), context = nothing,
               report_file::AbstractString="")
    if report_file == ""
        matched, v, i = recognize1(parser, node, input, index, finish, context)
        return matched, v, i, parser
    else
        let
            logger = TestLogger()
            with_logger(logger) do
                matched, v, i = recognize1(parser, node, input, index, finish, context)
            end
            process_and_report_parser_debug_log(node, input, logger, report_file)
            return matched, v, i, parser
        end
    end
end


"""
    recognize1(n::BNFNode, input::AbstractString; parser = Parser(), index = 1, finish = lastindex(input), context = nothing)
    recognize1(p::Parser, n::BNFNode, input::AbstractString; index = 1, finish = lastindex(input), context = nothing)

`recognize1` is a common intermediate point used by `recognize` in the
parsing process to perform logging.

Returns three values: whether the node matched the input, the parsed
value represented by the matched input, and the next index into
`input`.
"""
recognize1(n::BNFNode, input::AbstractString;
           parser = Parser(), index = firstindex(input), finish = lastindex(input),
           context = nothing) =
               recognize1(parser, n, input, index, finish, context)

function recognize1(p::Parser, n::BNFNode, input::AbstractString,
                    index::Int, finish::Int, context)
    dbg = n.uid in p.debug_bnfnodes
    p.call_counter += 1
    call_counter = p.call_counter
    node = pretty(n)
    if dbg
        @info "recognize1" call_counter node index "trying"
    end
    key = (n.uid, input, index)
    # We avoid infinite recursion and cache intermediate results:
    if haskey(p.recognize1_cache, key)
        if p.recognize1_cache[key] == p.pending_parse_token
            @info "recognize1" call_counter node index infinite_recursion=true
            error("infinite recursion duriing parse: $key")
        else
            result = p.recognize1_cache[key]
            if dbg
                @info "recognize1" call_counter node index = result[3] cacheed_result = result
            end
            return result
        end
    end
    p.recognize1_cache[key] = p.pending_parse_token
    matched, v, i = recognize(p, n, input, index, finish, context)
    if matched == true && i != index
        p.recognize1_cache[key] = (matched, v, i)
    end
    if dbg
        @info "recognize1" call_counter node index "returning" matched v i
    end
    p.recognize1_cache[key] = (matched, v, i)
    return matched, v, i
end

