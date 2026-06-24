export Parser, DEBUG_BNFNODES

"""
    DEBUG_BNFNODES

DEBUG_BNFNODES is a list of the node uid's of nodes that should be
`@info` logged when they match the current input at the specified
index.
"""
DEBUG_BNFNODES = []

mutable struct Parser
    call_counter::Int
    recognize1_cache::Dict
    pending_parse_token

    Parser() = new(1, Dict(), gensym())
end

function recognize1(p::Parser, n::BNFNode, input::AbstractString;
                    index = 1, finish = length(input), context = nothing)
    recognize1(p, n, input, index, finish, context)
end

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

