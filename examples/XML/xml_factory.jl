# Abstract definitions of the generic functions that the XML grammar
# will use to construct an XML document.

export AbstractXMLFactory, xmlDocument, xmlDTD, xmlComment, xmlText,
    xmlElement, xmlEntityRef, xmlPEReference, xmlCharReference,
    xmlProcessingInstruction, xmlCData

abstract type AbstractXMLFactory end

function unsupported_xml(factory, constructor, args...)
    (:unsupported_xml, factory, constructor, args...)
end


"""
    xmlDocument(factory, prolog, root_element, misc...)

Constructs an XML document.
"""
function xmlDocument(factory::AbstractXMLFactory, children)
    unsupported_xml(factory, children)
end


"""
    xmlXMLDecl(factory::AbstractXMLFactory, attrs::AbstractDict)

Returns an XML declaration.
"""
function xmlXMLDecl(factory::AbstractXMLFactory, attrs::AbstractDict)
    unsupported_xml(factory, xmlXMLDecl, attrs)
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


"""
    xmlCharReference(factory::AbstractXMLFactory, charcode::Int)

Constructs an XML character reference.
"""
function xmlCharReference(factory::AbstractXMLFactory, charcode::Int)
    unsupported_xml(factory, xmlCharReference, charcode)
end


"""
    xmlProcessingInstruction(factory::AbstractXMLFactory, pi::AbstractString)

Constructs an XML processing instruction
"""
function xmlProcessingInstruction(factory::AbstractXMLFactory, pi::AbstractString)
    unsupported_xml(factory, xmlProcessingInstruction, pi)
end


"""
    xmlCData(factory::AbstractXMLFactory, cdata::AbstractString)

Constructs an XML CData section.
"""
function xmlCData(factory::AbstractXMLFactory, cdata::AbstractString)
    unsupported_xml(factory, xmlCData, cdata)
end

