using Documenter
using DocumenterMermaid
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
        "Quick Start" => "quickstart.md",
        "Variable Declaration" => "variables.md",
        "Using with Pluto reactive notebooks" => "pluto.md",
        "Command discovery and help" => "command_discovery_help.md",
        "Linear Algebra" => "linear_algebra.md",
        "Tables.jl Compatibility" => "tables.md",
        "Variable Substitution" => "substitute.md",
        "API Reference" => [
            "Core API" => "api/core.md",
            "GIAC Commands" => "api/giac_commands.md",
            "Commands submodule" => "api/commands_submodule.md",
            "TempApi" => "api/tempapi.md",
        ],
        "Extensions" => [
             "Symbolics.jl" => "extensions/symbolics.md",
        ],
        "Developer Guide" => [
            "Overview" => "developer/index.md",
            "Package Architecture" => "developer/architecture.md",
            "Performance Tiers" => "developer/tier-system.md",
            "Adding Functions" => "developer/contributing.md",
            "Memory Management" => "developer/memory.md",
            "Troubleshooting" => "developer/troubleshooting.md",
        ],
    ],
    checkdocs = :exports,
    warnonly = false,  # Strict mode - fail on any warning
)

deploydocs(
    repo = "github.com/s-celles/Giac.jl.git",
    devbranch = "main",
)
