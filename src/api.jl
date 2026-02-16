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
# Note: Calculus and Algebra functions removed (Feature 021)
# =============================================================================
# The following functions have been removed in favor of Giac.Commands:
#   - giac_diff → Giac.Commands.diff or invoke_cmd(:diff, ...)
#   - giac_integrate → Giac.Commands.integrate or invoke_cmd(:integrate, ...)
#   - giac_limit → Giac.Commands.limit or invoke_cmd(:limit, ...)
#   - giac_series → Giac.Commands.series or invoke_cmd(:series, ...)
#   - giac_factor → Giac.Commands.factor or invoke_cmd(:factor, ...)
#   - giac_expand → Giac.Commands.expand or invoke_cmd(:expand, ...)
#   - giac_simplify → Giac.Commands.simplify or invoke_cmd(:simplify, ...)
#   - giac_solve → Giac.Commands.solve or invoke_cmd(:solve, ...)
#   - giac_gcd → Giac.Commands.gcd or invoke_cmd(:gcd, ...)
# =============================================================================

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
