using Logging
using VectorLogging
using NahaJuliaLib

include("node_equivalence.jl")
include("test_nodeeq.jl")

function showingTraces(body, mod::Module, vbl::Symbol, show::Bool)
    setv(new_value) = Base.eval(mod, :($vbl = $new_value))
    old = Base.eval(mod, vbl)
    logger = VectorLogger()
    result = nothing
    try
        setv(show)
        with_logger(logger) do
            result = body()
        end
    finally
        setv(old)
        traces = analyze_traces(logger)
        for trace in traces
            show_trace(trace)
        end
    end
    result
end


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

BNFGrammar(:TestGrammar)

@testset "Test hand coded BNF grammar" begin
    grammar = AllGrammars[:BootstrapBNFGrammar]
    let
        matched, v, i = recognize(grammar["<character1>"], "abcd")
        @test matched = true
        @test v == "a"
        @test i== 2
    end
    let
        matched, v, i = recognize(grammar["<literal>"],
                                  "'abcd'")
        @test matched == true
        @test i == 7
        @test v isa StringLiteral
        @test v.str == "abcd"
    end
    let
        matched, v, i = recognize(grammar["<rule-name>"],
                                  "abcd ")
        @test matched == true
        @test i == 5
        @test v == "abcd"
    end
    let
        showingTraces(AnotherParser, :trace_recognize, false) do
            # loggingReductions() do
            matched, v, i = recognize(grammar["<rule-name>"],
                                      "abcd")
            @test matched == true
            @test i == 5
            @test v == "abcd"
        end
    end
    let
        matched, v, i = recognize(grammar["<term>"],
                                  "'abcd'")
        @test matched == true
        @test i == 7
        @test v isa StringLiteral
        @test v.str == "abcd"        
    end
    let
        matched, v, i = recognize(grammar["<term>"],
                                  "<abcd>";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(:BootstrapBNFGrammar, "<abcd>"))
    end
    let
        matched, v, i = recognize(grammar["<list>"],
                                  "<abcd>";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(:BootstrapBNFGrammar, "<abcd>"))
    end
    let
        matched, v, i = recognize(grammar["<expression>"],
                                  "<abcd>"; context = :TestGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(:BootstrapBNFGrammar, "<abcd>"))
    end
    let
        matched, v, i = recognize(grammar["<list>"],
                                  "<abcd> 'efgh' 'i'";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 18
        want = Sequence(BNFRef(:BootstrapBNFGrammar, "<abcd>"),
                        StringLiteral("efgh"),
                        StringLiteral("i"))
        @test nodeeq(v, want)
    end
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<expression>"),
                                  "<a1> | <a2>"; context = :TestGrammar)
        @test matched == true
        @test i == 12
        want = Alternatives(BNFRef(:BootstrapB2NFGrammar, "<a1>"),
                            BNFRef(:Bootstrap3NFGrammar, "<a2>"))
        @test nodeeq(v, want)
    end    
    let
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<expression>"),
                                  "<a1> | <a2> | <a3>";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 19
        want = Alternatives(BNFRef(:BootstrapBNFGrammar, "<a1>"),
                            BNFRef(:BootstrapBNFGrammar, "<a2>"),
                            BNFRef(:BootstrapBNFGrammar, "<a3>"))
        @test nodeeq(v, want)
    end    
    # Trying to hunt down the infinite recursion problem at the end of <rule>.
    # These next two blocks show that the empty tail in <opt-whitespace> is safe.
    let
        showingTraces(AnotherParser, :trace_recognize, false) do
            matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<opt-whitespace>"),
                                      "  ";
                                      context = :TestGrammar)
            @test matched == true
            @test i == 3
            @test v== nothing
        end
    end
    let
        @info("<opt-whitespace> empty")
        matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<opt-whitespace>"),
                                  "";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 1
        @test v== nothing
    end
#= STACK OVERFLOW:
    let
        @info("<opt-rule>")
        # loggingReductions() do
            matched, v, i = recognize(BNFRef(:BootstrapBNFGrammar, "<rule>"),
                                      "<xs> ::= 'x' | 'x' <xs>\n";
                                      context = :TestGrammar)
        # end
        @test matched == true
        @test i == 24
        want = DerivationRule(:TestGrammar, "<xs>",
                              Alternatives(StringLiteral("x"),
                                           Sequence(StringLiteral("x"),
                                                    BNFRef(:TestGrammar, "<xs>"))))
        @test nodeeq(v, want)
    end
=#
end

