# Define BNFNode macros so we can record source locations in the BNF.

using MacroTools
using MacroTools: postwalk


find_name(s::Symbol) = s

function find_name(exp::Expr)
    @assert length(exp.args) >= 1
    find_name(exp.args[1])
end

function grok_struct(def::Expr)
    mutable = false
    if @capture(def,
                mutable struct nameexp_
                    fields__
                end)
        mutable = true
    elseif !@capture(def,
                    struct nameexp_
                        fields__
                    end)
        error("@bnfnode: unrecognized struct definition")
    end
    return mutable, nameexp, fields
end

let
    next_id = 1
    global function next_node_id(name)
        x = next_id
        next_id += 1
        "$(name)_$x"
    end
end

function rewrite_constructor(constructor::Expr, add_source::Bool)::Expr
    s = splitdef(constructor)
    if add_source
        opt = findfirst(s[:args]) do a
            isexpr(a, :kw)
        end
        if opt === nothing
            opt = max(1, length(s[:args]))
        end
        insert!(s[:args], opt,
                :(source::Union{Nothing, LineNumberNode}))
    end
    s[:body] = postwalk(s[:body]) do e
        if iscall(e, :new)
            Expr(:call, :new,
                 Expr(:call, :next_node_id, find_name(s[:name])),
                 if add_source
                     :source
                 else
                     nothing
                 end,
                 e.args[2:end]...)
        else
            e
        end
    end
    combinedef(s)
end

function rewrite_struct(def::Expr)::Expr
    mutable, nameexp, f = grok_struct(def)
    fields = []
    constructors = []
    for e in f
        e = longdef(e)
        if isexpr(e, :function)
            push!(constructors, e)
        else
            push!(fields, e)
        end
    end
    name = find_name(nameexp)
    if length(constructors) == 0
        # Add default constructor
        args = map(find_name, fields)
        push!(constructors,
              :(function $name($(args...))
                    new($(args...))
                end))
    end
    # Modify the constructors to initialize the :uid and :source
    # fields:
    constructors2 = []
    for e in constructors
        # default uid and source arguments
        push!(constructors2, rewrite_constructor(e, false))
        # pass through source argument
        push!(constructors2, rewrite_constructor(e, true))
    end
    Expr(:macrocall, Expr(:., :Base, QuoteNode(Symbol("@__doc__"))),
         nothing, # LineNumberNode
         Expr(:struct, mutable, nameexp,
              Expr(:block,
                   :uid,
                   Expr(:(::), :source,
                        Expr(:curly, :Union, Nothing, LineNumberNode)),
                   fields...,
                   constructors2...)))
end


export @bnfnode

macro bnfnode(exp)
    mutable, nameexp, fields = grok_struct(exp)
    name = find_name(nameexp)
    mname = Symbol("@$name")
    source = __source__
    @assert source isa LineNumberNode
    quote
        $(esc(rewrite_struct(exp)))

        export $(esc(name)), $(esc(mname))
        macro $(esc(name))(args...)
            Expr(:call, $(esc(name)), $(esc(source)), args...)
        end
        $(esc(name))
    end
end

