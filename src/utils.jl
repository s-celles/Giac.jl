# Utilities for Giac.jl
# Thread safety, type conversion, and helper functions

"""
Global lock for serializing GIAC library calls.
GIAC is not thread-safe, so all calls must be serialized.
"""
const GIAC_LOCK = ReentrantLock()

"""
    with_giac_lock(f)

Execute function `f` while holding the GIAC lock.
Ensures thread-safe access to GIAC library.
"""
function with_giac_lock(f)
    lock(GIAC_LOCK) do
        f()
    end
end

"""
    to_julia(expr::GiacExpr)

Convert a GIAC expression to a Julia-native value if possible.

# Returns
- `Int64` or `BigInt` for integer results
- `Float64` for floating-point results
- `ComplexF64` for complex results
- `Rational` for rational results
- `GiacExpr` if the expression is symbolic (cannot be converted)

# Example
```julia
result = giac_eval("2 + 3")
julia_value = to_julia(result)  # Returns Int64(5)
```
"""
function to_julia(expr::GiacExpr)
    if expr.ptr == C_NULL
        throw(GiacError("Cannot convert null expression", :type))
    end

    with_giac_lock() do
        expr_type = _giac_expr_type(expr.ptr)

        if expr_type == :integer
            # Try to convert to Int64, fall back to BigInt
            val = _giac_to_int64(expr.ptr)
            return val
        elseif expr_type == :float
            return _giac_to_float64(expr.ptr)
        elseif expr_type == :complex
            re = _giac_complex_real(expr.ptr)
            im = _giac_complex_imag(expr.ptr)
            return Complex(re, im)
        elseif expr_type == :rational
            num = _giac_rational_num(expr.ptr)
            den = _giac_rational_den(expr.ptr)
            return Rational(num, den)
        elseif expr_type == :infinity
            return Inf
        elseif expr_type == :undefined
            return NaN
        else
            # Symbolic expression - return as-is
            return expr
        end
    end
end

"""
    is_numeric(expr::GiacExpr)

Check if the expression can be converted to a Julia numeric type.
"""
function is_numeric(expr::GiacExpr)::Bool
    if expr.ptr == C_NULL
        return false
    end
    expr_type = with_giac_lock() do
        _giac_expr_type(expr.ptr)
    end
    return expr_type in (:integer, :float, :complex, :rational, :infinity, :undefined)
end

"""
    is_symbolic(expr::GiacExpr)

Check if the expression is symbolic (contains variables).
"""
function is_symbolic(expr::GiacExpr)::Bool
    return !is_numeric(expr)
end
