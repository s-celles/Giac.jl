# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - Unreleased

### Added

- **Multiple dispatch for JULIA_CONFLICTS commands**: GIAC commands that conflict with Julia
  (like `zeros`, `min`, `max`, `det`, `inv`) now work with `GiacExpr` arguments via multiple dispatch.
  Julia's type-based dispatch routes calls correctly:
  - `zeros(giac_expr)` → finds polynomial roots via GIAC
  - `zeros(3, 3)` → creates Julia Matrix of zeros (unchanged)

  This enables natural Julia syntax for ~150+ additional GIAC commands without breaking
  existing Base/LinearAlgebra functionality.

- Helper functions `_extendable_conflicts()` and `_has_giac_method()` in `Giac.Commands`
  for conflict resolution logic

- **Equation syntax with `~` operator**: Create symbolic equations using the tilde operator,
  following Julia's Symbolics.jl convention:
  ```julia
  @giac_var x
  eq = x^2 - 1 ~ 0    # Creates equation: x^2-1=0
  solve(eq, x)        # Solves for roots: [-1, 1]
  ```

  This provides a natural syntax alternative to `giac_eval("x^2-1=0")`. The `~` operator
  works with mixed types (`GiacExpr ~ Number` and `Number ~ GiacExpr`).

### Changed

- **Suppressed misleading conflict warnings**: The "GIAC command 'X' conflicts with Julia"
  warning is now suppressed for non-keyword conflicts since they work correctly via
  multiple dispatch. Only true keyword conflicts (`:if`, `:for`, etc.) trigger warnings.

## [0.3.0] - 2026-02-16

### Removed

- **BREAKING**: Removed `giac_` prefixed functions in favor of `Giac.Commands` equivalents:
  - `giac_diff` → Use `Giac.Commands.diff` or `invoke_cmd(:diff, ...)`
  - `giac_expand` → Use `Giac.Commands.expand` or `invoke_cmd(:expand, ...)`
  - `giac_factor` → Use `Giac.Commands.factor` or `invoke_cmd(:factor, ...)`
  - `giac_gcd` → Use `Giac.Commands.gcd` or `invoke_cmd(:gcd, ...)`
  - `giac_integrate` → Use `Giac.Commands.integrate` or `invoke_cmd(:integrate, ...)`
  - `giac_limit` → Use `Giac.Commands.limit` or `invoke_cmd(:limit, ...)`
  - `giac_series` → Use `Giac.Commands.series` or `invoke_cmd(:series, ...)`
  - `giac_simplify` → Use `Giac.Commands.simplify` or `invoke_cmd(:simplify, ...)`
  - `giac_solve` → Use `Giac.Commands.solve` or `invoke_cmd(:solve, ...)`

  **Migration**: Replace `giac_factor(expr)` with either:
  ```julia
  # Option 1: Import from Giac.Commands
  using Giac.Commands: factor
  factor(expr)

  # Option 2: Use invoke_cmd (always available)
  invoke_cmd(:factor, expr)
  ```

  **Retained**: `giac_eval` and `help` remain available as core functions.

### Changed

- `Giac.TempApi` now delegates to `invoke_cmd` instead of removed `giac_*` functions

## [0.2.0] - 2026-02-16

### Changed

- **BREAKING**: Renamed `@giac_several_var` to `@giac_several_vars` (plural form)
  - The macro creates multiple variables, so the name should use plural "vars"
  - **Migration**: Find and replace `@giac_several_var` with `@giac_several_vars` in your code
  - Example: `@giac_several_var a 3` becomes `@giac_several_vars a 3`

## [0.1.0] - Initial Release

### Added

- Core symbolic expression type `GiacExpr`
- Expression evaluation with `giac_eval`
- Calculus operations: `giac_diff`, `giac_integrate`, `giac_limit`, `giac_series`
- Algebraic operations: `giac_factor`, `giac_expand`, `giac_simplify`, `giac_solve`, `giac_gcd`
- Symbolic variable macros: `@giac_var`, `@giac_several_vars`
- Matrix type `GiacMatrix` with `det`, `inv`, `tr`, `transpose`
- Command discovery: `list_commands`, `search_commands`, `suggest_commands`
- Commands submodule with ~2000 GIAC commands
- Performance tier system (Tier 1/2/3)
- Thread-safe evaluation with `GiacContext`
