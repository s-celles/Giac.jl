# Namespace command access for Giac.jl
# Enables direct access to common GIAC commands via exported functions
# Feature: 007-giac-namespace-commands

# ============================================================================
# GiacCommand Type (Foundational)
# ============================================================================

"""
    GiacCommand

A callable wrapper for GIAC commands.

This type stores a command name and can be called with arguments to execute
the underlying GIAC command. It provides a structured way to represent
commands that can be passed around and invoked.

# Fields
- `name::Symbol`: The GIAC command name (e.g., `:factor`, `:diff`)

# Example
```julia
# Create a command and call it
factor_cmd = GiacCommand(:factor)
expr = giac_eval("x^2 - 1")
result = factor_cmd(expr)  # Returns (x-1)*(x+1)

# Equivalent to:
result = giac_cmd(:factor, expr)
```

# See also
- [`giac_cmd`](@ref): Direct command invocation
"""
struct GiacCommand
    name::Symbol
end

"""
    (cmd::GiacCommand)(args...)::GiacExpr

Execute a GiacCommand with the given arguments.

Delegates to `giac_cmd` for actual execution, providing the same functionality
with a callable object interface.

# Arguments
- `args...`: Variable arguments passed to the underlying GIAC command
  (GiacExpr, String, Number, Symbol, or Vector)

# Returns
- `GiacExpr`: Result of command execution

# Throws
- `GiacError(:eval)`: If command execution fails
- `ArgumentError`: If arguments cannot be converted to GIAC format

# Example
```julia
expr = giac_eval("x^2 - 1")
x = giac_eval("x")

# Using GiacCommand callable
factor_cmd = GiacCommand(:factor)
result = factor_cmd(expr)  # Returns (x-1)*(x+1)

diff_cmd = GiacCommand(:diff)
deriv = diff_cmd(expr, x)  # Returns 2*x
```
"""
function (cmd::GiacCommand)(args...)::GiacExpr
    giac_cmd(cmd.name, args...)
end

# ============================================================================
# Exported Commands (US2)
# ============================================================================

"""
Curated list of commonly used GIAC commands to export for direct access.

These commands are exported so users can call them without the `Giac.` prefix
after `using Giac`. The list is intentionally limited to avoid namespace pollution.

Note: Some commands like `eval` and `float` are not included because they
conflict with Julia built-in functions. Use `giac_cmd(:eval, ...)` for those.

Categories:
- Algebra: factor, expand, simplify, normal, collect
- Calculus: diff, integrate, limit, series, taylor, sum, product
- Solving: solve, fsolve, dsolve, linsolve, nsolve
- Polynomial: degree, coeff, lcoeff, quo, rem, gcd, lcm, roots
- Trigonometry: trigexpand, trigreduce, trigtan, trigcos, trigsin
- Complex: re, im, conj, arg
- Matrix: det, rank, kernel, eigenvals, eigenvects, trace
- Utilities: subst, evalf, exact, assume, about
"""
const EXPORTED_COMMANDS = Symbol[
    # Algebra (5)
    :factor, :expand, :simplify, :normal, :collect,
    # Calculus (7)
    :diff, :integrate, :limit, :series, :taylor, :sum, :product,
    # Solving (5)
    :solve, :fsolve, :dsolve, :linsolve, :nsolve,
    # Polynomial (9)
    :degree, :coeff, :lcoeff, :quo, :rem, :gcd, :lcm, :roots, :resultant,
    # Trigonometry (5)
    :trigexpand, :trigreduce, :trigtan, :trigcos, :trigsin,
    # Complex (4)
    :re, :im, :conj, :arg,
    # Matrix (6)
    :det, :rank, :kernel, :eigenvals, :eigenvects, :trace,
    # Utilities (5) - excluding :eval and :float which conflict with Julia builtins
    :subst, :evalf, :exact, :assume, :about,
    # Additional commonly used (12)
    :partfrac, :apart, :together, :rationalize, :numer, :denom,
    :proot, :froot, :cfactor, :ifactor, :iquo, :irem,
]

# Generate exported functions for all commands in EXPORTED_COMMANDS
# Each function is a thin wrapper that calls giac_cmd
for cmd in EXPORTED_COMMANDS
    @eval begin
        """
            $($cmd)(args...)::GiacExpr

        Call the GIAC `$($cmd)` command with the given arguments.

        This is a convenience function exported for direct use. Equivalent to:
        - `giac_cmd(:$($cmd), args...)`

        See GIAC documentation for detailed usage of this command.
        """
        function $(cmd)(args...)::GiacExpr
            giac_cmd($(QuoteNode(cmd)), args...)
        end
    end
end

# ============================================================================
# Tab Completion Support (US3) - Programmatic Discovery
# ============================================================================

"""
    available_commands()

Return a sorted vector of all available GIAC command names that can be called.

This function provides programmatic discovery of available commands.
For commands not in EXPORTED_COMMANDS, use `giac_cmd(:commandname, args...)`.

# Example
```julia
# List all available commands
cmds = available_commands()
println("Found \$(length(cmds)) commands")

# Check if a command exists
"factor" in cmds  # true

# Use non-exported commands via giac_cmd
giac_cmd(:somecommand, args...)
```

# See also
- [`EXPORTED_COMMANDS`](@ref): Curated list of exported commands
- [`giac_cmd`](@ref): Direct command invocation for any command
"""
function available_commands()::Vector{String}
    if !isempty(VALID_COMMANDS)
        return sort(collect(cmd for cmd in VALID_COMMANDS if !isempty(cmd) && isletter(first(cmd))))
    end
    return String[]
end
