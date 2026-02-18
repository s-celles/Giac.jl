# Type conversion for Giac.jl
# Provides extended to_julia functionality with vector/complex/fraction support
#
# Part of feature 029-output-handling, 030-to-julia-bool-conversion

# ============================================================================
# Extended to_julia Conversion
# ============================================================================

"""
    to_julia(g::GiacExpr) -> Union{Bool, Int64, BigInt, Float64, Rational, Complex, Vector, String, GiacExpr}

Recursively convert a GIAC expression to native Julia types.

# Conversion Rules
| GIAC Type | Julia Return Type |
|-----------|-------------------|
| Boolean (`true`/`false`) | `Bool` |
| `GIAC_INT` | `Int64` |
| `GIAC_ZINT` | `BigInt` |
| `GIAC_DOUBLE`, `GIAC_REAL` | `Float64` |
| `GIAC_FRAC` | `Rational{Int64}` or `Rational{BigInt}` |
| `GIAC_CPLX` | `Complex{T}` (T promoted from parts) |
| `GIAC_VECT` | `Vector{T}` (T narrowed from elements) |
| `GIAC_STRNG` | `String` |
| `GIAC_SYMB`, `GIAC_IDNT`, `GIAC_FUNC` | `GiacExpr` (unchanged) |

Note: GIAC represents booleans as integers internally, but `to_julia` detects them
via their string representation ("true"/"false") and returns Julia `Bool` values.

# Examples
```julia
# Boolean conversion
to_julia(giac_eval("true"))      # true::Bool
to_julia(giac_eval("false"))     # false::Bool
to_julia(giac_eval("1==1"))      # true::Bool (comparison result)

# Integer conversion (distinct from booleans)
to_julia(giac_eval("1"))         # Int64(1)
to_julia(giac_eval("0"))         # Int64(0)
to_julia(giac_eval("42"))        # Int64(42)

# Float conversion
to_julia(giac_eval("3.14"))      # Float64(3.14)

# Rational conversion
to_julia(giac_eval("3/4"))       # 3//4

# Complex conversion
to_julia(giac_eval("3+4*i"))     # 3.0 + 4.0im

# Vector conversion with type narrowing
to_julia(giac_eval("[1, 2, 3]")) # [1, 2, 3]::Vector{Int64}

# Symbolic expressions are unchanged
to_julia(giac_eval("x + 1"))     # GiacExpr (unchanged)
```

# See also
[`giac_type`](@ref), [`is_boolean`](@ref), [`is_numeric`](@ref), [`is_vector`](@ref)
"""
function to_julia(g::GiacExpr)
    if g.ptr == C_NULL
        throw(GiacError("Cannot convert null expression", :type))
    end

    t = giac_type(g)
    return _convert_by_type(g, t)
end

# Internal dispatcher based on type constant
function _convert_by_type(g::GiacExpr, t::Int32)
    if t == GIAC_INT
        # Check for boolean before integer conversion (030-to-julia-bool-conversion)
        if is_boolean(g)
            return _convert_to_bool(g)
        end
        return _convert_to_int64(g)
    elseif t == GIAC_DOUBLE || t == GIAC_REAL
        return _convert_to_float64(g)
    elseif t == GIAC_ZINT
        return _convert_to_bigint(g)
    elseif t == GIAC_FRAC
        return _convert_to_rational(g)
    elseif t == GIAC_CPLX
        return _convert_to_complex(g)
    elseif t == GIAC_VECT
        return _convert_to_vector(g)
    elseif t == GIAC_STRNG
        return _convert_to_string(g)
    else
        # Symbolic types (GIAC_SYMB, GIAC_IDNT, GIAC_FUNC) - return unchanged
        return g
    end
end

# ============================================================================
# Scalar Conversion Helpers
# ============================================================================

"""
    _convert_to_bool(g::GiacExpr)::Bool

Convert a boolean GiacExpr to Julia Bool.
The expression must represent "true" or "false".
"""
function _convert_to_bool(g::GiacExpr)::Bool
    str = string(g)
    return str == "true"
end

function _convert_to_int64(g::GiacExpr)::Int64
    with_giac_lock() do
        return _giac_to_int64(g.ptr)
    end
end

function _convert_to_float64(g::GiacExpr)::Float64
    with_giac_lock() do
        return _giac_to_float64(g.ptr)
    end
end

function _convert_to_bigint(g::GiacExpr)::BigInt
    # BigInt requires string parsing (GIAC stores as GMP internally)
    str = string(g)
    return parse(BigInt, str)
end

function _convert_to_string(g::GiacExpr)::String
    return string(g)
end

# ============================================================================
# Compound Type Conversion Helpers
# ============================================================================

function _convert_to_rational(g::GiacExpr)
    num_expr = numer(g)
    den_expr = denom(g)

    num_type = giac_type(num_expr)
    den_type = giac_type(den_expr)

    # Check if either is BigInt (ZINT)
    if num_type == GIAC_ZINT || den_type == GIAC_ZINT
        num = to_julia(num_expr)::Union{Int64, BigInt}
        den = to_julia(den_expr)::Union{Int64, BigInt}
        return Rational{BigInt}(BigInt(num), BigInt(den))
    else
        num = _convert_to_int64(num_expr)
        den = _convert_to_int64(den_expr)
        return Rational{Int64}(num, den)
    end
end

function _convert_to_complex(g::GiacExpr)
    re_expr = real_part(g)
    im_expr = imag_part(g)

    re = to_julia(re_expr)
    im = to_julia(im_expr)

    # Promote to common type
    if re isa GiacExpr || im isa GiacExpr
        # If either part is symbolic, return as-is
        return g
    end

    T = promote_type(typeof(re), typeof(im))
    return Complex{T}(convert(T, re), convert(T, im))
end

# ============================================================================
# Vector Conversion with Type Narrowing
# ============================================================================

function _convert_to_vector(g::GiacExpr)
    n = _vector_length(g)

    if n == 0
        return Vector{Any}()
    end

    # First pass: convert all elements
    elements = Vector{Any}(undef, n)
    for i in 1:n
        elem = _vector_element(g, i)
        elements[i] = to_julia(elem)
    end

    # Second pass: narrow type
    return _narrow_vector_type(elements)
end

"""
    _narrow_vector_type(elements::Vector{Any}) -> Vector

Narrow a Vector{Any} to the most specific element type.

For homogeneous numeric vectors, returns a typed vector.
For mixed numeric types, promotes to common numeric type.
For vectors containing non-numeric types, returns Vector{Any}.
"""
function _narrow_vector_type(elements::Vector{Any})
    if isempty(elements)
        return elements
    end

    types = unique(typeof.(elements))

    if length(types) == 1
        # Homogeneous type
        T = types[1]
        return convert(Vector{T}, elements)
    elseif all(T -> T <: Number, types)
        # Mixed numeric types - promote
        T = reduce(promote_type, types)
        return convert(Vector{T}, elements)
    else
        # Mixed types including non-numeric
        return elements
    end
end

# Internal vector access helpers
function _vector_length(g::GiacExpr)::Int
    with_giac_lock() do
        if !_stub_mode[] && GiacCxxBindings._have_library
            gen = _ptr_to_gen(g.ptr)
            if gen !== nothing
                return GiacCxxBindings.vector_size(gen)
            end
        end
        # Fallback: parse from string
        str = string(g)
        # Count commas + 1, handling nested structures
        # Simple heuristic for now
        if startswith(str, "[") && endswith(str, "]")
            inner = str[2:end-1]
            if isempty(inner)
                return 0
            end
            # Count top-level commas (not inside nested brackets)
            depth = 0
            count = 1
            for c in inner
                if c == '[' || c == '('
                    depth += 1
                elseif c == ']' || c == ')'
                    depth -= 1
                elseif c == ',' && depth == 0
                    count += 1
                end
            end
            return count
        end
        return 1
    end
end

function _vector_element(g::GiacExpr, i::Int)::GiacExpr
    with_giac_lock() do
        if !_stub_mode[] && GiacCxxBindings._have_library
            gen = _ptr_to_gen(g.ptr)
            if gen !== nothing
                # 0-based indexing in C++
                elem_gen = GiacCxxBindings.vector_getindex(gen, i - 1)
                return _gen_to_giacexpr(elem_gen)
            end
        end
        # Fallback: parse and evaluate element
        str = string(g)
        if startswith(str, "[") && endswith(str, "]")
            inner = str[2:end-1]
            # Split by top-level commas
            elements = _split_vector_string(inner)
            if i >= 1 && i <= length(elements)
                return giac_eval(elements[i])
            end
        end
        throw(BoundsError(g, i))
    end
end

# Helper to split vector string by top-level commas
function _split_vector_string(s::AbstractString)::Vector{String}
    result = String[]
    depth = 0
    current = ""
    for c in s
        if c == '[' || c == '('
            depth += 1
            current *= c
        elseif c == ']' || c == ')'
            depth -= 1
            current *= c
        elseif c == ',' && depth == 0
            push!(result, strip(current))
            current = ""
        else
            current *= c
        end
    end
    if !isempty(current)
        push!(result, strip(current))
    end
    return result
end

# ============================================================================
# Explicit Type Conversion via Base.convert
# ============================================================================

"""
    Base.convert(::Type{Int64}, g::GiacExpr) -> Int64

Convert an integer GiacExpr to Int64.
"""
function Base.convert(::Type{Int64}, g::GiacExpr)::Int64
    t = giac_type(g)
    if t == GIAC_INT
        return _convert_to_int64(g)
    elseif t == GIAC_ZINT
        big = _convert_to_bigint(g)
        if big > typemax(Int64) || big < typemin(Int64)
            throw(InexactError(:convert, Int64, big))
        end
        return Int64(big)
    else
        throw(MethodError(convert, (Int64, g)))
    end
end

"""
    Base.convert(::Type{Float64}, g::GiacExpr) -> Float64

Convert a numeric GiacExpr to Float64.
"""
function Base.convert(::Type{Float64}, g::GiacExpr)::Float64
    t = giac_type(g)
    if t == GIAC_DOUBLE || t == GIAC_REAL
        return _convert_to_float64(g)
    elseif t == GIAC_INT
        return Float64(_convert_to_int64(g))
    elseif t == GIAC_ZINT
        return Float64(_convert_to_bigint(g))
    elseif t == GIAC_FRAC
        r = _convert_to_rational(g)
        return Float64(r)
    else
        throw(MethodError(convert, (Float64, g)))
    end
end

"""
    Base.convert(::Type{Vector}, g::GiacExpr) -> Vector

Convert a vector GiacExpr to a Julia Vector.
"""
function Base.convert(::Type{Vector}, g::GiacExpr)::Vector
    if !is_vector(g)
        throw(MethodError(convert, (Vector, g)))
    end
    return _convert_to_vector(g)
end

"""
    Base.convert(::Type{Rational}, g::GiacExpr) -> Rational

Convert a fraction or integer GiacExpr to a Rational.
"""
function Base.convert(::Type{Rational}, g::GiacExpr)::Rational
    t = giac_type(g)
    if t == GIAC_FRAC
        return _convert_to_rational(g)
    elseif t == GIAC_INT
        return Rational(_convert_to_int64(g))
    elseif t == GIAC_ZINT
        return Rational(_convert_to_bigint(g))
    else
        throw(MethodError(convert, (Rational, g)))
    end
end

"""
    Base.convert(::Type{Complex}, g::GiacExpr) -> Complex

Convert a complex GiacExpr to a Julia Complex.
"""
function Base.convert(::Type{Complex}, g::GiacExpr)::Complex
    t = giac_type(g)
    if t == GIAC_CPLX
        return _convert_to_complex(g)
    elseif is_numeric(g)
        # Numeric but not complex - treat as real
        val = to_julia(g)
        return Complex(val)
    else
        throw(MethodError(convert, (Complex, g)))
    end
end

"""
    Base.convert(::Type{Bool}, g::GiacExpr) -> Bool

Convert a GiacExpr to a Julia Bool.

# Conversion Rules
- Boolean expressions (`true`, `false`, comparison results) convert directly
- Integer `0` converts to `false`
- Integer `1` converts to `true`
- All other values throw `InexactError`

# Example
```julia
convert(Bool, giac_eval("true"))   # true
convert(Bool, giac_eval("1==1"))   # true
convert(Bool, giac_eval("1"))      # true (integer 1 coerces to true)
convert(Bool, giac_eval("0"))      # false
convert(Bool, giac_eval("2"))      # throws InexactError
```

# See also
[`to_julia`](@ref), [`is_boolean`](@ref)
"""
function Base.convert(::Type{Bool}, g::GiacExpr)::Bool
    # Check for boolean expressions first
    if is_boolean(g)
        return _convert_to_bool(g)
    end

    # Allow integer 0/1 to convert to Bool (standard Julia behavior)
    t = giac_type(g)
    if t == GIAC_INT
        val = _convert_to_int64(g)
        if val == 0
            return false
        elseif val == 1
            return true
        end
    end

    # All other values throw InexactError
    throw(InexactError(:convert, Bool, g))
end
