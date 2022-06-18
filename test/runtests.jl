using AnotherParser
using Test


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
end

@testset "test StringLiteral" begin
    matched, v, i = recognize(StringLiteral("abc"),
                              "abcd") # ; index = 2)
    @test matched == true
    @test i == 4
    @test v == "abc"
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

include("SemVerBNF.jl")
include("test_note_BNFNode_location.jl")

include("../examples/BNF/test_bnf_grammar.jl")

@testset "AnotherParser.jl" begin
    # Write your tests here.
end

