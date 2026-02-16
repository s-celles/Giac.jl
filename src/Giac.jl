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
- `@giac_var`: Create symbolic variables from Julia symbols
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

# Quick Start
```julia
using Giac

# Declare symbolic variables with @giac_var macro
@giac_var x y

# Build and manipulate expressions
expr = giac_eval("x^2 + 2*x*y + y^2")
result = giac_factor(expr)   # (x+y)^2

# Or use string-based evaluation directly
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
include("command_utils.jl")
include("namespace_commands.jl")
include("api.jl")
include("operators.jl")
include("macros.jl")

# Include Commands submodule (009-commands-submodule)
include("Commands.jl")

# Include TempApi submodule (010-tempapi-submodule)
include("TempApi.jl")

# Types
export GiacExpr, GiacContext, GiacMatrix, GiacError, HelpResult

# Core functions
export giac_eval, to_julia, is_stub_mode, list_commands, help_count

# Macros (011-giac-symbol-macro, 012-giac-several-var)
export @giac_var, @giac_several_vars

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

# ============================================================================
# LaTeX Display Support (014-pluto-latex-notebook)
# ============================================================================

"""
    Base.show(io::IO, ::MIME"text/latex", expr::GiacExpr)

Display a GiacExpr as LaTeX. Enables automatic LaTeX rendering in Pluto notebooks
and other environments that support the `text/latex` MIME type.

# Example
In Pluto, simply evaluating a GiacExpr will render it as formatted mathematics:
```julia
using Giac
f = giac_eval("2/(1-x)")  # Renders as LaTeX fraction in Pluto
```
"""
function Base.show(io::IO, ::MIME"text/latex", expr::GiacExpr)
    latex_result = invoke_cmd(:latex, expr)
    latex_str = string(latex_result)
    if length(latex_str) > 2
        print(io, "\$\$", latex_str[2:end-1], "\$\$")  # Remove surrounding quotes from GIAC's LaTeX output
    else
        # Fallback to default display if LaTeX conversion fails
        print(io, string(expr))
    end
end

"""
    Base.show(io::IO, ::MIME"text/latex", m::GiacMatrix)

Display a GiacMatrix as LaTeX. Enables automatic LaTeX rendering in Pluto notebooks
and other environments that support the `text/latex` MIME type.

# Example
In Pluto, simply evaluating a GiacMatrix will render it as a formatted matrix:
```julia
using Giac
M = GiacMatrix([1 2; 3 4])  # Renders as LaTeX matrix in Pluto
```
"""
function Base.show(io::IO, ::MIME"text/latex", m::GiacMatrix)
    # Build matrix string in GIAC format: [[a,b],[c,d]]
    rows_str = String[]
    for i in 1:m.rows
        row_elements = String[]
        for j in 1:m.cols
            push!(row_elements, string(m[i, j]))
        end
        push!(rows_str, "[" * join(row_elements, ",") * "]")
    end
    matrix_str = "[" * join(rows_str, ",") * "]"

    # Call latex command on the matrix string
    matrix_expr = giac_eval(matrix_str)
    latex_result = invoke_cmd(:latex, matrix_expr)
    latex_str = string(latex_result)
    if length(latex_str) > 2
        print(io, "\$\$", latex_str[2:end-1], "\$\$")  # Remove surrounding quotes from GIAC's LaTeX output
    else
        # Fallback to default display if LaTeX conversion fails
        print(io, string(m))
    end
end

end # module Giac
