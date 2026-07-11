# Maintains a reverse index from BNFNode to its parent and to the path
# from AllGrammars that leads there.

export NODE_TO_PARENT, index_grammar, index_grammars, path_to_node

const NODE_TO_PARENT = Dict{BNFNode, Tuple{BNFNode, Symbol}}()

index_node(parent::BNFNode, fieldname::Symbol, child::BNFNode) = NODE_TO_PARENT[child] = (parent, fieldname)

function index_grammars()
    for g in values(AllGrammars)
        index_grammar(g)
    end
end

index_grammar(g::Symbol) = index_grammar(AllGrammars[g])
index_grammar(g::BNFGrammar) = walk_nodes(index_node_children, g)

# I'm too lazy to maintain methods for each node type.
function index_node_children(n::BNFNode)
    T = typeof(n)
    for f in fieldnames(T)
        if fieldtype(T, f) <: BNFNode
            index_node(n, f, getfield(n, f))
        end
    end
end


function path_to_node(n::BNFNode)
    parent, field = NODE_TO_PARENT[n]
    Expr(:., path_to_node(parent),
         QuoteNode(field))
end

function path_to_node(n::DerivationRule)
    Expr(:ref,
         Expr(:ref, :AllGrammars,
              QuoteNode(n.grammar_name)),
         QuoteNode(n.name))
end


############################################################
# Find the root productions of a grammar:

export root_productions

"""
     root_productions(::BNFGrammar)

Returns a list of the productions in the grammar that are not referred
to by any other productions in the grammar.

Each is represented by a Tuple of the grammar name and the
DerivationRule name.
"""
function root_productions(g::BNFGrammar)
    refs = Set{Tuple{Symbol, String}}()
    rules = Set{Tuple{Symbol, String}}()
    walker(n::BNFRef) = push!(refs, (n.grammar_name, n.name))
    walker(n::DerivationRule) = push!(rules, (n.grammar_name, n.name))
    walker(n::BNFNode) = nothing
    walk_nodes(walker, g)
    setdiff(rules, refs)
end

