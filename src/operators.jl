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
