using Documenter
using AnotherParser

# Temporary hack:
push!(LOAD_PATH,"../src/")

makedocs(;
         modules=[AnotherParser],
         format=Documenter.HTML(),
         pages=[
             "Home" => "index.md",
         ],
         # repo="https://github.com/MarkNahabedian/AnotherParser.jl/blob/{commit}{path}#L{line}",
         sitename="AnotherParser.jl",
         authors="Mark Nahabedian"
         )
