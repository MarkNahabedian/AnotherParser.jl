
# BNF from https://semver.org/

#=
<valid semver> ::= <version core>
                 | <version core> "-" <pre-release>
                 | <version core> "+" <build>
                 | <version core> "-" <pre-release> "+" <build>

<version core> ::= <major> "." <minor> "." <patch>

<major> ::= <numeric identifier>

<minor> ::= <numeric identifier>

<patch> ::= <numeric identifier>

<pre-release> ::= <dot-separated pre-release identifiers>

<dot-separated pre-release identifiers> ::= <pre-release identifier>
                                          | <pre-release identifier> "." <dot-separated pre-release identifiers>

<build> ::= <dot-separated build  identifiers>

<dot-separated build identifiers> ::= <build identifier>
                                    | <build identifier> "." <dot-separated build identifiers>

<pre-release identifier> ::= <alphanumeric identifier>
                           | <numeric identifier>

<build identifier> ::= <alphanumeric identifier>
                     | <digits>

<alphanumeric identifier> ::= <non-digit>
                            | <non-digit> <identifier characters>
                            | <identifier characters> <non-digit>
                            | <identifier characters> <non-digit> <identifier characters>

<numeric identifier> ::= "0"
                       | <positive digit>
                       | <positive digit> <digits>

<identifier characters> ::= <identifier character>
                          | <identifier character> <identifier characters>

<identifier character> ::= <digit>
                         | <non-digit>

<non-digit> ::= <letter>
              | "-"

<digits> ::= <digit>
           | <digit> <digits>

<digit> ::= "0"
          | <positive digit>

<positive digit> ::= "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"

<letter> ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J"
           | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T"
           | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d"
           | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n"
           | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x"
           | "y" | "z"
=#

SemVerBNF = let
    r = BNFRules()
    ref(name) = BNFRef(r, name)

    r["<valid semver>"] =
        Alternatives(Sequence(ref("<version core>"),
                              CharacterLiteral('-'),
                              ref("<pre-release>")),
                     Sequence(ref("<version core>"),
                              CharacterLiteral('+'),
                              ref("<build>")),
                     Sequence(ref("<version core>"),
                              CharacterLiteral('-'),
                              ref("<pre-release>"),
                              CharacterLiteral('+'),
                              ref("<build>")))

    r["<version core>"] =
        Sequence(ref("<major>"), CharacterLiteral('.'),
                 ref("<minor>"), CharacterLiteral('.'),
                 ref("<patch>"))

    r["<major>"] = ref("<numeric identifier>")

    r["<minor>"] = ref("<numeric identifier>")

    r["<patch>"] = ref("<numeric identifier>")

    r["<pre-release>"] = ref("<dot-separated pre-release identifiers>")

    r["<dot-separated pre-release identifiers>"] =
        Alternatives(ref("<pre-release identifier>"),
                     Sequence(ref("<pre-release identifier>"),
                              ref("<dot-separated pre-release identifiers>")))

    r["<build>"] = ref("<dot-separated build identifiers>")

    r["<dot-separated build identifiers>"] =
        Alternatives(ref("<build identifier>"),
                     Sequence(ref("<build identifier>"),
                              CharacterLiteral('.'),
                              ref("<dot-separated build identifiers>")))
    
    r["<pre-release identifier>"] =
        Alternatives(ref("<alphanumeric identifier>"),
                     ref("<numeric identifier>"))
    
    r["<build identifier>"] =
        Alternatives(ref("<alphanumeric identifier>"),
                     ref("<digits>"))

    r["<alphanumeric identifier>"] =
        Constructor(Alternatives(ref("<non-digit>"),
                                 Sequence(ref("<non-digit>"),
                                          ref("<identifier characters>")),
                                 Sequence(ref("<identifier characters>"),
                                          ref("<non-digit>")),
                                 Sequence(ref("<identifier characters>"),
                                          ref("<non-digit>"),
                                          ref("<identifier characters>"))),
                    string)

    r["<numeric identifier>"] =
        Constructor(Alternatives(CharacterLiteral('0'),
                                 ref("<positive digit>"),
                                 ref("<positive digit> <digits>")),
                    string)

    r["<identifier characters>"] =
        Constructor(Alternatives(ref("<identifier character>"),
                                 Sequence(ref("<identifier character>"),
                                          ref("<identifier characters>"))),
                    string)
    
    r["<identifier character>"] =
        Alternatives(ref("<digit>"),
                     ref("<non-digit>"))

    r["<non-digit>"] =
        Constructor(Alternatives(ref("<letter>"),
                                 CharacterLiteral('-')),
                    string)

    r["<digits>"] =
        Constructor(Alternatives(ref("<digit>"),
                                 Sequence(ref("<digit>"),
                                          ref("<digits>"))),
                    string)
        
    r["<digit>"]=
        Alternatives(CharacterLiteral('0'),
                     ref("<positive digit>"))

    r["<positive digit>"]=
        Alternatives([CharacterLiteral(c) for c in '1':'9']...)
    
    r["<letter>"]=
        Alternatives([CharacterLiteral(c) for c in 'A':'Z']...,
                     [CharacterLiteral(c) for c in 'a':'z']...)
                     
    @test recognize(r["<letter>"], "abc", 1) == ('a',2)
    @test recognize(r["<digits>"], "1234 ", 1) == ("1234", 5)
    @test recognize(r["<digits>"], "ABCD", 1) == ("ABCD", 5)

    return r["<valid semver>"]
end

