
using Documenter
using DocumenterTools
using AnotherParser

#=
See this document
https://juliadocs.github.io/Documenter.jl/stable/man/hosting/
for somewhat rambling instructions about how to set up a
documentation generation workflow.
=#

# Temporary hack:
push!(LOAD_PATH,"../src/")

#=
# One time setup of deployment secret
DocumenterTools.genkeys(; user="MarkNahabedian",
                        repo="AnotherParser.jl")
=#

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
