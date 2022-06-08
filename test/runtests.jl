using AnotherParser
using Test

@testset "test StringLiteral" begin
    matched, v, i = recognize(StringLiteral("abc"),
                              "abcd") # ; index = 2)
    @test matched == true
    @test i == 4
    @test v == "abc"
end

include("SemVerBNF.jl")
include("test_note_BNFNode_location.jl")

include("../examples/BNF/test_bnf_grammar.jl")

@testset "AnotherParser.jl" begin
    # Write your tests here.
end

