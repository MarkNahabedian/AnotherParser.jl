# A concrete syntax tree for XML.

# The goal of this file is to define data structure that can represent
# parsed XML to such a level of detail that the data-structure can be
# re-serialized to produce an output file that faithfully matches the
# original.

export CSTNode

include("byte_order_decoding.jl")

abstract type CSTNode end

######################################################################
### CSTWhitespace

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

######################################################################
### CSTName

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

######################################################################
### CSTCharData

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
### CSTComment

struct CSTComment <: CSTNode
    text::AbstractString
end

function Base.print(io::IO, n::CSTComment)
    print(io, "<!--")
    print(io, n.text)
    print(io, "-->")
end

######################################################################
### CSTProcessingInstruction

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
### CSTEntityRef

struct CSTEntityRef <: CSTNode
    name::CSTName
end

Base.print(io::IO, n::CSTEntityRef) = print(io, "&$(n.name);")

######################################################################
### CSTPEReference

struct CSTPEReference <: CSTNode
    name::CSTName
end

Base.print(io::IO, n::CSTPEReference) = print(io, "%$(n.name);")

######################################################################
### CSTCharRef

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
### CSTEq

struct CSTEq <: CSTNode
    preceeding_whitespace::CSTWhitespace
    trailing_whitespace::CSTWhitespace
end

Base.print(io::IO, n::CSTEq) = 
    print(io, n.preceeding_whitespace, "=", n.trailing_whitespace)

######################################################################
### CSTAttribute

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
### CSTXMLDecl

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
### CSTElement

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

######################################################################
### CSTExtIdSystem

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
### CSTNDataDecl

struct CSTNDataDecl <: CSTNode
    whitespace1::CSTWhitespace
    whitespace2::CSTWhitespace
    name::CSTName
end

Base.print(io::IO, n::CSTNDataDecl) =
    print(io, n.whitespace1, "NDATA", n.whitespace2, n.name)

######################################################################
### CSTExtIdPublic

Base.print(io::IO, n::CSTExtIdPublic) =
    print(io, "PUBLIC", n.whitespace1, n.public_literal,
          n.whitespace2, n.system_literal)

######################################################################
### CSTElementDecl

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
### CSTAttDef

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
### CSTPEDecl

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

######################################################################
### CSTReference

const CSTReference = Union{CSTEntityRef, CSTCharRef}

######################################################################
### CSTEntityValue

struct CSTEntityValue <: CSTNode
    quotechar::Char
    elements::Vector{Union{AbstractString, CSTPEReference, CSTReference}}
end

Base.print(io::IO, n::CSTEntityValue) =
    print(io, n.quotechar, n.elements..., n.quotechar)

######################################################################
### CSTMisc

const CSTMisc = Union{CSTComment,
                      CSTProcessingInstruction,
                      CSTWhitespace}

######################################################################
### CSTProlog

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

######################################################################
### CSTDocument

struct CSTDocument <: CSTNode
    prolog::CSTProlog
    root::CSTElement
    misc  # ::Vector{CSTMisc}
end

Base.print(io::IO, n::CSTDocument) =
    print(io, n.prolog, n.root, n.misc...)

######################################################################
### CSTExternalId

const CSTExternalId = Union{CSTExtIdSystem,
                            CSTExtIdPublic}

######################################################################
### CSTPublicID

struct CSTPublicID <: CSTNode
    whitespace1::CSTWhitespace
    literal::AbstractString
end

Base.print(io::IO, n::CSTPublicID) =
    print(io, "PUBLIC", n.whitespace1, n.literal)

######################################################################
### CSTNotationDecl

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
### CSTPEDef

const CSTPEDef = Union{CSTEntityValue,
                       CSTExternalId}

######################################################################
### CSTEntityDef

const CSTEntityDef = Union{CSTEntityValue,
                           Tuple{CSTExternalId},
                           Tuple{CSTExternalId,
                                 CSTNDataDecl}}

######################################################################
### CSTGEDecl

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

######################################################################
### CSTEntityDeclW

const CSTEntityDecl = Union{CSTGEDecl,
                            CSTPEDecl}

######################################################################
### CSTMarkupDecl

const CSTMarkupDecl = Union{CSTElementDecl,
                            CSTAttlistDecl,
                            CSTEntityDecl,
                            CSTNotationDecl,
                            CSTProcessingInstruction,
                            CSTComment}

######################################################################
### CSTDeclSep

const CSTDeclSep = Union{CSTPEReference, CSTWhitespace}

######################################################################
### CSTIntSubset

const CSTIntSubset = Vector{Union{CSTMarkupDecl, CSTDeclSep}}

######################################################################
### CSTDocTypeDecl

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

######################################################################

