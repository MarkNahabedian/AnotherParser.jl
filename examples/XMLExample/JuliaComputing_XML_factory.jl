
using XML
using Printf


"""
    JuliaComputingXMLFactory

An XML factroy for constructing XML that is compatible with the
https://github.com/JuliaComputing/XML.jl XML implementation.
"""
struct JuliaComputingXMLFactory <: AbstractXMLFactory end


function xmlDocument(::JuliaComputingXMLFactory, input::AbstractString,
                     from::Int, to::Int, value)
    prolog = value[1]
    element = value[2]
    misc = value[3]
    children = filter(x -> x != nothing,
                      [ prolog..., element, misc... ])
    XML.Node(XML.Document, nothing, nothing, nothing, children)
end

function xmlXMLDecl(::JuliaComputingXMLFactory, input::AbstractString,
                    from::Int, to::Int, value)
    attrs = OrderedDict(
                       [ value[2], value[3]..., value[4]... ]
    )
    Node(XML.Declaration, nothing, attrs, nothing, nothing)
end

function xmlDTD(::JuliaComputingXMLFactory, input::AbstractString,
                from::Int, to::Int, value)
    Node(XML.DTD, nothing, nothing,
         SubString(input, value[3],
                   prevind(input, value[7], 1)), nothing)
end

function xmlComment(::JuliaComputingXMLFactory, input::AbstractString,
                    from::Int, to::Int, value)
    XML.Comment(value[2])
end

function xmlText(factory::JuliaComputingXMLFactory, text::AbstractString)
    XML.Text(text)
end


function xmlElement(factory::JuliaComputingXMLFactory, input::AbstractString,
                    from::Int, to::Int, value)
    if value isa NamedTuple              # EmptyElemTag
        return XML.Element(value.name, [], value.attributes)
    end
    starttag, content, endtag = value
    @assert starttag.name == endtag.name
    XML.Element(starttag.name,
                content...;
                starttag.attributes...)
end

function xmlCharReference(::JuliaComputingXMLFactory, charcode::Int, ishex)
    # XML.jl leaves the character reference as is.
    if ishex
        @sprintf("&#x%x;", charcode)
    else
        @sprintf("&#%d;", charcode)
    end
end

function xmlEntityRef(::JuliaComputingXMLFactory, name::AbstractString)
    @sprintf("&%s;", name)
end

function xmlProcessingInstruction(::JuliaComputingXMLFactory, input::AbstractString,
                                  from::Int, to::Int, value)
    pitarget = value[2]
    # chars = map(join, values[2])
    Node(XML.ProcessingInstruction, pitarget, nothing, nothing, nothing)
end

function xmlCData(::JuliaComputingXMLFactory, input::AbstractString,
                  from::Int, to::Int, value)
    Node(XML.CData, nothing, nothing, value[2], nothing)
end

