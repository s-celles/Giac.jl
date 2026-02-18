# Type introspection for Giac.jl
# Provides type constants, predicates, and component accessors for Gen/GiacExpr objects
#
# Part of feature 029-output-handling

# ============================================================================
# Import CxxWrap functions if available to extend them for GiacExpr
# ============================================================================
# Note: GiacCxxBindings may define is_integer, etc. for Gen type.
# We check and import these to add methods for GiacExpr.

# We'll define our own predicates - they won't conflict with CxxWrap's
# because Julia's method dispatch is based on argument types.
# The key is to ensure our functions are in the Giac module namespace.

# ============================================================================
# Type Constants
# ============================================================================
# These map to GIAC's internal type enum values
# Reference: EARS document Annexe A

"""
Type constant for machine integers (Int64).
"""
const GIAC_INT = 0

"""
Type constant for double-precision floating point (Float64).
"""
const GIAC_DOUBLE = 1

"""
Type constant for arbitrary precision integers (BigInt via GMP).
"""
const GIAC_ZINT = 2

"""
Type constant for extended precision reals.
"""
const GIAC_REAL = 3

"""
Type constant for complex numbers.
"""
const GIAC_CPLX = 4

"""
Type constant for polynomials (internal representation).
"""
const GIAC_POLY = 5

"""
Type constant for identifiers/variables.
"""
const GIAC_IDNT = 6

"""
Type constant for vectors/lists/sequences.
"""
const GIAC_VECT = 7

"""
Type constant for symbolic expressions.
"""
const GIAC_SYMB = 8

"""
Type constant for sparse polynomials.
"""
const GIAC_SPOL1 = 9

"""
Type constant for rational fractions.
"""
const GIAC_FRAC = 10

"""
Type constant for string values.
Note: GIAC uses type 12 for strings (not 11 as in some documentation).
"""
const GIAC_STRNG = 12

"""
Type constant for function references.
"""
const GIAC_FUNC = 13

# ============================================================================
# Vector Subtype Constants
# ============================================================================

"""
Subtype constant for sequences (function arguments).
"""
const GIAC_SEQ_VECT = 1

"""
Subtype constant for sets (unordered collections).
"""
const GIAC_SET_VECT = 2

"""
Subtype constant for lists (ordered collections).
"""
const GIAC_LIST_VECT = 3

# ============================================================================
# Type Introspection Functions
# ============================================================================

"""
    giac_type(g::GiacExpr) -> Int32

Return the GIAC type constant for the expression.

Returns one of: `GIAC_INT`, `GIAC_DOUBLE`, `GIAC_ZINT`, `GIAC_REAL`,
`GIAC_CPLX`, `GIAC_VECT`, `GIAC_SYMB`, `GIAC_IDNT`, `GIAC_STRNG`,
`GIAC_FRAC`, `GIAC_FUNC`.

# Example
```julia
g = giac_eval("42")
giac_type(g) == GIAC_INT  # true

g = giac_eval("[1, 2, 3]")
giac_type(g) == GIAC_VECT  # true
```
"""
function giac_type(g::GiacExpr)::Int32
    if g.ptr == C_NULL
        throw(GiacError("Cannot get type of null expression", :type))
    end

    with_giac_lock() do
        if !_stub_mode[] && GiacCxxBindings._have_library
            # Get the expression string and evaluate it to get a Gen object
            expr_str = string(g)
            try
                gen = GiacCxxBindings.giac_eval(expr_str)
                return Int32(GiacCxxBindings.type(gen))
            catch e
                @debug "Failed to get type via CxxWrap: $e"
            end
        end
        # Fallback: use existing _giac_expr_type and map to constants
        expr_type = _giac_expr_type(g.ptr)
        return _symbol_to_type_const(expr_type)
    end
end

"""
    subtype(g::GiacExpr) -> Int32

Return the subtype for vector expressions.

For vectors, returns `GIAC_SEQ_VECT`, `GIAC_SET_VECT`, `GIAC_LIST_VECT`,
or `0` for standard vectors.

# Example
```julia
g = giac_eval("{1, 2, 3}")  # set
subtype(g) == GIAC_SET_VECT  # true
```
"""
function subtype(g::GiacExpr)::Int32
    if g.ptr == C_NULL
        throw(GiacError("Cannot get subtype of null expression", :type))
    end

    with_giac_lock() do
        if !_stub_mode[] && GiacCxxBindings._have_library
            expr_str = string(g)
            try
                gen = GiacCxxBindings.giac_eval(expr_str)
                return Int32(GiacCxxBindings.subtype(gen))
            catch e
                @debug "Failed to get subtype via CxxWrap: $e"
            end
        end
        return Int32(0)  # Default subtype
    end
end

# Internal helper to convert symbol to type constant
function _symbol_to_type_const(sym::Symbol)::Int32
    if sym == :integer
        return GIAC_INT
    elseif sym == :float
        return GIAC_DOUBLE
    elseif sym == :complex
        return GIAC_CPLX
    elseif sym == :rational
        return GIAC_FRAC
    elseif sym == :vector
        return GIAC_VECT
    elseif sym == :matrix
        return GIAC_VECT  # Matrices are stored as vectors in GIAC
    elseif sym == :symbolic
        return GIAC_SYMB
    else
        return GIAC_SYMB  # Default to symbolic
    end
end

# Internal helper to convert GiacExpr to CxxWrap Gen
# Used for vector operations and other CxxWrap-based conversions
function _ptr_to_gen(g::GiacExpr)
    if !_stub_mode[] && GiacCxxBindings._have_library
        expr_str = string(g)
        return GiacCxxBindings.giac_eval(expr_str)
    end
    return nothing
end

# ============================================================================
# Type Predicates
# ============================================================================

"""
    is_integer(g::GiacExpr) -> Bool

Return `true` if the expression is an integer (`GIAC_INT` or `GIAC_ZINT`).

# Example
```julia
is_integer(giac_eval("42"))      # true
is_integer(giac_eval("3.14"))    # false
is_integer(giac_eval("x"))       # false
```
"""
function is_integer(g::GiacExpr)::Bool
    t = giac_type(g)
    return t == GIAC_INT || t == GIAC_ZINT
end

"""
    is_numeric(g::GiacExpr) -> Bool

Return `true` if the expression is a numeric value
(`GIAC_INT`, `GIAC_DOUBLE`, `GIAC_ZINT`, or `GIAC_REAL`).

# Example
```julia
is_numeric(giac_eval("42"))      # true
is_numeric(giac_eval("3.14"))    # true
is_numeric(giac_eval("x"))       # false
```
"""
function is_numeric(g::GiacExpr)::Bool
    t = giac_type(g)
    return t == GIAC_INT || t == GIAC_DOUBLE || t == GIAC_ZINT || t == GIAC_REAL
end

"""
    is_vector(g::GiacExpr) -> Bool

Return `true` if the expression is a vector/list/sequence (`GIAC_VECT`).

# Example
```julia
is_vector(giac_eval("[1, 2, 3]"))  # true
is_vector(giac_eval("42"))         # false
```
"""
function is_vector(g::GiacExpr)::Bool
    return giac_type(g) == GIAC_VECT
end

"""
    is_symbolic(g::GiacExpr) -> Bool

Return `true` if the expression is symbolic (`GIAC_SYMB`).

# Example
```julia
is_symbolic(giac_eval("sin(x)"))  # true
is_symbolic(giac_eval("x + 1"))   # true
is_symbolic(giac_eval("42"))      # false
```
"""
function is_symbolic(g::GiacExpr)::Bool
    return giac_type(g) == GIAC_SYMB
end

"""
    is_identifier(g::GiacExpr) -> Bool

Return `true` if the expression is an identifier/variable (`GIAC_IDNT`).

# Example
```julia
is_identifier(giac_eval("x"))       # true
is_identifier(giac_eval("x + 1"))   # false
```
"""
function is_identifier(g::GiacExpr)::Bool
    return giac_type(g) == GIAC_IDNT
end

"""
    is_fraction(g::GiacExpr) -> Bool

Return `true` if the expression is a rational fraction (`GIAC_FRAC`).

# Example
```julia
is_fraction(giac_eval("3/4"))    # true
is_fraction(giac_eval("42"))     # false
```
"""
function is_fraction(g::GiacExpr)::Bool
    return giac_type(g) == GIAC_FRAC
end

"""
    is_complex(g::GiacExpr) -> Bool

Return `true` if the expression is a complex number (`GIAC_CPLX`).

# Example
```julia
is_complex(giac_eval("3+4*i"))   # true
is_complex(giac_eval("42"))      # false
```
"""
function is_complex(g::GiacExpr)::Bool
    return giac_type(g) == GIAC_CPLX
end

"""
    is_string(g::GiacExpr) -> Bool

Return `true` if the expression is a string (`GIAC_STRNG`).

# Example
```julia
is_string(giac_eval("\"hello\""))  # true
is_string(giac_eval("42"))         # false
```
"""
function is_string(g::GiacExpr)::Bool
    return giac_type(g) == GIAC_STRNG
end

"""
    is_boolean(g::GiacExpr) -> Bool

Return `true` if the expression represents a boolean value (`true` or `false`).

Note: GIAC represents booleans as integers internally (type `GIAC_INT`), but
displays them as "true" or "false". This function detects boolean values by
checking the string representation.

# Example
```julia
is_boolean(giac_eval("true"))      # true
is_boolean(giac_eval("false"))     # true
is_boolean(giac_eval("1==1"))      # true (comparison returns boolean)
is_boolean(giac_eval("1"))         # false (integer, not boolean)
is_boolean(giac_eval("0"))         # false (integer, not boolean)
```

# See also
[`to_julia`](@ref), [`is_integer`](@ref)
"""
function is_boolean(g::GiacExpr)::Bool
    str = string(g)
    return str == "true" || str == "false"
end

# ============================================================================
# Component Access Functions
# ============================================================================

"""
    numer(g::GiacExpr) -> GiacExpr

Return the numerator of a fraction, or the value itself for integers.

# Example
```julia
numer(giac_eval("3/4"))   # GiacExpr representing 3
numer(giac_eval("5"))     # GiacExpr representing 5
```
"""
function numer(g::GiacExpr)::GiacExpr
    if g.ptr == C_NULL
        throw(GiacError("Cannot get numerator of null expression", :type))
    end

    t = giac_type(g)
    if t == GIAC_INT || t == GIAC_ZINT
        return g  # Integer is its own numerator
    elseif t == GIAC_FRAC
        # Use existing _giac_rational_num or CxxWrap frac_num
        with_giac_lock() do
            if !_stub_mode[] && GiacCxxBindings._have_library
                gen = _ptr_to_gen(g)
                if gen !== nothing
                    num_gen = GiacCxxBindings.frac_num(gen)
                    return _gen_to_giacexpr(num_gen)
                end
            end
            # Fallback: get numerator value
            num_val = _giac_rational_num(g.ptr)
            return giac_eval(string(num_val))
        end
    else
        throw(GiacError("Gen is not a fraction or integer", :type))
    end
end

"""
    denom(g::GiacExpr) -> GiacExpr

Return the denominator of a fraction, or `1` for integers.

# Example
```julia
denom(giac_eval("3/4"))   # GiacExpr representing 4
denom(giac_eval("5"))     # GiacExpr representing 1
```
"""
function denom(g::GiacExpr)::GiacExpr
    if g.ptr == C_NULL
        throw(GiacError("Cannot get denominator of null expression", :type))
    end

    t = giac_type(g)
    if t == GIAC_INT || t == GIAC_ZINT
        return giac_eval("1")  # Integer has denominator 1
    elseif t == GIAC_FRAC
        # Use existing _giac_rational_den or CxxWrap frac_den
        with_giac_lock() do
            if !_stub_mode[] && GiacCxxBindings._have_library
                gen = _ptr_to_gen(g)
                if gen !== nothing
                    den_gen = GiacCxxBindings.frac_den(gen)
                    return _gen_to_giacexpr(den_gen)
                end
            end
            # Fallback: get denominator value
            den_val = _giac_rational_den(g.ptr)
            return giac_eval(string(den_val))
        end
    else
        throw(GiacError("Gen is not a fraction or integer", :type))
    end
end

"""
    real_part(g::GiacExpr) -> GiacExpr

Return the real part of a complex number, or the value itself for non-complex.

# Example
```julia
real_part(giac_eval("3+4*i"))  # GiacExpr representing 3
real_part(giac_eval("5"))      # GiacExpr representing 5
```
"""
function real_part(g::GiacExpr)::GiacExpr
    if g.ptr == C_NULL
        throw(GiacError("Cannot get real part of null expression", :type))
    end

    t = giac_type(g)
    if t == GIAC_CPLX
        with_giac_lock() do
            if !_stub_mode[] && GiacCxxBindings._have_library
                gen = _ptr_to_gen(g)
                if gen !== nothing
                    re_gen = GiacCxxBindings.cplx_re(gen)
                    return _gen_to_giacexpr(re_gen)
                end
            end
            # Fallback: get real part value
            re_val = _giac_complex_real(g.ptr)
            return giac_eval(string(re_val))
        end
    else
        return g  # Non-complex is its own real part
    end
end

"""
    imag_part(g::GiacExpr) -> GiacExpr

Return the imaginary part of a complex number, or `0` for non-complex.

# Example
```julia
imag_part(giac_eval("3+4*i"))  # GiacExpr representing 4
imag_part(giac_eval("5"))      # GiacExpr representing 0
```
"""
function imag_part(g::GiacExpr)::GiacExpr
    if g.ptr == C_NULL
        throw(GiacError("Cannot get imaginary part of null expression", :type))
    end

    t = giac_type(g)
    if t == GIAC_CPLX
        with_giac_lock() do
            if !_stub_mode[] && GiacCxxBindings._have_library
                gen = _ptr_to_gen(g)
                if gen !== nothing
                    im_gen = GiacCxxBindings.cplx_im(gen)
                    return _gen_to_giacexpr(im_gen)
                end
            end
            # Fallback: get imaginary part value
            im_val = _giac_complex_imag(g.ptr)
            return giac_eval(string(im_val))
        end
    else
        return giac_eval("0")  # Non-complex has zero imaginary part
    end
end

"""
    symb_funcname(g::GiacExpr) -> String

Return the function name of a symbolic expression.

# Example
```julia
symb_funcname(giac_eval("sin(x)"))  # "sin"
```
"""
function symb_funcname(g::GiacExpr)::String
    if g.ptr == C_NULL
        throw(GiacError("Cannot get function name of null expression", :type))
    end

    if giac_type(g) != GIAC_SYMB
        throw(GiacError("Gen is not symbolic", :type))
    end

    with_giac_lock() do
        if !_stub_mode[] && GiacCxxBindings._have_library
            gen = _ptr_to_gen(g)
            ctx = _get_cxxwrap_context()
            if gen !== nothing && ctx !== nothing
                return GiacCxxBindings.symb_funcname(gen, ctx)
            end
        end
        # Fallback: parse from string representation
        expr_str = string(g)
        m = match(r"^(\w+)\(", expr_str)
        return m !== nothing ? String(m.captures[1]) : ""
    end
end

"""
    symb_argument(g::GiacExpr) -> GiacExpr

Return the argument (operand) of a symbolic expression.

# Example
```julia
arg = symb_argument(giac_eval("sin(x)"))  # GiacExpr representing x
```
"""
function symb_argument(g::GiacExpr)::GiacExpr
    if g.ptr == C_NULL
        throw(GiacError("Cannot get argument of null expression", :type))
    end

    if giac_type(g) != GIAC_SYMB
        throw(GiacError("Gen is not symbolic", :type))
    end

    with_giac_lock() do
        if !_stub_mode[] && GiacCxxBindings._have_library
            gen = _ptr_to_gen(g)
            if gen !== nothing
                arg_gen = GiacCxxBindings.symb_argument(gen)
                return _gen_to_giacexpr(arg_gen)
            end
        end
        # Fallback: extract argument from string representation
        expr_str = string(g)
        m = match(r"^\w+\((.+)\)$", expr_str)
        return m !== nothing ? giac_eval(String(m.captures[1])) : g
    end
end

# Internal helper to convert Gen to GiacExpr
function _gen_to_giacexpr(gen)
    # Convert CxxWrap Gen to GiacExpr via string representation
    if gen !== nothing
        # GiacCxxBindings.to_string returns a CxxWrap StdString, convert to Julia String
        std_str = GiacCxxBindings.to_string(gen)
        julia_str = String(std_str)
        return giac_eval(julia_str)
    end
    throw(GiacError("Cannot convert Gen to GiacExpr", :type))
end
