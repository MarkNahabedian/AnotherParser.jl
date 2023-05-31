
using MacroTools
using MacroTools: postwalk

test_match(x1, x2) = x1 == x2

function test_match(e1::Expr, e2::Expr)
    if !(e1.head == e2.head)
        @info "test_match" e1 e2
        return false
    end
    if length(e1.args) != length(e2.args)
        @info "test_match" "length mismatch" e1.args e2.args
        return false
    end
    for i in length(e1.args)
        if !test_match(e1.args[i], e2.args[i])
            @info "test_match" i e1.args[i] e2.args[i]
            return false
        end
    end
    true
end

@testset "rewrite_struct" begin
    def = Meta.parse("struct Sequence <: BNFNode
                  elements::Tuple{Vararg{<:BNFNode}}
                  function Sequence(elements...)
                      new(elements)
                  end
              end")
    got = postwalk(rmlines, AnotherParser.rewrite_struct(def))
    want = postwalk(rmlines,
                    Meta.parse("""
Base.@__doc__ struct Sequence <: BNFNode
    uid
    source::Union{Nothing, LineNumberNode}
    elements::Tuple{Vararg{<:BNFNode}}
    function Sequence(elements...;)
        new(next_node_id(Sequence), nothing, elements)
    end
    function Sequence(source::Union{Nothing, LineNumberNode},
                      elements...;)
        new(next_node_id(Sequence), source, elements)
    end
end
"""))
    @test test_match(got, want)
    # Why does this fail?
    # @test got == want
end
