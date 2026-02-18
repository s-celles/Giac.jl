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

## Modules

- **[Core API](@ref)**: Types, evaluation, and main functions
- **[Commands](@ref Giac.Commands)**: All GIAC commands as functions
- **[TempApi](@ref Giac.TempApi)**: Convenience functions with simple names

## Contents

```@contents
Pages = ["install.md", "quickstart.md", "variables.md", "linear_algebra.md", "differential_equations.md", "api/core.md", "api/commands_submodule.md", "api/tempapi.md"]
```

## Related Projects

- [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) - The underlying computer algebra system
- [libgiac-julia-wrapper](https://github.com/s-celles/libgiac-julia-wrapper) - CxxWrap bindings for GIAC
- [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) - C++ wrapper generator for Julia
