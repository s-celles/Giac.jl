# Namespace command access for Giac.jl
# Enables direct access to common GIAC commands via exported functions
# Feature: 007-giac-namespace-commands
# Enhanced: 008-all-giac-commands (runtime generation of all exportable commands)

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
- [`invoke_cmd`](@ref): Direct command invocation
"""
struct GiacCommand
    name::Symbol
end

"""
    (cmd::GiacCommand)(args...)::GiacExpr

Execute a GiacCommand with the given arguments.

Delegates to the internal `giac_cmd` for actual execution, providing the same
functionality with a callable object interface.

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

# See also
- [`invoke_cmd`](@ref): Direct command invocation (preferred)
"""
function (cmd::GiacCommand)(args...)::GiacExpr
    giac_cmd(cmd.name, args...)
end

# ============================================================================
# Note: Command Exports Moved to Giac.Commands (009-commands-submodule)
# ============================================================================
#
# The EXPORTED_COMMANDS constant and compile-time function generation have been
# removed. All GIAC commands are now exported from the Giac.Commands submodule.
#
# To use commands:
# 1. invoke_cmd(:name, args...) - always available from main Giac module
# 2. using Giac.Commands: factor, expand - selective import
# 3. using Giac.Commands - import all ~2000+ commands
#
# See Giac.Commands for the new implementation.
# ============================================================================

# ============================================================================
# Tab Completion Support (US3) - Programmatic Discovery
# ============================================================================

"""
    available_commands()

Return a sorted vector of all available GIAC command names that start with
an ASCII letter (a-z, A-Z).

This function provides programmatic discovery of available commands. It filters
out operators, keywords, and commands starting with non-ASCII characters.

# Returns
- `Vector{String}`: Sorted list of command names starting with ASCII letters

# Example
```julia
# List all available commands
cmds = available_commands()
println("Found \$(length(cmds)) commands")  # ~2100+

# Check if a command exists
"factor" in cmds  # true
"+" in cmds       # false (operator)

# Compare with exportable commands
exportable = exportable_commands()
length(exportable)  # ~2000+ (excludes Julia conflicts)
```

# Accessing Commands

1. **invoke_cmd** (all commands): Universal access, always available
   ```julia
   invoke_cmd(:eval, expr)  # Works for conflicting commands too
   invoke_cmd(:factor, expr)
   ```

2. **Selective import**: Import specific commands from Giac.Commands
   ```julia
   using Giac.Commands: factor, expand
   factor(expr)  # Works directly
   ```

3. **Full import**: Import all ~2000+ commands
   ```julia
   using Giac.Commands
   factor(expr)   # Works directly
   ifactor(expr)  # All commands available
   ```

# See also
- [`exportable_commands`](@ref): Commands safe to export (no Julia conflicts)
- [`invoke_cmd`](@ref): Universal command invocation
- [`Giac.Commands`](@ref): Submodule with all exportable commands
"""
function available_commands()::Vector{Symbol}
    if !isempty(VALID_COMMANDS)
        return sort!(collect(cmd for cmd in VALID_COMMANDS if begin
            cmd_str = string(cmd)
            !isempty(cmd_str) && isletter(first(cmd_str)) && isascii(first(cmd_str))
        end), by=string)
    end
    return Symbol[]
end

# ============================================================================
# Note: Runtime Function Generation Moved to Giac.Commands (009-commands-submodule)
# ============================================================================
#
# The _generate_exported_functions() has been removed from this file.
# Command generation is now handled by Commands._generate_command_functions()
# which is called during Commands.__init__().
#
# See src/Commands.jl for the new implementation.
# ============================================================================
