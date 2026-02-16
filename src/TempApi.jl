"""
    Giac.TempApi

A submodule providing convenience functions with simplified names for common
symbolic computation operations. These functions delegate to `invoke_cmd`
from the main Giac module.

This is intended as a temporary API for interactive use and quick access to 
common commands without needing to import the entire `Giac.Commands` submodule.

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

- `diff`: Differentiate an expression (uses `invoke_cmd(:diff, ...)`)
- `integrate`: Integrate an expression (uses `invoke_cmd(:integrate, ...)`)
- `limit`: Compute limit (uses `invoke_cmd(:limit, ...)`)
- `factor`: Factor a polynomial (uses `invoke_cmd(:factor, ...)`)
- `expand`: Expand an expression (uses `invoke_cmd(:expand, ...)`)
- `simplify`: Simplify an expression (uses `invoke_cmd(:simplify, ...)`)
- `solve`: Solve an equation (uses `invoke_cmd(:solve, ...)`)

# See also

- [`invoke_cmd`](@ref): Universal command invocation
- [`Giac.Commands`](@ref): Submodule with all GIAC commands
"""
module TempApi

using ..Giac: GiacExpr, giac_eval

# Import invoke_cmd from Commands submodule
using ..Giac.Commands: invoke_cmd

# =============================================================================
# Calculus Functions
# =============================================================================

"""
    diff(expr, var, n=1)

Compute the nth derivative of an expression with respect to a variable.

Uses `invoke_cmd(:diff, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
diff(expr::GiacExpr, var::GiacExpr, n::Int=1) = invoke_cmd(:diff, expr, var, n)
diff(expr::String, var::String, n::Int=1) = invoke_cmd(:diff, giac_eval(expr), giac_eval(var), n)

"""
    integrate(expr, var)
    integrate(expr, var, a, b)

Compute indefinite or definite integral.

Uses `invoke_cmd(:integrate, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
integrate(expr::GiacExpr, var::GiacExpr) = invoke_cmd(:integrate, expr, var)
integrate(expr::GiacExpr, var::GiacExpr, a::GiacExpr, b::GiacExpr) = invoke_cmd(:integrate, expr, var, a, b)
integrate(expr::GiacExpr, var::GiacExpr, a::Number, b::Number) = invoke_cmd(:integrate, expr, var, giac_eval(string(a)), giac_eval(string(b)))
integrate(expr::String, var::String) = invoke_cmd(:integrate, giac_eval(expr), giac_eval(var))
integrate(expr::String, var::String, a, b) = invoke_cmd(:integrate, giac_eval(expr), giac_eval(var), giac_eval(string(a)), giac_eval(string(b)))

"""
    limit(expr, var, point; direction=:both)

Compute the limit of an expression as a variable approaches a point.

Uses `invoke_cmd(:limit, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
function limit(expr::GiacExpr, var::GiacExpr, point::GiacExpr; direction::Symbol=:both)
    # Note: direction parameter handling would require special GIAC syntax
    # For now, we use the basic limit command
    invoke_cmd(:limit, expr, var, point)
end
function limit(expr::String, var::String, point; direction::Symbol=:both)
    point_expr = point isa GiacExpr ? point : giac_eval(string(point))
    invoke_cmd(:limit, giac_eval(expr), giac_eval(var), point_expr)
end

# =============================================================================
# Algebra Functions
# =============================================================================

"""
    factor(expr)

Factor a polynomial expression.

Uses `invoke_cmd(:factor, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
factor(expr::GiacExpr) = invoke_cmd(:factor, expr)
factor(expr::String) = invoke_cmd(:factor, giac_eval(expr))

"""
    expand(expr)

Expand a polynomial expression.

Uses `invoke_cmd(:expand, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
expand(expr::GiacExpr) = invoke_cmd(:expand, expr)
expand(expr::String) = invoke_cmd(:expand, giac_eval(expr))

"""
    simplify(expr)

Simplify an expression.

Uses `invoke_cmd(:simplify, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
simplify(expr::GiacExpr) = invoke_cmd(:simplify, expr)
simplify(expr::String) = invoke_cmd(:simplify, giac_eval(expr))

"""
    solve(expr, var)

Solve an equation for a variable.

Uses `invoke_cmd(:solve, ...)`.

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
- [`invoke_cmd`](@ref): Universal command invocation
"""
solve(expr::GiacExpr, var::GiacExpr) = invoke_cmd(:solve, expr, var)
solve(expr::String, var::String) = invoke_cmd(:solve, giac_eval(expr), giac_eval(var))

# =============================================================================
# Exports
# =============================================================================

export diff, integrate, limit, factor, expand, simplify, solve

end # module TempApi
