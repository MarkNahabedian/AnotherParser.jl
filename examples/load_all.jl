
using AnotherParser

Pkg.activate(; temp=true)

Pkg.develop(path=joinpath(@__DIR__, "BNFExample"))
using BNFExample

include(joinpath(@__DIR__, "Arithmetic/arithmetic.jl"))

Pkg.develop(path=joinpath(@__DIR__, "XMLExample"))
using XMLExample

