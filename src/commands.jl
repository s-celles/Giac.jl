# Dynamic command invocation for Giac.jl
# Enables calling any GIAC command via giac_cmd(:cmd, args...)

# ============================================================================
# Argument Conversion
# ============================================================================

"""
    _arg_to_giac_string(arg)

Convert a Julia argument to a GIAC-compatible string representation.

# Supported types
- `GiacExpr`: Uses string representation
- `String`: Used directly
- `Number`: Converted via string()
- `Symbol`: Converted to string (for variable names)
- `Vector`: Converted to GIAC list syntax [a, b, c]
"""
function _arg_to_giac_string(arg::GiacExpr)::String
    return string(arg)
end

function _arg_to_giac_string(arg::String)::String
    return arg
end

function _arg_to_giac_string(arg::Number)::String
    return string(arg)
end

function _arg_to_giac_string(arg::Symbol)::String
    return string(arg)
end

function _arg_to_giac_string(arg::AbstractVector)::String
    elements = [_arg_to_giac_string(x) for x in arg]
    return "[" * join(elements, ",") * "]"
end

function _arg_to_giac_string(arg)
    throw(ArgumentError("Cannot convert $(typeof(arg)) to GIAC string representation"))
end

# ============================================================================
# Command String Building
# ============================================================================

"""
    _build_command_string(cmd::String, args::Vector{String})

Build a GIAC command string from command name and string arguments.

# Example
```julia
_build_command_string("factor", ["x^2-1"])  # Returns "factor(x^2-1)"
_build_command_string("diff", ["x^2", "x"]) # Returns "diff(x^2,x)"
```
"""
function _build_command_string(cmd::String, args::Vector{String})::String
    if isempty(args)
        return "$cmd()"
    end
    return "$cmd(" * join(args, ",") * ")"
end

# ============================================================================
# Core Command Invocation
# ============================================================================

"""
    giac_cmd(cmd::Symbol, args...) -> GiacExpr

Invoke any GIAC command by name and return the result as a GiacExpr.

This is the core function for dynamic command invocation, enabling access to
all 2200+ GIAC commands through a uniform interface.

# Arguments
- `cmd::Symbol`: GIAC command name (e.g., `:factor`, `:sin`, `:integrate`)
- `args...`: Command arguments (GiacExpr, String, Number, or Symbol)

# Returns
- `GiacExpr`: Result of command execution

# Throws
- `GiacError(:eval)`: If command is unknown or execution fails
- `ArgumentError`: If arguments cannot be converted to GIAC format

# Examples
```julia
# Single argument
expr = giac_eval("x^2 - 1")
result = giac_cmd(:factor, expr)  # Returns (x-1)*(x+1)

# Multiple arguments
x = giac_eval("x")
derivative = giac_cmd(:diff, expr, x)  # Returns 2*x

# Trigonometric functions
result = giac_cmd(:sin, giac_eval("pi/6"))  # Returns 1/2
```

# See also
- `giac_eval`: Direct string evaluation
- `search_commands`: Find available commands
- `giac_help`: Get help for a command
"""
function giac_cmd(cmd::Symbol, args...)::GiacExpr
    cmd_str = string(cmd)

    # Validate command exists
    if !isempty(VALID_COMMANDS) && cmd_str ∉ VALID_COMMANDS
        # Use suggest_commands from command_registry.jl (005-nearest-command-suggestions)
        suggestions = suggest_commands(cmd_str)
        suggestion_text = _format_suggestions(suggestions)
        throw(GiacError("Unknown command: $cmd_str.$suggestion_text", :eval))
    end

    # Warn about Julia conflicts (008-all-giac-commands, FR-010)
    # This helps users understand why certain commands can't be exported directly
    _warn_conflict(cmd_str)

    # Convert arguments to GIAC strings
    arg_strings = String[]
    for arg in args
        try
            push!(arg_strings, _arg_to_giac_string(arg))
        catch e
            if e isa ArgumentError
                rethrow()
            end
            throw(ArgumentError("Cannot convert argument of type $(typeof(arg)) to GIAC format"))
        end
    end

    # Build and execute command
    cmd_string = _build_command_string(cmd_str, arg_strings)

    return with_giac_lock() do
        giac_eval(cmd_string)
    end
end

# ============================================================================
# Base Function Extensions (using Tier 1 wrappers for performance)
# ============================================================================

# Note: These use Tier 1 wrappers when available, falling back to giac_cmd.
# The public API is invoke_cmd from Giac.Commands.

# Helper to wrap Tier 1 unary functions
function _tier1_or_fallback(tier1_func::Function, cmd::Symbol, expr::GiacExpr)::GiacExpr
    result_ptr = tier1_func(expr.ptr)
    if result_ptr != C_NULL
        return GiacExpr(result_ptr)
    end
    # Fall back to string-based command
    return giac_cmd(cmd, expr)
end

# Helper to wrap Tier 1 binary functions
function _tier1_or_fallback_binary(tier1_func::Function, cmd::Symbol, a::GiacExpr, b::GiacExpr)::GiacExpr
    result_ptr = tier1_func(a.ptr, b.ptr)
    if result_ptr != C_NULL
        return GiacExpr(result_ptr)
    end
    # Fall back to string-based command
    return giac_cmd(cmd, a, b)
end

# Helper to wrap Tier 1 ternary functions
function _tier1_or_fallback_ternary(tier1_func::Function, cmd::Symbol, a::GiacExpr, b::GiacExpr, c::GiacExpr)::GiacExpr
    result_ptr = tier1_func(a.ptr, b.ptr, c.ptr)
    if result_ptr != C_NULL
        return GiacExpr(result_ptr)
    end
    # Fall back to string-based command
    return giac_cmd(cmd, a, b, c)
end

"""
    Base.sin(expr::GiacExpr) -> GiacExpr

Compute the sine of a GiacExpr. Enables natural Julia syntax for symbolic math.
Uses Tier 1 C++ wrapper for high performance.

# Example
```julia
x = giac_eval("x")
result = sin(x^2)  # Works naturally with GiacExpr
```
"""
Base.sin(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_sin_tier1, :sin, expr)

"""
    Base.cos(expr::GiacExpr) -> GiacExpr

Compute the cosine of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.cos(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_cos_tier1, :cos, expr)

"""
    Base.tan(expr::GiacExpr) -> GiacExpr

Compute the tangent of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.tan(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_tan_tier1, :tan, expr)

"""
    Base.asin(expr::GiacExpr) -> GiacExpr

Compute the arc sine of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.asin(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_asin_tier1, :asin, expr)

"""
    Base.acos(expr::GiacExpr) -> GiacExpr

Compute the arc cosine of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.acos(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_acos_tier1, :acos, expr)

"""
    Base.atan(expr::GiacExpr) -> GiacExpr

Compute the arc tangent of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.atan(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_atan_tier1, :atan, expr)

"""
    Base.exp(expr::GiacExpr) -> GiacExpr

Compute the exponential of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.exp(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_exp_tier1, :exp, expr)

"""
    Base.log(expr::GiacExpr) -> GiacExpr

Compute the natural logarithm of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.log(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_ln_tier1, :ln, expr)

"""
    Base.sqrt(expr::GiacExpr) -> GiacExpr

Compute the square root of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.sqrt(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_sqrt_tier1, :sqrt, expr)

"""
    Base.abs(expr::GiacExpr) -> GiacExpr

Compute the absolute value of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.abs(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_abs_tier1, :abs, expr)

"""
    Base.sign(expr::GiacExpr) -> GiacExpr

Compute the sign of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.sign(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_sign_tier1, :sign, expr)

"""
    Base.floor(expr::GiacExpr) -> GiacExpr

Compute the floor of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.floor(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_floor_tier1, :floor, expr)

"""
    Base.ceil(expr::GiacExpr) -> GiacExpr

Compute the ceiling of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.ceil(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_ceil_tier1, :ceil, expr)

"""
    Base.real(expr::GiacExpr) -> GiacExpr

Extract the real part of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.real(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_re_tier1, :re, expr)

"""
    Base.imag(expr::GiacExpr) -> GiacExpr

Extract the imaginary part of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.imag(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_im_tier1, :im, expr)

"""
    Base.conj(expr::GiacExpr) -> GiacExpr

Compute the complex conjugate of a GiacExpr.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.conj(expr::GiacExpr)::GiacExpr = _tier1_or_fallback(_giac_conj_tier1, :conj, expr)

"""
    Base.gcd(a::GiacExpr, b::GiacExpr) -> GiacExpr

Compute the greatest common divisor of two GiacExprs.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.gcd(a::GiacExpr, b::GiacExpr)::GiacExpr = _tier1_or_fallback_binary(_giac_gcd_tier1, :gcd, a, b)

"""
    Base.lcm(a::GiacExpr, b::GiacExpr) -> GiacExpr

Compute the least common multiple of two GiacExprs.
Uses Tier 1 C++ wrapper for high performance.
"""
Base.lcm(a::GiacExpr, b::GiacExpr)::GiacExpr = _tier1_or_fallback_binary(_giac_lcm_tier1, :lcm, a, b)
