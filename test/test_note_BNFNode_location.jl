
using MacroTools
using MacroTools: postwalk

@testset "rewrite_struct" begin
    def = Meta.parse("struct Sequence <: BNFNode
                  elements::Tuple{Vararg{<:BNFNode}}
                  function Sequence(elements...)
                      new(elements)
                  end
              end")
    got = postwalk(rmlines, AnotherParser.rewrite_struct(def))
    want = postwalk(rmlines,
                    Meta.parse("struct Sequence <: BNFNode
                                    source::Union{Nothing, LineNumberNode}
                                    elements::Tuple{Vararg{<:BNFNode}}
                                    function Sequence(elements...)
                                        new(nothing, elements)
                                    end
                                    function Sequence(source::Union{Nothing, LineNumberNode},
                                                      elements...)
                                        new(source, elements)
                                    end
                                end"))
    # ??? Why does Expr == Expr fail?
    # @test got == want
    @test string(got) == string(want)
end

