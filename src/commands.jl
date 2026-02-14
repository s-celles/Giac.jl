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
# Levenshtein Distance for "Did you mean?" suggestions
# ============================================================================

"""
    _levenshtein_distance(s1::String, s2::String)

Calculate the Levenshtein edit distance between two strings.
Used for "did you mean?" suggestions when a command is not found.
"""
function _levenshtein_distance(s1::String, s2::String)::Int
    m, n = length(s1), length(s2)

    # Create distance matrix
    d = zeros(Int, m + 1, n + 1)

    for i in 0:m
        d[i + 1, 1] = i
    end
    for j in 0:n
        d[1, j + 1] = j
    end

    for j in 1:n
        for i in 1:m
            cost = s1[i] == s2[j] ? 0 : 1
            d[i + 1, j + 1] = min(
                d[i, j + 1] + 1,      # deletion
                d[i + 1, j] + 1,      # insertion
                d[i, j] + cost        # substitution
            )
        end
    end

    return d[m + 1, n + 1]
end

"""
    _find_similar_commands(cmd::String, valid_commands::Set{String}; max_distance::Int=3, max_results::Int=3)

Find commands similar to `cmd` using Levenshtein distance.
Returns up to `max_results` suggestions within `max_distance` edits.
"""
function _find_similar_commands(cmd::String, valid_commands::Set{String}; max_distance::Int=3, max_results::Int=3)::Vector{String}
    suggestions = Tuple{String, Int}[]

    for valid_cmd in valid_commands
        dist = _levenshtein_distance(cmd, valid_cmd)
        if dist <= max_distance
            push!(suggestions, (valid_cmd, dist))
        end
    end

    # Sort by distance (closest first)
    sort!(suggestions, by=x -> x[2])

    # Return just the command names
    return [s[1] for s in suggestions[1:min(max_results, length(suggestions))]]
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
        suggestions = _find_similar_commands(cmd_str, VALID_COMMANDS)
        suggestion_text = isempty(suggestions) ? "" : " Did you mean: $(join(suggestions, ", "))?"
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
