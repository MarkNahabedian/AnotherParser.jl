
using AnotherParser
using XMLExample
using Test
using Glob: glob

include("cst_unit_tests.jl")

include("zip_file_doenload.jl")
ensure_w3c_test_files()

@testset "test $(relpath(xml, XML_CONFORMANCE_TEST_ROOT))" for xml in glob(
    joinpath(XML_CONFORMANCE_TEST_ROOT,
             "xmlconf/xmltest/valid/sa/*.xml"))
    xmltext = read_decoded(xml)
    matched, v, i = recognize(AllGrammars[:XML]["document"], xmltext)
    @test matched == true
    serialized = string(v)
    @test xmltext == serialized
end

