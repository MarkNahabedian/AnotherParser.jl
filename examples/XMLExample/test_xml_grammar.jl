using XML

@testset "example XML Grammar" begin
    grammar = AllGrammars[:XML]
    factory = JuliaComputingXMLFactory()
    let
        text = "foo"
        matched, v, i = recognize(grammar["Name"], text, context=factory)
        @test matched = true
        @test i == length(text) + 1
        @test v == "foo"
    end
    let
        text = "foo bar baz"
        matched, v, i = recognize(grammar["Names"], text, context=factory)
        @test matched = true
        @test i == length(text) + 1
        @test v == [ "foo", "bar", "baz" ]
    end
    let
        text = "foo bar baz"
        matched, v, i = recognize(grammar["Nmtokens"], text, context=factory)
        @test matched = true
        @test i == length(text) + 1
        @test v == [ "foo", "bar", "baz" ]
    end
    let
        comment_text = " The sixth sick sheik's sixth sheep's sick. "
        xml_text = "<!--$comment_text-->>"
        matched, v, i = recognize(grammar["Comment"],
                                  xml_text;
                                  context=factory)
        @test matched = true
        @test i == length(xml_text)
        @test v == XML.Comment(comment_text)
    end
    #=
    let #  'string'
        matched, v, i = recognize(grammar["String"],
                                  "'string'";
                                  context=factory)
        @test matched = true
        @test i == 9
        @test v == "string"
    end
    let #  "string"
        matched, v, i = recognize(grammar["String"],
                                  "\"string\"";
                                  context=factory)
        @test matched = true
        @test i == 9
        @test v == "string"
    end
    =#
    let
        xml_text = "<foo attr='yowza'>The sixth sick sheik's sixth sheep's sick.</foo>"
        matched, v, i =
            debug_parsing(grammar["element"], xml_text;
                          report_file="yowza.html",
                          enable_debug_logging_for = _ -> true,
                          context=factory)
        @test matched = true
        @test i == length(xml_text) + 1
        expecting = XML.Element("foo",
                                XML.Text("The sixth sick sheik's sixth sheep's sick.");
                                attr="yowza")
        @test XML.write(v) == XML.write(expecting)
    end
end


