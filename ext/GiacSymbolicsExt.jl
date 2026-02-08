# Extension module for Symbolics.jl integration
# Provides bidirectional conversion between GiacExpr and Symbolics.Num types

module GiacSymbolicsExt

using Giac
using Symbolics

"""
    to_giac(expr::Num)

Convert a Symbolics.jl expression to a GiacExpr.

# Example
```julia
using Giac, Symbolics
@variables x y
giac_expr = to_giac(x^2 + y)
```
"""
function Giac.to_giac(expr::Num)::GiacExpr
    # Convert Symbolics expression to string and parse with GIAC
    expr_str = string(Symbolics.unwrap(expr))
    return giac_eval(expr_str)
end

"""
    to_symbolics(expr::GiacExpr)

Convert a GiacExpr to a Symbolics.jl Num expression.

# Example
```julia
using Giac, Symbolics
result = giac_eval("x^2 + y")
sym_expr = to_symbolics(result)
```
"""
function Giac.to_symbolics(expr::GiacExpr)
    # Convert GIAC expression to string and parse with Symbolics
    expr_str = string(expr)
    # Use Symbolics parsing
    return Symbolics.parse_expr_to_symbolic(Meta.parse(expr_str), @__MODULE__)
end

# Export conversion functions
export to_giac, to_symbolics

end # module GiacSymbolicsExt
