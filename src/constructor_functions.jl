
export identity_constructor_function, substring_constructor_function,
    deep_flatten, flattening_constructor_function


    """
    identity_constructor_function(context, input::AbstractString, from::Int, to::Int, value)

A constructor function that just returns the raw value from its
associated DerivationRule or subexpression.
"""
identity_constructor_function(context, input::AbstractString, from::Int, to::Int, value) = value


"""
    substring_constructor_function(context, input::AbstractString, from::Int, to::Int, value)

A constructor function that ruturns the matched substring.
"""
substring_constructor_function(context, input::AbstractString, from::Int, to::Int, value) =
    SubString(input, from, to)


"""
    deep_flatten(collection)

Flattens an arbitrarily deeply nested collection.
"""
function deep_flatten(collection)
    result = []
    function walk(v)
        if v isa AbstractString
            push!(result, v)
        elseif v isa Number
            push!(result, v)
        elseif applicable(iterate, v)
            for v1 in v
                walk(v1)
            end
        else
            push!(result, v)
        end
    end
    walk(collection)
    result
end


"""
    flattening_constructor_function(context, input::AbstractString, from::Int, to::Int, value)

Returns a flattened list given an arbitrarily nested one.
"""
flattening_constructor_function(context, input::AbstractString, from::Int, to::Int, value) =
    deep_flatten(value)


