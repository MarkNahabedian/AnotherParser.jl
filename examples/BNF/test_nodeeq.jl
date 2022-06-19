
@testset "test nodeeq" begin
    @test nodeeq("foo", "foo")
    @test nodeeq(Empty(), Empty())
    @test nodeeq(BNFRef(:G1, "<foo>"),
                 BNFRef(:G2, "<foo>"))
    @test !nodeeq(BNFRef(:G1, "<foo>"),
                 BNFRef(:G2, "<bar>"))
    @test nodeeq(StringLiteral("foo"),
                 StringLiteral("foo"))
    @test !nodeeq(StringLiteral("foo"),
                 StringLiteral("bar"))
    @test nodeeq(Sequence(StringLiteral("foo"),
                          CharacterLiteral('a')),
                 Sequence(StringLiteral("foo"),
                          CharacterLiteral('a')))
    @test nodeeq(Alternatives(StringLiteral("foo"),
                              CharacterLiteral('a')),
                 Alternatives(StringLiteral("foo"),
                              CharacterLiteral('a')))
end

 
