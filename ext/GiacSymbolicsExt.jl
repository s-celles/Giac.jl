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
        if expr.head == :call
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
    to_symbolics(expr::GiacExpr)

Convert a GiacExpr to a Symbolics.jl Num expression.

Preserves symbolic mathematical functions like sqrt, exp, log, sin, cos, etc.
instead of evaluating them to floating-point approximations.

# Examples
```julia
using Giac, Symbolics

# sqrt(2) is preserved symbolically
result = giac_eval("sqrt(2)")
sym_expr = to_symbolics(result)  # sqrt(2), not 1.414...

# Complex expressions work too
result = giac_eval("factor(x^8-1)")
sym_expr = to_symbolics(result)  # Contains sqrt(2) symbolically

# Variables are preserved
result = giac_eval("x^2 + y")
sym_expr = to_symbolics(result)
```
"""
function Giac.to_symbolics(expr::GiacExpr)
    # Convert GIAC expression to string
    expr_str = string(expr)

    # Create variable cache for consistent variable handling
    var_cache = Dict{String, Num}()

    # Use symbolic-preserving parser
    return _parse_symbolic_expr(expr_str, var_cache)
end

# Export conversion functions
export to_giac, to_symbolics

end # module GiacSymbolicsExt
