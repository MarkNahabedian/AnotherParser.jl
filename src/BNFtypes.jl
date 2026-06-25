export BNFNode, EndOfInput, Empty, Sequence, Alternatives, Repeat,
    NonTerminal, CharacterLiteral, CharacterInSet,
    CharacterSatisfiesPredicate, StringLiteral, RegexNode,
    Constructor, BNFRef, Excluding
export recognize, pretty, is_left_recursive, logReductions, loggingReductions
export BNFGrammar, DerivationRule
export AllGrammars
export walk_nodes, print_uid_index

using PropertyMethods

trace_recognize = false


"""
    pretty(::BNFNode)

Return a human-readable string that describes the node.
"""
function pretty end


"""
    is_left_recursive(::BNFGrammar)
    is_left_recursive(::DerivationRule)
    is_left_recursive(node::BNFNode, grammar::Symbol, name::AbstractString)

Returns true is `node` is left recursive with respect to the
[`DerivationRule`](@ref) named `name`.
"""
function is_left_recursive end

is_left_recursive(::BNFNode, ::Symbol, ::AbstractString) = false


"""
    recognize(::Parser, ::BNFNode, input::AbstractString; index, finish, context)

Attempt to parse `input` as the specified `BNFNode`, starting at `index`.
Return three values: whether the node matched the input,
the parsed value represented by the matched input,
and the next index into `input`.
`finish` is the index into `input` of the last character to be considered.
The `context` argument is passed to constructor functions
(see `Constructor` and `DerivationRule`) but
is otherwise unused.
"""
function recognize end

recognize(n::BNFNode, input::AbstractString;
          index=1, finish=lastindex(input),
          parser=Parser(),
          context=nothing) =
              recognize(parser, n, input, index, finish, context)


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

pretty(::EndOfInput) = "EndOfInput()"

function recognize(p::Parser, n::EndOfInput,
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

pretty(::Empty) = "Empty()"

function recognize(p::Parser, n::Empty,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    return true, nothing, index
end


"""
    Sequence(nodes...)

Successively match each of nodes in turn.
"""
@bnfnode struct Sequence <: BNFNode
    elements::Tuple{Vararg{BNFNode}}

    Sequence(elements...) = new(elements)
    Sequence(elements::Tuple) = new(elements)
end

pretty(n::Sequence) = *("Sequence(",
                        join(map(pretty, n.elements), " "),
                        ")")

is_left_recursive(node::Sequence, grammar::Symbol, name::AbstractString) =
    is_left_recursive(first(node.elements), grammar, name)

function recognize(p::Parser, n::Sequence,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    collected = []
    in = index
    for n1 in n.elements
        matched, v, i = recognize1(p, n1, input, in, finish, context)
        if !matched
            parse_failed_at(p, index, n)
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
    alternatives::Tuple{Vararg{BNFNode}}

    Alternatives(alternatives...) = new(alternatives)
    Alternatives(alternatives::Tuple) = new(alternatives)
end

pretty(n::Alternatives) = *("Alternatives(",
                            join(map(pretty, n.alternatives), " "),
                            ")")

is_left_recursive(node::Alternatives, grammar::Symbol, name::AbstractString) =
    any(n -> is_left_recursive(n, grammar, name), node.alternatives)

function recognize(p::Parser, n::Alternatives,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    # Greedy match: choose the alternative that consumes the most
    # input.
    alts_matched = false
    bestv = nothing
    # If one of the alternatives is Empty, we want our match to
    # succeed. WHAT ABOUT INFINITE RECURSION?
    besti = index - 1
    for n1 in n.alternatives
        matched, v, i = recognize1(p, n1, input, index, finish, context)
        if matched && i > besti
            alts_matched = true
            bestv = v
            besti = i
        end
    end
    if !alts_matched
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    return true, bestv, besti
end


"""
    Repeat(n::BNFNode; min=0, max=typemax(Int))

Matches repeated occurances of `n`.  The minimum and maxmum number of
allowed matches can be specified.
"""
@bnfnode struct Repeat <: BNFNode
    node::BNFNode
    min
    max

    function Repeat(repeating::BNFNode; min=0, max=typemax(Int))
        @assert min <= max
        new(repeating, min, max)
    end

end

pretty(n::Repeat) = *("Repeat(",
                      pretty(n.node),
                      ")")

is_left_recursive(node::Repeat, grammar::Symbol, name::AbstractString) =
    is_left_recursive(node.node, grammar, name)

function recognize(p::Parser, n::Repeat,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    result = []
    in = index
    while true
        if length(result) >= n.max
            break
        end
        matched, v, i = recognize1(p, n.node, input, in, finish, context)                    
        if !matched
            break
        end
        push!(result, v)
        if i == in
            if length(result) >= n.min
                return true, result, in
            end
            error("Input index failed to advance from $i in $n")
        end
        in = i
        if i > finish
            break
        end
    end
    if n.min > length(result)
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    return true, result, in
end


"""
    CharacterLiteral(c)

Matches the single character `c`.
"""
@bnfnode struct CharacterLiteral <: BNFNode
    character::Char
end

pretty(n::CharacterLiteral) = *("CharacterLiteral('",
                                n.character,
                                "')")

function recognize(p::Parser, n::CharacterLiteral,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    if exhausted(input, index, finish)
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    c = input[index]
    if c == n.character
        return true, c, nextind(input, index, 1)
    end
    parse_failed_at(p, index, n)
    return false, nothing, index
end


"""
    CharacterInSet(set)

Matches any single character in `set`.
"""
@bnfnode struct CharacterInSet <: BNFNode
    chars::Set{Char}

    CharacterInSet(v::Vector) = new(Set(v))

    CharacterInSet(s::Set) = new(s)
end

pretty(n::CharacterInSet) = *("CharacterInSet([",
                                n.chars...,
                                "])")

function recognize(p::Parser, n::CharacterInSet,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    if exhausted(input, index, finish)
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    c = input[index]
    if c in n.chars
        return true, c, nextind(input, index, 1)
    end
    parse_failed_at(p, index, n)
    return false, nothing, index
end


"""
    CharacterSatisfiesPredicate(predicate::Function)

Matches any single character that `predicate` returns true for.
"""
@bnfnode struct CharacterSatisfiesPredicate <: BNFNode
    predicate::Function
end

pretty(n::CharacterSatisfiesPredicate) = *("CharacterSatisfiesPredicate(",
                                           string(n.predicate),
                                           ")")

function recognize(p::Parser, n::CharacterSatisfiesPredicate,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    c = input[index]
    if n.predicate(c)
        return true, c, nextind(input, index, 1)
    end
    parse_failed_at(p, index, n)
    return false, nothing, index
end


"""
    StringLiteral(str)

Matches the string `str`.
"""
@bnfnode struct StringLiteral <: BNFNode
    str::AbstractString
end

pretty(n::StringLiteral) = *("StringLiteral(\"",
                             n.str,
                             "\")")

function recognize(p::Parser, n::StringLiteral,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    if length(n.str) == 0
        return true, n.str, index
    end
    if index > finish
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    if nextind(input, index, length(n.str) - 1) > finish
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    if startswith(SubString(input, index), n.str)
        return (true,
                n.str,
                nextind(input, index, length(n.str)))
    end
    parse_failed_at(p, index, n)
    return false, nothing, index
end


"""
    RegexNode <: BNFNode(re::Regex)

Match the specified regular expression.
So that the parser can access captures, The second return value
of `recognize` is the RegexMatch object returned by `match`.
"""
@bnfnode struct RegexNode <: BNFNode
    re::Regex
end

pretty(n::RegexNode) = *("RegexNode(",
                         string(n.re),
                         ")")

function recognize(p::Parser, n::RegexNode,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    m = match(n.re, input, index)
    if m == nothing
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    if m.offset != index
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    if m.offset != index
        parse_failed_at(p, index, n)
        return false, nothing, index
    end
    return true, m, nextind(input, index, length(m.match))
end


"""
    Constructor(node, constructor_function)

Apply `constructor_function` to the result of recognizing `node`
and return that as the result.
"""
@bnfnode struct Constructor <: BNFNode
    node::BNFNode
    constructor
end

pretty(::Constructor) = "Constructor()"

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

function recognize(p::Parser, n::Constructor,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    matched, v, i = recognize1(p, n.node, input, index, finish, context)
    if !matched
        parse_failed_at(p, index, n)
        return false, v, i
    end
    v2 = n.constructor(context, input, index, prevind(input, i, 1), v)
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
    uid_index

    function BNFGrammar(name::Symbol)
        g = new(name,
                # Dict{String, DerivationRule}()
                Dict(),
                Dict())
        AllGrammars[g.name] = g
        g
    end
end

Base.haskey(grammar::BNFGrammar, key::String) =
    haskey(grammar.derivations, key) || haskey(grammar.uid_index, key)

function Base.getindex(grammar::BNFGrammar, key::String)
    if haskey(grammar.derivations, key)
        grammar.derivations[key]
    else
        grammar.uid_index[key]
    end
end

function is_left_recursive(node::BNFGrammar)
    for d in values(node.derivations)
        if is_left_recursive(d)
            return true
        end
    end
    false
end


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
The rule can have a constructor function, which, if present, will
be called with the recognized value, and the context.
"""
@bnfnode mutable struct DerivationRule <: BNFNode
    grammar_name::Symbol
    name::String
    lhs::BNFNode
    constructor

    function DerivationRule(grammar::BNFGrammar, name, lhs; add_to_grammar=true)
        p = new(grammar.name, name, lhs, identity_constructor_function)
        if is_left_recursive(p)
            @warn "Left-recursive derivation" derivation = p
        end
        if add_to_grammar
            add_derivation(p)
        end
        p
    end
    DerivationRule(grammar_name::Symbol, name, lhs; add_to_grammar=true) =
        DerivationRule(AllGrammars[grammar_name], name, lhs; add_to_grammar)
end

@property_trampolines DerivationRule

Base.getproperty(p::DerivationRule, ::Val{:grammar}) =
    return AllGrammars[p.grammar_name]

pretty(n::DerivationRule) = *("DerivationRule(",
                              n.name,
                              " ::= ",
                              pretty(n.lhs),
                              ")")

is_left_recursive(node::DerivationRule) = is_left_recursive(node, node.grammar_name, node.name)

is_left_recursive(node::DerivationRule, grammar::Symbol, name::AbstractString) =
    is_left_recursive(node.lhs, grammar, name)

function recognize(p::Parser, n::DerivationRule,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    matched, v, i = recognize1(p, n.lhs, input, index, finish, context)
    if !matched
        parse_failed_at(p, index, n)
        return false, v, i
    end
    v2 = n.constructor(context, input, index,
                       prevind(input, i, 1),
                       v)
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
    walk_nodes(derivation) do node
        grammar.uid_index[node.uid] = node
    end
    derivation
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
        new(grammar.name, name)
end

@property_trampolines BNFRef

Base.getproperty(p::BNFRef, ::Val{:grammar}) =
    AllGrammars[p.grammar_name]

Base.getproperty(n::BNFRef, ::Val{:target}) =
    AllGrammars[n.grammar_name][n.name]

pretty(n::BNFRef) = "BNFRef(" * n.name * ")"

is_left_recursive(node::BNFRef, grammar::Symbol, name::AbstractString) =
    node.grammar_name == grammar && node.name == name

function recognize(p::Parser, n::BNFRef,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    recognize1(p, n.target, input, index, finish, context)
end


"""
    Excluding(exclude, match)

Match if the current input matches `match`, but ofly if it does not
match `exclude`.
"""
@bnfnode struct Excluding <:BNFNode
    exclude::BNFNode
    match::BNFNode
end

pretty(n::Excluding) = *("Excluding(", pretty(n.exclude), " ", pretty(n.match), ")")

is_left_recursive(node::Excluding, grammar::Symbol, name::AbstractString) =
    is_left_recursive(node.exclude, grammar, name) ||
    is_left_recursive(node.match, grammar, name)

function recognize(p::Parser, n::Excluding,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    matched, v, i = recognize1(p, n.exclude, input, index, finish, context)
    if matched
        parse_failed_at(p, index, n)
        return false, nothing, i
    end
    recognize1(p, n.match, input, index, finish, context)
end


"""
    walk_nodes(f, node)

Applies `f` to each node in the node tree that descends from `node`.
"""
function walk_nodes(f, node::BNFNode)
    f(node)
end

function walk_nodes(f, node::BNFGrammar)
    for d in values(node.derivations)
        walk_nodes(f, d)
    end
end

function walk_nodes(f, node::DerivationRule)
    f(node)
    walk_nodes(f, node.lhs)
end

function walk_nodes(f, node::Sequence)
    f(node)
    for e in node.elements
        walk_nodes(f, e)
    end
end

function walk_nodes(f, node::Alternatives)
    f(node)
    for alt in node.alternatives
        walk_nodes(f, alt)
    end
end

function walk_nodes(f, node::Repeat)
    f(node)
    walk_nodes(f, node.node)
end

function walk_nodes(f, node::Constructor)
    f(node)
    walk_nodes(f, node.node)
end

function print_uid_index(grammar::BNFGrammar)
    for (k, v) in grammar.uid_index
        println("\n", k, "\n\t", v)
    end
end

