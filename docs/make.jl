using Pkg
using TOML
using Logging

function with_project_toml(f::Function, project_dir::AbstractString)
    project_path = joinpath((project_dir, "Project.toml"))
    manifest_path = joinpath((project_dir, "Manifest.toml"))
    project_toml = TOML.parsefile(project_path)
    manifest_toml = TOML.parsefile(manifest_path)
    f(project_toml, manifest_toml)
end

let
    project_path = normpath(@__DIR__, "..")
    with_project_toml(project_path) do project_toml, manifest_toml
        target = "docs"
        @assert target in keys(project_toml["targets"])
        @assert "NahaJuliaLib" in keys(project_toml["deps"])
        @assert "Documenter" in project_toml["targets"][target]
        @assert "NahaJuliaLib" in keys(manifest_toml["deps"])
        @assert "Documenter" in keys(manifest_toml["deps"])
        @assert "Test" in keys(manifest_toml["deps"])
        pspec = PackageSpec(;
                            name = project_toml["name"],
                            uuid = project_toml["uuid"],
                            path = splitdir(project_path)[1])
        @info project_toml
        # gen_target_project expects that the above uuid should
        # be in ctx.env.manifest.deps.
        ctx = Pkg.Types.Context()
        # This doesn't seem to do what we want
        docs_project = Pkg.Operations.gen_target_project(
            ctx,
            pspec,
            project_path,
            "docs")
        @info typeof(docs_project)
        @info docs_project
        docs_workspace = mktempdir()
        @info docs_workspace
        atexit(function ()
                   rm(docs_workspace; force=true, recursive=true)
               end)
        project_file = Pkg.Operations.projectfile_path(docs_workspace)
        Pkg.Types.write_project(docs_project, project_file)
        manifest_file = Pkg.Operations.manifestfile_path(docs_workspace)
        Pkg.Types.write_manifest(
            Pkg.Operations.abspath!(
                ctx.env,
                Pkg.Operations.sandbox_preserve(ctx.env,
                                                pspec, project_path)),
            manifest_file)
        @info docs_workspace
        @assert docs_workspace isa String
        with_project_toml(docs_workspace) do ptoml, mtoml
            @assert "NahaJuliaLib" in keys(ptoml["deps"])
            @assert "Documenter" in keys(ptoml["deps"])
        end                      
        Pkg.activate(docs_workspace)
    end
end


using Documenter
using AnotherParser
# using NahaJuliaLib

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
"""

