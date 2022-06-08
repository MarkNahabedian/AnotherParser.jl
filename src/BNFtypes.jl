export BNFNode, Empty, Sequence, Alternatives,  NonTerminal,
    CharacterLiteral, StringLiteral
export Constructor, StringCollector
export BNFRef, recognize, logReductions, loggingReductions
export BNFGrammar, DerivationRule
export AllGrammars

using NahaJuliaLib

trace_recognize = false

"""
    BNFNode
Abstract supertype for all structs that we use to implement a grammar.
"""
abstract type BNFNode end


"""
    recognize(::BNFNode, input::String; index, finish)
Attempt to parse `input` as the specified `BNFNode`.
Return three values: whether the node matched the input,
the value represented by the matched input,
and the next index into input.

"""
@trace trace_recognize recognize(n::BNFNode, input::String; index=1, finish=length(input) + 1) =
    recognize(n, input, index, finish)


"""
    Empty()
Succeed while matching nothing.
"""
@bnfnode struct Empty <: BNFNode
end

@trace trace_recognize function recognize(n::Empty, input::String, index::Int, finish::Int)
    return true, nothing, index
end


"""
    Sequence(nodes...)
Successively match each of nodes in turn.
"""
@bnfnode struct Sequence <: BNFNode
    elements::Tuple{Vararg{<:BNFNode}}

    Sequence(elements...) = new(elements)
    Sequence(elements::Tuple) = new(elements)
end

@trace trace_recognize function recognize(n::Sequence, input::String, index::Int, finish::Int)
    collected = []
    in = index
    for n1 in n.elements
        matched, v, i = recognize(n1, input, in, finish)
        if !matched
            return false, nothing, index
        end
        in = i
        push!(collected, v)
    end
    return true, collected, in
end


"""
    Alternatives(nodes...)
Matches any one element of `nodes`.
"""
@bnfnode struct Alternatives <: BNFNode
    alternatives::Tuple{Vararg{<:BNFNode}}

    Alternatives(alternatives...) = new(alternatives)
    Alternatives(alternatives::Tuple) = new(alternatives)
end

@trace trace_recognize function recognize(n::Alternatives, input::String, index::Int, finish::Int)
    bestv= nothing
    # If one of the alternatives is Empty, we want our match to
    # succeed.
    besti = index - 1
    for n1 in n.alternatives
        matched, v, i = recognize(n1, input, index, finish)
        if matched && i > besti
            bestv = v
            besti = i
        end
    end
    if besti < index
        return false, nothing, index
    end
    return true, bestv, besti
end


"""
    CharacterLiteral(c)
Matches the single character `c`.
"""
@bnfnode struct CharacterLiteral <: BNFNode
    character::Char
end

@trace trace_recognize function recognize(n::CharacterLiteral, input::String, index::Int, finish::Int)
    if index > min(finish, length(input))
        return false, nothing, index
    end
    c = input[index]
    if c == n.character
        return true, c, index + 1
    end
    return false, nothing, index
end


"""
    StringLiteral(str)
Matches the string `str`.
"""
@bnfnode struct StringLiteral <: BNFNode
    str::AbstractString
end

@trace trace_recognize function recognize(n::StringLiteral, input::String, index::Int, finish::Int)
    e = index + length(n.str) - 1
    if e > min(finish, length(input))
        return false, nothing, index
    end
    ss = SubString(input, index, e)
    if n.str == ss
        return true, ss, e + 1
    end
    return false, nothing, index
end



"""
    Constructor(node, constructor_function)
Apply `constructor_function` to rhe result of recognizing `node`
and return that as the result.
"""
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

@trace trace_recognize function recognize(n::Constructor, input::String, index::Int, finish::Int)
    matched, v, i = recognize(n.node, input, index, finish)
    if !matched
        return false, v, i
    end
    v2 = n.constructor(v)
    if logReductions
        @info "$(n.constructor) reduced $(typeof(v)) $v to $(typeof(v2)) $v2"
    end
    return true, v2, i
end


"""
    BNFGrammar
Represents a single grammar which can consist of a number of
`DerivationRule`s.
"""
struct BNFGrammar
    name::Symbol
    derivations # ::Dict{String, DerivationRule}

    function BNFGrammar(name::Symbol)
        g = new(name,
                # Dict{String, DerivationRule}()
                Dict())
        AllGrammars[g.name] = g
        g
    end
end

Base.haskey(grammar::BNFGrammar, rule::String) =
    haskey(grammar.derivations, rule)

Base.getindex(grammar::BNFGrammar, rule::String) =
    grammar.derivations[rule]


"""
A Dict of all defined grammars.
"""
AllGrammars = Dict{Symbol, BNFGrammar}()

function Base.getindex(grammar::BNFGrammar, nonterminal)
    grammar.derivations[nonterminal]
end


"""
    DerivationRule(grammar, rule_name, expression)
Implements a single production named `name` in the specified `grammar`.
One can include `expression` in other expressions using
`BNFRef(grammar, rule_name)`.
"""
@bnfnode struct DerivationRule <: BNFNode
    grammar_name::Symbol
    name::String
    lhs::BNFNode

    function DerivationRule(grammar::BNFGrammar, name, lhs)
        p = new(grammar.name, name, lhs)
        add_derivation(p)
        p
    end
    DerivationRule(grammar_name::Symbol, name, lhs) =
        DerivationRule(AllGrammars[grammar_name], name, lhs)
end

@njl_getprop DerivationRule

Base.getproperty(p::DerivationRule, ::Val{:grammar}) =
    return AllGrammars[p.grammar_name]

@trace trace_recognize function recognize(n::DerivationRule, input::String, index::Int, finish::Int)
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

"""
   BNFRef(grammar, name)
delegates to the "left hand side" of the `DerivationRule` named `name`
in `grammar`.
"""
@bnfnode struct BNFRef <:BNFNode
    grammar_name::Symbol
    name::String

    BNFRef(grammar_name::Symbol, name::String) =
        new(grammar_name, name)

    BNFRef(grammar::BNFGrammar, name::String) =
        BNFRef(grammar.name, name)
end

function lhs(n::BNFRef)
    AllGrammars[n.grammar_name][n.name].lhs
end

@trace trace_recognize function recognize(n::BNFRef, input::String, index::Int, finish::Int)
    recognize(lhs(n), input, index, finish)
end

"""
   StringCollector
StringCollector returns the entire substrring of the input that
@trace trace_recognize was recognized by its subexpression.
"""
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


@trace trace_recognize function recognize(n::StringCollector, input::String, index::Int, finish::Int)
    start = index
    matched, v, i = recognize(n.node, input, index, finish)
    if !matched
        return false, v, i
    end
    return true, SubString(input, start, i - 1), i
end

