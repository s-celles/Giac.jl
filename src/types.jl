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
