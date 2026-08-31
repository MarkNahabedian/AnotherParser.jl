export Excluding


"""
    Excluding(exclude, match)

Match if the current input matches `match`, but ofly if it does not
match `exclude`.

USE WITH CAUTION: `Excluding` does not implement the full
set-theoretic `-` operator of the W3C XML Extended BNF.  Be
particularly carefule near the `Repeat` node, which is greedy.
"""
@bnfnode struct Excluding <:BNFNode
    exclude::BNFNode
    match::BNFNode
end

pretty(n::Excluding) = *("Excluding(", pretty(n.exclude), " ", pretty(n.match), ")")

is_left_recursive(node::Excluding, grammar::Symbol, name::AbstractString) =
    is_left_recursive(node.exclude, grammar, name) ||
    is_left_recursive(node.match, grammar, name)

function walk_nodes(f, n::Excluding)
    f(n)
    walk_nodes(f, n.exclude)
    walk_nodes(f, n.match)
end

function recognize(p::Parser, n::Excluding,
                   input::AbstractString, index::Int, finish::Int,
                   context::Any)
    matched, v, i = recognize1(p, n.exclude, input, index, finish, context)
    if matched
        parse_failed_at(p, index, n, "n.exclude matched")
        return false, nothing, i
    end
    recognize1(p, n.match, input, index, finish, context)
end


