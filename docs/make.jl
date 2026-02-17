using Documenter
using DocumenterMermaid
using Giac
# Note: Giac.Commands is not imported here because it has ~2000 auto-generated
# command functions. Their usage is documented in commands_submodule.md.
using Giac.TempApi

makedocs(
    sitename = "Giac.jl",
    # Note: Giac.Commands is excluded from modules because it has ~2000 auto-generated
    # command functions that aren't individually documented (usage is documented in
    # commands_submodule.md instead)
    modules = [Giac, Giac.TempApi],
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
    # Allow missing_docs warning for auto-generated Commands (1800+ functions)
    warnonly = [:missing_docs],
)

deploydocs(
    repo = "github.com/s-celles/Giac.jl.git",
    devbranch = "main",
)
