using Logging

# Default method:

nodeeq(n1::Any, n2::Any) = n1 == n2

# We might need to define methods for other node types once line
# number recording is working.

nodeeq(l1::CharacterLiteral, l2::CharacterLiteral) =
    l1.character == l2.character

nodeeq(l1::StringLiteral, l2::StringLiteral) =
    l1.str == l2.str

nodeeq(n1::Sequence, n2::Sequence) =
    nodeeq(n1.elements, n2.elements)

# Technically, for Alternatives, the order shouldn't matter, but for
# how we're using it, we expect it wont be an issue.
nodeeq(n1::Alternatives, n2::Alternatives) =
    nodeeq(n1.alternatives, n2.alternatives)

function nodeeq(v1::Tuple, v2::Tuple)
    if length(v1) != length(v2)
        @warn("mismatched length", v1, v2)
        return false
    end
    for i in length(v1)
        if !nodeeq(v1[i], v2[i])
            @warn("mismatch at index $i", v1[i], v2[i])
            return false
        end
    end
    return true
end

# We might want to compare BNFRefs to two different grammars, so
# grammar_name should be tested separately.
nodeeq(n1::BNFRef, n2::BNFRef) = n1.name == n2.name

