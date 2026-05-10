# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.14.1] - 2026-05-10

### Added

- **`CONTRIBUTORS.md`**: a top-level acknowledgements file listing the
  people who built, reviewed, and inspired this package — Giac authors
  (Bernard Parisse & Renée De Graeve), the original `Giac.jl`
  (Harald Hofstaetter), Julia ecosystem reviewers (Viral B. Shah,
  Mosè Giordano, Max Horn), code contributors (John Verzani),
  feature/bug-report contributors (Thibault Duretz), and methodology
  inspiration (Sam Abbott). Linked from the README.

### Fixed

- **`D` operator now accepts Unicode identifiers**: `D(ϕ)` on a function
  variable defined as `@giac_var 𝑧 ϕ(𝑧)` previously failed with
  `ArgumentError: D() requires a function expression like u(t)`. The
  internal parser regex (`_parse_function_expr`) only matched ASCII
  letters, even though GIAC C++ and Julia both accept Unicode names. The
  regex now uses Unicode letter/number classes (`\p{L}`, `\p{N}`), so
  Greek letters, mathematical italics, and other Unicode identifiers work
  with `D(u)`, `D(u, n)`, and chained forms. Reported by
  [@tduretz](https://github.com/tduretz).

- **`is_constant` now recognizes the GIAC `infinity` and `undef`
  atoms.** Previously, `is_constant(giac_eval("inf"))` returned `false`
  because `infinity` was treated as a free identifier. After this fix,
  any expression built from these atoms — including `inf`, `+inf`,
  `-inf`, `+infinity`, `-infinity`, `unsigned_inf`, `1/0` (which GIAC
  evaluates to `+infinity`), and `0/0` (which evaluates to `undef`) —
  is correctly classified as a constant. `Giac.Constants.is_giac_constant`
  picks up these atoms via a name-based fallback, since GIAC's internal
  `==` reports `infinity == infinity` as `false`. As a follow-on fix,
  `to_julia` no longer infinitely recurses on these irreducible atoms
  (`evalf` is a no-op on them); it returns the `GiacExpr` unchanged,
  matching the prior public behavior. Closes
  [#19](https://github.com/s-celles/Giac.jl/issues/19).

  Note: names like `nan`, `NaN`, `unsigned_infinity`, and `undefined`
  are *not* GIAC atoms — GIAC parses them as ordinary free identifiers
  (e.g. `nan + 1` yields `nan+1` exactly like `xyz + 1` yields `xyz+1`),
  so they remain non-constant.

## [0.14.0] - 2026-05-02

### Added

- **`build_function` Symbolics backend (Tier 3)**: a new `backend::Symbol`
  keyword on `build_function` selects the evaluation engine. The default
  `backend = :giac` is unchanged from v0.13. The new `backend = :symbolics`
  (requires `using Symbolics`) round-trips the expression through
  `to_symbolics` and compiles it via `Symbolics.build_function`, returning a
  native Julia callable that is autodiff-friendly (ForwardDiff, SciML
  solvers) and typically at least an order of magnitude faster in hot
  loops. Documented in
  [`docs/src/julia_functions.md`](docs/src/julia_functions.md), with a
  comparison table and a runtime benchmark.

  Error paths: `backend = :symbolics` without `using Symbolics`, free
  symbols not bound by `vars`, GIAC heads with no `to_symbolics`
  translation, and bad backend symbols all surface as actionable
  `ArgumentError`s at `build_function` time. Closes
  [#17](https://github.com/s-celles/Giac.jl/issues/17) Tier 3.

  Naming caveat: `Symbolics` also exports `build_function`; with both
  `using Giac` and `using Symbolics` in scope, qualify as
  `Giac.build_function(...)` (this is the standard Julia convention for
  name conflicts and is documented in the docstring and docs page).
  (067-build-function-tier3)

## [0.13.0] - 2026-05-02

### Added

- **`build_function`**: convert a `GiacExpr` into a native Julia callable
  with one named call. `f = build_function(expr, x, y)` returns a closure
  satisfying `f(a, b) == to_julia(substitute(expr, x => a, y => b))`, suitable
  as a drop-in argument to `Plots.plot`, `Plots.surface`, broadcasting
  (`f.(xs)`), and matrix comprehensions. The wrapper is intentionally thin —
  it composes the existing `substitute` + `to_julia` chain — and the
  underlying primitives remain available for cases that need a custom step
  in between. Documented in
  [`docs/src/julia_functions.md`](docs/src/julia_functions.md), with a
  comparison table to `Symbolics.build_function` and SymPy's `lambdify`, and
  showcased in the existing `examples/04_plotting.jl` Pluto notebook.
  Closes [#17](https://github.com/s-celles/Giac.jl/issues/17).
  (066-build-function)

## [0.12.0] - 2026-05-01

### Added

- **Varargs `substitute`**: `substitute(expr, x => 1, y => 2)` and the matching
  `GiacMatrix` form now accept any number of `Pair` arguments, aligned with
  `Symbolics.substitute`. Equivalent to the dict form `substitute(expr, Dict(pairs))`;
  all pairs are applied simultaneously. Calling with zero pairs returns the input
  unchanged. (065-substitute-tier1)
- **Call-syntax substitution**: a `GiacExpr` called with pair arguments now performs
  substitution. `expr(a => 15, b => 10, c => 5, d => 0)` is equivalent to
  `substitute(expr, a => 15, b => 10, c => 5, d => 0)` and inherits its simultaneous
  semantics. The existing function-evaluation call shape (`u(0)`, `f(x)`) is
  unchanged because the new method dispatches only on `Pair{<:GiacExpr}...`.
  Idea contributed by [@jverzani](https://github.com/jverzani) in
  [PR #11](https://github.com/s-celles/Giac.jl/pull/11). (065-substitute-tier1)
- **Julia `Function` arguments accepted by GIAC commands**: `_arg_to_giac_string`
  now serializes a `Function` value as `string(nameof(arg))`, so callers can pass
  a Julia function directly where the GIAC command expects a function name —
  e.g. `combine(log(x) + 2*log(x), log)` instead of `combine(..., "log")`. As a
  side effect, the same fallback also lets `substitute` accept a `Function`
  value (`substitute(f, f => log)` yields `log`). Contributed by
  [@jverzani](https://github.com/jverzani) in
  [PR #6](https://github.com/s-celles/Giac.jl/pull/6).
- **Additional math operations on `GiacExpr`** — degree-based and pi-multiple
  trig variants (`sind`, `cosd`, `sinpi`, `cospi`, `asind`, `acosd`, `atand`,
  `secd`, `cscd`, `cotd`), paired trig (`sincos`, `sincosd`, `sincospi` —
  return a 2-tuple of `GiacExpr`), angle conversion (`deg2rad`, `rad2deg`),
  exponential / logarithm extensions (`exp2`, `exp10`, `log1p`, two-argument
  `log(b, x)` for any base), `adjoint` (so postfix `'` works on `GiacExpr`),
  and `zero` / `one` (instance and `::Type{GiacExpr}` forms). Contributed by
  [@jverzani](https://github.com/jverzani) in
  [PR #9](https://github.com/s-celles/Giac.jl/pull/9).
- **`GiacMatrix` iteration and linear indexing**: `length(M)` returns
  `rows * cols`; `for e in M` and `collect(M)` walk the entries in
  column-major order (matching Julia's `Matrix` convention); `M[i]` and
  `M[CartesianIndex(i, j)]` provide linear and Cartesian indexing; and
  `LinearIndices(M)` / `CartesianIndices(M)` are available for converting
  between forms. Contributed by [@jverzani](https://github.com/jverzani) in
  [PR #10](https://github.com/s-celles/Giac.jl/pull/10).
- **Introspection helpers**: `is_constant`, `unwrap_const`, `free_symbols`,
  `hasmatch`, `iscall`, `operation`, `arguments`, `maketerm`,
  `Constants.is_giac_constant`, identity constructor `GiacExpr(::GiacExpr)`.
  These let callers query whether an expression is closed-form constant,
  enumerate its free symbols, and walk it as a syntax tree. Contributed by
  [@jverzani](https://github.com/jverzani) in
  [PR #8](https://github.com/s-celles/Giac.jl/pull/8). Resolves
  [issue #3](https://github.com/s-celles/Giac.jl/issues/3).
- **TermInterface.jl extension** (`GiacTermInterfaceExt`): when
  `TermInterface` is loaded, `GiacExpr` participates in the
  `iscall` / `operation` / `arguments` / `maketerm` / `isexpr` protocol
  used by Metatheory.jl, SymbolicUtils.jl, and other rewriters. Pure
  weak-dep — no cost to users who don't load `TermInterface`.
- **`Base.isfinite(::GiacExpr)`**: returns a Julia `Bool`. `isfinite(x)` is
  `true` for free identifiers, ordinary symbolic expressions, and finite
  numbers; `false` for `inf`, `-inf`, and `1/0` (which GIAC normalizes to
  infinity). Implemented as `!to_julia(isinf(expr))::Bool`.
- **CommonSolve.jl integration**: `Giac.Commands.solve` is now the same generic
  function as `CommonSolve.solve` (`Giac.Commands.solve === CommonSolve.solve`),
  so Giac's `solve` participates in the broader Julia "solve" verb ecosystem
  alongside `DifferentialEquations.jl`, `NLsolve.jl`, `Symbolics.jl`, etc.
  Dispatch is by argument type, so there is no conflict — `solve(::GiacExpr, …)`
  routes to GIAC, `solve(::ODEProblem, …)` routes to DifferentialEquations,
  and so on. `CommonSolve` is a tiny hard dependency (~50 LOC, compat `0.2`).
  Note that `CommonSolve` also exports `init` and `solve!` as part of an
  iterative-solver protocol; Giac is a symbolic CAS (non-iterative) so only
  `solve` is extended — `init` and `solve!` are left untouched and remain
  available for other packages to extend without conflict.
  Contributed by [@jverzani](https://github.com/jverzani) in
  [PR #7](https://github.com/s-celles/Giac.jl/pull/7).

### Changed

- **`to_julia(::GiacExpr)` now reduces free-variable-free expressions to
  numbers via `evalf`.** Previously, `to_julia(substitute(sin(x), x => 2))`
  returned `GiacExpr: sin(2)` — the symbolic form was preserved even though
  the caller asked for a Julia value. Now it returns `0.9092…` (a `Float64`).
  The layered design holds: `evalf(expr)` keeps you in Giac and returns a
  `GiacExpr` whose internal type is `DOUBLE`; `to_julia(expr)` bridges to a
  Julia number. Symbolic expressions with at least one free variable still
  pass through unchanged. **This is a behavior change for users who relied
  on `to_julia` of constant symbolic expressions returning a `GiacExpr`** —
  use `evalf(expr)` instead if you want a numeric `GiacExpr`. Resolves
  [issue #3](https://github.com/s-celles/Giac.jl/issues/3).

- **`^(::GiacExpr, ::Number)` and `^(::Number, ::GiacExpr)` widened**: powers
  on `GiacExpr` previously accepted only an `Integer` exponent; now any
  `Number` is accepted on either side via `promote`. Existing
  `^(::GiacExpr, ::Integer)` calls continue to work unchanged. Contributed by
  [@jverzani](https://github.com/jverzani) in
  [PR #9](https://github.com/s-celles/Giac.jl/pull/9).
- **`substitute(expr, dict)` no longer round-trips through the GIAC parser.** The
  dict-form `substitute` for both `GiacExpr` and `GiacMatrix` now calls the direct
  CxxWrap binding `giac_subst` with structured `Gen` vector arguments built via
  `make_vect`. Simultaneous-substitution semantics (e.g. `Dict(x => y, y => x)`
  swaps `x` and `y`) and the public API are unchanged. On a representative
  non-trivial expression with two pairs, this is roughly 1.5–2× faster than the
  prior string-round-trip implementation (machine-dependent), and floating-point
  replacement values are preserved exactly. (065-substitute-tier1)
- **`substitute(expr, pair)` single-pair method replaced** by the new varargs
  method. `substitute(expr, x => 1)` continues to work without change; the dispatch
  path simply delegates to the new varargs definition. (065-substitute-tier1)

### Fixed

- **`asind` / `acosd` / `atand`**: implementation was `asin(deg2rad(x))` etc.,
  which converted the input from degrees to radians instead of converting the
  angle output from radians to degrees (e.g. `asind(1)` returned
  `asin(π/180)` instead of `90`). Corrected to `rad2deg(asin(x))` (matches
  Julia Base). Note: GIAC keeps the result as `pi/2 * 180/pi`; calling
  `simplify` reduces it to the integer.
- **`sincos` / `sincosd` / `sincospi`**: return-type annotation was
  `::GiacExpr` but the body returned a 2-tuple, triggering a `MethodError`
  on every call. Annotation changed to `::Tuple{GiacExpr, GiacExpr}`.

### Removed

- Internal helper `_build_subst_command` (no longer needed; the substitution path
  no longer constructs subst-command strings). Not part of the public API.

## [0.11.2] - 2026-04-16

### Added

- **Symbolic comparison and logical operators on `GiacExpr`**: `<`, `>`, `<=`, `>=`,
  `&`, `|` are now defined for `GiacExpr`, allowing symbolic conditions to be
  expressed directly (e.g. `x < y`, `(x > 0) & (y < 1)`). (#4)

## [0.11.1] - 2026-04-11

### Fixed

- **`to_giac` with Symbolics v7 literal numbers**: handles symbolic literal numbers
  produced by Symbolics v7, fixing a `TypeError` when squaring or otherwise
  manipulating expressions converted from Symbolics. (#2, closes #1)

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
