export BNFNode, Sequence, Alternatives, Constructor,  NonTerminal, CharacterLiteral
export BNFRules, BNFRef, recognize

abstract type BNFNode end

struct Sequence <: BNFNode
    elements::Tuple{Vararg{<:BNFNode}}

    function Sequence(elements...)
        new(elements)
    end
end

function recognize(n::Sequence, input::String, index::Int)
    collected = []
    in = index
    for n1 in n.elements
        v, i = recognize(n1, input, in)
        if v == nothing
            break
        end
        in = i
        push!(collected, v)
    end
    if length(collected) == length(n.elements)
        return collected, in
    end
    return nothing, index
end


struct Alternatives <: BNFNode
    alternatives::Tuple{Vararg{<:BNFNode}}

    function Alternatives(alternatives...)
        new(alternatives)
    end
end

function recognize(n::Alternatives, input::String, index::Int)
    bestv= nothing
    besti = index
    for n1 in n.alternatives
        v, i = recognize(n1, input, index)
        if i > besti
            bestv = v
            besti = i
        end
    end
    return bestv, besti
end


struct CharacterLiteral <: BNFNode
    character::Char
end

function recognize(n::CharacterLiteral, input::String, index::Int)
    if index > length(input)
        return nothing,index
    end
    c = input[index]
    if c == n.character
        return c, index + 1
    end
    return nothing, index
end


struct Constructor <: BNFNode
    node::BNFNode
    constructor
end

function recognize(n::Constructor, input::String, index::Int)
    v, i = recognize(n.node, input,index)
    if v == nothing
        return v, i
    end
    return n.constructor(v...), i
end


struct Terminal <: BNFNode
    predicate
end

BNFRules = Dict{String, BNFNode}

# Provides fgr deferred namelookup
struct BNFRef <:BNFNode
    rules::BNFRules
    name::String
end

function recognize(n::BNFRef, input::String, index::Int)
    recognize(n.rules[n.name], input, index)
end


#=
struct NonTerminal <: BNFNode
    name::Symbol
    bnf::BNFNode
end
=#

