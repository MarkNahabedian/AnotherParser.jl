
include("SemVerBNF.jl")

@testset "example SemVer grammar" begin
    SemVerGrammar = AllGrammars[:SemVer]
    @test undot("foo") == ("foo",)
    @test undot(["foo", '.', ["bar"]]) == ("foo", "bar")
    @test undot(["foo", '.', ["bar", '.', ["baz"]]]) == ("foo", "bar", "baz")
    @test recognize1(CharacterLiteral('a'), "abc") == (true, 'a', 2)
    @test recognize1(CharacterLiteral('a'), "b") == (false, nothing, 1)
    @test recognize1(CharacterLiteral('a'), "") == (false, nothing, 1)
    @test recognize1(SemVerGrammar["<letter>"], "abc") == (true, 'a', 2)
    @test recognize1(SemVerGrammar["<digits>"], "1234 ") == (true, "1234", 5)
    @test recognize1(BNFRef(SemVerGrammar, "<positive digit>"), "0") == (false, nothing, 1)
    @test recognize1(BNFRef(SemVerGrammar, "<positive digit>"), "1") == (true, '1', 2)
    @test recognize1(SemVerGrammar["<numeric identifier>"], "1") == (true, 1, 2)
    @test recognize1(SemVerGrammar["<major>"],"2") == (true, 2, 2)
    @test recognize1(SemVerGrammar["<minor>"],"21") == (true, 21, 3)
    @test recognize1(SemVerGrammar["<version core>"], "3.2.11") == (true, (3, 2, 11), 7)
    @test recognize1(SemVerGrammar["<valid semver>"], "1.2.3") == (true, VersionNumber(1, 2,3), 6)
    @test recognize1(SemVerGrammar["<alphanumeric identifier>"], "dev") == (true, "dev", 4)
    @test recognize1(SemVerGrammar["<pre-release identifier>"], "dev") == (true, "dev", 4)
    @test recognize1(SemVerGrammar["<pre-release identifier>"], "15") == (true, 15, 3)
    @test recognize1(SemVerGrammar["<pre-release>"], "dev") == (true, ("dev",), 4)
    @test recognize1(SemVerGrammar["<pre-release>"],
                    "foo.3.bar") == (true, ("foo", 3, "bar"), 10)
    @test recognize1(SemVerGrammar["<pre-release>"],"3") == (true, (3,), 2)
    @test recognize1(SemVerGrammar["<pre-release>"], "dev") == (true, ("dev",), 4)
    @test recognize1(SemVerGrammar["<pre-release>"],"dev.naha.2") == (true, ("dev", "naha", 2), 11)
    @test recognize1(SemVerGrammar["<pre-release>"],"dev.naha-2") == (true, ("dev", "naha-2"), 11)
    @test recognize1(SemVerGrammar["<valid semver>"], "1.2.3-dev.3") ==
        (true, VersionNumber(1, 2, 3, ("dev", 3)), 12)
end

