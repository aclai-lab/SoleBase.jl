using SoleBase
using Documenter

DocMeta.setdocmeta!(SoleBase, :DocTestSetup, :(using SoleBase); recursive=true)

makedocs(;
    modules=[SoleBase],
    authors="Federico Manzella, Giovanni Pagliarini, Eduard I. Stan",
    repo=Documenter.Remotes.GitHub("aclai-lab", "SoleBase.jl"),
    sitename="SoleBase.jl",
    format=Documenter.HTML(;
        size_threshold = 4000000,
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleBase.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo = "github.com/aclai-lab/SoleBase.jl",
    target = "build",
    branch = "gh-pages",
    versions = ["main" => "main", "stable" => "v^", "v#.#", "dev" => "dev"],
)
