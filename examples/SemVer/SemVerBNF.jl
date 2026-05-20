
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

# To simplify how we construct the intermediate results, we have
# inserted some intermediate nodes to do the construction.  These are
# tagged with an asterisk after teh opening < sign in the name.  They
# are used to distinguish the entry points of recursive rules from the
# recursion steps.

SemVerGrammar = BNFGrammar(:SemVer)


str2int(s) = parse(Int, s)

function undot(x)
    result = []
    function ud(x)
        if x == '.'
            return
        end
        if x isa AbstractVector
            for x1 in x
                ud(x1)
            end
        else
            push!(result, x)
        end
    end
    ud(x)
    return Tuple(result)
end

DerivationRule(
    SemVerGrammar, "<valid semver>",
    Alternatives(Constructor(BNFRef(SemVerGrammar, "<version core>"),
                             (context, input::AbstractString,
                              from::Int, to::Int, v) -> VersionNumber(v...)),
                 Constructor(Sequence(BNFRef(SemVerGrammar, "<version core>"),
                                      CharacterLiteral('-'),
                                      BNFRef(SemVerGrammar, "<pre-release>")),
                             function(context, input::AbstractString,
                                      from::Int, to::Int, v)
                                 (vc, dash, pre) = v
                                 VersionNumber(vc..., pre)
                             end),
                 Constructor(Sequence(BNFRef(SemVerGrammar, "<version core>"),
                                      CharacterLiteral('+'),
                                      BNFRef(SemVerGrammar, "<build>")),
                             function(context, input::AbstractString,
                                      from::Int, to::Int, v)
                                 (vc, plus, build) = v
                                 VersionNumber(vc..., (), build)
                             end),
                 Constructor(Sequence(BNFRef(SemVerGrammar, "<version core>"),
                                      CharacterLiteral('-'),
                                      BNFRef(SemVerGrammar, "<pre-release>"),
                                      CharacterLiteral('+'),
                                      BNFRef(SemVerGrammar, "<build>")),
                             function(context, input::AbstractString,
                                      from::Int, to::Int, v)
                                 (vc, dash, pre, plus, build) = v
                                 VersionNumber(vc..., pre, build)
                             end)))

DerivationRule(
    SemVerGrammar, "<version core>",
    Constructor(Sequence(BNFRef(SemVerGrammar, "<major>"), CharacterLiteral('.'),
                         BNFRef(SemVerGrammar, "<minor>"), CharacterLiteral('.'),
                         BNFRef(SemVerGrammar, "<patch>")),
                (context, input::AbstractString, from::Int, to::Int, v) -> undot(v)))

DerivationRule(
    SemVerGrammar, "<major>",
    BNFRef(SemVerGrammar, "<numeric identifier>"))

DerivationRule(
    SemVerGrammar, "<minor>",
    BNFRef(SemVerGrammar, "<numeric identifier>"))

DerivationRule(
    SemVerGrammar, "<patch>",
    BNFRef(SemVerGrammar, "<numeric identifier>"))

DerivationRule(
    SemVerGrammar, "<pre-release>",
    Constructor(
        BNFRef(SemVerGrammar, "<dot-separated pre-release identifiers>"),
        (context, input::AbstractString, from::Int, to::Int, v) -> undot(v)))

DerivationRule(
    SemVerGrammar, "<dot-separated pre-release identifiers>",
    Alternatives(
        BNFRef(SemVerGrammar, "<pre-release identifier>"),
        Sequence(BNFRef(SemVerGrammar, "<pre-release identifier>"),
                  CharacterLiteral('.'),
                  BNFRef(SemVerGrammar, "<dot-separated pre-release identifiers>"))))

DerivationRule(
    SemVerGrammar, "<build>",
    BNFRef(SemVerGrammar, "<dot-separated build identifiers>"))

DerivationRule(
    SemVerGrammar, "<dot-separated build identifiers>",
    Constructor(
        Alternatives(
            BNFRef(SemVerGrammar, "<build identifier>"),
            Sequence(BNFRef(SemVerGrammar, "<build identifier>"),
                      CharacterLiteral('.'),
                      BNFRef(SemVerGrammar, "<dot-separated build identifiers>"))),
        (context, input::AbstractString, from::Int, to::Int, v) -> undot(v)))

DerivationRule(
    SemVerGrammar, "<pre-release identifier>",
    Alternatives(BNFRef(SemVerGrammar, "<alphanumeric identifier>"),
                  BNFRef(SemVerGrammar, "<numeric identifier>")))

DerivationRule(
    SemVerGrammar, "<build identifier>",
    Alternatives(BNFRef(SemVerGrammar, "<alphanumeric identifier>"),
                 Constructor(BNFRef(SemVerGrammar, "<digits>"),
                             (context, input::AbstractString, from::Int, to::Int, v) ->
                                 str2int(v))))

DerivationRule(
    SemVerGrammar, "<alphanumeric identifier>",
    Alternatives(BNFRef(SemVerGrammar, "<non-digit>"),
                 Sequence(BNFRef(SemVerGrammar, "<non-digit>"),
                          BNFRef(SemVerGrammar, "<identifier characters>")),
                 Sequence(BNFRef(SemVerGrammar, "<identifier characters>"),
                          BNFRef(SemVerGrammar, "<non-digit>")),
                 Sequence(BNFRef(SemVerGrammar, "<identifier characters>"),
                          BNFRef(SemVerGrammar, "<non-digit>"),
                          BNFRef(SemVerGrammar, "<identifier characters>")))
).constructor = substring_constructor_function

DerivationRule(
    SemVerGrammar, "<numeric identifier>",
    Alternatives(CharacterLiteral('0'),
                 BNFRef(SemVerGrammar, "<positive digit>"),
                 Sequence(BNFRef(SemVerGrammar, "<positive digit>"),
                          BNFRef(SemVerGrammar, "<digits>")))
).constructor = function (context, input::AbstractString, from::Int, to::Int, v)
    str2int(SubString(input, from, to))
end

DerivationRule(
    SemVerGrammar, "<identifier characters>",
    BNFRef(SemVerGrammar, "<*identifier characters>")
).constructor = substring_constructor_function

DerivationRule(
    SemVerGrammar, "<*identifier characters>",
    Alternatives(BNFRef(SemVerGrammar, "<identifier character>"),
                  Sequence(BNFRef(SemVerGrammar, "<identifier character>"),
                            BNFRef(SemVerGrammar, "<*identifier characters>"))))

DerivationRule(
    SemVerGrammar, "<identifier character>",
    Alternatives(BNFRef(SemVerGrammar, "<digit>"),
                  BNFRef(SemVerGrammar, "<non-digit>")))

DerivationRule(
    SemVerGrammar, "<non-digit>",
    Alternatives(BNFRef(SemVerGrammar, "<letter>"),
                  CharacterLiteral('-')))

DerivationRule(
    SemVerGrammar, "<digits>",
    BNFRef(SemVerGrammar, "<*digits>")
).constructor = substring_constructor_function

DerivationRule(
    SemVerGrammar, "<*digits>",
    Alternatives(
        # Reordered the alternatives to reduce calls to <digit>.
        Sequence(BNFRef(SemVerGrammar, "<digit>"),
                  BNFRef(SemVerGrammar, "<*digits>")),
        BNFRef(SemVerGrammar, "<digit>")))

DerivationRule(
    SemVerGrammar, "<digit>",
    Alternatives(CharacterLiteral('0'),
                  BNFRef(SemVerGrammar, "<positive digit>")))

DerivationRule(
    SemVerGrammar, "<positive digit>",
    Alternatives([CharacterLiteral(c) for c in '1':'9']...))

DerivationRule(
    SemVerGrammar, "<letter>",
    Alternatives([CharacterLiteral(c) for c in 'A':'Z']...,
                  [CharacterLiteral(c) for c in 'a':'z']...))

check_references(:SemVer)

