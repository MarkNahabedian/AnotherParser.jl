export Parser, DEBUG_BNFNODES

DEBUG_BNFNODES = []

struct Parser
    recognize1_history::Dict

    Parser() = new(Dict())
end

function recognize1(p::Parser, n, input, index, finish, context)
    dbg = n.uid in DEBUG_BNFNODES
    key = (n.uid, input, index)
    if haskey(p.recognize1_history, key)
        if dbg
            @info "recognize1 has already seen" n.uid index
        end
        return false, nothing, index
    end
    matched, v, i = recognize(p, n, input, index, finish, context)
    if matched == true && i == index
        p.recognize1_history[key] = true
    end
    if dbg
        @info "recognize1" n.uid index "returning" matched v i
    end
    return matched, v, i
end
