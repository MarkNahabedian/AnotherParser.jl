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
    if length(constructors) == 0
        # Add default constructor
        name = find_name(nameexp)
        args = map(find_name, fields)
        push!(constructors,
              :(function $name($(args...))
                    new($(args...))
                end))
    end
    constructors2 = []
    for e in constructors
        # default source argument
        push!(constructors2,
              postwalk(e) do e
                  if iscall(e, :new)
                      # Default the source argument when calling new
                      # in existing methods:
                      Expr(:call, :new, nothing, e.args[2:end]...)
                  else
                      e
                  end
              end)
        # pass through source argument
        constructorpattern = postwalk(rmlines, Meta.parse(
            "function fname_(fargs__) fbody__ end"))
        bindings2 = MacroTools.match(constructorpattern, e)
        push!(constructors2,
              :(function $(bindings2[:fname])(source::Union{Nothing, LineNumberNode},
                                              $(bindings2[:fargs]...))
                    $(map(bindings2[:fbody]) do e
                          postwalk(e) do e
                              if iscall(e, :new)
                                  Expr(:call, :new, :source, e.args[2:end]...)
                              else
                                  e
                              end
                          end
                      end...)
                end))
    end
    Expr(:macrocall, Expr(:., :Base, QuoteNode(Symbol("@__doc__"))),
         nothing, # LineNumberNode
         Expr(:struct, mutable, nameexp,
              Expr(:block,
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
        $(rewrite_struct(exp))

        export $(esc(name)), $(esc(mname))

        macro $(esc(name))(args...)
            Expr(:call, $(esc(name)), $(esc(source)), args...)
        end
        $(esc(name))
    end
end

