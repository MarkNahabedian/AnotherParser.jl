using AnotherParser
using AnotherParser: exhausted
using Test

@testset "Test exhausted" begin
    @test exhausted("12345", 5, 6) == false
    @test exhausted("12345", 6, 7) == true
    @test exhausted("12345", 3, 4) == false
    @test exhausted("12345", 5, 4) == true
end

@testset "test EndOfInput" begin
    node = EndOfInput()
    let
        p = Parser()
        matched, v, i = recognize(node, "abcd";
                                  index = 1, parser = p)
        @test matched == false
        @test v == nothing
        @test i == 1
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(1, node, "input not exhausted")
        ])
    end
    let
        p = Parser()
        matched, v, i = recognize(node, "abcd";
                                  index = 3, finish = 2, parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == nothing
        @test i == 3
    end
    let
        p = Parser()
        matched, v, i = recognize(node, "abcd";
                                  parser = p, index = 5)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == nothing
        @test i == 5
    end
end

@testset "test CharacterLiteral" begin
    let
        p = Parser()
        matched, v, i = recognize(CharacterLiteral('z'), "abzd";
                                  parser = p, index = 3)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 4
        @test v == 'z'
    end
    let
        p = Parser()
        node = CharacterLiteral('z')
        matched, v, i = recognize(node, "abzd"; index = 2, parser = p)
        @test matched == false
        @test i == 2
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(2, node, "b doesn't match 'z'")
        ])
    end
    let
        p = Parser()
        node = CharacterLiteral('z')
        matched, v, i = recognize(node, "abzd"; index = 5, parser = p)
        @test matched == false
        @test i == 5
        @test v == nothing
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(5, node, "input exhausted")
        ])
    end
    let
        p = Parser()
        node = CharacterLiteral('z')
        matched, v, i = recognize(node, "abzd"; index = 4, finish = 3,
                                  parser = p)
        @test matched == false
        @test i == 4
        @test v == nothing
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(4, node, "input exhausted")
        ])
    end
end

@testset "test CharacterInSet" begin
    let
        p = Parser()
        matched, v, i = recognize(CharacterInSet(['a', 'y', 'z']),
                                  "abzd"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 2
        @test v == 'a'
    end
    let
        p = Parser()
        node = CharacterInSet(['a', 'b', 'c'])
        matched, v, i = recognize(node, "zbcd"; parser = p)
        @test matched == false
        @test i == 1
        @test v == nothing
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(1, node, "z not in character set")
        ])
    end
end

@testset "test CharacterSatisfiesPredicate" begin
    predicate = c -> c in "abc"
    node = CharacterSatisfiesPredicate(predicate)
    let
        p = Parser()
        matched, v, i = recognize(node, "abcd"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 2
        @test v == 'a'        
    end
    let
        p = Parser()
        matched, v, i = recognize(node, "zbcd"; parser = p)
        @test matched == false
        @test i == 1
        @test v == nothing
        @test p.parse_failures == Set{
            ParseFailure}([
                ParseFailure(1, node, "z doesn't satisfy predicate")
            ])
    end
end

@testset "test StringLiteral" begin
    let
        p = Parser()
        matched, v, i = recognize(StringLiteral(""), "abcd";
                                  parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == ""
        @test i == 1
    end
    let
        p = Parser()
        matched, v, i = recognize(StringLiteral("abc"), "abcd";
                                  parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 4
        @test v == "abc"
    end
    let
        p = Parser()
        node = StringLiteral("abc")
        matched, v, i = recognize(node, "abcd"; parser = p, index = 2)
        @test matched == false
        @test i == 2
        @test v == nothing
        @test p.parse_failures == Set{
            ParseFailure}([
                ParseFailure(2, node, "no match")
            ])
    end
    let
        p = Parser()
        node = StringLiteral("bcd")
        matched, v, i = recognize(node, "abcd";
                                  parser = p, index = 2, finish = 3)
        @test matched == false
        @test i == 2
        @test v == nothing
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(2, node, "end of string to match exceeds 3")
        ])
    end
    let
        p = Parser()
        matched, v, i = recognize(Sequence(StringLiteral("bcd"),
                                           StringLiteral("efg")),
                                  "abcdefghi"; index = 2, finish = 7,
                                  parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 8
        @test v == ["bcd", "efg"]
    end
    # Test when there are larger characters encoded in Julia's
    # standard UTF-8:
    let
        input = "abcd" * Char(0x1F4A9) * "efghi"
        seek = SubString(input, 1, 9)
        p = Parser()
        matched, v, i = recognize(StringLiteral(seek), input; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 10
        @test v == seek
        matched, v, i = recognize(StringLiteral("fghi"), input; index = i)
        @test matched == true
        @test i == 14
        @test v == "fghi"
    end
end

@testset "test RegexNode" begin
    let
        p = Parser()
        matched, v, i = recognize(RegexNode(r"[a-z]+"), "abcd123";
                                  parser = p, index = 2)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test i == 5
        @test v.match == "bcd"
    end
    let
        @info "RegexNode 2"
        p = Parser()
        node = RegexNode(r"[a-z]+")
        matched, v, i = recognize(node, "a1bcd123";
                                  parser = p, index = 2)
        @test matched == false
        @test i == 2
        @test v == nothing
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(2, node, "match starts at 3 not at 2")
        ])
    end
end

@testset "test Sequence" begin
    let
        p = Parser()
        matched, v, i = recognize(Sequence(CharacterLiteral('a'),
                                           CharacterLiteral('b'),
                                           CharacterLiteral('c')),
                                  "abcd"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == ['a', 'b', 'c']
        @test i == 4
    end
    let
        p = Parser()
        node = Sequence(CharacterLiteral('a'),
                        CharacterLiteral('b'),
                        CharacterLiteral('c'))
        matched, v, i = recognize(node, "aBcd"; parser = p)
        @test matched == false
        @test v == nothing
        @test i == 1
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(2, node.elements[2], "B doesn't match 'b'")
        ])
    end
end

@testset "test Alternatives" begin
    let
        p = Parser()
        matched, v, i = recognize(Alternatives(CharacterLiteral('a'),
                                               CharacterLiteral('b'),
                                               CharacterLiteral('c')),
                                 "abcd"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == 'a'
        @test i == 2
    end
    let
        @info "Alternatives 2"
        p = Parser()
        cla = CharacterLiteral('a')
        clb = CharacterLiteral('b')
        clc = CharacterLiteral('c')
        node = Alternatives(cla, clb, clc)
        matched, v, i = recognize(node, "Abcd"; parser = p)
        @test matched == false
        @test v == nothing
        @test i == 1
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(1, cla, "A doesn't match 'a'"),
            ParseFailure(1, clb, "A doesn't match 'b'"),
            ParseFailure(1, clc, "A doesn't match 'c'")
        ])
    end
end

@testset "test Repeat" begin
    let
        p = Parser()
        matched, v, i = recognize(Repeat(CharacterLiteral('a')),
                                  ""; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == []
        @test i == 1
    end
    let
        p = Parser()
        node = Repeat(CharacterLiteral('a'); min=1)
        matched, v, i = recognize(node, ""; parser = p)
        @test matched == false
        @test v == nothing
        @test i == 1
        @test p.parse_failures == Set{ParseFailure}([
            ParseFailure(1, node, "only 0 matches, < 1"),
            ParseFailure(1, node.node, "input exhausted")
        ])
    end
    let
        p = Parser()
        matched, v, i = recognize(Repeat(CharacterLiteral('a')),
                                  "aaa"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == ['a', 'a', 'a']
        @test i == 4
    end
    let
        p = Parser()
        matched, v, i = recognize(Repeat(CharacterLiteral('a')),
                                  "aaab"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == ['a', 'a', 'a']
        @test i == 4
    end
    let
        p = Parser()
        matched, v, i = recognize(Repeat(CharacterLiteral('a'); max=2),
                                  "aaab"; parser = p)
        if !matched
            @warn("parse_failed", p.parse_failures)
        end
        @test matched == true
        @test v == ['a', 'a']
        @test i == 3
    end
end


#=
Not yet tested above:

 BNFRef
 Constructor
 DerivationRule
 Empty
 Excluding

=#


include("test_note_BNFNode_location.jl")


# Test example grammars:

using Pkg

include("../examples/SemVer/test_SemVerBNF.jl")

Pkg.develop(path="../examples/BNFExample")
Pkg.test("BNFExample")

include("../examples/Arithmetic/test_arithmetic_grammar.jl")

Pkg.develop(path="../examples/XMLExample")
Pkg.test("XMLExample")

