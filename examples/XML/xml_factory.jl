# Abstract definitions of the generic functions that the XML grammar
# will use to construct an XML document.

export AbstractXMLFactory, xmlComment, xmlText, xmlElement

abstract type AbstractXMLFactory end


"""
    xmlComment(factory, comment)

Construct an XML comment node.
"""
function xmlComment(factory, comment::AbstractString) end


"""
   xmlText(factory, text::AbstractString)

Construct an XML text node.
"""
function xmlComment(factory::AbstractXMLFactory, comment) end


"""
    xmlElement(factory::AbstractXMLFactory, tagname::AbstractString, attributes, children::Vector)

Construct an XML element.
"""
function xmlElement(factory::AbstractXMLFactory,
                    tagname::AbstractString,
                    attributes::Vector{<:Pair{Symbol, <:AbstractString}},
                    children::Vector) end

