export BNFNode, Sequence, Alternatives, Constructor,  NonTerminal, CharacterLiteral
export BNFRules, BNFRef, recognize


abstract type BNFNode end


"""
    recognize(::BNFNode, input::String; index, finish)
Attempt to parse `input` as the specified `BNFNode`.
Return two values: the  value represented by the matched input,
and the next index into input.
If the returned index is equal to the initial index then the
input did not matchthe `BNFNode`.
"""
recognize(n::BNFNode, input::String; index=1, finish=length(input) + 1) =
    recognize(n, input, index, finish)


struct Sequence <: BNFNode
    elements::Tuple{Vararg{<:BNFNode}}

    function Sequence(elements...)
        new(elements)
    end
end

function recognize(n::Sequence, input::String, index::Int, finish::Int)
    collected = []
    in = index
    for n1 in n.elements
        v, i = recognize(n1, input, in, finish)
        if i == in
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

function recognize(n::Alternatives, input::String, index::Int, finish::Int)
    bestv= nothing
    besti = index
    for n1 in n.alternatives
        v, i = recognize(n1, input, index, finish)
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

function recognize(n::CharacterLiteral, input::String, index::Int, finish::Int)
    if index > length(input)
        return nothing, index
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

function recognize(n::Constructor, input::String, index::Int, finish::Int)
    v, i = recognize(n.node, input, index, finish)
    if i == index
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

function recognize(n::BNFRef, input::String, index::Int, finish::Int)
    recognize(n.rules[n.name], input, index, finish)
end

