# Test against part of the W3C XML conformance test suite as described
# at https://www.w3.org/XML/Test/.

using AnotherParser
include("xml_factory.jl")
include("JuliaComputing_XML_factory.jl")
include("xml.jl")


# Where was the conformance test suite from
# https://www.w3.org/XML/Test/xmlts20130923.zip downloaded?
XML_CONFORMANCE_TEST_ROOT = "/Users/MarkNahabedian/Downloads/xmlconf"

#=
How do we verify that the results of the parse are correct?  What is
the standard to compare to?  Do we need to make a more complete XML
factory than XML.jl supports?

XML.jl just captures the entire DTD as a DTD node with string content
that's the entire DTD.

doc = read("/Users/MarkNahabedian/Downloads/xmlconf/xmltest/valid/sa/001.xml", Node)
doc.children[1]
Node DTD <!DOCTYPE doc [
<!ELEMENT doc (#PCDATA)>
]>

doc.children[1].children        # returns nothing

doc.children[1].value           # returns "doc [\r\n<!ELEMENT doc (#PCDATA)>\r\n]"

This suggests a factory function xmlDTD.
=#

function test_xml_conformance()
    # For now we only consider the standalone validity tests.
    factory = JuliaComputingXMLFactory()
    valid_sa = joinpath(XML_CONFORMANCE_TEST_ROOT, "xmltest/valid/sa")
    mkpath(joinpath(@__DIR__, "conformance_debugging"))
    for xml in readdir(valid_sa)
        xml1 = joinpath(valid_sa, xml)
        test_xml_file(factory, xml1)
    end
end

"""
    test_xml_file(factory, path)

Parses the XML file at `path` using both our XML parserr and the
JuliaComputing XML.jl parser, and compares the results.
"""
function test_xml_file(factory::AbstractXMLFactory, path)
    base, _ = splitext(path)
    report_file= joinpath(@__DIR__, "conformance_debugging", base * ".html")
    println("Parsing $path")
    matched, v, i = debug_parsing(AllGrammars[:XML]["document"],
                                  read(path, String);
                                  context = factory,
                                  enable_debug_logging_for = n -> true,
                                  report_file = report_file)
    if !matched
        println("XML parse failed for $path")
    end
    xmljldoc = read(path, Node)
    # compare_docs(xmljldoc, v)
    compare_nodes(xmljldoc, v)
end

function compare_docs(node1::Node, node2::Node)
    string1 = XML.write(node1)
    string2 = XML.write(node2)
    if string1 != string2
        at = findfirst(collect(zip(string1, string2)) .|> (c -> c[1] != c[2]))
        println("Documents don't match starting at $at\n$string1\n$string2")
    end
end

function compare_nodes(node1::Node, node2::Node)
    mismatch = false
    # Check if node types and data (tag names or text content) match
    if nodetype(node1) != nodetype(node2)
        println(stderr, "compare_nodes: Node type mismatch:\n\t$(nodetype(node1))\n\t$(nodetype(node2))")
        mismatch = true
    end
    if node1.tag != node2.tag
        println(stderr, "compare_nodes: Node tag mismatch:\n\t$(node1.tag)\n\t$(node2.tag)")
        mismatch = true
    end
    if node1.value != node2.value
        println(stderr, "compare_nodes: Node value mismatch:\n\t$(node1.value)\n\t$(node2.value)")
        mismatch = true
    end
    # Check if attributes match (if applicable)    
    if something(node1.attributes, Dict()) != something(node2.attributes, Dict())
        println(stderr, "compare_nodes: Node attributes mismatch:\n\t$(node1.attributes)\n\t$(node2.attributes)")
        mismatch = true
    end
    # Recursively check all children
    kids1 = children(node1)
    kids2 = children(node2)
    if length(kids1) != length(kids2)
        println(stderr, "compare_nodes: child nodecount mismatch:\n\t$(length(kids1))\n\t$(length(kids2))")
        mismatch = true
    else
        for (c1, c2) in zip(kids1, kids2)
            compare_nodes(c1, c2)
        end
    end
    if mismatch
        println("NODE DON'T MATCH\n$node1\n$node2\n")
    end
end


