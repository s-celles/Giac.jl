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
# Base Function Extensions
# ============================================================================

"""
    Base.sin(expr::GiacExpr) -> GiacExpr

Compute the sine of a GiacExpr. Enables natural Julia syntax for symbolic math.

# Example
```julia
x = giac_eval("x")
result = sin(x^2)  # Works naturally with GiacExpr
```
"""
Base.sin(expr::GiacExpr)::GiacExpr = giac_cmd(:sin, expr)

"""
    Base.cos(expr::GiacExpr) -> GiacExpr

Compute the cosine of a GiacExpr.
"""
Base.cos(expr::GiacExpr)::GiacExpr = giac_cmd(:cos, expr)

"""
    Base.tan(expr::GiacExpr) -> GiacExpr

Compute the tangent of a GiacExpr.
"""
Base.tan(expr::GiacExpr)::GiacExpr = giac_cmd(:tan, expr)

"""
    Base.exp(expr::GiacExpr) -> GiacExpr

Compute the exponential of a GiacExpr.
"""
Base.exp(expr::GiacExpr)::GiacExpr = giac_cmd(:exp, expr)

"""
    Base.log(expr::GiacExpr) -> GiacExpr

Compute the natural logarithm of a GiacExpr.
"""
Base.log(expr::GiacExpr)::GiacExpr = giac_cmd(:ln, expr)

"""
    Base.sqrt(expr::GiacExpr) -> GiacExpr

Compute the square root of a GiacExpr.
"""
Base.sqrt(expr::GiacExpr)::GiacExpr = giac_cmd(:sqrt, expr)

"""
    Base.abs(expr::GiacExpr) -> GiacExpr

Compute the absolute value of a GiacExpr.
"""
Base.abs(expr::GiacExpr)::GiacExpr = giac_cmd(:abs, expr)
