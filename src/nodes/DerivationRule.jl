export DerivationRule


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

function walk_nodes(f, node::DerivationRule)
    f(node)
    walk_nodes(f, node.lhs)
end

function recognize(p::Parser, n::DerivationRule,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    matched, v, i = recognize1(p, n.lhs, input, index, finish, context)
    if !matched
        # No need to report n since n.lhs will aready have been
        # reported:
        # parse_failed_at(p, index, n)
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


