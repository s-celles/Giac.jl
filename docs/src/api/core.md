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
```

## Expression Evaluation

```@docs
giac_eval
to_julia
```

## Symbolic Variables

```@docs
@giac_var
@giac_several_var
```

## Calculus Operations

```@docs
giac_diff
giac_integrate
giac_limit
giac_series
```

## Algebraic Operations

```@docs
giac_factor
giac_expand
giac_simplify
giac_solve
giac_gcd
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
