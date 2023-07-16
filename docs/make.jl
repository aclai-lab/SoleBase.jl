using SoleBase
using Documenter

DocMeta.setdocmeta!(SoleBase, :DocTestSetup, :(using SoleBase); recursive=true)

makedocs(;
    modules=[SoleBase],
    authors="Federico Manzella, Giovanni Pagliarini, Eduard I. Stan",
    repo="https://github.com/aclai-lab/SoleBase.jl/blob/{commit}{path}#{line}",
    sitename="SoleBase.jl",
    format=Documenter.HTML(;
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
    devbranch = "main",
    target = "build",
    branch = "gh-pages",
    versions = ["stable" => "v^", "v#.#"],
)
