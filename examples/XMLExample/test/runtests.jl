
using AnotherParser
using AnotherParser: parse
using XMLExample
using Test
using Glob: glob

include("cst_unit_tests.jl")

include("zip_file_doenload.jl")
ensure_w3c_test_files()

index_grammars()

@testset "test $(relpath(xml, XML_CONFORMANCE_TEST_ROOT))" for xml in glob(
    joinpath(XML_CONFORMANCE_TEST_ROOT,
             "xmlconf/xmltest/valid/sa/*.xml"))
    testnum = splitext(basename(xml))[1]
    debug_file = joinpath(@__DIR__, "debug", testnum * ".html")
    mkpath(joinpath(@__DIR__, "debug"))
    xmltext = read_decoded(xml)
    grammar = AllGrammars[:XML]
    p = Parser()
    note_nodes_to_debug(p, grammar, _ -> true)
    matched, v, i = parse(grammar["document"], xmltext;
                                  parser = p, report_file = debug_file)
    if matched == false
        @info("Parse failures",
              testnum,
              failures = [ string(pf)
                           for pf in p.parse_failures ])
    end
    @test matched == true
    serialized = string(v)
    if xmltext != serialized
        @info("XML parse",
              testnum,
              input = xmltext,
              output = v,
              serialized)
    end
    @test xmltext == serialized
end

