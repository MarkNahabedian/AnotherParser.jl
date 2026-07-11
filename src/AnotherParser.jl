module AnotherParser

using PrettyPrint
using Parameters

"""
    BNFNode

Abstract supertype for all structs that we use to implement a grammar.
"""
abstract type BNFNode end

Base.hash(n::BNFNode, h::UInt64) = hash(n.uid, h)


include("note_BNFNode_location.jl")
include("parser.jl")
include("constructor_functions.jl")
include("BNFtypes.jl")
include("node_reverse_index.jl")
include("debug_parser.jl");
include("check_references.jl")
include("pprint.jl")

end
