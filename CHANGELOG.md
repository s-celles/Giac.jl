# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.1] - 2026-04-11

### Fixed

- **to_giac power expressions** ([#1](https://github.com/s-celles/Giac.jl/issues/1)):
  Fixed `TypeError` when converting power expressions like `a^2` from Symbolics.jl v7
  to Giac. Integer constants in expression trees are now `BasicSymbolic` literal numbers
  in Symbolics v7; added `is_literal_number`/`unwrap_const` handling to extract the
  underlying values.

## [0.11.0] - 2026-04-06

### Added

- **JLL-based library loading**: `GIAC_jll` and `libgiac_julia_jll` are now direct
  dependencies, providing the GIAC library and C++ wrapper automatically. No manual
  compilation or environment variables needed.
- **Windows support**: Fixed POSIX `dup`/`dup2` calls in `search_commands_by_description`
  to use Windows-compatible `_dup`/`_dup2`.
- **Symbolics 7 compatibility**: `to_symbolics` now returns consistent `Num` type using
  `Symbolics.wrap()` and pairwise `Symbolics.term()` for multiplication, preserving
  symbolic forms like `sqrt(2)`.

### Removed

- **BREAKING**: Removed `is_stub_mode()` from public API. Stub mode no longer exists —
  the library is always available via JLL packages.
- **BREAKING**: Removed `TempApi` submodule. Use `Giac.Commands` instead for the same
  functions (`diff`, `integrate`, `factor`, etc.).
- Removed all stub mode infrastructure (`_stub_mode` flag, stub expressions, conditional
  branches in ~30 functions).

### Changed

- **BREAKING**: Minimum Julia version raised from 1.10 to 1.11.
- Library initialization now throws `GiacError` instead of silently falling back to
  stub mode when the wrapper library is not found.

## [0.10.0] - 2026-04-05

### Added

- **HeldCmd LaTeX rendering**: Specialized LaTeX renderers for `limit`, `sum`, `product`,
  and `sum_riemann` held commands.
- **HeldEquation tilde operator**: `~` operator support for `HeldCmd` with LaTeX rendering.
- **GiacMatrix command support**: GIAC commands now work with `GiacMatrix` arguments.
- `Base.numerator` and `Base.denominator` methods for `GiacExpr`.

## [0.9.0] - 2026-03-20

### Added

- **Symbolic Constants module (`Giac.Constants`)**: Submodule providing symbolic
  mathematical constants `pi`, `e`, and `i` as `GiacExpr` values:
  ```julia
  using Giac.Constants: pi, e, i
  expr = 2 * pi * x  # stays symbolic
  ```

- **MathJSON.jl extension**: Bidirectional conversion between `GiacExpr` and MathJSON
  expression trees via `to_mathjson` and `to_giac`.

- **Direct pointer conversion**: `to_symbolics` and `to_giac` use direct Gen pointer
  transfer instead of string serialization for better performance.

- **Direct GMP binary transfer**: `BigInt` conversion uses direct memory transfer from
  GIAC's GMP integers, avoiding string parsing.

### Changed

- `GiacSymbolicsExt` uses `GenTypes` enum instead of magic numbers.
- Factorized expressions preserved in `to_symbolics` conversion.

## [0.8.0] - 2026-03-15

### Added

- **GenTypes module**: `T` enum for GIAC expression types with C++ alignment.
- **Pluto example notebooks**: Basics and advanced usage notebooks with screenshots.

### Changed

- Tier 2 N-ary dispatch for functions with >3 parameters.

## [0.7.0] - 2026-03-10

### Added

- **UnitRange indexing**: `GiacMatrix` and `@giac_several_vars` support `UnitRange` indices.
- **Z-transform functions**: `ztrans` and `invztrans` with documentation.
- **Laplace transform functions**: `laplace` and `ilaplace` with documentation.
- **D operator**: Derivative operator for ODE initial conditions.
- **Callable GiacExpr**: `f(x)` syntax for function evaluation.
- **Extended `@giac_var` macro**: Function syntax support.

## [0.6.0] - 2026-03-05

### Added

- **Domain documentation**: Mathematics (algebra, calculus, linear algebra, ODEs,
  trigonometry) and physics (mechanics, electromagnetism) with test-verified examples.
- **Vector input support**: GIAC commands accept Julia vectors as arguments.
- **Boolean conversion**: `to_julia` handles GIAC boolean results.

### Fixed

- `to_julia` for `solve` results using CxxWrap bindings.
- Correct `GIAC_STRNG` type constant.

## [0.5.0] - 2026-02-25

### Added

- **Tables.jl compatibility**: `GiacMatrix` and command help implement Tables.jl interface.
- **Julia help system integration**: `?command` works in the REPL.
- **Variable substitution**: `substitute` function with Symbolics.jl-compatible interface.
- **Output handling**: Improved type conversion and introspection.

### Removed

- Public `help()` function (replaced by Julia help system integration).

## [0.4.0] - 2026-02-20

### Added

- **Multiple dispatch for JULIA_CONFLICTS commands**: GIAC commands that conflict with
  Julia (like `zeros`, `min`, `max`, `det`, `inv`) now work with `GiacExpr` arguments
  via multiple dispatch.

- **Equation syntax with `~` operator**: Create symbolic equations using the tilde operator:
  ```julia
  @giac_var x
  eq = x^2 - 1 ~ 0
  solve(eq, x)
  ```

### Changed

- Suppressed misleading conflict warnings for non-keyword conflicts.

## [0.3.0] - 2026-02-16

### Removed

- **BREAKING**: Removed `giac_` prefixed functions in favor of `Giac.Commands` equivalents.

### Changed

- `Giac.TempApi` delegated to `invoke_cmd` instead of removed `giac_*` functions.

## [0.2.0] - 2026-02-16

### Changed

- **BREAKING**: Renamed `@giac_several_var` to `@giac_several_vars` (plural form).

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
