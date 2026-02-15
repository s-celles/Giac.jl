# Giac.jl

A Julia wrapper for the [GIAC](https://www-fourier.ujf-grenoble.fr/~parisse/giac.html) computer algebra system.

## Features

- **Symbolic Computation**: Full access to GIAC's powerful symbolic computation engine
- **Calculus**: Differentiation, integration, limits, and series expansion
- **Algebra**: Factorization, expansion, simplification, and equation solving
- **Linear Algebra**: Symbolic matrices with determinant, inverse, trace operations
- **2200+ Commands**: Access to all GIAC commands through a unified API
- **LaTeX Support**: Automatic LaTeX rendering in Pluto notebooks

## Installation

```julia
using Pkg
Pkg.add("Giac")
```

For full GIAC integration with C++ library, see the [Installation Guide](install.md).

## Quick Start

```julia
using Giac

# Create symbolic variables
@giac_var x y

# Evaluate expressions
expr = giac_eval("x^2 + 2*x*y + y^2")

# Factor polynomials
result = giac_factor(expr)  # Returns (x+y)^2

# Differentiate
derivative = giac_diff(result, x)  # Returns 2*(x+y)

# Integrate
integral = giac_integrate(giac_eval("x^2"), x)  # Returns x^3/3
```

## Command Access

GIAC commands are available through multiple access patterns:

### 1. Universal Command Invocation (Recommended)

```julia
using Giac

# Works for ALL commands, including those conflicting with Julia
invoke_cmd(:factor, giac_eval("x^2-1"))
invoke_cmd(:sin, giac_eval("pi/6"))
```

### 2. Selective Import from Commands Submodule

```julia
using Giac
using Giac.Commands: factor, expand, ifactor

factor(giac_eval("x^2-1"))  # Works directly
```

### 3. Full Import (Interactive Use)

```julia
using Giac
using Giac.Commands

factor(giac_eval("x^2-1"))
ifactor(giac_eval("120"))  # All ~2000+ commands available
```

## Modules

- **[Core API](@ref)**: Types, evaluation, and main functions
- **[Commands](@ref Giac.Commands)**: All GIAC commands as functions
- **[TempApi](@ref Giac.TempApi)**: Convenience functions with simple names

## Contents

```@contents
Pages = ["install.md", "api/core.md", "api/commands.md", "api/tempapi.md"]
```
