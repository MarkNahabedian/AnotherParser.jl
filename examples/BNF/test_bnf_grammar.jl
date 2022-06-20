using Logging
using VectorLogging
using NahaJuliaLib

include("node_equivalence.jl")
include("test_nodeeq.jl")

@testset "test flatten_to_string" begin
    @test flatten_to_string(["abc", 'd', ["e", ['f', 'g', ['h'], 'i'], 'j']]) ==
        "abcdefghij"
end

@testset "Recognize empty Sequence" begin
    @test recognize(Sequence(), "abcd") == (true, [], 1)
    @test recognize(CharacterLiteral('a'), "ab") == (true, 'a', 2)
    @test recognize(Alternatives(CharacterLiteral('a')), "bb") == (false, nothing, 1)
    @test recognize(Alternatives(CharacterLiteral('a')), "ab") == (true, 'a', 2)
    @test recognize(Alternatives(Empty(), CharacterLiteral('a')),
                    "bb") == (true, nothing, 1)
    @test recognize(Alternatives(Empty(),
                                 CharacterLiteral('a')), "ab") == (true, 'a', 2)
end

@testset "Test hand coded BNF grammar" begin
    @test recognize(BNFRef(:BootstrapBNFGrammar, "<character1>"), "abcd") ==
        (true, 'a', 2)
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<literal>"),
                                  "'abcd'")
        @test matched == true
        @test i == 7
        @test v isa StringLiteral
        @test v.str == "abcd"
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<rule-name>"),
                                  "abcd")
        @test matched == true
        @test i == 5
        @test nodeeq(v, "abcd")
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<term>"),
                                  "'abcd'")
        @test matched == true
        @test i == 7
        @test v isa StringLiteral
        @test v.str == "abcd"        
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<term>"),
                                  "<abcd>"; context = :BootstrapBNFGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(:BootstrapBNFGrammar, "<abcd>"))
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<list>"),
                                  "<abcd>"; context = :BootstrapBNFGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(:BootstrapBNFGrammar, "<abcd>"))
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<expression>"),
                                  "<abcd>"; context = :BootstrapBNFGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(:BootstrapBNFGrammar, "<abcd>"))
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<list>"),
                                  "<abcd> 'efgh' 'i'"; context = :BootstrapBNFGrammar)
        @test matched == true
        @test i == 18
        want = Sequence(BNFRef(:BootstrapBNFGrammar, "<abcd>"),
                        StringLiteral("efgh"),
                        StringLiteral("i"))
        @test nodeeq(v, want)
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<expression>"),
                                  "<a1> | <a2>"; context = :BootstrapBNFGrammar)
        @test matched == true
        @test i == 12
        want = Alternatives(BNFRef(:BootstrapB2NFGrammar, "<a1>"),
                            BNFRef(:Bootstrap3NFGrammar, "<a2>"))
        @test nodeeq(v, want)
    end    
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<expression>"),
                                  "<a1> | <a2> | <a3>"; context = :BootstrapBNFGrammar)
        @test matched == true
        @test i == 19
        want = Alternatives(BNFRef(:BootstrapBNFGrammar, "<a1>"),
                            BNFRef(:BootstrapBNFGrammar, "<a2>"),
                            BNFRef(:BootstrapBNFGrammar, "<a3>"))
        @test nodeeq(v, want)
    end    
    
    #=
    logger = VectorLogger()
    @eval(AnotherParser, trace_recognize = true)
    @test AnotherParser.trace_recognize == true
    with_logger(logger) do
        try
            r = recognize(BNFRef(:BootstrapBNFGrammar, "<literal>"),
                          "'abcd'")
            @test r == (true, "abcd", 7)
        finally
            @test length(logger.log) > 0
            show_trace(analyze_traces(logger)[1])
        end
    end
    =#
end

