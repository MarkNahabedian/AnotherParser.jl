
export show_grammar

"""
    show_grammar(grammar_name::Symbol)
Show a pretty description of all of the derivations in the grammar.
"""
function show_grammar(grammar_name::Symbol)
    g = AllGrammars[grammar_name]
    k = sort(collect(keys(g.derivations)))
    for dk in k
        d = g.derivations[dk]
        println(d.name)
        pprint(d.lhs)
        println("\n")
    end
end

function PrettyPrint.pp_impl(io, o::Empty, indent::Int)
    r ="Empty()"
    print(io, r)
    indent + length(r)
end

function PrettyPrint.pp_impl(io, o::CharacterLiteral, indent::Int)
    r = "CharacterLiteral($(repr(o.character)))"
    print(io, r)
    indent + length(r)
end

function PrettyPrint.pp_impl(io, o::StringLiteral, indent::Int)
    r = "StringLiteral($(repr(o.str)))"
    print(io, r)
    indent + length(r)
end

function PrettyPrint.pp_impl(io, o::BNFRef, indent::Int)
    r = "BNFRef($(repr(o.grammar_name)), $(repr(o.name)))"
    print(io, r)
    indent + length(r)
end

PrettyPrint.pp_impl(io, o::Sequence, indent::Int) =
    PrettyPrint.pprint_for_seq(io, "Sequence(", ")",
                               o.elements, indent)

PrettyPrint.pp_impl(io, o::Alternatives, indent::Int) =
    PrettyPrint.pprint_for_seq(io, "Alternatives(", ")",
                               o.alternatives, indent)    

function PrettyPrint.pp_impl(io, o::StringCollector, indent::Int)
    r = "StringCollector("
    print(io, r)
    pprint(io, o.node, indent + 4)
    print(io, ")")
    indent + 2
end

function PrettyPrint.pp_impl(io, o::Constructor, indent::Int)
    r = "Constructor("
    print(io, r)
    pprint(io, o.node, indent + 4)
    print(io, ",\n")
    pprinit(io, o.constructor, indent + 4)
    print(io, ")")
    indent + 2
end

function PrettyPrint.pp_impl(io, o::DerivationRule, indent::Int)
    r = "DerivationRule("
    print(io, r)
    pprint(o.grammar_name, indent + 4)
    print(io, ",\n")
    pprint(o.name, indent + 4)
    print(io, ",\n")
    pprint(o.lhs, indent + 4)
    print(io, ")")
    indent + 2
end
