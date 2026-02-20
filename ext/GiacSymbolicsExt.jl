# Extension module for Symbolics.jl integration
# Provides bidirectional conversion between GiacExpr and Symbolics.Num types
# Updated for 042-preserve-symbolic-sqrt: Preserves symbolic functions like sqrt(2)

module GiacSymbolicsExt

using Giac
using Symbolics
# Import Term from SymbolicUtils (available via Symbolics reexport)
import Symbolics.SymbolicUtils: Term, Sym, symtype

# ============================================================================
# Preservable Functions Mapping (T004)
# Maps GIAC function names to Julia Base functions for Term construction
# ============================================================================

"""
    PRESERVABLE_FUNCTIONS

Dictionary mapping GIAC function names to Julia functions.
These functions will be preserved as symbolic Term expressions rather than evaluated.
"""
const PRESERVABLE_FUNCTIONS = Dict{String, Function}(
    # Square and cube roots (US1, US2)
    "sqrt" => sqrt,
    # Exponential and logarithmic (US2)
    "exp" => exp,
    "log" => log,
    "ln" => log,
    # Trigonometric (US2)
    "sin" => sin,
    "cos" => cos,
    "tan" => tan,
    "asin" => asin,
    "acos" => acos,
    "atan" => atan,
    # Hyperbolic (US2)
    "sinh" => sinh,
    "cosh" => cosh,
    "tanh" => tanh,
    # Other
    "abs" => abs,
)

# ============================================================================
# Symbolic Operators Mapping (T010 - Feature 044)
# Maps GIAC operator names to Julia functions for Term construction
# These operators preserve factored structure when used with Term()
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
Uses SymbolicUtils.Term for preservable functions like sqrt, exp, log, etc.

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

        # Check if this is a preservable function
        if haskey(PRESERVABLE_FUNCTIONS, funcname)
            julia_func = PRESERVABLE_FUNCTIONS[funcname]
            args = _split_args(args_str)

            # Recursively parse arguments
            parsed_args = [_parse_symbolic_expr(arg, var_cache) for arg in args]

            # Create a Term to preserve the symbolic function
            # Wrap in Num for Symbolics compatibility
            if length(parsed_args) == 1
                return Num(Term(julia_func, [Symbolics.unwrap(parsed_args[1])]))
            else
                return Num(Term(julia_func, [Symbolics.unwrap(a) for a in parsed_args]))
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

            # Check if this function should be preserved
            func_name = String(func)
            if haskey(PRESERVABLE_FUNCTIONS, func_name)
                julia_func = PRESERVABLE_FUNCTIONS[func_name]
                converted_args = [_convert_parsed_expr(a, var_cache) for a in args]
                # Create Term for symbolic preservation
                return Num(Term(julia_func, [Symbolics.unwrap(a) for a in converted_args]))
            else
                # Standard function call - evaluate normally
                converted_args = [_convert_parsed_expr(a, var_cache) for a in args]
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
                else
                    # Unknown function - try to evaluate
                    try
                        f = getfield(Base, func)
                        return f(converted_args...)
                    catch
                        # Fall back to creating a symbolic call
                        return Symbolics.parse_expr_to_symbolic(expr, @__MODULE__)
                    end
                end
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
    _gen_tree_to_symbolics(gen, var_cache::Dict{String, Num}) -> Any

Recursively convert a CxxWrap Gen object tree to Symbolics.jl expression.
Uses Term objects for multiplication and exponentiation to preserve factored structure.
"""
function _gen_tree_to_symbolics(gen, var_cache::Dict{String, Num})
    t = Giac.GiacCxxBindings.type(gen)

    if t == 0  # INT
        # Integer: extract value directly and wrap in Num for consistency
        gen_str = String(Giac.GiacCxxBindings.to_string(gen))
        return Num(parse(Int64, gen_str))
    elseif t == 1  # DOUBLE
        # Float: parse from string and wrap in Num for consistency
        gen_str = String(Giac.GiacCxxBindings.to_string(gen))
        return Num(parse(Float64, gen_str))
    elseif t == 2  # ZINT (arbitrary precision integer - GMP)
        # Feature 045: Handle large integers that don't fit in Int64
        gen_str = String(Giac.GiacCxxBindings.to_string(gen))
        return Num(parse(BigInt, gen_str))
    elseif t == 6  # IDNT
        # Identifier/variable
        name = String(Giac.GiacCxxBindings.to_string(gen))
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
    elseif t == 8  # SYMB
        # Symbolic expression: traverse tree
        op = Giac.GiacCxxBindings.symb_sommet_name(gen)
        feuille = Giac.GiacCxxBindings.symb_feuille(gen)
        feuille_type = Giac.GiacCxxBindings.type(feuille)

        # Get arguments
        args = if feuille_type == 7  # VECT
            n = Giac.GiacCxxBindings.vect_size(feuille)
            [Giac.GiacCxxBindings.vect_at(feuille, i-1) for i in 1:n]
        else
            [feuille]
        end

        # Recursively convert arguments
        converted_args = [_gen_tree_to_symbolics(a, var_cache) for a in args]

        # Handle operators that should preserve structure (factorization)
        if op == "*" || op == "^"
            # Use Term to preserve factored structure without evaluation
            julia_op = SYMBOLIC_OPS[op]
            unwrapped = [Symbolics.unwrap(a) for a in converted_args]
            return Num(Term(julia_op, unwrapped))
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
        elseif haskey(PRESERVABLE_FUNCTIONS, op)
            # Preservable function (sqrt, sin, exp, etc.)
            julia_func = PRESERVABLE_FUNCTIONS[op]
            unwrapped = [Symbolics.unwrap(a) for a in converted_args]
            return Num(Term(julia_func, unwrapped))
        else
            # Unknown operator: fall back to string parsing
            gen_str = String(Giac.GiacCxxBindings.to_string(gen))
            return _parse_symbolic_expr(gen_str, var_cache)
        end
    elseif t == 7  # VECT
        # Vector: convert each element
        n = Giac.GiacCxxBindings.vect_size(gen)
        return [_gen_tree_to_symbolics(Giac.GiacCxxBindings.vect_at(gen, i-1), var_cache) for i in 1:n]
    elseif t == 10  # FRAC
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
            held_type = Giac.GiacCxxBindings.type(held_gen)

            # Use tree-based conversion for most types
            # This ensures consistent Num wrapping
            if held_type in (0, 1, 6, 7, 8, 10)  # INT, DOUBLE, IDNT, VECT, SYMB, FRAC
                return _gen_tree_to_symbolics(held_gen, var_cache)
            end
        catch e
            @debug "Failed to use held conversion, falling back to string parsing" exception=e
        end
    end

    # For other expressions or when CxxWrap isn't available,
    # use the string-based parser and wrap in Num for consistency
    result = _parse_symbolic_expr(expr_str, var_cache)
    # Ensure we return Num for consistency
    if result isa Number && !(result isa Num)
        return Num(result)
    end
    return result
end

# Export conversion functions
export to_giac, to_symbolics

end # module GiacSymbolicsExt
