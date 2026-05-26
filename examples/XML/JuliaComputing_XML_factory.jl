
using XML


"""
    JuliaComputingXMLFactory

An XML factroy for constructing XML that is compatible with the
https://github.com/JuliaComputing/XML.jl XML implementation.
"""
struct JuliaComputingXMLFactory end


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

