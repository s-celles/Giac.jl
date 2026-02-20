# Extension module for Symbolics.jl integration
# Provides bidirectional conversion between GiacExpr and Symbolics.Num types
# Updated for 042-preserve-symbolic-sqrt: Preserves symbolic functions like sqrt(2)

module GiacSymbolicsExt

using Giac
using Symbolics
# Import SymbolicUtils types (Sym and symtype used for type checking)
# Note: Term removed - use Symbolics.term() for cross-version compatibility (v6/v7+)
import Symbolics.SymbolicUtils: Sym, symtype

# ============================================================================
# GIAC to Julia Name Mapping
# Only needed for function names that differ between GIAC and Julia
# ============================================================================

"""
    GIAC_NAME_MAPPING

Dictionary mapping GIAC function names to Julia functions where names differ.
For functions with identical names, Julia functions are resolved dynamically.
"""
const GIAC_NAME_MAPPING = Dict{String, Function}(
    "ln" => log,  # GIAC uses "ln", Julia uses "log" (not to be confused with log10, which is "log10" in both)
)

"""
    _get_julia_function(giac_name::String) -> Union{Function, Nothing}

Get the Julia function corresponding to a GIAC function name.
First checks GIAC_NAME_MAPPING for name differences, then tries to resolve
from Base using the same name. Returns nothing if not found.
"""
function _get_julia_function(giac_name::String)::Union{Function, Nothing}
    # Check name mapping first (for names that differ)
    if haskey(GIAC_NAME_MAPPING, giac_name)
        return GIAC_NAME_MAPPING[giac_name]
    end
    # Try to get function from Base with same name
    sym = Symbol(giac_name)
    if isdefined(Base, sym)
        f = getfield(Base, sym)
        if f isa Function
            return f
        end
    end
    return nothing
end

# ============================================================================
# Symbolic Operators Mapping (T010 - Feature 044)
# Maps GIAC operator names to Julia functions for symbolic term construction
# These operators preserve factored structure when used with Symbolics.term()
# ============================================================================

"""
    SYMBOLIC_OPS

Dictionary mapping GIAC operator names to Julia functions.
Used for preserving factorized expression structure (e.g., 2^6*5^6).
"""
const SYMBOLIC_OPS = Dict{String, Function}(
    "*" => *,
    "^" => ^,
    "+" => +,
    "-" => -,
    "/" => /,
)

# ============================================================================
# Foundational Helper Functions (T005-T007)
# ============================================================================

"""
    _is_function_call(s::AbstractString) -> Bool

Check if a string represents a function call pattern: `funcname(args)`.
Returns true if the string matches the pattern where funcname is a valid identifier.

# Examples
```julia
_is_function_call("sqrt(2)")       # true
_is_function_call("sin(x + 1)")    # true
_is_function_call("x + 1")         # false
_is_function_call("123")           # false
```
"""
function _is_function_call(s::AbstractString)::Bool
    s = strip(s)
    # Match pattern: identifier followed by (...)
    m = match(r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(.*\)$"s, s)
    return m !== nothing
end

"""
    _extract_function_parts(s::AbstractString) -> Tuple{String, String}

Extract function name and arguments string from a function call.
Returns (funcname, args_string) tuple.

# Examples
```julia
_extract_function_parts("sqrt(2)")       # ("sqrt", "2")
_extract_function_parts("sin(x + 1)")    # ("sin", "x + 1")
_extract_function_parts("f(a, b, c)")    # ("f", "a, b, c")
```
"""
function _extract_function_parts(s::AbstractString)::Tuple{String, String}
    s = strip(s)
    # Find the opening parenthesis
    paren_start = findfirst('(', s)
    if paren_start === nothing
        error("Not a function call: $s")
    end

    funcname = strip(s[1:paren_start-1])
    # Extract content between first ( and last )
    args_str = s[paren_start+1:end-1]  # Remove ( and )

    return (String(funcname), String(args_str))
end

"""
    _split_args(s::AbstractString) -> Vector{String}

Split a comma-separated argument string, respecting nested parentheses and brackets.

# Examples
```julia
_split_args("a, b, c")           # ["a", "b", "c"]
_split_args("f(x), g(y)")        # ["f(x)", "g(y)"]
_split_args("a + b, c * d")      # ["a + b", "c * d"]
_split_args("")                  # String[]
```
"""
function _split_args(s::AbstractString)::Vector{String}
    s = strip(s)
    if isempty(s)
        return String[]
    end

    result = String[]
    current = ""
    depth = 0

    for c in s
        if c == '(' || c == '[' || c == '{'
            depth += 1
            current *= c
        elseif c == ')' || c == ']' || c == '}'
            depth -= 1
            current *= c
        elseif c == ',' && depth == 0
            push!(result, strip(current))
            current = ""
        else
            current *= c
        end
    end

    # Don't forget the last argument
    if !isempty(strip(current))
        push!(result, strip(current))
    end

    return result
end

# ============================================================================
# Symbolic Expression Parser (T013-T015)
# ============================================================================

"""
    _parse_symbolic_expr(s::AbstractString, var_cache::Dict{String, Num}) -> Any

Recursively parse a GIAC expression string, preserving symbolic functions.
Uses Symbolics.term() for preservable functions like sqrt, exp, log, etc.

# Arguments
- `s`: The expression string to parse
- `var_cache`: Cache of already-created symbolic variables

# Returns
A Symbolics.jl expression (Num) with symbolic functions preserved.
"""
function _parse_symbolic_expr(s::AbstractString, var_cache::Dict{String, Num})
    s = strip(s)

    # Handle empty string
    if isempty(s)
        return 0
    end

    # Handle pi constant (T025)
    if s == "pi" || s == "π"
        return Symbolics.pi
    end

    # Handle imaginary unit
    if s == "i"
        return im
    end

    # Try to parse as a number first
    # Feature 045: Try BigInt first for integer-looking strings to handle large numbers
    if match(r"^-?\d+$", s) !== nothing
        # It's an integer literal - use BigInt to handle any size
        big_val = parse(BigInt, s)
        # For small integers, convert to Int for better compatibility
        if typemin(Int64) <= big_val <= typemax(Int64)
            return Int64(big_val)
        end
        return big_val
    end
    num = tryparse(Float64, s)
    if num !== nothing
        # Check if it's actually an integer
        if isinteger(num)
            return Int(num)
        end
        return num
    end

    # Check if it's a simple identifier (variable)
    if match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", s) !== nothing
        # Create or retrieve symbolic variable
        if !haskey(var_cache, s)
            var_cache[s] = Symbolics.variable(Symbol(s))
        end
        return var_cache[s]
    end

    # Check if it's a function call
    if _is_function_call(s)
        funcname, args_str = _extract_function_parts(s)

        # Try to resolve Julia function (handles name mapping + Base lookup)
        julia_func = _get_julia_function(funcname)
        if julia_func !== nothing
            args = _split_args(args_str)

            # Recursively parse arguments
            parsed_args = [_parse_symbolic_expr(arg, var_cache) for arg in args]

            # Create a symbolic term to preserve the function
            # Use Symbolics.term for cross-version compatibility (v6 and v7+)
            if length(parsed_args) == 1
                return Num(Symbolics.term(julia_func, Symbolics.unwrap(parsed_args[1])))
            else
                return Num(Symbolics.term(julia_func, [Symbolics.unwrap(a) for a in parsed_args]...))
            end
        end
    end

    # Fall back to standard Symbolics parsing for complex expressions
    # This handles arithmetic, powers, etc.
    try
        parsed = Meta.parse(s)
        return _convert_parsed_expr(parsed, var_cache)
    catch
        # If parsing fails, try the original method
        return Symbolics.parse_expr_to_symbolic(Meta.parse(s), @__MODULE__)
    end
end

"""
    _convert_parsed_expr(expr, var_cache::Dict{String, Num}) -> Any

Convert a Julia Expr to Symbolics, preserving symbolic functions.
"""
function _convert_parsed_expr(expr, var_cache::Dict{String, Num})
    if expr isa Number
        return expr
    elseif expr isa Symbol
        name = String(expr)
        # Handle special constants
        if name == "pi" || name == "π"
            return Symbolics.pi
        elseif name == "i"
            return im
        end
        # Create or retrieve variable
        if !haskey(var_cache, name)
            var_cache[name] = Symbolics.variable(expr)
        end
        return var_cache[name]
    elseif expr isa Expr
        if expr.head == :macrocall
            # Feature 045: Handle large integer literals (e.g., @int128_str, @big_str)
            # These are created by Meta.parse for integers larger than Int64
            return Core.eval(Main, expr)
        elseif expr.head == :call
            func = expr.args[1]
            args = expr.args[2:end]
            func_name = String(func)
            converted_args = [_convert_parsed_expr(a, var_cache) for a in args]

            # Handle arithmetic operators directly
            if func == :+
                return sum(converted_args)
            elseif func == :-
                if length(converted_args) == 1
                    return -converted_args[1]
                else
                    return converted_args[1] - converted_args[2]
                end
            elseif func == :*
                return prod(converted_args)
            elseif func == :/
                return converted_args[1] / converted_args[2]
            elseif func == :^
                return converted_args[1] ^ converted_args[2]
            end

            # Try to resolve as a symbolic function
            julia_func = _get_julia_function(func_name)
            if julia_func !== nothing
                # Create symbolic term for preservation (cross-version compatible)
                return Num(Symbolics.term(julia_func, [Symbolics.unwrap(a) for a in converted_args]...))
            else
                # Fall back to creating a symbolic call
                return Symbolics.parse_expr_to_symbolic(expr, @__MODULE__)
            end
        else
            # Other expression types - fall back
            return Symbolics.parse_expr_to_symbolic(expr, @__MODULE__)
        end
    else
        return expr
    end
end

# ============================================================================
# Public API Functions
# ============================================================================

"""
    to_giac(expr::Num)

Convert a Symbolics.jl expression to a GiacExpr.

# Example
```julia
using Giac, Symbolics
@variables x y
giac_expr = to_giac(x^2 + y)
```
"""
function Giac.to_giac(expr::Num)::GiacExpr
    # Convert Symbolics expression to string and parse with GIAC
    expr_str = string(Symbolics.unwrap(expr))
    return giac_eval(expr_str)
end

"""
    _is_factored_expression(s::AbstractString) -> Bool

Check if a string looks like a factored expression (contains operators that should be preserved).
"""
function _is_factored_expression(s::AbstractString)::Bool
    # Check for operators that indicate factored structure
    return occursin("^", s) && (occursin("*", s) || occursin(r"^\d+\^\d+$", s))
end

"""
    _get_held_gen(expr_str::AbstractString)

Get a Gen object for the expression with structure preserved using hold().
"""
function _get_held_gen(expr_str::AbstractString)
    # Use hold() to prevent evaluation
    held_str = "hold($expr_str)"
    return Giac.GiacCxxBindings.giac_eval(held_str)
end

"""
    _bytes_to_bigint(bytes::Vector{UInt8}, sign::Int32) -> BigInt

Construct a BigInt from raw bytes and sign using direct GMP ccall.
This avoids string parsing for better performance with large integers.

# Arguments
- `bytes`: Big-endian byte representation of the absolute value
- `sign`: -1 (negative), 0 (zero), or 1 (positive)

# Returns
BigInt with correct value and sign
"""
function _bytes_to_bigint(bytes::Vector{UInt8}, sign::Int32)::BigInt
    # Handle zero case
    if isempty(bytes) || sign == 0
        return BigInt(0)
    end

    result = BigInt()

    # mpz_import(rop, count, order=1 (MSB first), size=1 (byte), endian=1 (big), nails=0, data)
    ccall((:__gmpz_import, :libgmp), Cvoid,
          (Ref{BigInt}, Csize_t, Cint, Csize_t, Cint, Csize_t, Ptr{UInt8}),
          result, length(bytes), 1, 1, 1, 0, bytes)

    # Apply sign if negative
    if sign < 0
        ccall((:__gmpz_neg, :libgmp), Cvoid,
              (Ref{BigInt}, Ref{BigInt}), result, result)
    end

    return result
end

"""
    _gen_tree_to_symbolics(gen, var_cache::Dict{String, Num}) -> Any

Recursively convert a CxxWrap Gen object tree to Symbolics.jl expression.
Uses Symbolics.term() for multiplication and exponentiation to preserve factored structure.
"""
function _gen_tree_to_symbolics(gen, var_cache::Dict{String, Num})
    t = Giac.GenTypes.T(Giac.GiacCxxBindings.type(gen))

    if t == Giac.GenTypes.INT
        # Integer: use direct accessor for efficiency
        return Num(Giac.GiacCxxBindings.to_int64(gen))
    elseif t == Giac.GenTypes.DOUBLE
        # Float: use direct accessor for efficiency
        return Num(Giac.GiacCxxBindings.to_double(gen))
    elseif t == Giac.GenTypes.ZINT
        # Arbitrary precision integer (GMP) - Feature 049
        # Direct binary transfer: export bytes + sign, import via GMP ccall
        # This avoids string parsing for cleaner and faster conversion
        bytes = Vector{UInt8}(Giac.GiacCxxBindings.zint_to_bytes(gen))
        sign = Int32(Giac.GiacCxxBindings.zint_sign(gen))
        return Num(_bytes_to_bigint(bytes, sign))
    elseif t == Giac.GenTypes.CPLX
        # Complex number - Feature 050
        # Use direct C++ accessors for real and imaginary parts
        re_gen = Giac.GiacCxxBindings.cplx_re(gen)
        im_gen = Giac.GiacCxxBindings.cplx_im(gen)
        # Recursively convert both parts
        re_sym = _gen_tree_to_symbolics(re_gen, var_cache)
        im_sym = _gen_tree_to_symbolics(im_gen, var_cache)
        # Return Complex - don't wrap in Num (causes ambiguity error)
        return Symbolics.unwrap(re_sym) + Symbolics.unwrap(im_sym) * im
    elseif t == Giac.GenTypes.IDNT
        # Identifier/variable: use dedicated idnt_name accessor
        name = String(Giac.GiacCxxBindings.idnt_name(gen))
        # Handle special constants
        if name == "pi" || name == "π"
            return Symbolics.pi
        elseif name == "i"
            return im
        end
        # Create or retrieve symbolic variable
        if !haskey(var_cache, name)
            var_cache[name] = Symbolics.variable(Symbol(name))
        end
        return var_cache[name]
    elseif t == Giac.GenTypes.SYMB
        # Symbolic expression: traverse tree
        op = Giac.GiacCxxBindings.symb_sommet_name(gen)
        feuille = Giac.GiacCxxBindings.symb_feuille(gen)
        feuille_type = Giac.GenTypes.T(Giac.GiacCxxBindings.type(feuille))

        # Get arguments
        args = if feuille_type == Giac.GenTypes.VECT
            n = Giac.GiacCxxBindings.vect_size(feuille)
            [Giac.GiacCxxBindings.vect_at(feuille, i-1) for i in 1:n]
        else
            [feuille]
        end

        # Recursively convert arguments
        converted_args = [_gen_tree_to_symbolics(a, var_cache) for a in args]

        # Handle operators that should preserve structure (factorization)
        if op == "*" || op == "^"
            # Use Symbolics.term to preserve factored structure (cross-version compatible)
            julia_op = SYMBOLIC_OPS[op]
            unwrapped = [Symbolics.unwrap(a) for a in converted_args]
            return Num(Symbolics.term(julia_op, unwrapped...))
        elseif op == "+"
            # Sum can be evaluated without losing structure
            return sum(converted_args)
        elseif op == "-"
            if length(converted_args) == 1
                return -converted_args[1]
            else
                return converted_args[1] - converted_args[2]
            end
        elseif op == "/"
            return converted_args[1] / converted_args[2]
        else
            # Try to resolve as a Julia function
            julia_func = _get_julia_function(op)
            if julia_func !== nothing
                # Create symbolic term (cross-version compatible)
                unwrapped = [Symbolics.unwrap(a) for a in converted_args]
                return Num(Symbolics.term(julia_func, unwrapped...))
            else
                # Unknown operator: fall back to string parsing
                gen_str = String(Giac.GiacCxxBindings.to_string(gen))
                return _parse_symbolic_expr(gen_str, var_cache)
            end
        end
    elseif t == Giac.GenTypes.VECT
        # Vector: convert each element
        n = Giac.GiacCxxBindings.vect_size(gen)
        return [_gen_tree_to_symbolics(Giac.GiacCxxBindings.vect_at(gen, i-1), var_cache) for i in 1:n]
    elseif t == Giac.GenTypes.FRAC
        # Fraction: convert numerator and denominator
        num = Giac.GiacCxxBindings.frac_num(gen)
        den = Giac.GiacCxxBindings.frac_den(gen)
        num_sym = _gen_tree_to_symbolics(num, var_cache)
        den_sym = _gen_tree_to_symbolics(den, var_cache)
        return num_sym // den_sym
    else
        # Fallback: use string parsing for unknown types
        gen_str = String(Giac.GiacCxxBindings.to_string(gen))
        return _parse_symbolic_expr(gen_str, var_cache)
    end
end

"""
    to_symbolics(expr::GiacExpr)

Convert a GiacExpr to a Symbolics.jl Num expression.

Preserves symbolic mathematical functions like sqrt, exp, log, sin, cos, etc.
instead of evaluating them to floating-point approximations.

Also preserves factorized expression structure (Feature 044):
- `ifactor(n) |> to_symbolics` returns factored form (e.g., `2^6*5^6`)
- `factor(poly) |> to_symbolics` returns factored polynomial form

# Examples
```julia
using Giac, Symbolics
using Giac.Commands: ifactor, factor

# sqrt(2) is preserved symbolically
result = giac_eval("sqrt(2)")
sym_expr = to_symbolics(result)  # sqrt(2), not 1.414...

# Integer factorization is preserved
result = ifactor(1000000)
sym_expr = to_symbolics(result)  # 2^6*5^6, not 1000000

# Polynomial factorization is preserved
x = giac_eval("x")
result = factor(x^2 - 1)
sym_expr = to_symbolics(result)  # (x-1)*(x+1)

# Variables are preserved
result = giac_eval("x^2 + y")
sym_expr = to_symbolics(result)
```
"""
function Giac.to_symbolics(expr::GiacExpr)
    # Create variable cache for consistent variable handling
    var_cache = Dict{String, Num}()

    # Get the string representation
    expr_str = string(expr)

    # Check if this looks like a factored expression that needs tree traversal
    # to preserve structure (e.g., "2^6*5^6" from ifactor)
    if !Giac.is_stub_mode() && Giac.GiacCxxBindings._have_library
        # Use hold() to preserve structure and get the proper SYMB type
        try
            held_gen = _get_held_gen(expr_str)
            held_type = Giac.GenTypes.T(Giac.GiacCxxBindings.type(held_gen))

            # Use tree-based conversion for most types
            # This ensures consistent Num wrapping
            if held_type in (Giac.GenTypes.INT, Giac.GenTypes.DOUBLE, Giac.GenTypes.IDNT,
                             Giac.GenTypes.VECT, Giac.GenTypes.SYMB, Giac.GenTypes.FRAC,
                             Giac.GenTypes.CPLX)  # Feature 050: CPLX direct handling
                return _gen_tree_to_symbolics(held_gen, var_cache)
            end
        catch e
            @debug "Failed to use held conversion, falling back to string parsing" exception=e
        end
    end

    # For other expressions or when CxxWrap isn't available,
    # use the string-based parser and wrap in Num for consistency
    result = _parse_symbolic_expr(expr_str, var_cache)
    # Ensure we return Num for consistency (but not Complex, which can't be wrapped)
    if result isa Number && !(result isa Num) && !(result isa Complex)
        return Num(result)
    end
    return result
end

# Export conversion functions
export to_giac, to_symbolics

end # module GiacSymbolicsExt
