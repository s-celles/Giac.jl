# Operator overloading for GiacExpr
# Enables natural mathematical syntax for symbolic expressions

# =============================================================================
# Arithmetic Operators
# =============================================================================

"""
    +(a::GiacExpr, b::GiacExpr)

Add two GIAC expressions.
"""
function Base.:+(a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_add(a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("Addition failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    -(a::GiacExpr, b::GiacExpr)

Subtract two GIAC expressions.
"""
function Base.:-(a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_sub(a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("Subtraction failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    -(a::GiacExpr)

Negate a GIAC expression.
"""
function Base.:-(a::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_neg(a.ptr)
        if ptr == C_NULL
            throw(GiacError("Negation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    *(a::GiacExpr, b::GiacExpr)

Multiply two GIAC expressions.
"""
function Base.:*(a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_mul(a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("Multiplication failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    /(a::GiacExpr, b::GiacExpr)

Divide two GIAC expressions.
"""
function Base.:/(a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_div(a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("Division failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    ^(a::GiacExpr, b::GiacExpr)

Raise a GIAC expression to a power.
"""
function Base.:^(a::GiacExpr, b::GiacExpr)::GiacExpr
    with_giac_lock() do
        ptr = _giac_pow(a.ptr, b.ptr)
        if ptr == C_NULL
            throw(GiacError("Exponentiation failed", :eval))
        end
        return GiacExpr(ptr)
    end
end

"""
    ^(a::GiacExpr, n::Integer)

Raise a GIAC expression to an integer power.
"""
function Base.:^(a::GiacExpr, n::Integer)::GiacExpr
    b = giac_eval(string(n))
    return a^b
end

# =============================================================================
# Mixed-type arithmetic (GiacExpr with Julia numbers)
# =============================================================================

# Addition
Base.:+(a::GiacExpr, b::Number) = a + giac_eval(string(b))
Base.:+(a::Number, b::GiacExpr) = giac_eval(string(a)) + b

# Subtraction
Base.:-(a::GiacExpr, b::Number) = a - giac_eval(string(b))
Base.:-(a::Number, b::GiacExpr) = giac_eval(string(a)) - b

# Multiplication
Base.:*(a::GiacExpr, b::Number) = a * giac_eval(string(b))
Base.:*(a::Number, b::GiacExpr) = giac_eval(string(a)) * b

# Division
Base.:/(a::GiacExpr, b::Number) = a / giac_eval(string(b))
Base.:/(a::Number, b::GiacExpr) = giac_eval(string(a)) / b

# =============================================================================
# Comparison Operators
# =============================================================================

"""
    ==(a::GiacExpr, b::GiacExpr)

Check if two GIAC expressions are equal.
Note: This performs symbolic equality check, not numerical.
"""
function Base.:(==)(a::GiacExpr, b::GiacExpr)::Bool
    with_giac_lock() do
        return _giac_equal(a.ptr, b.ptr)
    end
end

Base.:(==)(a::GiacExpr, b::Number) = a == giac_eval(string(b))
Base.:(==)(a::Number, b::GiacExpr) = giac_eval(string(a)) == b

"""
    hash(expr::GiacExpr, h::UInt)

Hash a GIAC expression for use in dictionaries and sets.
"""
function Base.hash(expr::GiacExpr, h::UInt)::UInt
    # Use string representation for hashing
    return hash(string(expr), h)
end

# =============================================================================
# Matrix Operators
# =============================================================================

"""
    *(A::GiacMatrix, B::GiacMatrix)

Matrix multiplication.
"""
function Base.:*(A::GiacMatrix, B::GiacMatrix)::GiacMatrix
    if A.cols != B.rows
        throw(DimensionMismatch("Matrix dimensions do not match for multiplication: $(size(A)) * $(size(B))"))
    end

    with_giac_lock() do
        ptr = _giac_matrix_mul(A.ptr, B.ptr)
        if ptr == C_NULL
            throw(GiacError("Matrix multiplication failed", :eval))
        end
        return GiacMatrix(ptr, A.rows, B.cols)
    end
end

"""
    +(A::GiacMatrix, B::GiacMatrix)

Matrix addition.
"""
function Base.:+(A::GiacMatrix, B::GiacMatrix)::GiacMatrix
    if A.rows != B.rows || A.cols != B.cols
        throw(DimensionMismatch("Matrix dimensions do not match for addition"))
    end

    with_giac_lock() do
        ptr = _giac_matrix_add(A.ptr, B.ptr)
        if ptr == C_NULL
            throw(GiacError("Matrix addition failed", :eval))
        end
        return GiacMatrix(ptr, A.rows, A.cols)
    end
end

"""
    -(A::GiacMatrix, B::GiacMatrix)

Matrix subtraction.
"""
function Base.:-(A::GiacMatrix, B::GiacMatrix)::GiacMatrix
    if A.rows != B.rows || A.cols != B.cols
        throw(DimensionMismatch("Matrix dimensions do not match for subtraction"))
    end

    with_giac_lock() do
        ptr = _giac_matrix_sub(A.ptr, B.ptr)
        if ptr == C_NULL
            throw(GiacError("Matrix subtraction failed", :eval))
        end
        return GiacMatrix(ptr, A.rows, A.cols)
    end
end

"""
    *(A::GiacMatrix, c::Number)

Scalar multiplication of matrix.
"""
function Base.:*(A::GiacMatrix, c::Number)::GiacMatrix
    scalar = giac_eval(string(c))
    with_giac_lock() do
        ptr = _giac_matrix_scalar_mul(A.ptr, scalar.ptr)
        if ptr == C_NULL
            throw(GiacError("Scalar multiplication failed", :eval))
        end
        return GiacMatrix(ptr, A.rows, A.cols)
    end
end

Base.:*(c::Number, A::GiacMatrix) = A * c

# =============================================================================
# Equation Operator (~) - 024-equation-syntax
# =============================================================================

"""
    ~(a::GiacExpr, b::GiacExpr) -> GiacExpr

Create a symbolic equation from two GIAC expressions.

This operator follows the Julia Symbolics.jl convention where `~` creates
an equation (equality relation) rather than a boolean comparison.

# Arguments
- `a::GiacExpr`: Left-hand side of the equation
- `b::GiacExpr`: Right-hand side of the equation

# Returns
- `GiacExpr`: A GIAC expression representing the equation `a = b`

# Examples
```julia
@giac_var x
eq = x^2 - 1 ~ giac_eval("0")  # Creates equation x^2-1=0
solve(eq, x)                    # Solves for x: [-1, 1]

# Multiple variable equation
@giac_several_vars x y
eq = x + y ~ giac_eval("10")   # Creates equation x+y=10
```

# See also
- [`==`](@ref): Boolean equality check (returns `Bool`)
- [`solve`](@ref): Solve equations
"""
function Base.:~(a::GiacExpr, b::GiacExpr)::GiacExpr
    eq_str = "$(string(a))=$(string(b))"
    return giac_eval(eq_str)
end

"""
    ~(a::GiacExpr, b::Number) -> GiacExpr

Create a symbolic equation from a GIAC expression and a number.

# Examples
```julia
@giac_var x
eq = x ~ 5      # Creates equation x=5
eq = x^2 ~ 4    # Creates equation x^2=4
```
"""
function Base.:~(a::GiacExpr, b::Number)::GiacExpr
    return a ~ giac_eval(string(b))
end

"""
    ~(a::Number, b::GiacExpr) -> GiacExpr

Create a symbolic equation from a number and a GIAC expression.

# Examples
```julia
@giac_var x
eq = 0 ~ x^2 - 1    # Creates equation 0=x^2-1
eq = 10 ~ x + 5     # Creates equation 10=x+5
```
"""
function Base.:~(a::Number, b::GiacExpr)::GiacExpr
    return giac_eval(string(a)) ~ b
end

# =============================================================================
# Promotion and Conversion
# =============================================================================

# Enable automatic conversion in mixed operations
Base.promote_rule(::Type{GiacExpr}, ::Type{<:Number}) = GiacExpr
Base.convert(::Type{GiacExpr}, x::Number) = giac_eval(string(x))

# =============================================================================
# Iteration support for expression components (future enhancement)
# =============================================================================

# These would be implemented when we add expression tree traversal
# Base.iterate(expr::GiacExpr) = ...
# Base.length(expr::GiacExpr) = ...
