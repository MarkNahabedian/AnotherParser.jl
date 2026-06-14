# A concrete syntax tree for XML.

# The goal of this file is to define data structure that can represent
# parsed XML to such a level of detail that the data-structure can be
# re-serialized to produce an output file that faithfully matches the
# original.

export CSTNode

abstract type CSTNode end

const CSTMarkupDecl = Union{CSTElementDecl,
                            CSTAttlistDecl,
                            CSTEntityDecl,
                            CSTNotationDecl,
                            CSTProcessingInstruction,
                            CSTComment}

const CSTIntSubset = Union{CSTMarkupDecl, DeclSep}

const CSTEntityDecl =  Union{CSTGEDecl,
                             CSTPEDecl}

const CSTReference = Union{CSTEntityRef, CSTCharRef}

const CSTMisc = Union{CSTComment,
                      CSTProcessingInstrcution,
                      CSTWhitespace}

const CSTExternalId = Union{CSTExtIdSystem,
                            CSTExtIdPublic}

const CSTPEDef = Union{CSTEntityValue,
                       CSTExternalId}

const CSTEntityDef = Union{CSTEntityValue,
                           CSTExternalId,
                           CSTNDataDecl)


function test_round_trip(rulename, input)
    matches, value, i = recognize(AllGrammars[:XML][rulename], input)
    got = string(value)
    @assert input == got "$input == $got"
end

#=

CSTAttValue      no test
# CSTAttlistDecl
# CSTAttribute
 CSTCharData     no test
# CSTCharRef
# CSTComment
# CSTDeclAttr
 CSTDocTypeDecl   no test
# CSTElement
# CSTEntityRef
# CSTElementDecl
 CSTEq            no test
CSTEntityValue
# CSTExtIdPublic
# CSTExtIdSystem
# CSTName
# CSTNotationDecl
# CSTPEReference
# CSTProcessingInstruction
# CSTPublicID
# CSTWhitespace
# CSTXMLDecl

* indicates that there's an assertion test below.

"document"
"Char"
"S"                * CSTWhitespace
"NameStartChar"
"NameChar"
"Name"             * CSTName
"Names"
"Nmtoken"
"Nmtokens"
"EntityValue"        CSTEntityValue
"AttValue"           CSTAttValue
"SystemLiteral"      AbstractString
"PubidLiteral"       AbstractString
PubidChar            AbstractString
"CharData"         * AbstractString
"Comment"          * CSTComment
"PI"               * CSTProcessingInstruction
"PITarget"           CSTName
"CDSect"             CSTCharData
"CDStart"
"CData"              AbstractString
"CDEnd"
"prolog"
"XMLDecl"          * CSTXMLDecl
"VersionInfo"      * CSTDeclAttr
"Eq"                 CSTEq
"VersionNum"         AbstractString
"Misc"
"doctypedecl"
"DeclSep"
"intSubset"
"markupdecl"
"extSubset"
"extSubsetDecl"
"SDDecl"           * CSTDeclAttr
"element"          * CSTElement
"<AttributeList>"    Vector{Attribute}
"STag"
"Attribute'        * CSTAttribute
"ETag"
"content"
"EmptyElemTag"
"elementdecl"      * CSTElementDecl
"contentspec"        AbstractString
"children"
"cp"
"choice"
"seq"
"Mixed"
"AttlistDecl"    * CSTAttlistDecl
"AttDef"
"AttType"          AbstractString
StringType         AbstractString
"TokenizedType"    AbstractString
"EnumeratedType"   AbstractString
"NotationType"
"Enumeration"
"DefaultDecl"
"conditionalSect"
"includeSect"
"ignoreSect"
"ignoreSectContents"
"Ignore"
"CharRef"          * CSTCharRef
"Reference"
"EntityRef"        * CSTEntityRef
"PEReference"      * CSTPEReference
"GEDecl"
"PEDecl"
"EntityDef"
"PEDef"
"ExternalID"       * CSTExternalId >: CSTExtIdSystem CSTExtIdPublic
"NDataDecl"          CSTNDataDecl
"TextDecl"
"extParsedEnt"
"EncodingDecl"     * CSTDeclAttr
"EncName"            AbstractString
"NotationDecl"     * CSTNotationDecl
"PublicID"         * CSTPublicID

=#

######################################################################
export CSTWhitespace

mutable struct CSTWhitespace <: CSTNode
    # In the CST we allof for text to be empty to deal with all of the
    # cases where "S" production is optional.  That way we don't need
    # to do tests against `nothing`.
    text::AbstractString
    is_ignorable::Bool

    CSTWhitespace(text::AbstractString) = new(text, false)
end

Base.print(io::IO, n::CSTWhitespace) = print(io, n.text)

######################################################################
export CSTName, prefix, local_name

mutable struct CSTName <: CSTNode
    name::AbstractString
    namespace_uri::Union{Nothing, AbstractString}

    CSTName(name::AbstractString) = new(name, nothing)
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

######################################################################
export CSTCharData

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

######################################################################
export CSTComment

struct CSTComment <: CSTNode
    text::AbstractString
end

function Base.print(io::IO, n::CSTComment)
    print(io, "<!--")
    print(io, n.text)
    print(io, "-->")
end

######################################################################
export CSTProcessingInstruction

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

######################################################################
export CSTEntityRef

struct CSTEntityRef <: CSTNode
    name::CSTName
end

Base.print(io::IO, n::CSTEntityRef) = print(io, "&$(n.name);")

######################################################################

struct CSTPEReference <: CSTNode
    name::CSTName
end

Base.print(io::IO, n::CSTPEReference) = print(io, "%$(n.name);")

######################################################################
export CSTCharRef

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

######################################################################
export CSTAttValue, CSTAttribute

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

######################################################################

struct CSTEq  <: CSTNode
    preceeding_whitespace::CSTWhitespace
    trailing_whitespace::CSTWhitespace
end

Base.print(io::IO, n::CSTEq) = 
    print(io, n.preceeding_whitespace, "=", n.trailing_whitespace)


######################################################################
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

######################################################################

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

######################################################################

mutable struct CSTElement <: CSTNode
    tag::CSTName
    attributes::Vector{CSTAttribute}
    content::Vector{Union{AbstractString, CSTNode}}
    isempty::Bool
end

function Base.print(io::IO, n::CSTElement)
    if n.isempty
        print(io, "<", n.tag, n.attributes, "/>")
    else
        print(io, "<", n.tag, n.attributes, ">",
              n.content...,
              "</", n.tag, ">")
    end
end

######################################################################

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

######################################################################

struct CSTNDataDecl <: CSTNode
    whitespace1::CSTWhitespace
    name::CSTName
end

Base.print(io::IO, n::CSTNDataDecl) =
    print(io, n.whitespace1, n.name)

######################################################################

Base.print(io::IO, n::CSTExtIdPublic) =
    print(io, "PUBLIC", n.whitespace1, n.public_literal,
          n.whitespace2, n.system_literal)

struct CSTDocTypeDecl <: CSTNode
    whitespace1::CSTWhitespace
    name::CSTName
    external_ids::Vector{Tuple{CSTWhitespace, CSTExternalId}}

end

######################################################################

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

######################################################################

struct CSTDocTypeDecl <: CSTNode
    whitespace1::CSTWhitespace
    name::CSTName
    whitespace2::CSTWhitespace
    external_id::Union{CSTExtIdSystem, CSTExtIdPublic}
    whitespace3::CSTWhitespace
    internal_subset
end

######################################################################

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

######################################################################

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

######################################################################

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
    pedef::CSTPEDef
    whitespace4::CSTWhitespace
end

Base.print(io::IO, n::CSTPEDecl) =
    print(io, "<!ENTITY", n.whitespace1, "%", n.whitespace2, n.name,
          n.whitespace3,
          n.pedef,
          n.whitespace4, ">")

######################################################################

struct CSTDocTypeDecl <: CSTNode
    whitespace1::CSTWhitespace
    name::CSTName
    external_id::Vector{Tuple{CSTWhitespace, CSTExternalId}}
    whitespace2::CSTWhitespace
    internal_subset::Vector{Tuple{ CSTIntSubset,
                                   CSTWhitespace}}
end

function Base print(io::IO, n::CSTDocTypeDecl)
    print(io, "<!DOCTYPE", n.whitespace1, n.name)
    for x in n.external_id
        print(io, x[1], x[2])
    end
    print(io, whitespace2)
    for x in n.internal_subset
        print(io, "[", x[1], "]", x[2])
    end
    print(io, ">")
end

######################################################################

struct CSTProlog <: CSTNode
    xmldecl::Vector{CSTXMLDecl}
    misc::Vectorr{CSTMisc}
    dtd::Vector{Tuple{CSTDocTypeDecl
                      CSTMisc}}
end

function Base.print(io::IO, n::CSTProlog)
    print(io, n.xmldecl..., n.misc...)
    for x in n.dtd
        print(io, x[1], x[2])
    end
end

######################################################################

struct CSTDocument <: CSTNode
    prolog::CSTProlog
    root::CSTElement
    misc::Vector{CSTMisc}
end

Base.print(io::IO, n::CSTDocument) =
    print(io, n.prolog, n.root, n.misc...)


######################################################################


######################################################################

# document, prolog, element
# nmtoken, nmtoken    nmtoken doesn't need to be modeled as a CSTName


#=
using AnotherParser
include("examples/XML/cst.jl")
include("examples/XML/xml.jl")

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

=#

