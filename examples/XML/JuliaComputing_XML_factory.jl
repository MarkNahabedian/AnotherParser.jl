
using XML
using Printf


"""
    JuliaComputingXMLFactory

An XML factroy for constructing XML that is compatible with the
https://github.com/JuliaComputing/XML.jl XML implementation.
"""
struct JuliaComputingXMLFactory <: AbstractXMLFactory end


function xmlDocument(::JuliaComputingXMLFactory, prolog, root_element)
    XML.Document(prolog[1]..., prolog[2]..., root_element)
end

function xmlDTD(::JuliaComputingXMLFactory, dtd::AbstractString)
    Node(XML.DTD, nothing, nothing, dtd, nothing)
end

function xmlComment(::JuliaComputingXMLFactory, comment::AbstractString)
    XML.Comment(comment)
end


function xmlText(factory::JuliaComputingXMLFactory, text::AbstractString)
    XML.Text(text)
end


function xmlElement(::JuliaComputingXMLFactory,
                    tagname::AbstractString,
                    attributes::Vector{<:Pair{Symbol, <:AbstractString}},
                    children::Vector)
    XML.Element(tagname, children...;
                attributes...)
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

function xmlProcessingInstruction(::JuliaComputingXMLFactory, pi)
    Node(XML.ProcessingInstruction, pi, nothing, nothing, nothing)
end

