using Documenter
using Giac
using Giac.Commands
using Giac.TempApi

makedocs(
    sitename = "Giac.jl",
    modules = [Giac, Giac.Commands, Giac.TempApi],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://s-celles.github.io/Giac.jl",
    ),
    pages = [
        "Home" => "index.md",
        "Installation" => "install.md",
        "API Reference" => [
            "Core API" => "api/core.md",
            "Commands" => "api/commands.md",
            "TempApi" => "api/tempapi.md",
        ],
    ],
    checkdocs = :exports,
    warnonly = false,  # Strict mode - fail on any warning
)

deploydocs(
    repo = "github.com/s-celles/Giac.jl.git",
    devbranch = "main",
)
