
export EndFenced

"""
    EndFenced(match::BNFNode, fence::AbstractString)

Match `match` usinh a `finish` argument that is the starting position
of `fence`.  If `fence` does not occur then the end of input is used.
"""
@bnfnode struct EndFenced <:BNFNode
    match::BNFNode
    fence::AbstractString
end

pretty(n::EndFenced) = *("EndFenced(", pretty(n.match), " ", "\"$(n.fence)\"", ")")

is_left_recursive(node::EndFenced, grammar::Symbol, name::AbstractString) =
    is_left_recursive(node.match, grammar, name)

function walk_nodes(f, n::EndFenced)
    f(n)
    walk_nodes(f, n.match)
end

function check_references(n::EndFenced)
    check_references(n.match)
end

function recognize(p::Parser, n::EndFenced,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    fence = findnext(n.fence, SubString(input, 1, finish), index)
    if fence == nothing
        fence = finish
    else
        fence = first(fence)       # findfirst returns a Range.
        fence = prevind(input, fence, 1)
    end
    recognize1(p, n.match, input, index, fence, context)
end

