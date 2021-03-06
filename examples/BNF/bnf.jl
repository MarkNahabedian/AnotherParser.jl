# A BNF for BNF

# This wikipedia article has a BNF for BNF:
#   https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form

BootstrapBNFGrammar = BNFGrammar(:BootstrapBNFGrammar)

bnf"""
 <syntax>         ::= <rule> | <rule> <syntax>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<syntax>",
               @Alternatives(BNFRef(BootstrapBNFGrammar, "<rule>"),
                             Sequence(BNFRef(BootstrapBNFGrammar, "<rule>"))))


bnf"""
 <rule>           ::= <opt-whitespace> "<" <rule-name> ">" <opt-whitespace> "::=" <opt-whitespace> <expression> <line-end>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<rule>",
               Sequence(BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                        CharacterLiteral('<'),
                        BNFRef(BootstrapBNFGrammar, "<rule-name>"),
                        CharacterLiteral('>'),
                        BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                        StringLiteral("::="),
                        BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                        BNFRef(BootstrapBNFGrammar, "<expression>"),
                        BNFRef(BootstrapBNFGrammar, "<line-end>"))
               ).constructor = function (elts, grammar_name)
                   rule_name = join(elts[2:4])
                   expression = elts[8]
                   DerivationRule(grammar_name, rule_name, expression)
               end

bnf"""
 <opt-whitespace> ::= " " <opt-whitespace> | ""
"""BNF
DerivationRule(BootstrapBNFGrammar, "<opt-whitespace>",
               Alternatives(
                   Sequence(CharacterLiteral(' '),
                            BNFRef(BootstrapBNFGrammar, "<opt-whitespace>")),
                   StringLiteral(""))
               ).constructor =
                   (v, context) -> nothing


bnf"""
 <expression>     ::= <list> | <list> <opt-whitespace> "|" <opt-whitespace> <expression>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<expression>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<list>"),
                   Sequence(BNFRef(BootstrapBNFGrammar, "<list>"),
                            BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                            CharacterLiteral('|'),
                            BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                            BNFRef(BootstrapBNFGrammar, "<expression>"))
               )).constructor =
                   function (elts, grammar_name)
                       if elts isa BNFNode
                           return elts
                       end
                       list = elts[1]
                       expression = elts[5]
                       if expression isa Alternatives
                           Alternatives(list, expression.alternatives...)
                       else
                           Alternatives(list, expression)
                       end
                   end


bnf"""
 <line-end>       ::= <opt-whitespace> <EOL> | <line-end> <line-end>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<line-end>",
               Alternatives(
                   Sequence(BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                            BNFRef(BootstrapBNFGrammar, "<EOL>")),
                   Sequence(BNFRef(BootstrapBNFGrammar, "<line-end>"),
                            BNFRef(BootstrapBNFGrammar, "<line-end>"),)))

bnf"""
 <list>           ::= <term> | <term> <opt-whitespace> <list>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<list>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<term>"),
                   Sequence(BNFRef(BootstrapBNFGrammar, "<term>"),
                            BNFRef(BootstrapBNFGrammar, "<opt-whitespace>"),
                            BNFRef(BootstrapBNFGrammar, "<list>"),))
               ).constructor =
                   function (elts, grammar_name)
                       if elts isa BNFNode
                           return elts
                       end
                       term = elts[1]
                       list = elts[3]
                       if list isa Sequence
                           Sequence(term, list.elements...)
                       else
                           Sequence(term, list)
                       end
                   end

bnf"""
 <term>           ::= <literal> | "<" <rule-name> ">"
"""BNF
DerivationRule(BootstrapBNFGrammar, "<term>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<literal>"),
                   Sequence(CharacterLiteral('<'),
                            BNFRef(BootstrapBNFGrammar, "<rule-name>"),
                            CharacterLiteral('>')))
                       ).constructor =
                           function (elts, grammar_name)
                               if elts isa StringLiteral
                                   return elts
                               end
                               BNFRef(grammar_name, join(elts))
                           end

bnf"""
 <literal>        ::= '"' <text1> '"' | "'" <text2> "'"
"""BNF
# A double quoted string can contain single quotes.
# A single quoted string can contain double quotes.
DerivationRule(BootstrapBNFGrammar, "<literal>",
               Alternatives(
                   Sequence(
                       CharacterLiteral('"'),
                       StringCollector(BNFRef(BootstrapBNFGrammar, "<text1>")),
                       CharacterLiteral('"')),
                   Sequence(
                       CharacterLiteral('\''),
                       StringCollector(BNFRef(BootstrapBNFGrammar, "<text2>")),
                       CharacterLiteral('\'')))
               ).constructor =
                   function (x, grammar_name)
                       @assert length(x) == 3
                       StringLiteral(x[2])
                   end

bnf"""
 <text1>          ::= "" | <character1> <text1>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<text1>",
               Alternatives(
                   StringLiteral(""),
                   Sequence(
                       BNFRef(BootstrapBNFGrammar, "<character1>"),
                       BNFRef(BootstrapBNFGrammar, "<text1>"))))

bnf"""
 <text2>          ::= '' | <character2> <text2>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<text2>",
               Alternatives(
                   StringLiteral(""),
                   Sequence(
                       BNFRef(BootstrapBNFGrammar, "<character2>"),
                       BNFRef(BootstrapBNFGrammar, "<text2>"))))

bnf"""
 <character>      ::= <letter> | <digit> | <symbol>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<character>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<letter>"),
                   BNFRef(BootstrapBNFGrammar, "<digit>"),
                   BNFRef(BootstrapBNFGrammar, "<symbol>")))

bnf"""
 <letter>         ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
"""BNF
#=
DerivationRule(BootstrapBNFGrammar, "<letter>",
               Alternatives(
                   [CharacterLiteral(c) for c in 'A':'Z']...,
                   [CharacterLiteral(c) for c in 'a':'z']...))
=#
# Less noisy tracing:
DerivationRule(BootstrapBNFGrammar, "<letter>",
               RegexNode(r"[a-zA-Z]")).constructor =
                   (m, context) -> m.match

bnf"""
 <digit>          ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
"""BNF
#=
DerivationRule(BootstrapBNFGrammar, "<digit>",
               Alternatives(
                   [CharacterLiteral(c) for c in '0':'9']...))
=#
# Less noisy tracing:
DerivationRule(BootstrapBNFGrammar, "<digit>",
               RegexNode(r"[0-9]")).constructor =
                   (m, context) -> m.match

bnf"""
 <symbol>         ::=  "|" | " " | "!" | "#" | "$" | "%" | "&" | "(" | ")" | "*" | "+" | "," | "-" | "." | "/" | ":" | ";" | ">" | "=" | "<" | "?" | "@" | "[" | "\" | "]" | "^" | "_" | "`" | "{" | "}" | "~"
"""BNF
#=
DerivationRule(BootstrapBNFGrammar, "<symbol>",
               Alternatives(
                   CharacterLiteral('|'),
                   CharacterLiteral(' '),
                   CharacterLiteral('!'),
                   CharacterLiteral('#'),
                   CharacterLiteral('$'),
                   CharacterLiteral('%'),
                   CharacterLiteral('&'),
                   CharacterLiteral('('),
                   CharacterLiteral(')'),
                   CharacterLiteral('*'),
                   CharacterLiteral('+'),
                   CharacterLiteral(','),
                   CharacterLiteral('-'),
                   CharacterLiteral('.'),
                   CharacterLiteral('/'),
                   CharacterLiteral(':'),
                   CharacterLiteral(';'),
                   CharacterLiteral('>'),
                   CharacterLiteral('='),
                   CharacterLiteral('<'),
                   CharacterLiteral('?'),
                   CharacterLiteral('@'),
                   CharacterLiteral('['),
                   CharacterLiteral('\\'),
                   CharacterLiteral(']'),
                   CharacterLiteral('^'),
                   CharacterLiteral('_'),
                   CharacterLiteral('`'),
                   CharacterLiteral('{'),
                   CharacterLiteral('}'),
                   CharacterLiteral('~'),))
=#
# Less noisy tracing:
DerivationRule(BootstrapBNFGrammar, "<symbol>",
               RegexNode(r"[| !#$%&()*+,-./:;>=<?@\[\\\]^_`{}~]")).constructor = 
                   (m, context) -> m.match

bnf"""
 <character1>     ::= <character> | "'"
"""BNF
DerivationRule(BootstrapBNFGrammar, "<character1>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<character>"),
                   CharacterLiteral('\'')))

bnf"""
 <character2>     ::= <character> | '"'
"""BNF
DerivationRule(BootstrapBNFGrammar, "<character2>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<character>"),
                   CharacterLiteral('"')))

#=
# I think this production form the Wikipedia page is incorrect:
bnf"""
 <rule-name>      ::= <letter> | <rule-name> <rule-char>
"""BNF
DerivationRule(BootstrapBNFGrammar, "<rule-name>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<letter>"),
                   Sequence(
                       BNFRef(BootstrapBNFGrammar, "<rule-name>"),
                       BNFRef(BootstrapBNFGrammar, "<rule-char>"))))
=#
bnf"""
 <rule-name>      ::= <letter> <rule-name2>
 <rule-name2>     ::= EndOfInput() | "" | <rule-char> <rule-name2>
"""BNF
# I believe the intent is that a <rule-name> must begin with a letter,
# followed by any number of <rule-char>s.
DerivationRule(BootstrapBNFGrammar, "<rule-name>",
               Sequence(
                   BNFRef(BootstrapBNFGrammar, "<letter>"),
                   BNFRef(BootstrapBNFGrammar, "<rule-name2>"))
               ).constructor =
                   ignore_context(flatten_to_string)
                       
DerivationRule(BootstrapBNFGrammar, "<rule-name2>",
               Alternatives(
                   StringLiteral(""),
                   Sequence(BNFRef(BootstrapBNFGrammar, "<rule-char>"),
                            BNFRef(BootstrapBNFGrammar, "<rule-name2>"))))

bnf"""
 <rule-char>      ::= <letter> | <digit> | "-"
"""BNF
DerivationRule(BootstrapBNFGrammar, "<rule-char>",
               Alternatives(
                   BNFRef(BootstrapBNFGrammar, "<letter>"),
                   BNFRef(BootstrapBNFGrammar, "<digit>"),
                   CharacterLiteral('-')))


# The Wikipedia page did not include this rule
bnf"""
 <EOL>   ::= '\n'
"""BNF
DerivationRule(BootstrapBNFGrammar, "<EOL>",
               CharacterLiteral('\n'))


@assert !check_references(BootstrapBNFGrammar)

which_BNF_grammar = :BootstrapBNFGrammar

function bootstrap_bnf()
    errors = 0
    count = 0
    for e in deferred_bnf_strs
        try
            count += 1
            do_bnf_str(e...)
        catch err
            if err isa InterruptException
                rethrow(err)
            end
            println("$(e[1])")
            errors += 1
        end
    end
    println("$errors errors/$count.")
    # which_BNF_grammar = :BNF
end

