
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

@testset "SemVer grammar" begin
SemVerBNF = let

    # applier(op) = v -> op(v...)

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
        
    @test undot("foo") == ("foo",)
    @test undot(["foo", '.', ["bar"]]) == ("foo", "bar")
    @test undot(["foo", '.', ["bar", '.', ["baz"]]]) == ("foo", "bar", "baz")

    r = BNFRules()
    ref(name) = BNFRef(r, name)

    r["<valid semver>"] =
        Alternatives(Constructor(ref("<version core>"),
                                 v -> VersionNumber(v...)),
                     Constructor(Sequence(ref("<version core>"),
                                          CharacterLiteral('-'),
                                          ref("<pre-release>")),
                                 function(v)
                                     (vc, dash, pre) = v
                                     VersionNumber(vc..., pre)
                                 end),
                     Constructor(Sequence(ref("<version core>"),
                                          CharacterLiteral('+'),
                                          ref("<build>")),
                                 function(v)
                                     (vc, plus, build) = v
                                     VersionNumber(vc..., (), build)
                                 end),
                     Constructor(Sequence(ref("<version core>"),
                                          CharacterLiteral('-'),
                                          ref("<pre-release>"),
                                          CharacterLiteral('+'),
                                          ref("<build>")),
                                 function(v)
                                     (vc, dash, pre, plus, build) = v
                                     VersionNumber(vc..., pre, build)
                                 end))

    r["<version core>"] =
        Constructor(Sequence(ref("<major>"), CharacterLiteral('.'),
                             ref("<minor>"), CharacterLiteral('.'),
                             ref("<patch>")),
                    undot)

    r["<major>"] = ref("<numeric identifier>")

    r["<minor>"] = ref("<numeric identifier>")

    r["<patch>"] = ref("<numeric identifier>")

    r["<pre-release>"] =
        Constructor(
            ref("<dot-separated pre-release identifiers>"),
            undot)
    
    r["<dot-separated pre-release identifiers>"] =
        Alternatives(
            ref("<pre-release identifier>"),
            Sequence(ref("<pre-release identifier>"),
                     CharacterLiteral('.'),
                     ref("<dot-separated pre-release identifiers>")))
    
    r["<build>"] = ref("<dot-separated build identifiers>")
    
    r["<dot-separated build identifiers>"] =
        Constructor(
            Alternatives(
                ref("<build identifier>"),
                Sequence(ref("<build identifier>"),
                         CharacterLiteral('.'),
                         ref("<dot-separated build identifiers>"))),
            undot)
    
    r["<pre-release identifier>"] =
        Alternatives(ref("<alphanumeric identifier>"),
                     ref("<numeric identifier>"))
    
    r["<build identifier>"] =
        Alternatives(ref("<alphanumeric identifier>"),
                     Constructor(ref("<digits>"),
                                 str2int))

    r["<alphanumeric identifier>"] =
        StringCollector(
            Alternatives(ref("<non-digit>"),
                         Sequence(ref("<non-digit>"),
                                  ref("<identifier characters>")),
                         Sequence(ref("<identifier characters>"),
                                  ref("<non-digit>")),
                         Sequence(ref("<identifier characters>"),
                                  ref("<non-digit>"),
                                  ref("<identifier characters>"))))

    r["<numeric identifier>"] =
        Constructor(
            StringCollector(
                Alternatives(CharacterLiteral('0'),
                             ref("<positive digit>"),
                             Sequence(ref("<positive digit>"),
                                      ref("<digits>")))),
            str2int)

    r["<identifier characters>"] =
        StringCollector(
            ref("<*identifier characters>"))

    r["<*identifier characters>"]=
        Alternatives(ref("<identifier character>"),
                     Sequence(ref("<identifier character>"),
                              ref("<*identifier characters>")))
    
    r["<identifier character>"] =
        Alternatives(ref("<digit>"),
                     ref("<non-digit>"))

    r["<non-digit>"] =
        Alternatives(ref("<letter>"),
                     CharacterLiteral('-'))

    r["<digits>"] =
        StringCollector(
            ref("<*digits>"))

    r["<*digits>"] =
        Alternatives(
            # Reordered the alternatives to reduce calls to <digit>.
            Sequence(ref("<digit>"),
                     ref("<*digits>")),
            ref("<digit>"))

    r["<digit>"]=
        Alternatives(CharacterLiteral('0'),
                     ref("<positive digit>"))

    r["<positive digit>"]=
        Alternatives([CharacterLiteral(c) for c in '1':'9']...)
    
    r["<letter>"]=
        Alternatives([CharacterLiteral(c) for c in 'A':'Z']...,
                     [CharacterLiteral(c) for c in 'a':'z']...)
    
    @test recognize(CharacterLiteral('a'), "abc") == ('a', 2)
    @test recognize(CharacterLiteral('a'), "b") == (nothing, 1)
    @test recognize(CharacterLiteral('a'), "") == (nothing, 1)
    @test recognize(r["<letter>"], "abc") == ('a', 2)
    @test recognize(r["<digits>"], "1234 ") == ("1234", 5)
    @test recognize(ref("<positive digit>"), "0") == (nothing, 1)
    @test recognize(ref("<positive digit>"), "1") == ('1', 2)
    @test recognize(r["<numeric identifier>"], "1") == (1, 2)
    @test recognize(r["<major>"],"2") == (2, 2)
    @test recognize(r["<minor>"],"21") == (21, 3)
    @test recognize(r["<version core>"], "3.2.11") == ((3, 2, 11), 7)
    @test recognize(r["<valid semver>"], "1.2.3") == (VersionNumber(1, 2,3), 6)
    @test recognize(r["<alphanumeric identifier>"], "dev") == ("dev", 4)
    @test recognize(r["<pre-release identifier>"], "dev") == ("dev", 4)
    @test recognize(r["<pre-release identifier>"], "15") == (15, 3)
    @test recognize(r["<pre-release>"], "dev") == (("dev",), 4)
    @test recognize(r["<pre-release>"],
                    "foo.3.bar") == (("foo", 3, "bar"), 10)
    @test recognize(r["<pre-release>"],"3") == ((3,), 2)
    @test recognize(r["<pre-release>"], "dev") == (("dev",), 4)
    @test recognize(r["<pre-release>"],"dev.naha.2") == (("dev", "naha", 2), 11)
    @test recognize(r["<pre-release>"],"dev.naha-2") == (("dev", "naha-2"), 11)
    @test recognize(r["<valid semver>"], "1.2.3-dev.3") ==
        (VersionNumber(1, 2, 3, ("dev", 3)), 12)
    
    return r["<valid semver>"]
end

end
