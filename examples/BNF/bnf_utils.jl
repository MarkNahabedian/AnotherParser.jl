# Some utilities to assist in defining BNF grammars.

export @bnf_str
export flatten_to_string

which_BNF_grammar = nothing

deferred_bnf_strs = []

function do_bnf_str(str::String, grammar_name::Symbol)
    if !haskey(AllGrammars, grammar_name)
        BNFGrammar(grammar_name)
    end
    g::BNFGrammar = AllGrammars[Symbol(grammar_name)]
    bnf = AllGrammars[which_BNF_grammar]
    recognize(bnf["<syntax>"], str; context=grammar_name)
end


"""
Parse `str` as BNF and add those productions to the grammar named `grammar_name`.
"""
macro bnf_str(str, grammar_name)
    # HOW TO CAPTURE SOURCE LOCATION? SEE cl_str.
    grammar_name = Symbol(grammar_name)
    if which_BNF_grammar === nothing
        push!(deferred_bnf_strs, (str, grammar_name))
        return str
    end
    do_bnf_str(str, grammar_name)
end


"""
    flatten_to_string(v)
Flatten a tail recursive Vector of characters to a string.
"""
function flatten_to_string(v)
    b = IOBuffer()
    function walk(v)
        if v == nothing
            return
        end
        @assert v isa Vector
        @assert length(v) == 2
        write(b, v[1])
        walk(v[2])
    end
    walk(v)
    String(take!(b))
end

