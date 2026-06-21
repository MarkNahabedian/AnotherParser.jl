using Logging
using VectorLogging

include("node_equivalence.jl")
include("test_nodeeq.jl")

function showingTraces(body, mod::Module, vbl::Symbol, showtraces::Bool)
    if !showtraces
        return body()
    end
    setv(new_value) = Base.eval(mod, :($vbl = $new_value))
    old = Base.eval(mod, vbl)
    logfile = tempname()
    logformat = SerializationLogFileFormat()
    println("***** log file: $logfile")
    # logger = VectorLogger()
    result = nothing
    try
        setv(showtraces)
        FileLogger(logfile, logformat) do logger
            with_logger(logger) do
                @info "Logging."
                result = body()
            end
        end
    finally
        setv(old)
        traces = LogFileReader(logfile, logformat) do logreader
            analyze_traces(logreader)
        end
        println("*****", length(traces))
        for trace in traces
            show_trace(trace)
        end
    end
    result
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
        @test v == 'a'
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
        # loggingReductions() do
        matched, v, i = recognize(grammar["<rule-name>"],
                                  "abcd")
        @test matched == true
        @test i == 5
        @test v == "abcd"
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
        @test nodeeq(v, BNFRef(grammar.name, "<abcd>"))
    end
    let
        matched, v, i = recognize(grammar["<list>"],
                                  "<abcd>";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(grammar.name, "<abcd>"))
    end
    let
        matched, v, i = recognize(grammar["<expression>"],
                                  "<abcd>"; context = :TestGrammar)
        @test matched == true
        @test i == 7
        @test nodeeq(v, BNFRef(grammar.name, "<abcd>"))
    end
    let
        matched, v, i = recognize(grammar["<list>"],
                                  "<abcd> 'efgh' 'i'";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 18
        want = Sequence(BNFRef(:TestGrammar, "<abcd>"),
                        StringLiteral("efgh"),
                        StringLiteral("i"))
        @test nodeeq(v, want)
    end
    let
        matched, v, i = recognize(BNFRef(grammar.name, "<expression>"),
                                  "<a1> | <a2>"; context = :TestGrammar)
        @test matched == true
        @test i == 12
        want = Alternatives(BNFRef(:BootstrapB2NFGrammar, "<a1>"),
                            BNFRef(:Bootstrap3NFGrammar, "<a2>"))
        @test nodeeq(v, want)
    end    
    let
        matched, v, i = recognize(BNFRef(grammar.name, "<expression>"),
                                  "<a1> | <a2> | <a3>";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 19
        want = Alternatives(BNFRef(grammar.name, "<a1>"),
                            BNFRef(grammar.name, "<a2>"),
                            BNFRef(grammar.name, "<a3>"))
        @test nodeeq(v, want)
    end    
    # Trying to hunt down the infinite recursion problem at the end of <rule>.
    # These next two blocks show that the empty tail in <opt-whitespace> is safe.
    let
        matched, v, i = recognize(BNFRef(grammar.name, "<opt-whitespace>"),
                                  "  ";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 3
        @test v== nothing
    end
    let
        matched, v, i = recognize(BNFRef(grammar.name, "<opt-whitespace>"),
                                  "";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 1
        @test v== nothing
    end
    let
        matched, v, i = recognize(BNFRef(grammar.name, "<rule>"),
                                  "<xs> ::= 'x' | 'x' <xs>\n";
                                  context = :TestGrammar)
        @test matched == true
        @test i == 25
        want = DerivationRule(:TestGrammar, "<xs>",
                              Alternatives(StringLiteral("x"),
                                           Sequence(StringLiteral("x"),
                                                    BNFRef(:TestGrammar, "<xs>")));
                              add_to_grammar=false)
        @test nodeeq(v, want)
    end
end


@testset "Test generated BNF grammar" begin
    # Make sure each derivation matches the hand coded grammar.
    ignore_keys = ["<EOL>"]
    bootstrap_grammar = AllGrammars[:BootstrapBNFGrammar]
    bnf_grammar = AllGrammars[:BNF]
    for key in union(keys(bootstrap_grammar.derivations),
                     keys(bnf_grammar.derivations))
        if key in ignore_keys
            continue
        end
        println(key)
        dr1 = bootstrap_grammar[key]
        dr2 = bnf_grammar[key]
        @test nodeeq(dr1, dr2)
    end
end

