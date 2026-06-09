# Google Gemeni provided much of this model.

abstract type HSNode end

mutable struct HSDocument <: HSNode
    xmldecl::Union{Nothing, HSXMLDeclaration, HSComment, }
    prolog::Vector{}
    # dtd::Union{Nothing, HSNode}
    root::HSNode
end

mutable struct HSXMLDeclaration <: HSNode
    name::AbstractString
    system_id::AbstractString
    public_id::AbstractString
end

mutable struct HSPI <: HSNode
    target::AbstractString
    data::AbstractString
end

mutable struct HSElement <: HSNode
    tagname::AbstractString
    attributes::OrderedDict{AbstractString, AbstractString}
    is_emptytag::Bool
    children::Vector{HSNode}

    HSElement(tagname) =
        new(tagname, OrderedDict{AbstractString, AbstractString}(), HSNode[])
end

mutable struct HSText  <: HSNode
    text::AbstractSTring
    is_csata::Bool
end

mutable struct HSComment <: Comment
    comment::AbstractSTring
end


    
