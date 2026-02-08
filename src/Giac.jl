"""
    Giac

A Julia wrapper for the GIAC computer algebra system.

Provides symbolic expression evaluation, calculus operations, polynomial
manipulation, and linear algebra with a Julia-native API.

# Exports
- `GiacExpr`: Symbolic expression type
- `GiacContext`: Evaluation context
- `GiacMatrix`: Symbolic matrix type
- `GiacError`: Exception type for GIAC errors
- `giac_eval`: Evaluate expression strings
- `to_julia`: Convert GiacExpr to Julia types
- `giac_diff`, `giac_integrate`, `giac_limit`, `giac_series`: Calculus
- `giac_factor`, `giac_expand`, `giac_simplify`, `giac_solve`, `giac_gcd`: Algebra

# Example
```julia
using Giac

result = giac_eval("factor(x^2 - 1)")
println(result)  # (x-1)*(x+1)
```
"""
module Giac

using LinearAlgebra

# Include source files
include("types.jl")
include("utils.jl")
include("wrapper.jl")
include("api.jl")
include("operators.jl")

# Types
export GiacExpr, GiacContext, GiacMatrix, GiacError

# Core functions
export giac_eval, to_julia, is_stub_mode

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

Initialize the Giac module at runtime. Sets up the default context
and loads the GIAC library.
"""
function __init__()
    try
        init_giac_library()
        DEFAULT_CONTEXT[] = GiacContext()
    catch e
        @error "Failed to initialize GIAC library" exception=e
        rethrow()
    end
end

end # module Giac
