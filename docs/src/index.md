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
- **Variable Substitution**: Symbolics.jl-compatible `substitute(expr, Dict(var => value))` interface
- **Infinity Support**: Use Julia's `Inf` and `-Inf` directly in limits and improper integrals
- **Z-Transform**: `ztrans` and `invztrans` commands for discrete-time signal processing
- **Laplace Transform**: `laplace` and `ilaplace` commands for continuous-time signal processing

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

## Type Conversion and Introspection

Convert GIAC results to native Julia types:

```julia
using Giac

# Boolean conversion
to_julia(giac_eval("true"))   # true::Bool
to_julia(giac_eval("1==1"))   # true::Bool (comparison result)
to_julia(giac_eval("1"))      # 1::Int64 (integer, not boolean)

# Use in control flow
if to_julia(giac_eval("2 > 1"))
    println("Works!")
end

# Automatic type conversion
g = giac_eval("[1, 2, 3]")
result = to_julia(g)  # Vector{Int64}

# Boolean detection
is_boolean(giac_eval("true"))  # true
is_boolean(giac_eval("1"))     # false

# Type introspection
giac_type(g) == GIAC_VECT  # true
is_vector(g)               # true

# Fraction components
frac = giac_eval("3/4")
numer(frac)  # 3
denom(frac)  # 4

# Complex components
z = giac_eval("3+4*i")
real_part(z)  # 3
imag_part(z)  # 4

# Matrix conversion
m = GiacMatrix(giac_eval("[[1, 2], [3, 4]]"))
to_julia(m)  # 2×2 Matrix{Int64}
```

## Vector Indexing and Iteration

Access GIAC vectors with Julia's native indexing:

```julia
using Giac

g = giac_eval("[10, 20, 30]")
g[1]  # GiacExpr(10)
g[2]  # GiacExpr(20)

# Iterate over elements
for elem in g
    println(to_julia(elem))
end

# Collect to Julia vector
to_julia(g)  # [10, 20, 30]::Vector{Int64}
```

## Infinity Support

Use Julia's native `Inf` and `-Inf` in limits and improper integrals:

```julia
using Giac
using Giac.Commands: limit, integrate

@giac_var x

# Limits at infinity
limit(1/x, x, Inf)     # 0
limit(1/x, x, -Inf)    # 0
limit(x^2, x, Inf)     # +infinity

# Improper integrals
integrate(exp(-x), x, 0, Inf)    # 1
integrate(1/x^2, x, 1, Inf)      # 1
integrate(exp(x), x, -Inf, 0)    # 1
```

## Modules

- **[Core API](@ref)**: Types, evaluation, and main functions
- **[Commands](@ref Giac.Commands)**: All GIAC commands as functions
- **[TempApi](@ref Giac.TempApi)**: Convenience functions with simple names

## Documentation

### Getting Started
- [Installation Guide](install.md)
- [Quick Start](quickstart.md)
- [Variable Declaration](variables.md)

### Mathematics
- [Algebra](mathematics/algebra.md) - Factorization, expansion, simplification, solving
- [Calculus](mathematics/calculus.md) - Differentiation, integration, limits, series
- [Linear Algebra](mathematics/linear_algebra.md) - Matrices, determinants, eigenvalues
- [Differential Equations](mathematics/differential_equations.md) - ODE solving with D operator
- [Trigonometry](mathematics/trigonometry.md) - Identities, simplification, equations

### Physics
- [Mechanics](physics/mechanics.md) - Kinematics, dynamics, oscillations, energy
- [Electromagnetism](physics/electromagnetism.md) - Circuits, fields, waves

### API Reference
- [Core API](api/core.md) - Types, evaluation, and main functions
- [Commands Submodule](api/commands_submodule.md) - All GIAC commands as functions
- [TempApi](api/tempapi.md) - Convenience functions with simple names

## Related Projects

- [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) - The underlying computer algebra system
- [libgiac-julia-wrapper](https://github.com/s-celles/libgiac-julia-wrapper) - CxxWrap bindings for GIAC
- [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) - C++ wrapper generator for Julia
