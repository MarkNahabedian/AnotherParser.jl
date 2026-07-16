
using AnotherParser
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
    p = Parser()
    matched, v, i = recognize1(AllGrammars[:XML]["document"], xmltext; parser = p)
    #=
    # Why does switching to debug_parsing cause unit test failures?
    matched, v, i = debug_parsing(AllGrammars[:XML], "document", xmltext;
                                  parser = p,
                                  report_file = debug_file,
                                  enable_debug_logging_for = x -> true)
    =#
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

