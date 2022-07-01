export BNFNode, EndOfInput, Empty, Sequence, Alternatives,  NonTerminal,
    CharacterLiteral, StringLiteral, RegexNode
export Constructor, StringCollector
export BNFRef, recognize, logReductions, loggingReductions
export BNFGrammar, DerivationRule
export AllGrammars
export ignore_context

using NahaJuliaLib

trace_recognize = false

"""
    BNFNode
Abstract supertype for all structs that we use to implement a grammar.
"""
abstract type BNFNode end


"""
    recognize(::BNFNode, input::AbstractString; index, finish)
Attempt to parse `input` as the specified `BNFNode`, starting at `index`.
Return three values: whether the node matched the input,
the parsed value represented by the matched input,
and the next index into `input`.
`finish` is the index into `input` of the last character to be considered.
The `context` argument is passed to constructor functions
(see `Constructor` and `DerivationRule`) but
is otherwise unused.
"""
@trace trace_recognize recognize(n::BNFNode, input::AbstractString;
                                 index=1, finish=lastindex(input),
                                 context=nothing) =
    recognize(n, input, index, finish, context)


# True if input[index] would get out of bounds error.
# in Julia, "1234"[4] is 4.  5 is out of bounds.
function exhausted(input::AbstractString, index::Int, finish::Int)
    result = (index > finish) || (index > lastindex(input))
    result
end


"""
    EndOfInput()
Succeed if input is exhausted.
"""
@bnfnode struct EndOfInput <: BNFNode
end

@trace trace_recognize function recognize(n::EndOfInput,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    return exhausted(input, index, finish), nothing, index
end


"""
    Empty()
Succeed while matching nothing.
"""
@bnfnode struct Empty <: BNFNode
end

@trace trace_recognize function recognize(n::Empty,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
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

@trace trace_recognize function recognize(n::Sequence,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    collected = []
    in = index
    for n1 in n.elements
        matched, v, i = recognize(n1, input, in, finish, context)
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

@trace trace_recognize function recognize(n::Alternatives,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    alts_matched = false
    bestv = nothing
    # If one of the alternatives is Empty, we want our match to
    # succeed. WHAT ABOUT INFINITE RECURSION?
    besti = index - 1
    for n1 in n.alternatives
        matched, v, i = recognize(n1, input, index, finish, context)
        if matched && i > besti
            alts_matched = true
            bestv = v
            besti = i
        end
    end
    if !alts_matched
        return false, nothing, index
    end
    return alts_matched, bestv, besti
end


"""
    CharacterLiteral(c)
Matches the single character `c`.
"""
@bnfnode struct CharacterLiteral <: BNFNode
    character::Char
end

@trace trace_recognize function recognize(n::CharacterLiteral,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    if exhausted(input, index, finish)
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

@trace trace_recognize function recognize(n::StringLiteral,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    # Don't match "" at the end of input:
    if n.str == "" && exhausted(input, index, finish)
        return false, nothing, index
    end
    end_inclusive = index + lastindex(n.str) - firstindex(n.str)
    if exhausted(input, end_inclusive, finish)
        return false, nothing, index
    end
    ss = SubString(input, index, end_inclusive)
    if n.str == ss
        return true, ss, index + length(n.str)
    end
    return false, nothing, index
end


"""
    RegexNode <: BNFNode(re::Regex)
Match the specified regular expression."
So that the parser can access captures, The second return value
of `recognize` is the RegexMatch object returned by `match`.
"""
@bnfnode struct RegexNode <: BNFNode
    re::Regex
end

@trace trace_recognize function recognize(n::RegexNode,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    m = match(n.re, input, index)
    if m == nothing
        return false, nothing, index
    end
    if m.offset != index
        return false, nothing, index
    end
    return true, m, index + length(m.match)
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

@trace trace_recognize function recognize(n::Constructor,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    matched, v, i = recognize(n.node, input, index, finish, context)
    if !matched
        return false, v, i
    end
    v2 = n.constructor(v, context)
    if logReductions
        @info "$index: $(n.constructor) reduced $(typeof(v)) $v to $(typeof(v2)) $v2"
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
The rule can have a constructor function.
"""
@bnfnode mutable struct DerivationRule <: BNFNode
    grammar_name::Symbol
    name::String
    lhs::BNFNode
    constructor

    function DerivationRule(grammar::BNFGrammar, name, lhs)
        p = new(grammar.name, name, lhs, ignore_context(identity))
        add_derivation(p)
        p
    end
    DerivationRule(grammar_name::Symbol, name, lhs) =
        DerivationRule(AllGrammars[grammar_name], name, lhs,
                       ignore_context(identity))
end

@njl_getprop DerivationRule

Base.getproperty(p::DerivationRule, ::Val{:grammar}) =
    return AllGrammars[p.grammar_name]

ignore_context(f) = (x, context) -> f(x)

@trace trace_recognize function recognize(n::DerivationRule,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    matched, v, i = recognize(n.lhs, input, index, finish, context)
    if !matched
        return false, v, i
    end
    v2 = n.constructor(v, context)
    if logReductions
        @info "$index: constructor for $(n.name) reduced $(typeof(v)) $v to $(typeof(v2)) $v2"
    end
    return matched, v2, i
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

@njl_getprop BNFRef

Base.getproperty(p::BNFRef, ::Val{:grammar}) =
    AllGrammars[p.grammar_name]

Base.getproperty(n::BNFRef, ::Val{:target}) =
    AllGrammars[n.grammar_name][n.name]

@trace trace_recognize function recognize(n::BNFRef,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    recognize(n.target, input, index, finish, context)
end


"""
   StringCollector
StringCollector returns the entire substrring of the input that
@trace trace_recognize was recognized by its subexpression.
"""
@bnfnode struct StringCollector <: BNFNode
    node::BNFNode
end

@trace trace_recognize function recognize(n::StringCollector,
                                          input::AbstractString, index::Int, finish::Int,
                                          context::Any)
    start = index
    matched, v, i = recognize(n.node, input, index, finish, context)
    if !matched
        return false, v, i
    end
    return true, SubString(input, start, i - 1), i
end

