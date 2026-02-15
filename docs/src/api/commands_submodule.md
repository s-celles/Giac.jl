# Commands Submodule

```@docs
Giac.Commands
```

The `Giac.Commands` submodule provides access to all exportable GIAC commands as Julia functions.

## Usage

### Selective Import (Recommended)

```julia
using Giac
using Giac.Commands: factor, expand, diff

expr = giac_eval("x^2 - 1")
factor(expr)  # (x-1)*(x+1)
```

### Full Import

```julia
using Giac
using Giac.Commands

# All ~2000+ commands available
factor(giac_eval("x^2-1"))
ifactor(giac_eval("120"))
```

### Qualified Access

```julia
using Giac

Giac.Commands.factor(giac_eval("x^2-1"))
```

## Core Function

```@docs
Giac.Commands.invoke_cmd
```

## Conflicting Commands

Commands that conflict with Julia keywords, builtins, or standard library functions
are NOT exported from this module. Use `invoke_cmd` to call them:

```julia
# These conflict with Julia and are NOT exported:
# eval, sin, cos, det, inv, sum, prod, etc.

# Use invoke_cmd instead:
invoke_cmd(:eval, expr)
invoke_cmd(:sin, giac_eval("pi/6"))
invoke_cmd(:det, matrix)
```

See [`JULIA_CONFLICTS`](@ref) for the complete list of conflicting commands.

## Available Commands

Use [`exportable_commands()`](@ref) to get a list of all commands available in this module:

```julia
cmds = exportable_commands()
length(cmds)  # ~2000+
```
