"""
    Giac.Commands

A submodule containing all exportable GIAC commands as functions.

This module provides access to ~2000+ GIAC commands while keeping the main
`Giac` namespace clean. Commands can be accessed through three patterns:

# Access Patterns

1. **Qualified access** (cleanest namespace):
   ```julia
   using Giac
   Giac.Commands.factor(expr)
   Giac.Commands.diff(expr, x)
   ```

2. **Selective import** (recommended for most use cases):
   ```julia
   using Giac
   using Giac.Commands: factor, expand, diff
   factor(expr)  # Works directly
   ```

3. **Full import** (for interactive exploration):
   ```julia
   using Giac
   using Giac.Commands
   factor(expr)   # All ~2000+ commands available
   ifactor(expr)  # Works directly
   ```

# Conflicting Commands

Commands that conflict with Julia keywords, builtins, or standard library
functions (like `eval`, `sin`, `det`) are NOT exported from this module.
Use `invoke_cmd` to call them:

```julia
using Giac
invoke_cmd(:eval, expr)  # Works for any command
invoke_cmd(:sin, x)      # Including conflicting ones
```

# Exports

- `invoke_cmd`: Universal command invocation function
- All ~2000+ non-conflicting GIAC commands (runtime-generated)

# See also

- [`invoke_cmd`](@ref): Call any GIAC command by name
- [`Giac.JULIA_CONFLICTS`](@ref): Commands that conflict with Julia
- [`Giac.exportable_commands`](@ref): List of exportable commands
"""
module Commands

using ..Giac: GiacExpr, GiacError, giac_eval, with_giac_lock,
              VALID_COMMANDS, JULIA_CONFLICTS, exportable_commands,
              suggest_commands, _format_suggestions, _warn_conflict,
              _arg_to_giac_string, _build_command_string

# ============================================================================
# Core Command Invocation (invoke_cmd)
# ============================================================================

"""
    invoke_cmd(cmd::Symbol, args...) -> GiacExpr

Invoke any GIAC command by name and return the result as a GiacExpr.

This is the core function for dynamic command invocation, enabling access to
all 2200+ GIAC commands through a uniform interface. It works for all commands,
including those that conflict with Julia builtins.

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
using Giac

# Single argument
expr = giac_eval("x^2 - 1")
result = invoke_cmd(:factor, expr)  # Returns (x-1)*(x+1)

# Multiple arguments
x = giac_eval("x")
derivative = invoke_cmd(:diff, expr, x)  # Returns 2*x

# Trigonometric functions (conflicts with Base)
result = invoke_cmd(:sin, giac_eval("pi/6"))  # Returns 1/2

# Evaluation (conflicts with Base.eval)
result = invoke_cmd(:eval, giac_eval("2+3"))  # Returns 5
```

# See also
- [`giac_eval`](@ref): Direct string evaluation
- [`Giac.search_commands`](@ref): Find available commands
- [`Giac.help`](@ref): Get help for a command
"""
function invoke_cmd(cmd::Symbol, args...)::GiacExpr
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

# String variant for convenience
invoke_cmd(cmd::String, args...)::GiacExpr = invoke_cmd(Symbol(cmd), args...)

# Export invoke_cmd
export invoke_cmd

# ============================================================================
# Runtime Function Generation
# ============================================================================

"""
    _generate_command_functions()

Generate wrapper functions at runtime for all exportable GIAC commands.

This function is called during module initialization to create Julia functions
for each command in `exportable_commands()`. The functions are exported from
`Giac.Commands` for use with `using Giac.Commands` or selective imports.

# Implementation Notes

- Uses `@eval` to define functions at runtime
- Each generated function calls `invoke_cmd` internally
- Only generates functions for commands not in `JULIA_CONFLICTS`
- Exports all generated functions

# Performance

- Called once during module load
- Generates ~2000 functions in typically < 1 second
- No impact on command execution performance
"""
function _generate_command_functions()
    for cmd_str in exportable_commands()
        cmd = Symbol(cmd_str)

        # Skip if already defined (shouldn't happen, but safety check)
        if isdefined(@__MODULE__, cmd)
            continue
        end

        # Generate the wrapper function
        @eval begin
            function $(cmd)(args...)::GiacExpr
                invoke_cmd($(QuoteNode(cmd)), args...)
            end
            export $(cmd)
        end
    end

    @debug "Generated and exported command functions in Giac.Commands"
end

# ============================================================================
# Module Initialization
# ============================================================================

function __init__()
    # Generate command functions at runtime
    # This is called after Giac.__init__() has populated VALID_COMMANDS
    _generate_command_functions()
end

end # module Commands
