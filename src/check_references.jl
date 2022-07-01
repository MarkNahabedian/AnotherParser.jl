export check_references

"""
    check_references(grammar)::Bool
Warn of anyBNFRef nodes in the grammar that don't have a target.
Return trueif there are any issues.
"""
function check_references(g::BNFGrammar)
    err= false
    for(_, dr) in g.derivations
        err |= check_references(dr)
    end
    err
end

check_references(::Empty) = false
check_references(::CharacterLiteral) = false
check_references(::StringCollector) = false
check_references(::StringLiteral) = false
check_references(::RegexNode) = false
check_references(::Constructor) = false

check_references(dr::DerivationRule) = check_references(dr.lhs)

function check_references(ref::BNFRef)
    if !haskey(AllGrammars, ref.grammar_name)
        @warn("No grammar for", ref)
        return true
    end
    if !haskey(ref.grammar, ref.name)
        @warn("No rule for ", ref)
        return true
    end
    false
end

function check_references(n::Sequence)
    err = false
    for elt in n.elements
        err |= check_references(elt)
    end
    err
end

function check_references(n::Alternatives)
    err = false
    for alt in n.alternatives
        err |= check_references(alt)
    end
    err
end

