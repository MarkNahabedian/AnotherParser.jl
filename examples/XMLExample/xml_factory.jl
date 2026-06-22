# Abstract definitions of the generic functions that the XML grammar
# will use to construct an XML document.

export AbstractXMLFactory, xmlDocument, xmlDTD, xmlComment, xmlText,
    xmlElement, xmlEntityRef, xmlPEReference, xmlCharReference,
    xmlProcessingInstruction, xmlCData

abstract type AbstractXMLFactory end

function unsupported_xml(factory, constructor, args...)
    @warn("unsupported_xml", factory, constructor, args)
    (:unsupported_xml, factory, constructor, args...)
end


"""
    xmlDocument(factory, input::AbstractString, from::Int, to::Int, value)

Constructs an XML document.
"""
function xmlDocument(factory::AbstractXMLFactory, input::AbstractString, from::Int, to::Int, value)
    unsupported_xml(factory, xmlDocument, children)
end


"""
    xmlXMLDecl(factory, input::AbstractString, from::Int, to::Int, value)

Returns an XML declaration.
"""
function xmlXMLDecl(factory::AbstractXMLFactory, input::AbstractString, from::Int, to::Int, value)
    unsupported_xml(factory, xmlXMLDecl, attrs)
end


"""
    xmlDTD(factory, input::AbstractString, from::Int, to::Int, value)

Constructs a document type definition.
"""
function xmlDTD(factory::AbstractXMLFactory, input::AbstractString, from::Int, to::Int, value)
    unsupported_xml(factory, xmlDTD, dtd)
end


"""
    xmlComment(factory, input::AbstractString, from::Int, to::Int, value)

Construct an XML comment node.
"""
function xmlComment(factory::AbstractXMLFactory, input::AbstractString, from::Int, to::Int, value)
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
    xmlElement(factory, input::AbstractString, from::Int, to::Int, value)

Construct an XML element.
"""
function xmlElement(factory::AbstractXMLFactory, input::AbstractString,
                    from::Int, to::Int, value)
    unsupported_xml(factory, xmlElement, tagname, attributes, children)
end

"""
    xmlEntityRef(factory, name::AbstractString)

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
    xmlProcessingInstruction(factory, input::AbstractString, from::Int, to::Int, value)

Constructs an XML processing instruction
"""
function xmlProcessingInstruction(factory::AbstractXMLFactory,
                                  input::AbstractString, from::Int, to::Int, value)
    unsupported_xml(factory, xmlProcessingInstruction, pi)
end


"""
    xmlCData(factory::AbstractXMLFactory, input::AbstractString, from::Int, to::Int, value)

Constructs an XML CData section.
"""
function xmlCData(factory::AbstractXMLFactory, input::AbstractString, from::Int, to::Int, value)
    unsupported_xml(factory, xmlCData, value)
end


"""
    xmlCData(factory::AbstractXMLFactory, tarfget::AbstractString, content::AbstractString)

Constructs the representation of a Processing Instruction.  Note that
in the XML Infoset, these include DTD content likke ELEMENT and
ENTITY.
"""
function xmlPI(factory::AbstractXMLFactory, ::Any...)   # tarfget::AbstractString, content::AbstractString)
    unsupported_xml(factory, xmlPI, value)
end

#=

Evolution towards supporting multiple factories -- making the factory
interface and the grammar proper agnostic about the XML backend.

At this point we want to support both XML.jl and EzXML.

Any of the productions that use substring_constructor_function can
still do so.

"Names" and "Nmtokens": These constructors are already agnostic to
back end factory.  Uses Constructor for internal cleanup but I think
that is agnostic to back ends.

"AttValue":  already agnostic to back end factory.

"prolog": I think this constructor is a cleanup step that is back end
agnostic.

"VersionInfo": I think that this constructor is agnostic.

"Misc": this is currently a hand coding of the identty constructor.
Can we just revert to the default?  It uses Constructor to indicate
whitespace in Misc should be ignored.

"SDDecl":  I think this one is agnostic to back end.

"<AttributeList>": I think we can keep this constructor as is.

"Attribute": I think we can keep this constructor as is.

"EmptyElemTag", "STag" and construct_element_tag: I think we can keep
this constructor as is.  Maybe add a flag to distinguish empty element
nodes.

Fort these productions, redefine the factory function to confrm to the
constructor function interface and have the methods for each backend
do what they need to:

* "document"      xmlDocument
* "Comment"       xmlComment        USES Constructor, but I think agnostically.
* "CDSect"        xmlCData
* "PI"            xmlProcessingInstruction    CAN NO LONGER USE Constructor value_is_from_index
                                              I''m not sure what to do with the Chars data.
* "XMLDecl"       xmlXMLDecl
* "doctypedecl"   xmlDTD            THIS ONE MIGHT BE TRICKY THOUGH
* "element"       xmlElement


Baseline test against XML.jl before the above changes:

┌ Info: XML parser conformance test stats
│   file_count = 120
│   parse_failure_count = 8
└   mismatch_count = 24

After converting the above listed factory functions to the constructor
function interface:

┌ Info: XML parser conformance test stats
│   file_count = 120
│   parse_failure_count = 8
└   mismatch_count = 24


=#

