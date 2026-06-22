import EzXML

struct EzXML_Factory <: AbstractXMLFactory end


function xmlDocument(::EzXML_Factory, children)
    XMLDocumentNode(version)
end

function xmlXMLDecl(::EzXML_Factory, attrs::AbstractDict)
end

function xmlDTD(::EzXML_Factory, input::AbstractString,
                from::Int, to::Int, value)
    name = value[3]
    external_id =
        if isempty(value[4])
            nothing
        else
            value[4][1]
        end
    internal_subset
        if isempty(value[6])
            nothing
        else
            intSubset = value[6][1][2]
            # filter out whitespace?
        end
    # nodename(DTDNode) will be name
    # systemID(DTDNode)
    # externalID(DTDNode)
    # nodes(DTDNode) will contain the various decls.

    # EzXML doesn't provide a way to add the decls.  Google Gemeni
    # suggests invoking parsexml to construct the DTDNode.  If we try
    # to call EzXML.xmlparse on just the DTD text we get an error that
    # the document has no start tag.
    EzXML.DTDNode(name)    # Incomplete
end

function xmlComment(::EzXML_Factory, input::AbstractString,
                    from::Int, to::Int, value)
    EzXML.CommentNode(value[2])
end

function xmlText(::EzXML_Factory, text)
    EzXML.TextNode(text)
end

function xmlElement(::EzXML_Factory,
                    tagname::AbstractString,
                    attributes::Vector{<:Pair{Symbol, <:AbstractString}},
                    children::Vector)
    elt = ElementNode(tagname)
    for attr in attributes
        elt[attr.first= = attr.second
    end
    for child in children
        link!(elt, chld)
    end
    elt
end

function xmlEntityRef(::EzXML_Factory, name::AbstractString)
end

function xmlPEReference(::EzXML_Factory, name::AbstractString)
end

function xmlCharReference(::EzXML_Factory, charcode::Int)
end

function xmlProcessingInstruction(::EzXML_Factory, pi::AbstractString)
end

function xmlCData(::EzXML_Factory, cdata::AbstractString)
    EzXML.CDataNode(cdata)
end

