
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

function gref(name)
    BNFRef(SemVerGrammar, name)
end


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
    @Alternatives(@Constructor(gref("<version core>"),
                               v -> VersionNumber(v...)),
                  @Constructor(@Sequence(gref("<version core>"),
                                         @CharacterLiteral('-'),
                                         gref("<pre-release>")),
                               function(v)
                                   (vc, dash, pre) = v
                                   VersionNumber(vc..., pre)
                               end),
                  @Constructor(@Sequence(gref("<version core>"),
                                         @CharacterLiteral('+'),
                                         gref("<build>")),
                               function(v)
                                   (vc, plus, build) = v
                                   VersionNumber(vc..., (), build)
                               end),
                  @Constructor(@Sequence(gref("<version core>"),
                                         @CharacterLiteral('-'),
                                         gref("<pre-release>"),
                                         @CharacterLiteral('+'),
                                         gref("<build>")),
                               function(v)
                                   (vc, dash, pre, plus, build) = v
                                   VersionNumber(vc..., pre, build)
                               end)))

DerivationRule(
    SemVerGrammar, "<version core>",
    @Constructor(@Sequence(gref("<major>"), @CharacterLiteral('.'),
                           gref("<minor>"), @CharacterLiteral('.'),
                           gref("<patch>")),
                 undot))

DerivationRule(
    SemVerGrammar, "<major>",
    gref("<numeric identifier>"))

DerivationRule(
    SemVerGrammar, "<minor>",
    gref("<numeric identifier>"))

DerivationRule(
    SemVerGrammar, "<patch>",
    gref("<numeric identifier>"))

DerivationRule(
    SemVerGrammar, "<pre-release>",
    @Constructor(
        gref("<dot-separated pre-release identifiers>"),
        undot))

DerivationRule(
    SemVerGrammar, "<dot-separated pre-release identifiers>",
    @Alternatives(
        gref("<pre-release identifier>"),
        @Sequence(gref("<pre-release identifier>"),
                  @CharacterLiteral('.'),
                  gref("<dot-separated pre-release identifiers>"))))

DerivationRule(
    SemVerGrammar, "<build>",
    gref("<dot-separated build identifiers>"))

DerivationRule(
    SemVerGrammar, "<dot-separated build identifiers>",
    @Constructor(
        @Alternatives(
            gref("<build identifier>"),
            @Sequence(gref("<build identifier>"),
                      @CharacterLiteral('.'),
                      gref("<dot-separated build identifiers>"))),
        undot))

DerivationRule(
    SemVerGrammar, "<pre-release identifier>",
    @Alternatives(gref("<alphanumeric identifier>"),
                  gref("<numeric identifier>")))

DerivationRule(
    SemVerGrammar, "<build identifier>",
    @Alternatives(gref("<alphanumeric identifier>"),
                  @Constructor(gref("<digits>"),
                               str2int)))

DerivationRule(
    SemVerGrammar, "<alphanumeric identifier>",
    @StringCollector(
        @Alternatives(gref("<non-digit>"),
                      @Sequence(gref("<non-digit>"),
                                gref("<identifier characters>")),
                      @Sequence(gref("<identifier characters>"),
                                gref("<non-digit>")),
                      @Sequence(gref("<identifier characters>"),
                                gref("<non-digit>"),
                                gref("<identifier characters>")))))

DerivationRule(
    SemVerGrammar, "<numeric identifier>",
    @Constructor(
        @StringCollector(
            @Alternatives(@CharacterLiteral('0'),
                          gref("<positive digit>"),
                          @Sequence(gref("<positive digit>"),
                                    gref("<digits>")))),
        str2int))

DerivationRule(
    SemVerGrammar, "<identifier characters>",
    @StringCollector(
        gref("<*identifier characters>")))

DerivationRule(
    SemVerGrammar, "<*identifier characters>",
    @Alternatives(gref("<identifier character>"),
                  @Sequence(gref("<identifier character>"),
                            gref("<*identifier characters>"))))

DerivationRule(
    SemVerGrammar, "<identifier character>",
    @Alternatives(gref("<digit>"),
                  gref("<non-digit>")))

DerivationRule(
    SemVerGrammar, "<non-digit>",
    @Alternatives(gref("<letter>"),
                  @CharacterLiteral('-')))

DerivationRule(
    SemVerGrammar, "<digits>",
    @StringCollector(
        gref("<*digits>")))

DerivationRule(
    SemVerGrammar, "<*digits>",
    @Alternatives(
        # Reordered the alternatives to reduce calls to <digit>.
        @Sequence(gref("<digit>"),
                  gref("<*digits>")),
        gref("<digit>")))

DerivationRule(
    SemVerGrammar, "<digit>",
    @Alternatives(@CharacterLiteral('0'),
                  gref("<positive digit>")))

DerivationRule(
    SemVerGrammar, "<positive digit>",
    @Alternatives([@CharacterLiteral(c) for c in '1':'9']...))

DerivationRule(
    SemVerGrammar, "<letter>",
    @Alternatives([@CharacterLiteral(c) for c in 'A':'Z']...,
                  [@CharacterLiteral(c) for c in 'a':'z']...))


@testset "SemVer grammar" begin
    @test undot("foo") == ("foo",)
    @test undot(["foo", '.', ["bar"]]) == ("foo", "bar")
    @test undot(["foo", '.', ["bar", '.', ["baz"]]]) == ("foo", "bar", "baz")
    
    @test recognize(CharacterLiteral('a'), "abc") == ('a', 2)
    @test recognize(CharacterLiteral('a'), "b") == (nothing, 1)
    @test recognize(CharacterLiteral('a'), "") == (nothing, 1)
    @test recognize(SemVerGrammar["<letter>"], "abc") == ('a', 2)
    @test recognize(SemVerGrammar["<digits>"], "1234 ") == ("1234", 5)
    @test recognize(gref("<positive digit>"), "0") == (nothing, 1)
    @test recognize(gref("<positive digit>"), "1") == ('1', 2)
    @test recognize(SemVerGrammar["<numeric identifier>"], "1") == (1, 2)
    @test recognize(SemVerGrammar["<major>"],"2") == (2, 2)
    @test recognize(SemVerGrammar["<minor>"],"21") == (21, 3)
    @test recognize(SemVerGrammar["<version core>"], "3.2.11") == ((3, 2, 11), 7)
    @test recognize(SemVerGrammar["<valid semver>"], "1.2.3") == (VersionNumber(1, 2,3), 6)
    @test recognize(SemVerGrammar["<alphanumeric identifier>"], "dev") == ("dev", 4)
    @test recognize(SemVerGrammar["<pre-release identifier>"], "dev") == ("dev", 4)
    @test recognize(SemVerGrammar["<pre-release identifier>"], "15") == (15, 3)
    @test recognize(SemVerGrammar["<pre-release>"], "dev") == (("dev",), 4)
    @test recognize(SemVerGrammar["<pre-release>"],
                    "foo.3.bar") == (("foo", 3, "bar"), 10)
    @test recognize(SemVerGrammar["<pre-release>"],"3") == ((3,), 2)
    @test recognize(SemVerGrammar["<pre-release>"], "dev") == (("dev",), 4)
    @test recognize(SemVerGrammar["<pre-release>"],"dev.naha.2") == (("dev", "naha", 2), 11)
    @test recognize(SemVerGrammar["<pre-release>"],"dev.naha-2") == (("dev", "naha-2"), 11)
    @test recognize(SemVerGrammar["<valid semver>"], "1.2.3-dev.3") ==
        (VersionNumber(1, 2, 3, ("dev", 3)), 12)
end

