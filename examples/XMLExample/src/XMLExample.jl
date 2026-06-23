module XMLExample

using AnotherParser

include("cst.jl")
include("xml.jl")
include("byte_order_decoding.jl")

function __init__()
    # When Julia precompiles a module, it does not capture changes
    # made to other modules, so the grammar definition is lost.  This
    # makes sure the grammar is preserved t=when this module is
    # loaded.
    AllGrammars[XMLGrammar.name] = XMLGrammar
end

end #module

