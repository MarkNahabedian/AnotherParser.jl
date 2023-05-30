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
    let
        matched, v, i = recognize(EndOfInput(),
                                  "abcd"; index = 1)
        @test matched == false
        @test v == nothing
        @test i == 1
    end
    let
        matched, v, i = recognize(EndOfInput(),
                                  "abcd"; index = 3, finish = 2)
        @test matched == true
        @test v == nothing
        @test i == 3
    end
    let
        matched, v, i = recognize(EndOfInput(),
                                  "abcd"; index = 5)
        @test matched == true
        @test v == nothing
        @test i == 5
    end
end

@testset "test CharacterLiteral" begin
    let
        matched, v, i = recognize(CharacterLiteral('z'),
                                  "abzd"; index = 3)
        @test matched == true
        @test i == 4
        @test v == 'z'
    end
    let
        matched, v, i = recognize(CharacterLiteral('z'),
                                  "abzd"; index = 2)
        @test matched == false
        @test i == 2
    end
    let
        matched, v, i = recognize(CharacterLiteral('z'),
                                  "abzd"; index = 5)
        @test matched == false
        @test i == 5
        #test v == nothing
    end
    let
        matched, v, i = recognize(CharacterLiteral('z'),
                                  "abzd"; index = 4, finish = 3)
        @test matched == false
        @test i == 4
        #test v == nothing
    end
end

@testset "test StringLiteral" begin
    let
        matched, v, i = recognize(StringLiteral("abc"),
                                  "abcd")
        @test matched == true
        @test i == 4
        @test v == "abc"
    end
    let
        matched, v, i = recognize(StringLiteral("abc"),
                                  "abcd"; index = 2)
        @test matched == false
        @test i == 2
        @test v == nothing
    end
    let
        matched, v, i = recognize(StringLiteral("bcd"),
                                  "abcd"; index = 2, finish = 3)
        @test matched == false
        @test i == 2
        @test v == nothing
    end
    let
        matched, v, i = recognize(StringLiteral(""),
                                  "abcd")
        @test matched == true
        @test i == 1
        @test v == ""
    end
    #=
    let
        # Empty string should not match if input is exhausted:
        r = recognize(StringLiteral(""),
                      "abcd"; index=5)
        matched, v, i = recognize(StringLiteral(""),
                                  "abcd"; index=5)
        @test matched == false
        @test i == 5
        @test v == nothing
    end
    =#
end

@testset "test RegexNode" begin
    matched, v, i = recognize(RegexNode(r"[a-z]+"), "abcd123"; index = 2)
    @test matched == true
    @test i == 5
    @test v.match == "bcd"
end

@testset "test RegexNode" begin
    matched, v, i = recognize(RegexNode(r"[a-z]+"), "abcd123"; index = 2)
    @test matched == true
    @test i == 5
    @test v.match == "bcd"
end

@testset "test Sequence" begin
    let
        matched, v, i = recognize(Sequence(CharacterLiteral('a'),
                                           CharacterLiteral('b'),
                                           CharacterLiteral('c')),
                                  "abcd")
        @test matched == true
        @test v == ['a', 'b', 'c']
        @test i == 4
    end
    let
        matched, v, i = recognize(Sequence(CharacterLiteral('a'),
                                           CharacterLiteral('b'),
                                           CharacterLiteral('c')),
                                  "aBcd")
        @test matched == false
        @test v == nothing
        @test i == 1
    end
end

@testset "test Alternatives" begin
    let
        matched, v, i = recognize(Alternatives(CharacterLiteral('a'),
                                               CharacterLiteral('b'),
                                               CharacterLiteral('c')),
                                 "abcd")
        @test matched == true
        @test v == 'a'
        @test i == 2
    end
    let
        matched, v, i = recognize(Alternatives(CharacterLiteral('a'),
                                               CharacterLiteral('b'),
                                               CharacterLiteral('c')),
                                 "Abcd")
        @test matched == false
        @test v == nothing
        @test i == 1
    end
end

@testset "test Repeat" begin
    let
        matched, v, i = recognize(Repeat(CharacterLiteral('a')),
                                  "")
        @test matched == true
        @test v == []
        @test i == 1
    end
    let
        matched, v, i = recognize(Repeat(CharacterLiteral('a'); min=1),
                                  "")
        @test matched == false
        @test v == nothing
        @test i == 1
    end
    let
        matched, v, i = recognize(Repeat(CharacterLiteral('a')),
                                  "aaab")
        @test matched == true
        @test v == ['a', 'a', 'a']
        @test i == 4
    end
    let
        matched, v, i = recognize(Repeat(CharacterLiteral('a'); max=2),
                                  "aaab")
        @test matched == true
        @test v == ['a', 'a']
        @test i == 3
    end
end

include("SemVerBNF.jl")
include("test_note_BNFNode_location.jl")

# include("../examples/BNF/test_bnf_grammar.jl")
