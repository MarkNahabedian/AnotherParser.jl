
include("SemVerBNF.jl")

@testset "example SemVer grammar" begin
    SemVerGrammar = AllGrammars[:SemVer]
    @test undot("foo") == ("foo",)
    @test undot(["foo", '.', ["bar"]]) == ("foo", "bar")
    @test undot(["foo", '.', ["bar", '.', ["baz"]]]) == ("foo", "bar", "baz")
    @test recognize(CharacterLiteral('a'), "abc") == (true, 'a', 2)
    @test recognize(CharacterLiteral('a'), "b") == (false, nothing, 1)
    @test recognize(CharacterLiteral('a'), "") == (false, nothing, 1)
    @test recognize(SemVerGrammar["<letter>"], "abc") == (true, 'a', 2)
    @test recognize(SemVerGrammar["<digits>"], "1234 ") == (true, "1234", 5)
    @test recognize(BNFRef(SemVerGrammar, "<positive digit>"), "0") == (false, nothing, 1)
    @test recognize(BNFRef(SemVerGrammar, "<positive digit>"), "1") == (true, '1', 2)
    @test recognize(SemVerGrammar["<numeric identifier>"], "1") == (true, 1, 2)
    @test recognize(SemVerGrammar["<major>"],"2") == (true, 2, 2)
    @test recognize(SemVerGrammar["<minor>"],"21") == (true, 21, 3)
    @test recognize(SemVerGrammar["<version core>"], "3.2.11") == (true, (3, 2, 11), 7)
    @test recognize(SemVerGrammar["<valid semver>"], "1.2.3") == (true, VersionNumber(1, 2,3), 6)
    @test recognize(SemVerGrammar["<alphanumeric identifier>"], "dev") == (true, "dev", 4)
    @test recognize(SemVerGrammar["<pre-release identifier>"], "dev") == (true, "dev", 4)
    @test recognize(SemVerGrammar["<pre-release identifier>"], "15") == (true, 15, 3)
    @test recognize(SemVerGrammar["<pre-release>"], "dev") == (true, ("dev",), 4)
    @test recognize(SemVerGrammar["<pre-release>"],
                    "foo.3.bar") == (true, ("foo", 3, "bar"), 10)
    @test recognize(SemVerGrammar["<pre-release>"],"3") == (true, (3,), 2)
    @test recognize(SemVerGrammar["<pre-release>"], "dev") == (true, ("dev",), 4)
    @test recognize(SemVerGrammar["<pre-release>"],"dev.naha.2") == (true, ("dev", "naha", 2), 11)
    @test recognize(SemVerGrammar["<pre-release>"],"dev.naha-2") == (true, ("dev", "naha-2"), 11)
    @test recognize(SemVerGrammar["<valid semver>"], "1.2.3-dev.3") ==
        (true, VersionNumber(1, 2, 3, ("dev", 3)), 12)
end

