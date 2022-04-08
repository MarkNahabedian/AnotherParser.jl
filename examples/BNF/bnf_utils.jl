# Some utilities to assist in defining BNF grammars.

# for now this is a NO-OP.  Once we have a working BNF grammar to
# boostrap with, it will add a production specified by `test` to the
# grammar named `grammar_name`.
macro bnf_str(text, grammar_name)
    text
end

