export ParseFailure, Parser, recognize1, DEBUG_BNFNODES

"""
    DEBUG_BNFNODES

DEBUG_BNFNODES is a list of the node uid's of nodes that should be
`@info` logged when they match the current input at the specified
index.
"""
DEBUG_BNFNODES = []

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
    call_counter::Int
    recognize1_cache::Dict
    pending_parse_token
    # Try to give the user a hint of where the parse is failing:
    parse_failures::Set{ParseFailure}

    Parser() = new(1, Dict(), gensym(), Set{ParseFailure}([]))
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
    parse(n::BNFNode, input::AbstractString; index = firstindex(input), finish = lastindex(input), parser::Parser = Parser(), context = nothing)

`parse` is the preferred entry point for invoking the parser.  This is
where all of the argument defaulting happens.

`parse` returns two values: the result of the parse (or nothing if
unsuccessful) and the `Parser` object that was used for parsing.
"""
function parse(n::BNFNode, input::AbstractString;
               index = firstindex(input), finish = lastindex(input), 
               parser::Parser = Parser(),
               context = nothing)
    matched, v, i = recognize1(parser, n, input, index, finish, context)
    if matched
        return v, parser
    else
        return nothing, parser
    end
end

"""
    recognize1(n::BNFNode, input::AbstractString; parser = Parser(), index = 1, finish = lastindex(input), context = nothing)
    recognize1(p::Parser, n::BNFNode, input::AbstractString; index = 1, finish = lastindex(input), context = nothing)

`recognize` is a common intermediate point used by `recognize` in the
parsing process to perform logging.
"""
recognize1(n::BNFNode, input::AbstractString;
           parser = Parser(), index = firstindex(input), finish = lastindex(input),
           context = nothing) =
               recognize1(parser, n, input, index, finish, context)

function recognize1(p::Parser, n::BNFNode, input::AbstractString,
                    index::Int, finish::Int, context)
    dbg = n.uid in DEBUG_BNFNODES
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

