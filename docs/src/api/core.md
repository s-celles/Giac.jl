# Core API

The main Giac module provides core types and functions for symbolic computation.

```@docs
Giac
```

## Types

```@docs
GiacExpr
GiacContext
GiacMatrix
GiacError
HelpResult
GiacCommand
GiacInput
```

## Expression Evaluation

```@docs
giac_eval
to_julia
```

## Symbolic Variables

```@docs
@giac_var
@giac_several_vars
```

## Calculus Operations

Calculus functions are available via `Giac.Commands` or `invoke_cmd`:

```julia
using Giac
using Giac.Commands: diff, integrate, limit, series

# Or use invoke_cmd
invoke_cmd(:diff, expr, x)
invoke_cmd(:integrate, expr, x)
invoke_cmd(:limit, expr, x, point)
invoke_cmd(:series, expr, x, point, order)
```

## Algebraic Operations

Algebra functions are available via `Giac.Commands` or `invoke_cmd`:

```julia
using Giac
using Giac.Commands: factor, expand, simplify, solve, gcd

# Or use invoke_cmd
invoke_cmd(:factor, expr)
invoke_cmd(:expand, expr)
invoke_cmd(:simplify, expr)
invoke_cmd(:solve, expr, x)
invoke_cmd(:gcd, a, b)
```

## Command Discovery

```@docs
list_commands
help_count
search_commands
commands_in_category
command_info
list_categories
help
giac_help
```

## Command Suggestions

```@docs
suggest_commands
set_suggestion_count
get_suggestion_count
search_commands_by_description
```

## Namespace Management

```@docs
JULIA_CONFLICTS
exportable_commands
is_valid_command
conflict_reason
available_commands
reset_conflict_warnings!
```

## Conversion Functions

```@docs
to_giac
to_symbolics
```

## Utility Functions

```@docs
is_stub_mode
```

### Core Functions

| Function | Description |
|----------|-------------|
| `giac_eval(expr)` | Evaluate a GIAC expression string |
| `invoke_cmd(cmd, args...)` | Invoke any GIAC command dynamically |
| `is_stub_mode()` | Check if running without GIAC library |
| `to_julia(expr)` | Convert GiacExpr to Julia type |
