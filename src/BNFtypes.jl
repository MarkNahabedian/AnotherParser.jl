export BNFNode,Sequence, Alternatives, Alternatives, NonTerminal, CharacterLiteral
export BNFRules, BNFRef

abstract type BNFNode end

struct Sequence <: BNFNode
    elements::Tuple{Vararg{<:BNFNode}}

    function Sequence(elements...)
        new(elements)
    end
end

struct Alternatives <: BNFNode
    alternatives::Tuple{Vararg{<:BNFNode}}

    function Alternatives(alternatives...)
        new(alternatives)
    end
end

struct CharacterLiteral  <: BNFNode
    character::Char
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


#=
struct NonTerminal <: BNFNode
    name::Symbol
    bnf::BNFNode
end
=#

