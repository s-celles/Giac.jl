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
        "Constants" => "constants.md",
        "Command discovery and help" => "command_discovery_help.md",
        "Variable Substitution" => "substitute.md",
        "Using with Pluto reactive notebooks" => "pluto.md",
        "Mathematics" => [
            "Algebra" => "mathematics/algebra.md",
            "Calculus" => "mathematics/calculus.md",
            "Linear Algebra" => "mathematics/linear_algebra.md",
            "Differential Equations" => "mathematics/differential_equations.md",
            "Trigonometry" => "mathematics/trigonometry.md",
        ],
        "Physics" => [
            "Mechanics" => "physics/mechanics.md",
            "Electromagnetism" => "physics/electromagnetism.md",
        ],
        "Signal Processing" => [
            "Discrete-Time Transforms" => "domains/signal/discrete_transforms.md",
            "Continuous-Time Transforms" => "domains/signal/continuous_transforms.md",
        ],
        "API Reference" => [
            "Core API" => "api/core.md",
            "GIAC Commands" => "api/giac_commands.md",
            "Commands submodule" => "api/commands_submodule.md",
            "TempApi" => "api/tempapi.md",
        ],
        "Held Commands" => "held_commands.md",
        "Tables.jl Compatibility" => "tables.md",
        "Extensions" => [
             "Symbolics.jl" => "extensions/symbolics.md",
             "MathJSON.jl" => "extensions/mathjson.md",
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
