
struct Parser
    recognize1_history::Dict

    Parser() = new(Dict())
end

function recognize1(p::Parser, n, input, index, finish, context)
    key = (n,input, index)
    if haskey(p.recognize1_history, key)
        return false, nothing, index
    end
    matched, v, i = recognize(p, n, input, index, finish, context)
    if matched == true && i == index
        p.recognize1_history[key] = true
    end
    return matched, v, i
end
