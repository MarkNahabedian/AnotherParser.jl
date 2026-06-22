
# Where was the conformance test suite from
# https://www.w3.org/XML/Test/xmlts20130923.zip downloaded?
XML_CONFORMANCE_TEST_ROOT = "/Users/MarkNahabedian/Downloads/xmlconf"

function run_conformance_tests()
    valid_sa = joinpath(XML_CONFORMANCE_TEST_ROOT, "xmltest/valid/sa")
    file_count = 0
    parse_error_count = 0
    parse_failure_count = 0
    mismatch_count = 0
    match_count = 0
    parse_failures = []
    mismatch_failures = []
    @info("Conformatce test diectory", valid_sa)
    for filename in readdir(valid_sa)
        if last(splitext(filename)) == ".xml"
            @info("Parsing", filename)
            file_count += 1
            xml = joinpath(valid_sa, filename)
            xmltext = read_decoded(xml)
            matched, v, i = try
                recognize(AllGrammars[:XML]["document"], xmltext)
            catch e
                @warn("Parse error", e)
                parse_error_count += 1
                push!(parse_failures, filename)
                continue
            end
            if !matched
                @warn("XML parse failed")
                parse_failure_count += 1
                push!(parse_failures, filename)
                continue
            end
            serialized = string(v)
            if xmltext != serialized
                @info("serialized parse doesn't match", xmltext, serialized)
                mismatch_count += 1
                push!(mismatch_failures, filename)
            else
                match_count += 1
            end
        end
    end
    @info("failures", parse_failures, mismatch_failures)
    @info("Conformatnce tests", file_count, parse_error_count,
          parse_failure_count, mismatch_count, match_count)
end

