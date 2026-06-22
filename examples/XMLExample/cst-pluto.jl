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

# ╔═╡ 639082ff-89f6-4221-ab7f-5a80bfc980d2
include("byte_order_decoding.jl")

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

# ╔═╡ 96034286-77f3-47c5-b4d4-f702e5107293
begin
    struct CSTEq <: CSTNode
        preceeding_whitespace::CSTWhitespace
        trailing_whitespace::CSTWhitespace
    end

    Base.print(io::IO, n::CSTEq) = 
        print(io, n.preceeding_whitespace, "=", n.trailing_whitespace)

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
		eq::CSTEq
        value::CSTAttValue
        preceeding_whitespace::CSTWhitespace

        CSTAttribute(name::CSTName, eq::CSTEq, value::CSTAttValue,
                     preceeding_whitespace::CSTWhitespace) =
            new(name, eq, value, preceeding_whitespace)

        CSTAttribute(name::CSTName, eq::CSTEq, value::CSTAttValue) =
            new(name, eq, value, CSTWhitespace(""))
    end

    function Base.print(io::IO, n::CSTAttribute)
        print(io, n.name, n.eq, n.value)
    end

    function Base.print(io::IO, attributes::Vector{CSTAttribute})
        for a in attributes
            print(io, a.preceeding_whitespace, a)
        end
    end

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
            print(io, "<", n.tag, n.attributes, 
				  n.start_tag_trailing_whitespace...,
				  ">",
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
		whitespace2::CSTWhitespace
        name::CSTName
    end

    Base.print(io::IO, n::CSTNDataDecl) =
        print(io, n.whitespace1, "NDATA", n.whitespace2, n.name)

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

# ╔═╡ 395327b7-dcfd-4b98-8e99-80fbe34e0e67
begin
    struct CSTPEDecl <: CSTNode
        whitespace1::CSTWhitespace
        whitespace2::CSTWhitespace
        name::CSTName
        whitespace3::CSTWhitespace
        pedef    # ::CSTPEDef
        whitespace4::CSTWhitespace

		function CSTPEDecl(wsp1, wsp2, name, wsp3, pedef, wsp4)
			# assert(pedef isa CSTPEDef)
			new(wsp1, wsp2, name, wsp3, pedef, wsp4)
		end
    end

    Base.print(io::IO, n::CSTPEDecl) =
        print(io, "<!ENTITY", n.whitespace1, "%", n.whitespace2, n.name,
              n.whitespace3,
              n.pedef,
              n.whitespace4, ">")

end

# ╔═╡ 33bcb770-9e87-4925-922a-eae88b8536ba
const CSTReference = Union{CSTEntityRef, CSTCharRef}

# ╔═╡ a712d70f-5fe7-4ad2-8170-614e69759c43
begin
	struct CSTEntityValue <: CSTNode
        quotechar::Char
        elements::Vector{Union{AbstractString, CSTPEReference, CSTReference}}
    end

    Base.print(io::IO, n::CSTEntityValue) =
        print(io, n.quotechar, n.elements..., n.quotechar)
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
						   Tuple{CSTExternalId},
                           Tuple{CSTExternalId,
                           	     CSTNDataDecl}}


# ╔═╡ 58ebea76-b1d9-45d8-a9a3-ffcb9390a19a
function test_round_trip(rulename, input)
    matches, value, i = recognize(AllGrammars[:XML][rulename], input)
    got = string(value)
    @assert input == got "$input == $got"
end


# ╔═╡ 29a6a54a-553b-4220-bbfc-27aa1815b0fb
begin
struct CSTGEDecl <: CSTNode
    whitespace1::CSTWhitespace
    name::CSTName
    whitespace2::CSTWhitespace
    entity_def   # ::CSTEntityDef
    whitespace3::CSTWhitespace

	function CSTGEDecl(wsp1, name, wsp2, ed, wsp3)
		@assert((ed isa CSTEntityValue) ||
			(ed isa Tuple{CSTExternalId}) ||
				(ed isa Tuple{CSTExternalId, CSTNDataDecl}))
		new(wsp1, name, wsp2, ed, wsp3)
	end
end

function Base.print(io::IO, n::CSTGEDecl)
	print(io, "<!ENTITY", n.whitespace1, n.name, n.whitespace2)
	if n.entity_def isa Tuple
		print(io, n.entity_def...)
	else
		print(io, n.entity_def)
	end
	print(io, n.whitespace3, ">")
end
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

# ╔═╡ 3fefde54-b0c8-4ff6-a360-a6975257c28c
md"""# Info"""

# ╔═╡ 83f0550b-aca7-4c50-b05a-dc3658460321
subtypes(CSTNode)

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

# ╔═╡ 83ef2ebb-1ab0-442e-8658-95a4b8954452
if @isdefined PlutoRunner
    run_conformance_tests()
end

# ╔═╡ 74020c13-4105-4e8f-b9ee-90c3f5338a67
md"""## Hand Testing and Debugging"""

# ╔═╡ f19e2d7f-a0c7-4906-8285-eab6b20b9feb
conformance_dir = joinpath(XML_CONFORMANCE_TEST_ROOT, "xmltest/valid/sa")

# ╔═╡ 61298680-5bd0-4fbe-b113-4eae0def5ddc
md"""
### File 049.xml

This file starts with the bytes `0xff 0xfe`, which corresponds with

```
UTF-16 (Big-Endian)FE FF
```
"""

# ╔═╡ e735c04a-bbe4-4f56-b75e-fdbc3ae0bb93
read(joinpath(conformance_dir, "049.xml"))[1:4]

# ╔═╡ be8995b2-4a97-44e3-a8fb-ac08634f5127
read_decoded(joinpath(conformance_dir, "049.xml"))

# ╔═╡ 75eb6fcf-fdf8-4f3a-bede-35c7f724a041
md"""
### File 050.xml

This file starts with `0xff 0xfe`, which corresponds with
```
UTF-16 (Little-Endian)FF FE
```
"""

# ╔═╡ c786af9d-35f9-4eb3-a24f-02ad0ab6d67a
read(joinpath(conformance_dir, "050.xml"))[1:4]

# ╔═╡ ba9929ae-2504-4310-87b9-6670c574a40e
md"""
### File 051.xml

Like `050.xml`, this file starts with `0xff 0xfe 0x3c 0x00`, which corresponds with
```
UTF-16 (Little-Endian)FF FE
```
"""

# ╔═╡ 6529c7f4-1ee3-41e2-9236-2acdedca16b0
read(joinpath(conformance_dir, "051.xml"))[1:4]

# ╔═╡ 632b7baa-fb3e-4e02-a05d-8be3735a4a08
md""" ### File 091.xml"""

# ╔═╡ 252489fc-2417-48ab-aee8-75325d6643af
joinpath(conformance_dir, "091.xml")

# ╔═╡ d20a727a-e4c5-49d0-acae-5836a541f0d0
begin
	xml = read_decoded(joinpath(conformance_dir, "091.xml"))
	print(xml)
end

# ╔═╡ b6222567-e1fd-4f3c-95a3-ca69cf181791
recognize(BNFRef(:XML, "document"), xml)

# ╔═╡ 51012dd6-39d3-4377-9a4f-b73e4acb650d
doc = recognize(BNFRef(:XML, "document"), xml)[2]

# ╔═╡ f7acb4e5-11fb-4fab-bfbf-d3593961f517
(doc.prolog.dtd[1][1])

# ╔═╡ 42ee7d43-4ac5-4d3d-acad-b532a2378c86
string(doc) == xml

# ╔═╡ 327bd9f4-de0d-468c-92a3-5cc0141d6858
recognize(BNFRef(:XML, "doctypedecl"), xml)

# ╔═╡ 55b013e4-fb9e-447b-86fe-be2d2906abf4
findall("[", xml)

# ╔═╡ 05a62a82-c09a-48d1-8c3d-9ba1fa87519d
recognize(BNFRef(:XML, "intSubset"), xml; index=16)

# ╔═╡ cd4e0c7e-16a9-46e5-a10c-7ac1bb2feee7
recognize(BNFRef(:XML, "markupdecl"), xml; index=18)

# ╔═╡ f54fbc66-2843-4b27-948f-7162bbd21f77
recognize(BNFRef(:XML, "S"), xml; index=59)

# ╔═╡ d10f9f89-ac33-4f89-a73e-3d31580211f8
recognize(BNFRef(:XML, "markupdecl"), xml; index=61)

# ╔═╡ 2c796f8b-5137-4859-8a17-6ebde76c210c
md"""#### @61 Doesn't parse as `markupdecl`."""

# ╔═╡ 0686747d-a98f-40f9-a62d-2d9f3d839039
SubString(xml, 61)

# ╔═╡ 4bf96a73-f97d-482f-bd91-fc3c3a2f2a7c
recognize(StringLiteral("<!ENTITY"), xml; index=61)

# ╔═╡ 5c3abb39-e049-45e6-8292-e0e599553dc4
recognize(BNFRef(:XML, "S"), xml; index=69)

# ╔═╡ bc20f35c-87bb-451a-aa15-e695d4bb36cd
recognize(BNFRef(:XML, "Name"), xml; index=70)

# ╔═╡ a0d67b58-6717-44f9-a4e1-f3a283dfa592
recognize(BNFRef(:XML, "S"), xml; index=71)

# ╔═╡ 84af796f-c143-42e4-8621-45f0d82da3cf
md"""
#### @72 parses as an `EntityDef`
"""

# ╔═╡ 3a5666b5-4db6-45ae-b478-193f724fa6a7
recognize(BNFRef(:XML, "EntityDef"), xml; index=72)

# ╔═╡ 1bff1503-3575-47ec-bcd7-5d157d6bcb12
SubString(xml, 72, 99)

# ╔═╡ 5bc8406d-978d-4f69-ab73-c0037d8f41b7
recognize(BNFRef(:XML, "S"), xml; index=99)

# ╔═╡ cf1e9515-7b2d-4fd2-b713-bb6469291de0
recognize(CharacterLiteral('>'), xml; index=100)

# ╔═╡ 5cb29dd6-d604-4fa5-819f-08e0cb728b31
SubString(xml, 99)

# ╔═╡ f87a20af-5dc6-46d2-956d-e29f95e032a0
md"""
#### @99 does parse as `NDataDecl`
```
EntityDef   ::=   EntityValue | (ExternalID NDataDecl?)
GEDecl   ::=   '<!ENTITY' S Name S EntityDef S? '>'
EntityDecl   ::=   GEDecl | PEDecl
markupdecl  ::=  elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment
```
"""

# ╔═╡ 626fe89b-53a5-459a-be66-5341cafea6b2
recognize(BNFRef(:XML, "NDataDecl"), xml; index=99)

# ╔═╡ 3e1a2aef-ac23-4ea5-baf6-dc367500f913
SubString(xml, 61)

# ╔═╡ f79175e2-ff6d-4342-ae9e-d4462aa91793
recognize(BNFRef(:XML, "Comment"), xml; index=61)

# ╔═╡ b4cdd77c-aa6f-45e8-a73a-481239f318ae
md"""
### 100.xml

"""

# ╔═╡ b9644048-d1b9-42dd-8d42-e5b974d45688
xml100 = read_decoded(joinpath(conformance_dir, "100.xml"))

# ╔═╡ f148d2d7-8818-4765-8cd0-cd04695ec38f
print(xml100)

# ╔═╡ 13daecfa-7bc9-4a04-8d88-cfc1abcb719a
xml100

# ╔═╡ 8319d242-a824-47ef-8a21-2bdcb261dd68
recognize(BNFRef(:XML, "document"), xml100)

# ╔═╡ 8528d149-33af-4dc8-b65b-d6ed8d9a15f7
doc100 = recognize(BNFRef(:XML, "document"), xml100)[2]

# ╔═╡ c8b5f98d-1c26-46aa-a463-492594ef1fca
(doc100.prolog.dtd[1][1].internal_subset[2])

# ╔═╡ 377b2a76-705e-4847-8f04-70ccaac75f3e
print(doc100.prolog.dtd[1][1].internal_subset[2])

# ╔═╡ ee924d5d-0f68-436e-8837-170afd46b20b
doc100.prolog.dtd[1][1].internal_subset[2].entity_def

# ╔═╡ 6f76f0e2-fc38-4a0a-bc3e-f2642a9e52ed
print(doc100.prolog.dtd[1][1].internal_subset[2].entity_def...)

# ╔═╡ c6983b08-29cd-4606-9782-22476374f8fe
print(doc100)

# ╔═╡ 53b84b7e-0812-4b27-bbb9-a8b35de1f5b6
string(doc100) == xml100

# ╔═╡ 1f58d00b-7305-473e-b85c-fcec7e430999
findall("<!ENTITY", xml100)

# ╔═╡ d441b591-e603-466a-9095-95a13f86eec2
print(SubString(xml100, 18))

# ╔═╡ 1a20f51e-8ffc-42bd-bedb-af14d5ffaee5
recognize(BNFRef(:XML, "EntityDecl"), xml100; index=18)

# ╔═╡ ba1dca35-751a-45de-8b1f-d245a56f631a
findall("<!ELEMENT", xml100)

# ╔═╡ c6cfdbf2-a95c-4f46-96c3-b67d53cca1b9
SubString(xml100, 59)

# ╔═╡ 28814f60-8979-4e2c-9edf-bcd6e9f553e1
print(recognize(BNFRef(:XML, "elementdecl"), xml100; index=59)[2])

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
# ╠═a712d70f-5fe7-4ad2-8170-614e69759c43
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
# ╟─3fefde54-b0c8-4ff6-a360-a6975257c28c
# ╠═83f0550b-aca7-4c50-b05a-dc3658460321
# ╟─bf8cb073-8212-4553-be5c-2fcf11aa1321
# ╠═eaf455d3-fa8d-4d67-9b98-09f34daaad1a
# ╠═639082ff-89f6-4221-ab7f-5a80bfc980d2
# ╟─c6d29e05-4270-4f30-b088-e9e62e44c066
# ╟─9bdb0817-3ceb-423f-ba0d-2cc8dd1d5ae2
# ╠═76cb9eb7-8f58-4fb3-8ed5-179a7acc1f1d
# ╠═b6228446-df0e-4889-9101-e9f30e8ea7ed
# ╠═83ef2ebb-1ab0-442e-8658-95a4b8954452
# ╟─74020c13-4105-4e8f-b9ee-90c3f5338a67
# ╠═f19e2d7f-a0c7-4906-8285-eab6b20b9feb
# ╟─61298680-5bd0-4fbe-b113-4eae0def5ddc
# ╠═e735c04a-bbe4-4f56-b75e-fdbc3ae0bb93
# ╠═be8995b2-4a97-44e3-a8fb-ac08634f5127
# ╟─75eb6fcf-fdf8-4f3a-bede-35c7f724a041
# ╠═c786af9d-35f9-4eb3-a24f-02ad0ab6d67a
# ╟─ba9929ae-2504-4310-87b9-6670c574a40e
# ╠═6529c7f4-1ee3-41e2-9236-2acdedca16b0
# ╟─632b7baa-fb3e-4e02-a05d-8be3735a4a08
# ╠═252489fc-2417-48ab-aee8-75325d6643af
# ╠═d20a727a-e4c5-49d0-acae-5836a541f0d0
# ╠═b6222567-e1fd-4f3c-95a3-ca69cf181791
# ╠═51012dd6-39d3-4377-9a4f-b73e4acb650d
# ╠═f7acb4e5-11fb-4fab-bfbf-d3593961f517
# ╠═42ee7d43-4ac5-4d3d-acad-b532a2378c86
# ╠═327bd9f4-de0d-468c-92a3-5cc0141d6858
# ╠═55b013e4-fb9e-447b-86fe-be2d2906abf4
# ╠═05a62a82-c09a-48d1-8c3d-9ba1fa87519d
# ╠═cd4e0c7e-16a9-46e5-a10c-7ac1bb2feee7
# ╠═f54fbc66-2843-4b27-948f-7162bbd21f77
# ╠═d10f9f89-ac33-4f89-a73e-3d31580211f8
# ╟─2c796f8b-5137-4859-8a17-6ebde76c210c
# ╠═0686747d-a98f-40f9-a62d-2d9f3d839039
# ╠═4bf96a73-f97d-482f-bd91-fc3c3a2f2a7c
# ╠═5c3abb39-e049-45e6-8292-e0e599553dc4
# ╠═bc20f35c-87bb-451a-aa15-e695d4bb36cd
# ╠═a0d67b58-6717-44f9-a4e1-f3a283dfa592
# ╟─84af796f-c143-42e4-8621-45f0d82da3cf
# ╠═3a5666b5-4db6-45ae-b478-193f724fa6a7
# ╠═1bff1503-3575-47ec-bcd7-5d157d6bcb12
# ╠═5bc8406d-978d-4f69-ab73-c0037d8f41b7
# ╠═cf1e9515-7b2d-4fd2-b713-bb6469291de0
# ╠═5cb29dd6-d604-4fa5-819f-08e0cb728b31
# ╟─f87a20af-5dc6-46d2-956d-e29f95e032a0
# ╠═626fe89b-53a5-459a-be66-5341cafea6b2
# ╠═3e1a2aef-ac23-4ea5-baf6-dc367500f913
# ╠═f79175e2-ff6d-4342-ae9e-d4462aa91793
# ╟─b4cdd77c-aa6f-45e8-a73a-481239f318ae
# ╠═b9644048-d1b9-42dd-8d42-e5b974d45688
# ╠═f148d2d7-8818-4765-8cd0-cd04695ec38f
# ╠═13daecfa-7bc9-4a04-8d88-cfc1abcb719a
# ╠═8319d242-a824-47ef-8a21-2bdcb261dd68
# ╠═8528d149-33af-4dc8-b65b-d6ed8d9a15f7
# ╠═c8b5f98d-1c26-46aa-a463-492594ef1fca
# ╠═377b2a76-705e-4847-8f04-70ccaac75f3e
# ╠═ee924d5d-0f68-436e-8837-170afd46b20b
# ╠═6f76f0e2-fc38-4a0a-bc3e-f2642a9e52ed
# ╠═c6983b08-29cd-4606-9782-22476374f8fe
# ╠═53b84b7e-0812-4b27-bbb9-a8b35de1f5b6
# ╠═1f58d00b-7305-473e-b85c-fcec7e430999
# ╠═d441b591-e603-466a-9095-95a13f86eec2
# ╠═1a20f51e-8ffc-42bd-bedb-af14d5ffaee5
# ╠═ba1dca35-751a-45de-8b1f-d245a56f631a
# ╠═c6cfdbf2-a95c-4f46-96c3-b67d53cca1b9
# ╠═28814f60-8979-4e2c-9edf-bcd6e9f553e1
