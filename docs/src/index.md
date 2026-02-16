# Giac.jl

A Julia wrapper for the [GIAC](https://www-fourier.ujf-grenoble.fr/~parisse/giac.html) computer algebra system.

## Features

- **Dynamic Command Invocation**: Access all 2200+ GIAC commands via `invoke_cmd(:cmd, args...)`
- **Expression Evaluation**: Parse and evaluate mathematical expressions
- **Arithmetic Operations**: +, -, *, /, ^, unary negation, equality
- **Calculus**: Differentiation, integration, limits, and series expansion
- **Algebra**: Factorization, expansion, simplification, equation solving and GCD
- **Linear Algebra**: Symbolic matrices with determinant, inverse, trace, transpose operations
- **Command Discovery**: Search commands, browse by category, built-in help via `?cmd`
- **Commands Submodule**: All ~2000+ commands available via `Giac.Commands` for clean namespace
- **TempApi Submodule**: Simplified function names (`diff`, `factor`, etc.) via `Giac.TempApi`
- **Method Syntax**: Call commands as methods: `expr.factor()`, `expr.diff(x)`
- **Base Extensions**: Use `sin(expr)`, `cos(expr)`, `exp(expr)` with GiacExpr
- **Type Conversion**: Convert results to Julia native types (Int64, Float64, Rational)
- **LaTeX Support**: Automatic LaTeX rendering in Pluto notebooks
- **Symbolics.jl Integration**: Bidirectional conversion with Symbolics.jl
- **Tables.jl Compatibility**: Convert GiacMatrix and command help to DataFrames, CSV export

## Installation

```julia
using Pkg
Pkg.add("Giac")  # when registered to Julia General Registry
```

For full GIAC integration with C++ library, see the [Installation Guide](install.md).

## Command Access

GIAC commands are available through multiple access patterns:

### 1. Selective Import from Commands Submodule (Recommanded)

```julia
using Giac
using Giac.Commands: factor, expand, ifactor

@giac_var
factor(x^2 - 1)
```

### 2. Full Import (Interactive Use)

```julia
using Giac
using Giac.Commands

@giac_var x
factor(x^2 - 1)
ifactor(120)  # All ~2000+ commands available
```

### 3. Universal Command Invocation

```julia
using Giac

# Works for ALL commands, including those conflicting with Julia
invoke_cmd(:factor, giac_eval("x^2-1"))
invoke_cmd(:sin, giac_eval("pi/6"))
```

## Modules

- **[Core API](@ref)**: Types, evaluation, and main functions
- **[Commands](@ref Giac.Commands)**: All GIAC commands as functions
- **[TempApi](@ref Giac.TempApi)**: Convenience functions with simple names

## Contents

```@contents
Pages = ["install.md", "api/core.md", "api/commands.md", "api/tempapi.md"]
```

## Related Projects

- [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) - The underlying computer algebra system
- [libgiac-julia-wrapper](https://github.com/s-celles/libgiac-julia-wrapper) - CxxWrap bindings for GIAC
- [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) - C++ wrapper generator for Julia
