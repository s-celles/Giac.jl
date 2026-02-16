# Types for Giac.jl
# Core type definitions for wrapping GIAC expressions

"""
    GiacError <: Exception

Exception type for errors from the GIAC library.

# Fields
- `msg::String`: Error message
- `category::Symbol`: Error category (`:parse`, `:eval`, `:type`, `:memory`)

# Example
```julia
throw(GiacError("Failed to parse expression", :parse))
```
"""
struct GiacError <: Exception
    msg::String
    category::Symbol

    function GiacError(msg::String, category::Symbol=:eval)
        valid_categories = (:parse, :eval, :type, :memory)
        if category ∉ valid_categories
            category = :eval
        end
        new(msg, category)
    end
end

function Base.showerror(io::IO, e::GiacError)
    print(io, "GiacError(", e.category, "): ", e.msg)
end

"""
    GiacExpr

Represents a symbolic mathematical expression from GIAC.

Wraps a pointer to a C++ giac::gen object. Memory is managed automatically
via Julia's garbage collector and finalizers.

# Example
```julia
expr = giac_eval("x^2 + 1")
println(expr)  # x^2+1
```
"""
mutable struct GiacExpr
    ptr::Ptr{Cvoid}

    function GiacExpr(ptr::Ptr{Cvoid})
        obj = new(ptr)
        if ptr != C_NULL
            finalizer(_finalize_giacexpr, obj)
        end
        return obj
    end
end

"""
    _finalize_giacexpr(expr::GiacExpr)

Cleanup function for GiacExpr. Called by the garbage collector.
"""
function _finalize_giacexpr(expr::GiacExpr)
    if expr.ptr != C_NULL
        _giac_free_expr(expr.ptr)
        expr.ptr = C_NULL
    end
    nothing
end

# String conversion for GiacExpr
function Base.string(expr::GiacExpr)::String
    if expr.ptr == C_NULL
        return "<null GiacExpr>"
    end
    return _giac_expr_to_string(expr.ptr)
end

function Base.show(io::IO, expr::GiacExpr)
    print(io, string(expr))
end

function Base.show(io::IO, ::MIME"text/plain", expr::GiacExpr)
    print(io, "GiacExpr: ", string(expr))
end

# ============================================================================
# GiacInput Type Alias (022-julia-type-conversion)
# ============================================================================

"""
    GiacInput

Union type representing all valid input types for GIAC command functions.

This type alias enables generated GIAC command functions to accept native Julia
types in addition to `GiacExpr`, providing a more ergonomic API.

# Supported Types
- `GiacExpr`: Native GIAC expressions
- `Number`: All Julia numeric types (Integer, AbstractFloat, Rational, Complex, etc.)
- `String`: String representations of GIAC expressions
- `Symbol`: Variable names (e.g., `:x`, `:y`)

# Examples
```julia
using Giac
using Giac.Commands

# All of these work:
ifactor(1000)           # Integer
ifactor(giac_eval("1000"))  # GiacExpr
simplify("x^2 - 1")     # String
```

# See also
- [`GiacExpr`](@ref): The primary GIAC expression type
- [`invoke_cmd`](@ref): Universal command invocation
"""
const GiacInput = Union{GiacExpr, Number, String, Symbol}

# ============================================================================
# Method Syntax Support (003-giac-commands)
# ============================================================================

"""
    Base.getproperty(expr::GiacExpr, name::Symbol)

Enable method-style syntax for GIAC commands on GiacExpr objects.

Allows calling GIAC commands as methods: `expr.factor()` is equivalent to
`giac_cmd(:factor, expr)`.

# Behavior
- If `name` is a struct field (`:ptr`), returns the field value
- Otherwise, returns a closure that invokes `giac_cmd(name, expr, args...)`

# Examples
```julia
expr = giac_eval("x^2 - 1")
x = giac_eval("x")

# Method syntax (equivalent to giac_cmd calls)
result = expr.factor()           # Same as giac_cmd(:factor, expr)
deriv = expr.diff(x)             # Same as giac_cmd(:diff, expr, x)

# Chaining
result = expr.expand().simplify().factor()
```

# See also
- `giac_cmd`: Direct command invocation
"""
function Base.getproperty(expr::GiacExpr, name::Symbol)
    # Handle struct field access
    if name === :ptr
        return getfield(expr, :ptr)
    end

    # Return a closure that invokes giac_cmd with this expression as first argument
    return (args...) -> giac_cmd(name, expr, args...)
end

"""
    Base.propertynames(expr::GiacExpr)

Return property names for GiacExpr. Includes struct fields only.
GIAC commands are accessed dynamically via getproperty.
"""
function Base.propertynames(::GiacExpr, ::Bool=false)
    return (:ptr,)
end

"""
    GiacContext

Represents a GIAC evaluation context.

Manages configuration settings, variable bindings, and computation state.
Thread-safe via internal locking.

# Example
```julia
ctx = GiacContext()
result = giac_eval("x + 1", ctx)
```
"""
mutable struct GiacContext
    ptr::Ptr{Cvoid}
    lock::ReentrantLock

    function GiacContext()
        ptr = _giac_create_context()
        if ptr == C_NULL
            throw(GiacError("Failed to create GIAC context", :memory))
        end
        obj = new(ptr, ReentrantLock())
        finalizer(_finalize_giaccontext, obj)
        return obj
    end

    # Internal constructor for existing pointer
    function GiacContext(ptr::Ptr{Cvoid})
        if ptr == C_NULL
            throw(GiacError("Cannot create GiacContext from null pointer", :type))
        end
        obj = new(ptr, ReentrantLock())
        finalizer(_finalize_giaccontext, obj)
        return obj
    end
end

"""
    _finalize_giaccontext(ctx::GiacContext)

Cleanup function for GiacContext. Called by the garbage collector.
"""
function _finalize_giaccontext(ctx::GiacContext)
    if ctx.ptr != C_NULL
        _giac_free_context(ctx.ptr)
        ctx.ptr = C_NULL
    end
    nothing
end

"""
    GiacMatrix

Represents a symbolic matrix with GiacExpr elements.

# Fields
- `ptr::Ptr{Cvoid}`: Pointer to GIAC matrix object
- `rows::Int`: Number of rows
- `cols::Int`: Number of columns

# Example
```julia
A = GiacMatrix([[a, b], [c, d]])
det(A)  # a*d - b*c
```
"""
mutable struct GiacMatrix
    ptr::Ptr{Cvoid}
    rows::Int
    cols::Int

    function GiacMatrix(ptr::Ptr{Cvoid}, rows::Int, cols::Int)
        if rows <= 0 || cols <= 0
            throw(ArgumentError("Matrix dimensions must be positive"))
        end
        obj = new(ptr, rows, cols)
        if ptr != C_NULL
            finalizer(_finalize_giacmatrix, obj)
        end
        return obj
    end
end

"""
    _finalize_giacmatrix(m::GiacMatrix)

Cleanup function for GiacMatrix. Called by the garbage collector.
"""
function _finalize_giacmatrix(m::GiacMatrix)
    if m.ptr != C_NULL
        _giac_free_matrix(m.ptr)
        m.ptr = C_NULL
    end
    nothing
end

# Base methods for GiacMatrix
function Base.size(m::GiacMatrix)
    return (m.rows, m.cols)
end

function Base.size(m::GiacMatrix, dim::Int)
    if dim == 1
        return m.rows
    elseif dim == 2
        return m.cols
    else
        throw(ArgumentError("Invalid dimension: $dim"))
    end
end

function Base.getindex(m::GiacMatrix, i::Int, j::Int)
    if i < 1 || i > m.rows || j < 1 || j > m.cols
        throw(BoundsError(m, (i, j)))
    end
    ptr = _giac_matrix_getindex(m.ptr, i - 1, j - 1)  # 0-indexed in C
    return GiacExpr(ptr)
end

function Base.show(io::IO, m::GiacMatrix)
    print(io, "GiacMatrix($(m.rows)×$(m.cols))")
end

# ============================================================================
# GiacMatrix Display Improvement (011-giacmatrix-display)
# ============================================================================

# Display constants
const MAX_DISPLAY_ROWS = 10
const MAX_DISPLAY_COLS = 10
const MAX_ELEMENT_WIDTH = 20

"""
    _element_string(m::GiacMatrix, i::Int, j::Int)

Get string representation of matrix element at position (i, j).
Truncates long expressions with "…" if they exceed MAX_ELEMENT_WIDTH.
"""
function _element_string(m::GiacMatrix, i::Int, j::Int)
    elem = m[i, j]
    s = string(elem)
    if length(s) > MAX_ELEMENT_WIDTH
        return s[1:MAX_ELEMENT_WIDTH-1] * "…"
    end
    return s
end

"""
    _should_truncate_rows(m::GiacMatrix)

Check if matrix has more rows than can be displayed.
"""
function _should_truncate_rows(m::GiacMatrix)
    return m.rows > MAX_DISPLAY_ROWS
end

"""
    _should_truncate_cols(m::GiacMatrix)

Check if matrix has more columns than can be displayed.
"""
function _should_truncate_cols(m::GiacMatrix)
    return m.cols > MAX_DISPLAY_COLS
end

"""
    _display_row_indices(m::GiacMatrix)

Return the row indices to display. For large matrices, returns
first 5 rows, a marker (-1) for ellipsis, and last 2 rows.
"""
function _display_row_indices(m::GiacMatrix)
    if _should_truncate_rows(m)
        return [1:5; -1; (m.rows-1):m.rows]
    end
    return collect(1:m.rows)
end

"""
    _display_col_indices(m::GiacMatrix)

Return the column indices to display. For large matrices, returns
first 5 columns, a marker (-1) for ellipsis, and last 2 columns.
"""
function _display_col_indices(m::GiacMatrix)
    if _should_truncate_cols(m)
        return [1:5; -1; (m.cols-1):m.cols]
    end
    return collect(1:m.cols)
end

"""
    _compute_column_widths(m::GiacMatrix, row_indices, col_indices)

Compute the display width needed for each column.
"""
function _compute_column_widths(m::GiacMatrix, row_indices, col_indices)
    widths = zeros(Int, length(col_indices))
    for (cj, j) in enumerate(col_indices)
        if j == -1
            widths[cj] = 1  # Width for "⋯"
            continue
        end
        for i in row_indices
            if i == -1
                continue
            end
            elem_str = _element_string(m, i, j)
            widths[cj] = max(widths[cj], length(elem_str))
        end
    end
    return widths
end

"""
    Base.string(m::GiacMatrix)

Return compact string representation of GiacMatrix.
"""
function Base.string(m::GiacMatrix)
    return "GiacMatrix($(m.rows)×$(m.cols))"
end

"""
    Base.show(io::IO, ::MIME"text/plain", m::GiacMatrix)

Display GiacMatrix with dimensions header and grid of contents.
Large matrices are truncated with ellipsis indicators.
"""
function Base.show(io::IO, ::MIME"text/plain", m::GiacMatrix)
    # Print header
    println(io, "$(m.rows)×$(m.cols) GiacMatrix:")

    # Get indices to display
    row_indices = _display_row_indices(m)
    col_indices = _display_col_indices(m)

    # Compute column widths for alignment
    widths = _compute_column_widths(m, row_indices, col_indices)

    # Print matrix contents
    for (ri, i) in enumerate(row_indices)
        if i == -1
            # Print row ellipsis line
            for (cj, j) in enumerate(col_indices)
                if cj > 1
                    print(io, "  ")
                end
                if j == -1
                    print(io, lpad("⋱", widths[cj]))
                else
                    print(io, lpad("⋮", widths[cj]))
                end
            end
        else
            # Print actual row content
            for (cj, j) in enumerate(col_indices)
                if cj > 1
                    print(io, "  ")
                end
                if j == -1
                    print(io, lpad("⋯", widths[cj]))
                else
                    elem_str = _element_string(m, i, j)
                    print(io, lpad(elem_str, widths[cj]))
                end
            end
        end
        if ri < length(row_indices)
            println(io)
        end
    end
end
