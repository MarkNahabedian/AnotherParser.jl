using AnotherParser

include("arithmetic.jl")

@testset "test left recursive" begin
    @test is_left_recursive(AllGrammars[:LeftRecursiveArithmeticGrammar])
    @test is_left_recursive(AllGrammars[:LeftRecursiveArithmeticGrammar]["<expr>"])
    @test is_left_recursive(AllGrammars[:LeftRecursiveArithmeticGrammar]["<term>"])
    @test !is_left_recursive(AllGrammars[:LeftRecursiveArithmeticGrammar]["<paren-expr>"])
end

@testset "example arithmetic grammar" begin
    @test !is_left_recursive(AllGrammars[:ExampleArithmeticGrammar])
    matched, v, i = recognize(AllGrammars[:ExampleArithmeticGrammar]["<expr>"],
                              "(2+3*(5-1))/2")
    @test matched == true
    @test i == 14
    @test eval(v) == 7.0
end

