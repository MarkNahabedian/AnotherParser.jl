# Abstract definitions of the generic functions that the XML grammar
# will use to construct an XML document.

export AbstractXMLFactory, xmlDocument, xmlDTD, xmlComment, xmlText,
    xmlElement, xmlEntityRef, xmlPEReference, xmlCharReference

abstract type AbstractXMLFactory end

function unsupported_xml(factory, constructor, args...)
    (:unsupported_xml, factory, constructor, args...)
end


"""
    xmlDocument(factory, prolog, root_element)

Constructs an XML document.
"""
function xmlDocument(factory::AbstractXMLFactory, prolog, root_element)
    unsupported_xml(factory, prolog, root_element)
end


"""
    xmlDTD(factory, AbstractString)

Constructs a document type definition.
"""
function xmlDTD(factory::AbstractXMLFactory, dtd::AbstractString)
    unsupported_xml(factory, xmlDTD, dtd)
end


"""
    xmlComment(factory, comment)

Construct an XML comment node.
"""
function xmlComment(factory::AbstractXMLFactory, comment::AbstractString)
    unsupported_xml(factory, xmlComment, comment)
end


"""
   xmlText(factory, text::AbstractString)

Construct an XML text node.
"""
function xmlText(factory::AbstractXMLFactory, text)
    unsupported_xml(factory, xmlText, text)
end


"""
    xmlElement(factory::AbstractXMLFactory, tagname::AbstractString, attributes, children::Vector)

Construct an XML element.
"""
function xmlElement(factory::AbstractXMLFactory,
                    tagname::AbstractString,
                    attributes::Vector{<:Pair{Symbol, <:AbstractString}},
                    children::Vector)
    unsupported_xml(factory, xmlElement, tagname, attributes, children)
end


"""
    xmlEntityRef(factory::AbstractXMLFactory, name::AbstractString)

Returns the XML entity with the specified name.
"""
function xmlEntityRef(factory::AbstractXMLFactory, name::AbstractString)
    unsupported_xml(factory, xmlEntityRef, name)
end


"""
    xmlPEReference(factory::AbstractXMLFactory, name::AbstractString)

Returns the named Parameter-Entity Reference."
"""
function xmlPEReference(factory::AbstractXMLFactory, name::AbstractString)
    unsupported_xml(factory, xmlPEReference, name)
end

function xmlCharReference(factory::AbstractXMLFactory, charcode::Int)
    unsupported_xml(factory, xmlCharReference, charcode)
end

