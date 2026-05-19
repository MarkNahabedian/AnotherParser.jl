using Pkg
Pkg.activate(; temp = true)
Pkg.add("Documenter")
using Documenter

Pkg.activate(joinpath(dirname(dirname(@__FILE__)), "Project.toml"))

println(Base.load_path())

using AnotherParser
using Logging

makedocs(;
         modules=[AnotherParser],
         format=Documenter.HTML(),
         pages=[
             "Home" => "index.md",
         ],
         sitename="AnotherParser.jl",
         authors="Mark Nahabedian"
)

deploydocs(;
    repo="github.com/MarkNahabedian/AnotherParser.jl",
)

