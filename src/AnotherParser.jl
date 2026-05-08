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
include("BNFtypes.jl")
include("check_references.jl")
include("pprint.jl")

include("../examples/BNF/includes.jl")

end
