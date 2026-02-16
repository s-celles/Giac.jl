# High-level API for Giac.jl
# User-facing functions for symbolic computation

"""
    giac_eval(expr::String, ctx::GiacContext=DEFAULT_CONTEXT[])

Evaluate a GIAC expression string and return a GiacExpr.

# Arguments
- `expr::String`: A string containing a valid GIAC expression
- `ctx::GiacContext`: Optional evaluation context (uses DEFAULT_CONTEXT if not provided)

# Returns
- `GiacExpr`: The evaluated expression

# Throws
- `GiacError(:parse)`: If the expression cannot be parsed
- `GiacError(:eval)`: If evaluation fails

# Example
```julia
result = giac_eval("2 + 3")
println(result)  # 5

# Symbolic computation
expr = giac_eval("diff(x^2, x)")
println(expr)  # 2*x
```
"""
function giac_eval(expr::String, ctx::GiacContext=DEFAULT_CONTEXT[])::GiacExpr
    if isempty(expr)
        throw(GiacError("Empty expression", :parse))
    end

    with_giac_lock() do
        ptr = _giac_eval_string(expr, ctx.ptr)
        if ptr == C_NULL
            throw(GiacError("Failed to evaluate expression: $expr", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    giac_eval(expr::GiacExpr, ctx::GiacContext=DEFAULT_CONTEXT[])

Re-evaluate an existing GiacExpr in a context (useful after variable assignments).
"""
function giac_eval(expr::GiacExpr, ctx::GiacContext=DEFAULT_CONTEXT[])::GiacExpr
    # Convert to string and re-evaluate
    return giac_eval(string(expr), ctx)
end

# =============================================================================
# Calculus Operations
# =============================================================================

"""
    giac_diff(expr::GiacExpr, var::GiacExpr, n::Int=1)
    giac_diff(expr::String, var::String, n::Int=1)

Compute the nth derivative of an expression with respect to a variable.

# Arguments
- `expr`: The expression to differentiate
- `var`: The variable to differentiate with respect to
- `n`: Order of differentiation (default: 1)

# Example
```julia
f = giac_eval("x^3")
x = giac_eval("x")
df = giac_diff(f, x)      # 3*x^2
d2f = giac_diff(f, x, 2)  # 6*x
```
"""
function giac_diff(expr::GiacExpr, var::GiacExpr, n::Int=1)::GiacExpr
    if n < 0
        throw(ArgumentError("Differentiation order must be non-negative"))
    end
    if n == 0
        return expr
    end

    with_giac_lock() do
        ptr = _giac_diff(expr.ptr, var.ptr, n)
        if ptr == C_NULL
            throw(GiacError("Differentiation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

function giac_diff(expr::String, var::String, n::Int=1)::GiacExpr
    return giac_diff(giac_eval(expr), giac_eval(var), n)
end

"""
    giac_integrate(expr::GiacExpr, var::GiacExpr)
    giac_integrate(expr::GiacExpr, var::GiacExpr, a, b)

Compute indefinite or definite integral.

# Arguments
- `expr`: The expression to integrate
- `var`: The variable of integration
- `a`, `b`: Optional bounds for definite integration

# Example
```julia
f = giac_eval("x^2")
x = giac_eval("x")
F = giac_integrate(f, x)           # x^3/3
area = giac_integrate(f, x, 0, 1)  # 1/3
```
"""
function giac_integrate(expr::GiacExpr, var::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_integrate(expr.ptr, var.ptr)
        if ptr == C_NULL
            throw(GiacError("Integration failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

function giac_integrate(expr::GiacExpr, var::GiacExpr, a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_integrate_definite(expr.ptr, var.ptr, a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("Definite integration failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

function giac_integrate(expr::GiacExpr, var::GiacExpr, a::Number, b::Number)::GiacExpr
    return giac_integrate(expr, var, giac_eval(string(a)), giac_eval(string(b)))
end

function giac_integrate(expr::String, var::String)::GiacExpr
    return giac_integrate(giac_eval(expr), giac_eval(var))
end

function giac_integrate(expr::String, var::String, a, b)::GiacExpr
    return giac_integrate(giac_eval(expr), giac_eval(var), a, b)
end

"""
    giac_limit(expr::GiacExpr, var::GiacExpr, point::GiacExpr; direction::Symbol=:both)

Compute the limit of an expression as a variable approaches a point.

# Arguments
- `expr`: The expression
- `var`: The variable
- `point`: The point to approach
- `direction`: `:left`, `:right`, or `:both` (default)

# Example
```julia
f = giac_eval("sin(x)/x")
x = giac_eval("x")
lim = giac_limit(f, x, giac_eval("0"))  # 1
```
"""
function giac_limit(expr::GiacExpr, var::GiacExpr, point::GiacExpr; direction::Symbol=:both)::GiacExpr
    dir_code = if direction == :left
        -1
    elseif direction == :right
        1
    else
        0
    end

    with_giac_lock() do
        ptr = _giac_limit(expr.ptr, var.ptr, point.ptr, dir_code)
        if ptr == C_NULL
            throw(GiacError("Limit computation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

function giac_limit(expr::String, var::String, point; direction::Symbol=:both)::GiacExpr
    point_expr = point isa GiacExpr ? point : giac_eval(string(point))
    return giac_limit(giac_eval(expr), giac_eval(var), point_expr; direction=direction)
end

"""
    giac_series(expr::GiacExpr, var::GiacExpr, point::GiacExpr, order::Int)

Compute Taylor/Laurent series expansion.

# Example
```julia
f = giac_eval("exp(x)")
x = giac_eval("x")
s = giac_series(f, x, giac_eval("0"), 5)  # 1 + x + x^2/2 + x^3/6 + x^4/24 + ...
```
"""
function giac_series(expr::GiacExpr, var::GiacExpr, point::GiacExpr, order::Int)::GiacExpr
    if order < 0
        throw(ArgumentError("Series order must be non-negative"))
    end

    with_giac_lock() do
        ptr = _giac_series(expr.ptr, var.ptr, point.ptr, order)
        if ptr == C_NULL
            throw(GiacError("Series expansion failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

function giac_series(expr::String, var::String, point, order::Int)::GiacExpr
    point_expr = point isa GiacExpr ? point : giac_eval(string(point))
    return giac_series(giac_eval(expr), giac_eval(var), point_expr, order)
end

# =============================================================================
# Algebraic Operations
# =============================================================================

"""
    giac_factor(expr::GiacExpr)

Factor a polynomial expression.

# Example
```julia
p = giac_eval("x^2 - 1")
f = giac_factor(p)  # (x-1)*(x+1)
```
"""
function giac_factor(expr::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_factor(expr.ptr)
        if ptr == C_NULL
            throw(GiacError("Factorization failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

giac_factor(expr::String) = giac_factor(giac_eval(expr))

"""
    giac_expand(expr::GiacExpr)

Expand a polynomial expression.

# Example
```julia
p = giac_eval("(x+1)^3")
e = giac_expand(p)  # x^3 + 3*x^2 + 3*x + 1
```
"""
function giac_expand(expr::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_expand(expr.ptr)
        if ptr == C_NULL
            throw(GiacError("Expansion failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

giac_expand(expr::String) = giac_expand(giac_eval(expr))

"""
    giac_simplify(expr::GiacExpr)

Simplify an expression.

# Example
```julia
e = giac_eval("(x^2 - 1)/(x - 1)")
s = giac_simplify(e)  # x + 1
```
"""
function giac_simplify(expr::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_simplify(expr.ptr)
        if ptr == C_NULL
            throw(GiacError("Simplification failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

giac_simplify(expr::String) = giac_simplify(giac_eval(expr))

"""
    giac_solve(expr::GiacExpr, var::GiacExpr)

Solve an equation for a variable.

# Arguments
- `expr`: The equation (assumed equal to 0) or an equation with =
- `var`: The variable to solve for

# Returns
- `GiacExpr`: Solution set

# Example
```julia
eq = giac_eval("x^2 - 4")
x = giac_eval("x")
sols = giac_solve(eq, x)  # [-2, 2]
```
"""
function giac_solve(expr::GiacExpr, var::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_solve(expr.ptr, var.ptr)
        if ptr == C_NULL
            throw(GiacError("Solving failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

function giac_solve(expr::String, var::String)::GiacExpr
    return giac_solve(giac_eval(expr), giac_eval(var))
end

"""
    giac_gcd(a::GiacExpr, b::GiacExpr)

Compute the greatest common divisor of two expressions.
"""
function giac_gcd(a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_gcd(a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("GCD computation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

giac_gcd(a::String, b::String) = giac_gcd(giac_eval(a), giac_eval(b))

# =============================================================================
# Matrix Operations (Linear Algebra)
# =============================================================================

"""
    GiacMatrix(elements::AbstractMatrix)

Create a GiacMatrix from a Julia matrix.

# Example
```julia
A = GiacMatrix([1 2; 3 4])
```
"""
function GiacMatrix(elements::AbstractMatrix)
    rows, cols = size(elements)
    # Convert elements to strings for GIAC
    str_elements = ["[" * join([string(elements[i, j]) for j in 1:cols], ",") * "]" for i in 1:rows]
    matrix_str = "[" * join(str_elements, ",") * "]"

    with_giac_lock() do
        ptr = _giac_create_matrix(matrix_str, rows, cols)
        if ptr == C_NULL
            throw(GiacError("Failed to create matrix", :memory))
        end
        return GiacMatrix(ptr, rows, cols)
    end
end

"""
    GiacMatrix(elements::Vector{Vector})

Create a GiacMatrix from nested vectors.
"""
function GiacMatrix(elements::Vector{<:Vector})
    rows = length(elements)
    cols = length(elements[1])
    for row in elements
        if length(row) != cols
            throw(ArgumentError("All rows must have the same length"))
        end
    end

    matrix = [elements[i][j] for i in 1:rows, j in 1:cols]
    return GiacMatrix(matrix)
end

# =============================================================================
# GiacMatrix Symbol Constructor (Feature 013)
# =============================================================================

"""
    GiacMatrix(base::Symbol, dims::Integer...)

Create a symbolic GiacMatrix with variable elements named using the base symbol and indices.

This constructor creates a matrix populated with symbolic variables. For 1D input,
creates a column vector (n×1). For 2D input, creates a matrix (rows×cols).

# Arguments
- `base::Symbol`: Base name for the symbolic variables (e.g., `:m`, `:α`)
- `dims::Integer...`: One or two dimensions

# Naming Convention
- Dimensions ≤ 9: Indices concatenated directly (e.g., `m11`, `m23`)
- Any dimension > 9: Underscore separators used (e.g., `m_1_10`, `m_10_1`)
- 1D vectors use single index (e.g., `v1`, `v2`, `v3`)

# Examples

Create a 2×3 symbolic matrix:
```julia
M = GiacMatrix(:m, 2, 3)
# Elements: m11, m12, m13, m21, m22, m23
M[1, 2]  # m12
size(M)  # (2, 3)
```

Create a column vector:
```julia
V = GiacMatrix(:v, 3)
# Elements: v1, v2, v3
size(V)  # (3, 1)
```

Large dimensions use underscores:
```julia
M = GiacMatrix(:m, 10, 10)
M[1, 10]  # m_1_10
```

Unicode base names:
```julia
Γ = GiacMatrix(:Γ, 2, 2)
# Elements: Γ11, Γ12, Γ21, Γ22
```

# Throws
- `ArgumentError`: If no dimensions provided
- `ArgumentError`: If more than 2 dimensions provided
- `ArgumentError`: If any dimension is not positive (≤ 0)

# See also
- [`@giac_several_vars`](@ref): Macro for creating indexed symbolic variables
"""
function GiacMatrix(base::Symbol, dims::Integer...)
    # Validate dimension count
    if length(dims) == 0
        throw(ArgumentError("At least one dimension required"))
    end
    if length(dims) > 2
        throw(ArgumentError("GiacMatrix supports at most 2 dimensions. Use GiacTensor for N-dimensional arrays."))
    end

    # Validate dimension values (must be positive, GiacMatrix requires positive dimensions)
    for d in dims
        if d <= 0
            throw(ArgumentError("Dimensions must be positive, got $d"))
        end
    end

    # Handle based on number of dimensions
    if length(dims) == 1
        return _create_symbolic_vector(base, dims[1])
    else
        return _create_symbolic_matrix(base, dims[1], dims[2])
    end
end

"""
    _create_symbolic_vector(base::Symbol, n::Int) -> GiacMatrix

Internal helper to create an n×1 column vector with symbolic elements.
Elements are named with single index: base1, base2, ..., baseN.
"""
function _create_symbolic_vector(base::Symbol, n::Int)
    # Determine if we need underscore separators
    needs_sep = _needs_separator((n,))

    # Create elements as column vector
    elements = Matrix{GiacExpr}(undef, n, 1)
    for i in 1:n
        varname = _format_indices(base, (i,), needs_sep)
        elements[i, 1] = giac_eval(string(varname))
    end

    return GiacMatrix(elements)
end

"""
    _create_symbolic_matrix(base::Symbol, rows::Int, cols::Int) -> GiacMatrix

Internal helper to create a rows×cols matrix with symbolic elements.
Elements are named with double indices in row-major order: base11, base12, ..., baseRC.
"""
function _create_symbolic_matrix(base::Symbol, rows::Int, cols::Int)
    # Determine if we need underscore separators
    needs_sep = _needs_separator((rows, cols))

    # Create elements in row-major order
    elements = Matrix{GiacExpr}(undef, rows, cols)
    for i in 1:rows
        for j in 1:cols
            varname = _format_indices(base, (i, j), needs_sep)
            elements[i, j] = giac_eval(string(varname))
        end
    end

    return GiacMatrix(elements)
end

"""
    det(m::GiacMatrix)

Compute the determinant of a matrix.
"""
function LinearAlgebra.det(m::GiacMatrix)::GiacExpr
    if m.rows != m.cols
        throw(ArgumentError("Determinant requires a square matrix"))
    end

    with_giac_lock() do
        ptr = _giac_matrix_det(m.ptr)
        if ptr == C_NULL
            throw(GiacError("Determinant computation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    inv(m::GiacMatrix)

Compute the inverse of a matrix.
"""
function Base.inv(m::GiacMatrix)::GiacMatrix
    if m.rows != m.cols
        throw(ArgumentError("Inverse requires a square matrix"))
    end

    with_giac_lock() do
        ptr = _giac_matrix_inv(m.ptr)
        if ptr == C_NULL
            throw(GiacError("Matrix inversion failed (may be singular)", :eval))
        end
        return GiacMatrix(ptr, m.rows, m.cols)
    end
end

"""
    tr(m::GiacMatrix)

Compute the trace of a matrix.
"""
function LinearAlgebra.tr(m::GiacMatrix)::GiacExpr
    if m.rows != m.cols
        throw(ArgumentError("Trace requires a square matrix"))
    end

    with_giac_lock() do
        ptr = _giac_matrix_trace(m.ptr)
        if ptr == C_NULL
            throw(GiacError("Trace computation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    transpose(m::GiacMatrix)

Compute the transpose of a matrix.
"""
function Base.transpose(m::GiacMatrix)::GiacMatrix
    with_giac_lock() do
        ptr = _giac_matrix_transpose(m.ptr)
        if ptr == C_NULL
            throw(GiacError("Transpose failed", :eval))
        end
        return GiacMatrix(ptr, m.cols, m.rows)
    end
end
