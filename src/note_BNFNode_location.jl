# Define BNFNode macros so we can record source locations in the BNF.

using MacroTools
using MacroTools: postwalk


find_name(s::Symbol) = s

function find_name(exp::Expr)
    @assert length(exp.args) >= 1
    find_name(exp.args[1])
end

function rewrite_struct(def::Expr)::Expr
    structpattern = postwalk(rmlines, Meta.parse(
        "struct nameexp_ fields__ end "))
    constructorpattern = postwalk(rmlines, Meta.parse(
        "function fname_(fargs__) fbody__ end"))
    bindings = MacroTools.match(structpattern, def)
    fields = []
    constructors = []
    for e in bindings[:fields]
        e = longdef(e)
        if isexpr(e, :function)
            push!(constructors, e)
        else
            push!(fields, e)
        end
    end
    if length(constructors) == 0
        # Add default constructor
        name = find_name(bindings[:nameexp])
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
              # This might be misleading since it preserves the source
              # location in the original struct definition even though
              # we do a code substitution.
              postwalk(e) do e
                  if iscall(e, :new)
                      Expr(:call, :new, nothing, e.args[2:end]...)
                  else
                      e
                  end
              end)
        # pass through source argument
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
    :(struct $(bindings[:nameexp])
          source::Union{Nothing, LineNumberNode}
          $(fields...)

          $(constructors2...)
      end)
end


function BNFNodeMacro(macroname, constructorname)
    args = gensym("args")
    :(macro $macroname(($args)...)
          Expr(:call, $constructorname,
               __source__, ($args)...)
      end)
end

export @bnfnode

macro bnfnode(exp)
    @capture(exp,
             struct nameexp_
                 fields__
             end)
    name = find_name(nameexp)
    mname = Symbol("@$name")
    source = __source__
    @assert source isa LineNumberNode
    argselipsis = Expr(:(...), Expr(:escape, :args))

    Expr(:block,
         rewrite_struct(exp),
         Expr(:export, name, mname),
         esc(BNFNodeMacro(name, name)))
end

