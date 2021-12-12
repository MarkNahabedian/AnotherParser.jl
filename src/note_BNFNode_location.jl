# Define BNFNode macros so we can record source locations in the BNF.

using MacroTools
using MacroTools: postwalk


function rewrite_struct(def::Expr)::Expr
    structpattern = postwalk(rmlines, Meta.parse(
        "struct nameexp_ fields__ end "))
    constructorpattern = postwalk(rmlines, Meta.parse(
        "function fname_(fargs__) fbody__ end"))
    bindings = MacroTools.match(structpattern, def)
    fields2 = map(bindings[:fields]) do e
        e = longdef(e)
        if isexpr(e, :function)
            bindings2 = MacroTools.match(constructorpattern, e)
            [
                # default source argument
                postwalk(e) do e
                    if iscall(e, :new)
                        Expr(:call, :new, nothing, e.args[2:end]...)
                    else
                        e
                    end
                end,
                # pass through source argument
                :(function $(bindings2[:fname])(source::LineNumberNode,
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
                  end)
            ]
        else
            [e]
        end
    end
    fields2 = cat(fields2...; dims=1)
    :(struct $(bindings[:nameexp])
          source::Union{Nothing, LineNumberNode}
          $(fields2...)
      end)
end

#=
macro bnfnode(exp)
    @capture(exp,
             struct nameexp_
                 fields__
             end)
    find_name(s::Symbol) = s)

    function find_name(exp::Expr)
        @assert length(exp.args) >= 1
        find_name(exp.args[1])
    end
    new_fields = []
    for field in fields
        @capture(field,
        function $name(args__)
            body__
        end |
            $name(args__) = body__)
        if body != nothing
            # Need to find the call to new and add __source__ at the beginning
            push!(new_fields, quote
                      function $name(__source__, args...)
                      end
                  end)
        else
            push!(new_fields, field)
        end
    end
    
    name = find_name(nameexp)
    quote
        struct $nameexp
            source::LineNumberNode
            $new_fields...
        end

        macro $name(args...)
            :($name(__source__, $args...))
        end
    end
end
=#
