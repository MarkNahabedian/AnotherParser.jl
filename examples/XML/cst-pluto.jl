### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ 02a5daca-56f4-4da2-abce-450005238b31
begin
    using Pkg
    Pkg.activate(dirname(dirname(@__DIR__)))
    using AnotherParser
end

# ╔═╡ 1e9c0f53-6cad-4e35-8868-15374f528f32
using Markdown

# ╔═╡ eaf455d3-fa8d-4d67-9b98-09f34daaad1a
include(joinpath(@__DIR__, "../../examples/XML/xml.jl"))

# ╔═╡ 60d1e8e8-6837-11f1-85a8-b7dded61141e
abstract type CSTNode end

# ╔═╡ 13ce8946-2c9c-4177-8f1b-4693f0d922b7
begin
    mutable struct CSTWhitespace <: CSTNode
        # In the CST we allof for text to be empty to deal with all of the
        # cases where "S" production is optional.  That way we don't need
        # to do tests against `nothing`.
        text::AbstractString
        is_ignorable::Bool

        CSTWhitespace(text::AbstractString, is_ignorable::Bool) = new(text, is_ignorable)

        CSTWhitespace(text::AbstractString) = new(text, false)
    end

    Base.print(io::IO, n::CSTWhitespace) = print(io, n.text)
end

# ╔═╡ c1defcdb-f1c6-46ec-a704-922f23ecb893
begin
    mutable struct CSTName <: CSTNode
        name::AbstractString
        namespace_uri::Union{Nothing, AbstractString}

        CSTName(name::AbstractString) = new(name, nothing)
        CSTName(name::AbstractString, namespace_uri) = new(name, namespace_uri)
    end

    Base.print(io::IO, n::CSTName) = print(io, n.name)
    Base.print(io::IO, n::Vector{CSTName}) = print(io, join(n, " "))

    function prefix(name::CSTName)
        s = split(name.name, ':')
        if length(s) == 1
            ""
        elseif length(s) == 2
            s[1]
        else
            error("Name $(name.name) contains more than a single colon.")
        end
    end

    function local_name(name::CSTName)
        s = split(name.name, ':')
        if length(s) == 1
            s[1]
        elseif length(s) == 2
            s[2]
        else
            error("Name $(name.name) contains more than a single colon.")
        end
    end
end

# ╔═╡ 217ce513-3edd-4205-a7b3-204892bdb462
begin
    struct CSTCharData <: CSTNode
        text::AbstractString
        is_cdata::Bool
    end

    function Base.print(io::IO, n::CSTCharData)
        if n.is_cdata
            print(io, "<![CDATA[")
            print(io, n.text)
            print(io, "]]>")
        else
            print(io, n.text)
        end
    end

end

# ╔═╡ 591484d6-3889-4c6e-a694-8a19d5b81463
begin
    struct CSTComment <: CSTNode
        text::AbstractString
    end

    function Base.print(io::IO, n::CSTComment)
        print(io, "<!--")
        print(io, n.text)
        print(io, "-->")
    end

end

# ╔═╡ 925c0ebb-ae44-4684-8577-e8c98c0f3493
begin
    struct CSTProcessingInstruction <: CSTNode
        target::CSTName
        text::AbstractString
    end

    function Base.print(io::IO, n::CSTProcessingInstruction)
        print(io, "<?")
        print(io, n.target)
        print(io, n.text)
        print(io, "?>")
    end
end

# ╔═╡ 58ab2a93-4201-4af5-87a3-1cbe1ad4b566
begin
    struct CSTEntityRef <: CSTNode
        name::CSTName
    end

    Base.print(io::IO, n::CSTEntityRef) = print(io, "&$(n.name);")

end

# ╔═╡ 30e22a04-7526-4066-85c6-a66e52266159
begin
    struct CSTPEReference <: CSTNode
        name::CSTName
    end

    Base.print(io::IO, n::CSTPEReference) = print(io, "%$(n.name);")

end


# ╔═╡ 09880878-e618-4399-b282-e28482e4d5a2
begin
    struct CSTCharRef <: CSTNode
        str::AbstractString
    end

    Base.print(io::IO, n::CSTCharRef) = print(io, "&#$(n.str);")

    function Base.codepoint(c::CSTCharRef)
        base = 10
        codestart = 1
        if c.str[1] == 'x'
            base = 16
            codestart = 2
        end
        code = parse(c.str[codestart:end]; base=base)
    end

    Base.Char(c::CSTCharRef) = Char(codepoint(c))
end

# ╔═╡ 718e0ae3-93af-48e7-9a73-b0ed014327b0
begin
    const CSTAttValueFragment = Union{
        CSTEntityRef,
        CSTCharRef,
        AbstractString
    }

    mutable struct CSTAttValue <: CSTNode
        value::Vector{CSTAttValueFragment}   # entity refeerence character reference or text not containing < & " '
        quotechar::Char
    end

    function Base.print(io::IO, n::CSTAttValue)
        print(io, n.quotechar)
        for n1 in n.value
            print(io, n1)
        end
        print(io, n.quotechar)
    end

    mutable struct CSTAttribute <: CSTNode
        name::CSTName
        value::CSTAttValue
        preceeding_whitespace::CSTWhitespace

        CSTAttribute(name::CSTName, value::CSTAttValue,
                     preceeding_whitespace::CSTWhitespace) =
            new(name, value, preceeding_whitespace)

        CSTAttribute(name::CSTName, value::CSTAttValue) =
            new(name, value, CSTWhitespace(""))
    end

    function Base.print(io::IO, n::CSTAttribute)
        print(io, "$(n.name)=$(n.value)")
    end

    function Base.print(io::IO, attributes::Vector{CSTAttribute})
        for a in attributes
            print(io, a.preceeding_whitespace, a)
        end
    end

end

# ╔═╡ 96034286-77f3-47c5-b4d4-f702e5107293
begin
    struct CSTEq  <: CSTNode
        preceeding_whitespace::CSTWhitespace
        trailing_whitespace::CSTWhitespace
    end

    Base.print(io::IO, n::CSTEq) = 
        print(io, n.preceeding_whitespace, "=", n.trailing_whitespace)

end

# ╔═╡ 4d27c051-3a71-415b-bf01-6a7e996683ae
begin
    # VersionInfo, EncodingDecl and SDDecl all have the same form and
    # there's no reason to have separate models for them.

    struct CSTDeclAttr <: CSTNode
        preceeding_whitespace::CSTWhitespace
        name::AbstractString
        eq::CSTEq
        quotechar::Char
        version::AbstractString
    end

    function Base.print(io::IO, n::CSTDeclAttr)
        print(io, n.preceeding_whitespace, n.name, n.eq,
              n.quotechar, n.version, n.quotechar)
    end

end

# ╔═╡ df9150cf-869e-485f-ab04-87729e412535
begin
    mutable struct CSTXMLDecl <: CSTNode
        attributes::Vector{CSTDeclAttr}
        trailing_whitespace::CSTWhitespace

        CSTXMLDecl(attrs, wsp) = new(attrs, wsp)
        CSTXMLDecl(attrs) = new(attrs, CSTWhitespace(""))
    end

    function Base.print(io::IO, n::CSTXMLDecl)
        print(io, "<?xml", join(n.attributes, ""),
              n.trailing_whitespace,
              "?>")
    end

end

# ╔═╡ 2758f98f-cdc0-4c73-b15e-92e2e7a6f729
begin
    mutable struct CSTElement <: CSTNode
        tag::CSTName
        attributes::Vector{CSTAttribute}
		start_tag_trailing_whitespace::Vector{CSTWhitespace}
        content::Vector{Union{AbstractString, CSTNode}}
		end_tag_trailing_whitespace::Vector{CSTWhitespace}
        isempty::Bool
    end

    function Base.print(io::IO, n::CSTElement)
        if n.isempty
            print(io, "<", n.tag, n.attributes,
				  n.start_tag_trailing_whitespace...,
				  "/>")
        else
            print(io, "<", n.tag, n.attributes, ">",
                  n.content...,
                  "</", n.tag,
				  n.end_tag_trailing_whitespace...,
				  ">")
        end
    end

end

# ╔═╡ 8b1facc1-2959-44e4-b28f-f5c60d21a960
begin
    struct CSTExtIdSystem <: CSTNode
        whitespace1::CSTWhitespace
        system_literal::AbstractString
    end

    Base.print(io::IO, n::CSTExtIdSystem) =
        print(io, "SYSTEM", n.whitespace1, n.system_literal)

    struct CSTExtIdPublic <: CSTNode
        whitespace1::CSTWhitespace
        public_literal::AbstractString
        whitespace2::CSTWhitespace
        system_literal::AbstractString
    end

end

# ╔═╡ d5f3c788-bdcb-495b-9b1f-c33ecfeeb323
begin
    struct CSTNDataDecl <: CSTNode
        whitespace1::CSTWhitespace
        name::CSTName
    end

    Base.print(io::IO, n::CSTNDataDecl) =
        print(io, n.whitespace1, n.name)

end

# ╔═╡ 11e7d6e4-1799-44de-b014-fa9210cc9305
Base.print(io::IO, n::CSTExtIdPublic) =
    print(io, "PUBLIC", n.whitespace1, n.public_literal,
          n.whitespace2, n.system_literal)

# ╔═╡ cb43accd-e2c5-48e3-8331-6ea62a00a237
begin
    
    struct CSTElementDecl <: CSTNode
        whitespace1::CSTWhitespace
        name::CSTName
        whitespace2::CSTWhitespace
        contentspec::AbstractString
        whitespace3::CSTWhitespace
    end

    Base.print(io::IO, n::CSTElementDecl) =
        print(io, "<!ELEMENT", n.whitespace1, n.name,
              n.whitespace2, n.contentspec,
              n.whitespace3, '>')

end

# ╔═╡ 064ad685-660e-4030-906b-cc5f889cad65
begin
    struct CSTAttDef  <: CSTNode
        whitespace1::CSTWhitespace
        name::CSTName
        whitespace2::CSTWhitespace
        atttype::AbstractString
        whitespace3::CSTWhitespace
        DefaultDecl::AbstractString
    end

    Base.print(io::IO, n::CSTAttDef) =
        print(io, n.whitespace1, n.name, n.whitespace2, n.atttype,
              n.whitespace3, n.DefaultDecl)

    struct CSTAttlistDecl <: CSTNode
        whitespace1::CSTWhitespace
        name::CSTName
        attdefs::Vector{CSTAttDef}
        whitespace2::CSTWhitespace
    end

    Base.print(io::IO, n::CSTAttlistDecl) =
        print(io, "<!ATTLIST", n.whitespace1, n.name, n.attdefs...,
              n.whitespace2, ">")

end

# ╔═╡ 33bcb770-9e87-4925-922a-eae88b8536ba
const CSTReference = Union{CSTEntityRef, CSTCharRef}

# ╔═╡ 395327b7-dcfd-4b98-8e99-80fbe34e0e67
begin
    struct CSTEntityValue <: CSTNode
        quotechar::Char
        elements::Vector{Union{AbstractString, CSTPEReference, CSTReference}}
    end

    Base.print(io::IO, n::CSTEntityValue) =
        print(io, n.quotechar, n.elements..., n.quotechar)

    struct CSTPEDecl <: CSTNode
        whitespace1::CSTWhitespace
        whitespace2::CSTWhitespace
        name::CSTName
        whitespace3::CSTWhitespace
        pedef    # ::CSTPEDef
        whitespace4::CSTWhitespace
    end

    Base.print(io::IO, n::CSTPEDecl) =
        print(io, "<!ENTITY", n.whitespace1, "%", n.whitespace2, n.name,
              n.whitespace3,
              n.pedef,
              n.whitespace4, ">")

end

# ╔═╡ c2dae9f6-4409-4435-9784-b5e24c590abd
const CSTMisc = Union{CSTComment,
                      CSTProcessingInstruction,
                      CSTWhitespace}


# ╔═╡ d8233096-0669-4d96-9067-79f024ec89b5
begin
    struct CSTProlog <: CSTNode
        xmldecl::Vector{CSTXMLDecl}
        misc  # ::Vector{CSTMisc}
        dtd
		
		function CSTProlog(xmldecl, misc, dtd)
			@assert all(x -> x isa CSTMisc, misc)
			#= @assert(all(dtd) do x
				(x isa Tuple) &&
					(x[1] isa CSTExternalId) &&
						(x[2] isa Vector{CSTMisc})
			end, dtd) =#
			new(xmldecl, misc, dtd)
		end
    end

    function Base.print(io::IO, n::CSTProlog)
        print(io, n.xmldecl..., n.misc...)
        for x in n.dtd
            print(io, x[1], x[2]...)
        end
    end
end

# ╔═╡ e6843b8c-75d5-405d-8c3e-6f033fa67fb0
begin
    struct CSTDocument <: CSTNode
        prolog::CSTProlog
        root::CSTElement
        misc  # ::Vector{CSTMisc}
    end

    Base.print(io::IO, n::CSTDocument) =
        print(io, n.prolog, n.root, n.misc...)

end

# ╔═╡ b092cc49-9a3e-407e-9581-097c59d17beb
const CSTExternalId = Union{CSTExtIdSystem,
                            CSTExtIdPublic}


# ╔═╡ bda9fa7e-5796-4c8b-983b-b59f51347243
begin
    struct CSTPublicID <: CSTNode
        whitespace1::CSTWhitespace
        literal::AbstractString
    end

    Base.print(io::IO, n::CSTPublicID) =
        print(io, "PUBLIC", n.whitespace1, n.literal)

    struct CSTNotationDecl <: CSTNode
        whitespace1::CSTWhitespace
        name::CSTName
        whitespace2::CSTWhitespace
        id::Union{CSTExternalId, CSTPublicID}
        whitespace3::CSTWhitespace
    end

    Base.print(io::IO, n::CSTNotationDecl) =
        print(io, "<!NOTATION", n.whitespace1, n.name,
              n.whitespace2, n.id, '>')

end

# ╔═╡ 856c098d-b6f9-4fbd-9125-d525d88ba854
const CSTPEDef = Union{CSTEntityValue,
                       CSTExternalId}


# ╔═╡ c763d5ab-dc90-477b-a9b3-c1ae15dc1970
const CSTEntityDef = Union{CSTEntityValue,
                           CSTExternalId,
                           CSTNDataDecl}


# ╔═╡ 58ebea76-b1d9-45d8-a9a3-ffcb9390a19a
function test_round_trip(rulename, input)
    matches, value, i = recognize(AllGrammars[:XML][rulename], input)
    got = string(value)
    @assert input == got "$input == $got"
end


# ╔═╡ 29a6a54a-553b-4220-bbfc-27aa1815b0fb
struct CSTGEDecl <: CSTNode
    whitespace1::CSTWhitespace
    name::CSTName
    whitespace2::CSTWhitespace
    entity_def::CSTEntityDef
    whitespace3::Vector{CSTWhitespace}
end

# ╔═╡ 70e13e76-4609-49ab-b942-0343b60e68b7
const CSTEntityDecl =  Union{CSTGEDecl,
                             CSTPEDecl}


# ╔═╡ fa42f1e7-f0dc-4fbb-916b-161e19ad851e
const CSTMarkupDecl = Union{CSTElementDecl,
                            CSTAttlistDecl,
                            CSTEntityDecl,
                            CSTNotationDecl,
                            CSTProcessingInstruction,
                            CSTComment}


# ╔═╡ 46daf523-b0c5-4586-9877-ac4a09e60c60
subtypes(CSTNode)

# ╔═╡ a31c23db-321b-497e-b1be-19c6ba864cdb
const CSTDeclSep = Union{CSTPEReference, CSTWhitespace}

# ╔═╡ 0ab1c11a-a9d2-4c2f-8445-a5e9ac1896e2
const CSTIntSubset = Vector{Union{CSTMarkupDecl, CSTDeclSep}}

# ╔═╡ 84550d9a-e785-4249-8125-398ae5467e0c
begin
    struct CSTDocTypeDecl <: CSTNode
        whitespace1::CSTWhitespace
        name::CSTName
        external_id        # ::Vector{Tuple{CSTWhitespace, CSTExternalId}}
        whitespace2        # ::Vector{CSTWhitespace}
        internal_subset    # CSTIntSubset
        whitespace3::CSTWhitespace

        function CSTDocTypeDecl(wsp1, name, extid, wsp2, intsub, wsp3)
			@assert(all(extid) do x
				x isa Tuple && x[1] isa CSTWhitespace && x[2] isa CSTExternalId
			end)
            @assert(all(x -> x isa CSTWhitespace, wsp2))
            @assert all(x -> x isa eltype(CSTIntSubset),
                        intsub)
            new(wsp1, name, extid, wsp2, intsub, wsp3)
        end
    end

    function Base.print(io::IO, n::CSTDocTypeDecl)
        print(io, "<!DOCTYPE", n.whitespace1, n.name)
        for x in n.external_id
            print(io, x[1], x[2])
        end
        print(io, n.whitespace2...)
		print(io, "[", n.internal_subset..., "]")
        print(io, n.whitespace3)
        print(io, ">")
    end

end

# ╔═╡ bf8cb073-8212-4553-be5c-2fcf11aa1321
md"""# Testing"""

# ╔═╡ c6d29e05-4270-4f30-b088-e9e62e44c066
md"""## Conformance"""

# ╔═╡ 9bdb0817-3ceb-423f-ba0d-2cc8dd1d5ae2
begin
    # CSTWhitespace
    test_round_trip("S", " ")
    test_round_trip("S", "\t")
    test_round_trip("S", "\r")
    test_round_trip("S", "\n")

    # CSTName
    test_round_trip("Name", "foo")

    # CSTCharData
    test_round_trip("CharData", "jghfrcgf_y")

    # CSTComment
    test_round_trip("Comment", "<!-- foobar -->")

    # CSTProcessingInstruction
    test_round_trip("PI", "<?foo bar baz?>")

    # CSTEntityRef
    test_round_trip("EntityRef", "&amp;")

    # CSTPEReference
    test_round_trip("PEReference", "%foo;")

    # CSTCharRef
    test_round_trip("CharRef", "&#x531;")

    # CSTAttribute
    test_round_trip("Attribute", "attr='foobar'")
    test_round_trip("Attribute", "attr=\"foobar\"")
    test_round_trip("Attribute", "attr='foo&amp;bar'")
    test_round_trip("<AttributeList>", " attr=\"foobar\"    at2='jhgjyj87yt8'")

    # CSTDeclAttr
    test_round_trip("VersionInfo", "  version='1.0'")
    test_round_trip("EncodingDecl", "\tencoding='utf-8'")
    test_round_trip("SDDecl", "  standalone=\"yes\"")

    # CSTXMLDecl
    test_round_trip("XMLDecl", "<?xml version=\"1.0\"?>")
    test_round_trip("XMLDecl", "<?xml version='1.0'?>")
    test_round_trip("XMLDecl", "<?xml version = \"1.0\"?>")
    test_round_trip("XMLDecl", "<?xml version='1.0' encoding=\"UTF-8\"?>")
    test_round_trip("XMLDecl", "<?xml version='1.0' standalone='yes'?>")
    test_round_trip("XMLDecl", "<?xml version='1.0' encoding=\"UTF-8\" standalone='yes'?>")
    test_round_trip("XMLDecl", "<?xml version=\"1.0\" encoding=\"utf-8\"?>")

    # CSTElement
    test_round_trip("element", """<doc>
        <e a3="v3"/>
        <e a1="w1"/>
        <e a2="w2" a3="v3"/>
        </doc>""")

    # CSTNotationDecl
    test_round_trip("NotationDecl", "<!NOTATION n PUBLIC \"whatever\">")
    test_round_trip("NotationDecl", "<!NOTATION n1 SYSTEM \"http://www.w3.org/\">")

    # CSTPublicID
    test_round_trip("PublicID", "PUBLIC 'ABC123'")

    # CSTExternalId
    test_round_trip("ExternalID", "SYSTEM 'foo'")
    test_round_trip("ExternalID", "PUBLIC 'abc' 'foo'")

    # CSTElementDecl
    test_round_trip("elementdecl", "<!ELEMENT doc (#PCDATA)>")
    test_round_trip("elementdecl", "<!ELEMENT doc (foo)>")
    test_round_trip("elementdecl", "<!ELEMENT foo EMPTY>")

    # CSTAttlistDecl
    test_round_trip("AttlistDecl", "<!ATTLIST doc a1 CDATA \"v1\">")
    test_round_trip("AttlistDecl", "<!ATTLIST doc a1 CDATA #IMPLIED a2 CDATA #IMPLIED>")
    test_round_trip("AttlistDecl", "<!ATTLIST e a1 CDATA #IMPLIED a2 CDATA #IMPLIED a3 CDATA #IMPLIED>")

    # CSTPEDecl
    test_round_trip("PEDecl", "<!ENTITY % e \"<!ELEMENT doc (#PCDATA)>\">")
    test_round_trip("PEDecl", "<!ENTITY % e SYSTEM \"e.dtd\">")
    test_round_trip("PEDecl", "<!ENTITY % e PUBLIC 'whatever' \"e.dtd\">")
    test_round_trip("PEDecl", "<!ENTITY % e \"<foo>\">")

end

# ╔═╡ 76cb9eb7-8f58-4fb3-8ed5-179a7acc1f1d
XML_CONFORMANCE_TEST_ROOT = "/Users/MarkNahabedian/Downloads/xmlconf"

# ╔═╡ b6228446-df0e-4889-9101-e9f30e8ea7ed
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
            xmltext = read(xml, String)
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

# ╔═╡ 83ef2ebb-1ab0-442e-8658-95a4b8954452
if @isdefined PlutoRunner
    run_conformance_tests()
end

# ╔═╡ 74020c13-4105-4e8f-b9ee-90c3f5338a67
md"""## Hand Testing and Debugging"""

# ╔═╡ f19e2d7f-a0c7-4906-8285-eab6b20b9feb
conformance_dir = joinpath(XML_CONFORMANCE_TEST_ROOT, "xmltest/valid/sa")

# ╔═╡ d20a727a-e4c5-49d0-acae-5836a541f0d0
begin
	xml = read(joinpath(conformance_dir, "002.xml"), String)
	print(xml)
end

# ╔═╡ 87e7f1c4-613b-4537-8d02-481d1b8112ef
recognize(BNFRef(:XML, "document"), xml)

# ╔═╡ 51012dd6-39d3-4377-9a4f-b73e4acb650d
doc = recognize(BNFRef(:XML, "document"), xml)[2]

# ╔═╡ f7acb4e5-11fb-4fab-bfbf-d3593961f517
print(doc)

# ╔═╡ e31687d7-cfd1-4ef2-87aa-18bb8ce5e556
doc.prolog.dtd

# ╔═╡ b91fe301-7a6d-425d-b835-db7654b8cf24
print(doc.prolog)

# ╔═╡ 2995e9d6-8eeb-4908-9ddc-5a2fee23d65e
print(doc.prolog.dtd[1][1].external_id...)

# ╔═╡ 0b831028-dc8b-41fb-8776-34da514f07a5
print(doc.prolog.dtd[1][1].internal_subset...)

# ╔═╡ bb33f478-b159-4cc8-8533-2dcdc4b2327b
doc.root

# ╔═╡ 5770078e-f1fb-4c97-8f11-7f9e73248ee3
print(doc.prolog.dtd[1][1])

# ╔═╡ 6d55c633-fe8f-4ca0-9d02-5f3bae57a19b
print(doc.prolog.dtd[1]...)

# ╔═╡ fda25e0d-4f44-4cdf-b8c4-2b109f55d661
doc

# ╔═╡ 0ad91462-ebf5-43c9-a263-7e1770665fcf
for x in doc.prolog.dtd
	print(x[1], x[2]...)
end

# ╔═╡ 5d150475-c447-4dcd-ab27-b4b80a42bb7f
print(doc)

# ╔═╡ 1e450fd6-4517-4316-87da-ca898854a346
string(doc) == xml

# ╔═╡ 4bff0cb4-6be7-441d-8a73-9e7facd3344d
recognize(BNFRef(:XML, "doctypedecl"), xml)

# ╔═╡ fdcc2a61-a5b9-4779-a6e4-920c60471ab2
recognize(BNFRef(:XML, "prolog"), xml)

# ╔═╡ Cell order:
# ╠═1e9c0f53-6cad-4e35-8868-15374f528f32
# ╠═60d1e8e8-6837-11f1-85a8-b7dded61141e
# ╠═fa42f1e7-f0dc-4fbb-916b-161e19ad851e
# ╠═13ce8946-2c9c-4177-8f1b-4693f0d922b7
# ╠═c1defcdb-f1c6-46ec-a704-922f23ecb893
# ╠═217ce513-3edd-4205-a7b3-204892bdb462
# ╠═591484d6-3889-4c6e-a694-8a19d5b81463
# ╠═925c0ebb-ae44-4684-8577-e8c98c0f3493
# ╠═58ab2a93-4201-4af5-87a3-1cbe1ad4b566
# ╠═30e22a04-7526-4066-85c6-a66e52266159
# ╠═09880878-e618-4399-b282-e28482e4d5a2
# ╠═718e0ae3-93af-48e7-9a73-b0ed014327b0
# ╠═96034286-77f3-47c5-b4d4-f702e5107293
# ╠═4d27c051-3a71-415b-bf01-6a7e996683ae
# ╠═df9150cf-869e-485f-ab04-87729e412535
# ╠═2758f98f-cdc0-4c73-b15e-92e2e7a6f729
# ╠═8b1facc1-2959-44e4-b28f-f5c60d21a960
# ╠═d5f3c788-bdcb-495b-9b1f-c33ecfeeb323
# ╠═11e7d6e4-1799-44de-b014-fa9210cc9305
# ╠═bda9fa7e-5796-4c8b-983b-b59f51347243
# ╠═cb43accd-e2c5-48e3-8331-6ea62a00a237
# ╠═064ad685-660e-4030-906b-cc5f889cad65
# ╠═395327b7-dcfd-4b98-8e99-80fbe34e0e67
# ╠═84550d9a-e785-4249-8125-398ae5467e0c
# ╠═d8233096-0669-4d96-9067-79f024ec89b5
# ╠═e6843b8c-75d5-405d-8c3e-6f033fa67fb0
# ╠═0ab1c11a-a9d2-4c2f-8445-a5e9ac1896e2
# ╠═70e13e76-4609-49ab-b942-0343b60e68b7
# ╠═33bcb770-9e87-4925-922a-eae88b8536ba
# ╠═c2dae9f6-4409-4435-9784-b5e24c590abd
# ╠═b092cc49-9a3e-407e-9581-097c59d17beb
# ╠═856c098d-b6f9-4fbd-9125-d525d88ba854
# ╠═c763d5ab-dc90-477b-a9b3-c1ae15dc1970
# ╠═58ebea76-b1d9-45d8-a9a3-ffcb9390a19a
# ╠═29a6a54a-553b-4220-bbfc-27aa1815b0fb
# ╠═46daf523-b0c5-4586-9877-ac4a09e60c60
# ╠═a31c23db-321b-497e-b1be-19c6ba864cdb
# ╠═02a5daca-56f4-4da2-abce-450005238b31
# ╟─bf8cb073-8212-4553-be5c-2fcf11aa1321
# ╠═eaf455d3-fa8d-4d67-9b98-09f34daaad1a
# ╟─c6d29e05-4270-4f30-b088-e9e62e44c066
# ╟─9bdb0817-3ceb-423f-ba0d-2cc8dd1d5ae2
# ╠═76cb9eb7-8f58-4fb3-8ed5-179a7acc1f1d
# ╟─b6228446-df0e-4889-9101-e9f30e8ea7ed
# ╠═83ef2ebb-1ab0-442e-8658-95a4b8954452
# ╟─74020c13-4105-4e8f-b9ee-90c3f5338a67
# ╠═f19e2d7f-a0c7-4906-8285-eab6b20b9feb
# ╠═d20a727a-e4c5-49d0-acae-5836a541f0d0
# ╠═87e7f1c4-613b-4537-8d02-481d1b8112ef
# ╠═51012dd6-39d3-4377-9a4f-b73e4acb650d
# ╠═f7acb4e5-11fb-4fab-bfbf-d3593961f517
# ╠═e31687d7-cfd1-4ef2-87aa-18bb8ce5e556
# ╠═b91fe301-7a6d-425d-b835-db7654b8cf24
# ╠═2995e9d6-8eeb-4908-9ddc-5a2fee23d65e
# ╠═0b831028-dc8b-41fb-8776-34da514f07a5
# ╠═bb33f478-b159-4cc8-8533-2dcdc4b2327b
# ╠═5770078e-f1fb-4c97-8f11-7f9e73248ee3
# ╠═6d55c633-fe8f-4ca0-9d02-5f3bae57a19b
# ╠═fda25e0d-4f44-4cdf-b8c4-2b109f55d661
# ╠═0ad91462-ebf5-43c9-a263-7e1770665fcf
# ╠═5d150475-c447-4dcd-ab27-b4b80a42bb7f
# ╠═1e450fd6-4517-4316-87da-ca898854a346
# ╠═4bff0cb4-6be7-441d-8a73-9e7facd3344d
# ╠═fdcc2a61-a5b9-4779-a6e4-920c60471ab2
