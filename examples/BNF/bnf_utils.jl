# Some utilities to assist in defining BNF grammars.

export @bnf_str

which_BNF_grammar = nothing

deferred_bnf_strs = []

function do_bnf_str(str::String, grammar_name::Symbol, source)
    if !haskey(AllGrammars, grammar_name)
        BNFGrammar(grammar_name)
    end
    # g::BNFGrammar = AllGrammars[Symbol(grammar_name)]
    bnf = AllGrammars[which_BNF_grammar]
    # How to set source location?  Do we need to include it in the
    # context?
    recognize(bnf["<syntax>"], str; context=grammar_name)
end


"""
    bnf"str"grammar_name

Parse `str` as BNF and add those productions to the grammar named
`grammar_name`.

Since bnf_str is used to define the BNF grammar itself, and it's
convenient to have the BNF strings near the hand coded BNF grammar,
there's a bootstraping mode which defers parsing of `str` until a BNF
grammar is available.
"""
macro bnf_str(str, grammar_name)
    grammar_name = Symbol(grammar_name)
    if which_BNF_grammar === nothing
        push!(deferred_bnf_strs, (str, grammar_name, __source__))
        return str
    end
    do_bnf_str(str, grammar_name, __source__)
end


