export BNFRef


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

