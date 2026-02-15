"""
    Giac

A Julia wrapper for the GIAC computer algebra system.

Provides symbolic expression evaluation, calculus operations, polynomial
manipulation, and linear algebra with a Julia-native API.

# Core Exports
- `GiacExpr`: Symbolic expression type
- `GiacContext`: Evaluation context
- `GiacMatrix`: Symbolic matrix type
- `GiacError`: Exception type for GIAC errors
- `giac_eval`: Evaluate expression strings
- `to_julia`: Convert GiacExpr to Julia types
- `invoke_cmd`: Universal command invocation (works for ALL commands)
- `giac_diff`, `giac_integrate`, `giac_limit`, `giac_series`: Calculus
- `giac_factor`, `giac_expand`, `giac_simplify`, `giac_solve`, `giac_gcd`: Algebra

# Command Access

GIAC commands are available through the `Giac.Commands` submodule:

```julia
using Giac

# Use invoke_cmd for any command (always available)
invoke_cmd(:factor, giac_eval("x^2-1"))
invoke_cmd(:sin, giac_eval("pi/6"))  # Works for conflicting commands too

# Import commands selectively (recommended)
using Giac.Commands: factor, expand, diff
factor(giac_eval("x^2-1"))

# Or import all ~2000+ commands
using Giac.Commands
factor(giac_eval("x^2-1"))
ifactor(giac_eval("120"))
```

# Example
```julia
using Giac

result = giac_eval("factor(x^2 - 1)")
println(result)  # (x-1)*(x+1)
```

# See also
- [`Giac.Commands`](@ref): Submodule with all exportable commands
- [`invoke_cmd`](@ref): Universal command invocation
"""
module Giac

using LinearAlgebra

# Include source files
include("types.jl")
include("utils.jl")
include("wrapper.jl")
include("command_registry.jl")
include("commands.jl")
include("namespace_commands.jl")
include("api.jl")
include("operators.jl")

# Include Commands submodule (009-commands-submodule)
include("Commands.jl")

# Types
export GiacExpr, GiacContext, GiacMatrix, GiacError, HelpResult

# Core functions
export giac_eval, to_julia, is_stub_mode, list_commands, help_count

# Command invocation (009-commands-submodule)
# invoke_cmd replaces giac_cmd - available from main module and Giac.Commands
export invoke_cmd
export search_commands, commands_in_category, command_info, list_categories, giac_help, help

# Command suggestions (005-nearest-command-suggestions)
export suggest_commands, set_suggestion_count, get_suggestion_count

# Description search (006-search-command-description)
export search_commands_by_description

# All commands access (008-all-giac-commands)
export JULIA_CONFLICTS, exportable_commands, is_valid_command, conflict_reason
export available_commands, reset_conflict_warnings!

# GiacCommand type (kept for compatibility, callable uses invoke_cmd internally)
export GiacCommand

# Re-export invoke_cmd from Commands submodule (009-commands-submodule)
# This makes invoke_cmd available directly after `using Giac`
using .Commands: invoke_cmd

# Conversion functions (extended by GiacSymbolicsExt)
export to_giac, to_symbolics

"""
    to_giac(expr)

Convert an expression to GiacExpr. Extended by GiacSymbolicsExt for Symbolics.Num types.
"""
function to_giac end

"""
    to_symbolics(expr::GiacExpr)

Convert a GiacExpr to a Symbolics.jl expression. Extended by GiacSymbolicsExt.
"""
function to_symbolics end

# Calculus functions
export giac_diff, giac_integrate, giac_limit, giac_series

# Algebra functions
export giac_factor, giac_expand, giac_simplify, giac_solve, giac_gcd

# Default context (initialized in __init__)
const DEFAULT_CONTEXT = Ref{GiacContext}()

"""
    __init__()

Initialize the Giac module at runtime. Sets up the default context,
loads the GIAC library, and initializes the command registry.

# Initialization Steps
1. Initialize the GIAC library and default context
2. Populate the command registry from GIAC's help database
3. The Commands submodule then generates wrapper functions in Commands.__init__()

# Performance
- Total initialization typically completes in < 5 seconds
- Runtime function generation adds ~1 second for ~2000 functions

# Note
Command function generation moved to Giac.Commands submodule (009-commands-submodule).
"""
function __init__()
    try
        init_giac_library()
        DEFAULT_CONTEXT[] = GiacContext()
        # Initialize command registry (003-giac-commands)
        _init_command_registry()
        # Note: Command functions are generated in Commands.__init__() (009-commands-submodule)
    catch e
        @error "Failed to initialize GIAC library" exception=e
        rethrow()
    end
end

"""
    list_commands()

Return a vector of all available GIAC command names.

# Example
```julia
cmds = list_commands()
println("Number of commands: ", length(cmds))
println("First 10: ", cmds[1:10])
```
"""
function list_commands()
    if !_stub_mode[] && GiacCxxBindings._have_library
        cmds_str = GiacCxxBindings.list_commands()
        return split(cmds_str, '\n')
    end
    return String[]
end

"""
    help_count()

Return the number of commands in the GIAC help database.
"""
function help_count()
    if !_stub_mode[] && GiacCxxBindings._have_library
        return GiacCxxBindings.help_count()
    end
    return 0
end

end # module Giac
