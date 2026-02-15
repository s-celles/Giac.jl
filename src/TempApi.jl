"""
    Giac.TempApi

A submodule providing convenience functions with simplified names for common
symbolic computation operations. These functions delegate to the corresponding
`giac_*` functions from the main Giac module.

# Access Patterns

1. **Full import** (for interactive use):
   ```julia
   using Giac
   using Giac.TempApi

   x = giac_eval("x")
   expr = giac_eval("x^2 - 1")
   diff(expr, x)           # 2*x
   factor(expr)            # (x-1)*(x+1)
   ```

2. **Selective import** (recommended):
   ```julia
   using Giac
   using Giac.TempApi: diff, factor

   x = giac_eval("x")
   expr = giac_eval("x^2 - 1")
   diff(expr, x)    # Works
   factor(expr)     # Works
   ```

3. **Qualified access**:
   ```julia
   using Giac

   x = giac_eval("x")
   expr = giac_eval("x^2 - 1")
   Giac.TempApi.diff(expr, x)
   Giac.TempApi.factor(expr)
   ```

# Exports

- `diff`: Differentiate an expression (delegates to `giac_diff`)
- `integrate`: Integrate an expression (delegates to `giac_integrate`)
- `limit`: Compute limit (delegates to `giac_limit`)
- `factor`: Factor a polynomial (delegates to `giac_factor`)
- `expand`: Expand an expression (delegates to `giac_expand`)
- `simplify`: Simplify an expression (delegates to `giac_simplify`)
- `solve`: Solve an equation (delegates to `giac_solve`)

# See also

- [`giac_diff`](@ref), [`giac_integrate`](@ref), etc.: Original functions in main module
- [`Giac.Commands`](@ref): Submodule with all GIAC commands
"""
module TempApi

using ..Giac: GiacExpr, giac_eval,
              giac_diff, giac_integrate, giac_limit,
              giac_factor, giac_expand, giac_simplify, giac_solve

# =============================================================================
# Calculus Functions
# =============================================================================

"""
    diff(expr, var, n=1)

Compute the nth derivative of an expression with respect to a variable.

Delegates to [`giac_diff`](@ref).

# Arguments
- `expr`: Expression to differentiate (GiacExpr or String)
- `var`: Variable to differentiate with respect to (GiacExpr or String)
- `n`: Order of differentiation (default: 1)

# Returns
- `GiacExpr`: The derivative

# Example
```julia
using Giac
using Giac.TempApi

f = giac_eval("x^3")
x = giac_eval("x")
diff(f, x)      # 3*x^2
diff(f, x, 2)   # 6*x
```

# See also
- [`giac_diff`](@ref): Original function in main Giac module
"""
diff(expr::GiacExpr, var::GiacExpr, n::Int=1) = giac_diff(expr, var, n)
diff(expr::String, var::String, n::Int=1) = giac_diff(expr, var, n)

"""
    integrate(expr, var)
    integrate(expr, var, a, b)

Compute indefinite or definite integral.

Delegates to [`giac_integrate`](@ref).

# Arguments
- `expr`: Expression to integrate (GiacExpr or String)
- `var`: Variable of integration (GiacExpr or String)
- `a`, `b`: Optional bounds for definite integration

# Returns
- `GiacExpr`: The integral

# Example
```julia
using Giac
using Giac.TempApi

f = giac_eval("x^2")
x = giac_eval("x")
integrate(f, x)           # x^3/3
integrate(f, x, 0, 1)     # 1/3
```

# See also
- [`giac_integrate`](@ref): Original function in main Giac module
"""
integrate(expr::GiacExpr, var::GiacExpr) = giac_integrate(expr, var)
integrate(expr::GiacExpr, var::GiacExpr, a::GiacExpr, b::GiacExpr) = giac_integrate(expr, var, a, b)
integrate(expr::GiacExpr, var::GiacExpr, a::Number, b::Number) = giac_integrate(expr, var, a, b)
integrate(expr::String, var::String) = giac_integrate(expr, var)
integrate(expr::String, var::String, a, b) = giac_integrate(expr, var, a, b)

"""
    limit(expr, var, point; direction=:both)

Compute the limit of an expression as a variable approaches a point.

Delegates to [`giac_limit`](@ref).

# Arguments
- `expr`: The expression (GiacExpr or String)
- `var`: The variable (GiacExpr or String)
- `point`: The point to approach
- `direction`: `:left`, `:right`, or `:both` (default)

# Returns
- `GiacExpr`: The limit

# Example
```julia
using Giac
using Giac.TempApi

f = giac_eval("sin(x)/x")
x = giac_eval("x")
limit(f, x, giac_eval("0"))  # 1
```

# See also
- [`giac_limit`](@ref): Original function in main Giac module
"""
limit(expr::GiacExpr, var::GiacExpr, point::GiacExpr; direction::Symbol=:both) =
    giac_limit(expr, var, point; direction=direction)
limit(expr::String, var::String, point; direction::Symbol=:both) =
    giac_limit(expr, var, point; direction=direction)

# =============================================================================
# Algebra Functions
# =============================================================================

"""
    factor(expr)

Factor a polynomial expression.

Delegates to [`giac_factor`](@ref).

# Arguments
- `expr`: Expression to factor (GiacExpr or String)

# Returns
- `GiacExpr`: The factored expression

# Example
```julia
using Giac
using Giac.TempApi

p = giac_eval("x^2 - 1")
factor(p)  # (x-1)*(x+1)
```

# See also
- [`giac_factor`](@ref): Original function in main Giac module
"""
factor(expr::GiacExpr) = giac_factor(expr)
factor(expr::String) = giac_factor(expr)

"""
    expand(expr)

Expand a polynomial expression.

Delegates to [`giac_expand`](@ref).

# Arguments
- `expr`: Expression to expand (GiacExpr or String)

# Returns
- `GiacExpr`: The expanded expression

# Example
```julia
using Giac
using Giac.TempApi

p = giac_eval("(x+1)^3")
expand(p)  # x^3 + 3*x^2 + 3*x + 1
```

# See also
- [`giac_expand`](@ref): Original function in main Giac module
"""
expand(expr::GiacExpr) = giac_expand(expr)
expand(expr::String) = giac_expand(expr)

"""
    simplify(expr)

Simplify an expression.

Delegates to [`giac_simplify`](@ref).

# Arguments
- `expr`: Expression to simplify (GiacExpr or String)

# Returns
- `GiacExpr`: The simplified expression

# Example
```julia
using Giac
using Giac.TempApi

e = giac_eval("(x^2 - 1)/(x - 1)")
simplify(e)  # x + 1
```

# See also
- [`giac_simplify`](@ref): Original function in main Giac module
"""
simplify(expr::GiacExpr) = giac_simplify(expr)
simplify(expr::String) = giac_simplify(expr)

"""
    solve(expr, var)

Solve an equation for a variable.

Delegates to [`giac_solve`](@ref).

# Arguments
- `expr`: The equation (assumed equal to 0) or an equation with =
- `var`: The variable to solve for

# Returns
- `GiacExpr`: Solution set

# Example
```julia
using Giac
using Giac.TempApi

eq = giac_eval("x^2 - 4")
x = giac_eval("x")
solve(eq, x)  # [-2, 2]
```

# See also
- [`giac_solve`](@ref): Original function in main Giac module
"""
solve(expr::GiacExpr, var::GiacExpr) = giac_solve(expr, var)
solve(expr::String, var::String) = giac_solve(expr, var)

# =============================================================================
# Exports
# =============================================================================

export diff, integrate, limit, factor, expand, simplify, solve

end # module TempApi
