export BNFNode, Sequence, Alternatives,  NonTerminal, CharacterLiteral
export Constructor, StringCollector
export BNFRef, @BNFRef, recognize, logReductions, loggingReductions
export BNFGrammar, DerivationRule, @DerivationRule

abstract type BNFNode end

if !isdefined(@__MODULE__, Symbol("@bnfnode"))
    macro bnfnode(e)
        e
    end
end


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


@bnfnode struct Sequence <: BNFNode
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


@bnfnode struct Alternatives <: BNFNode
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


@bnfnode struct CharacterLiteral <: BNFNode
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


@bnfnode struct Constructor <: BNFNode
    node::BNFNode
    constructor
end

logReductions = false

function loggingReductions(f, log=true)
    global logReductions
    previous = logReductions
    try
        logReductions = true
        f()
    finally
        logReductions = previous
    end
end

function recognize(n::Constructor, input::String, index::Int, finish::Int)
    v, i = recognize(n.node, input, index, finish)
    if i == index
        return v, i
    end
    v2 = n.constructor(v)
    if logReductions
        @info "$(n.constructor) reduced $(typeof(v)) $v to $(typeof(v2)) $v2"
    end
    return v2, i
end


@bnfnode struct Terminal <: BNFNode
    predicate
end


struct BNFGrammar
    name::Symbol
    derivations # ::Dict{String, DerivationRule}

    BNFGrammar(name) = new(name,
                           # Dict{String, DerivationRule}()
                           Dict())
end

function Base.getindex(grammar::BNFGrammar, nonterminal)
    grammar.derivations[nonterminal]
end

@bnfnode struct DerivationRule <: BNFNode
    grammar::BNFGrammar
    name::String
    lhs::BNFNode

    function DerivationRule(grammar, name, lhs)
        p = new(grammar, name, lhs)
        add_derivation(p)
        p
    end
end

function recognize(n::DerivationRule, input::String, index::Int, finish::Int)
    recognize(n.lhs, input, index, finish)
end

function add_derivation(p::DerivationRule)
    add_derivation(p.grammar, p)
end

function add_derivation(grammar::BNFGrammar, derivation::DerivationRule)
    if haskey(grammar.derivations, derivation.name)
        throw(ErrorException(
            "The nonterminal $(derivation.name) is already defined in BNFGrammar $(grammar.name)."))
    end
    grammar.derivations[derivation.name] = derivation
end

# ????? Maybe we should merge DerivationRule and BNFRef, but it is
# really convenient for DerivationRules to automatically add
# themselves to their grammar.

# Provides fgr deferred name lookup
@bnfnode struct BNFRef <:BNFNode
    grammar::BNFGrammar
    name::String
end

function recognize(n::BNFRef, input::String, index::Int, finish::Int)
    recognize(n.grammar[n.name].lhs, input, index, finish)
end


@bnfnode struct StringCollector <: BNFNode
    node::BNFNode
end

"""
# Why is this 0?

SUBSTRING_SIZE = let
    alpha = *((('a':'z'))...)
    @allocated SubString(alpha, 3, 20)
end

# I was hoping to establish a threshhold to etermine if String or
# SubString was cheaper
"""

function recognize(n::StringCollector, input::String, index::Int, finish::Int)
    start = index
    v, i = recognize(n.node, input, index, finish)
    if i == index
        return v, i
    end
    return SubString(input, start, i - 1), i
end
