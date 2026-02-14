# Giac.jl

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18642707.svg)](https://doi.org/10.5281/zenodo.18642707)

A Julia wrapper for the [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) computer algebra system.

## Features

- **Expression Evaluation**: Parse and evaluate mathematical expressions
- **Arithmetic Operations**: +, -, *, /, ^, unary negation, equality
- **Calculus**: Differentiation, integration, limits, series expansion
- **Algebra**: Factorization, expansion, simplification, equation solving, GCD
- **Linear Algebra**: Matrix determinant, inverse, trace, transpose
- **Type Conversion**: Convert results to Julia native types (Int64, Float64, Rational)
- **Symbolics.jl Integration**: Bidirectional conversion with Symbolics.jl

## Installation

### Option 1: Stub Mode (No C++ Dependencies)

For development or testing without the full GIAC library:

```julia
using Pkg
Pkg.add(url="https://github.com/s-celles/Giac.jl")
```

In stub mode, basic operations work but return placeholder values.

### Option 2: Full Integration (With GIAC 2.0.0)

#### Prerequisites

- Julia 1.10+ (LTS recommended)
- C++ compiler with C++17 support
- CMake 3.15+
- GIAC 2.0.0 source

#### Step 1: Build GIAC 2.0.0

```bash
# Download GIAC
wget https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac/giac_stable.tgz
tar xzf giac_stable.tgz
cd giac-2.0.0

# Configure and build
./configure --enable-shared --disable-gui --disable-pari
make -j$(nproc)
```

#### Step 2: Build libgiac-julia-wrapper

```bash
git clone https://github.com/s-celles/libgiac-julia-wrapper
cd libgiac-julia-wrapper
mkdir build && cd build
cmake .. -DGIAC_ROOT=/path/to/giac-2.0.0
make -j$(nproc)
```

#### Step 3: Set Environment

```bash
export GIAC_WRAPPER_LIB=/path/to/libgiac-julia-wrapper/build/src/libgiac_wrapper.so
export LD_LIBRARY_PATH=/path/to/giac-2.0.0/src/.libs:$LD_LIBRARY_PATH
```

## Quick Start

```julia
using Giac

# Check mode
println("Stub mode: ", is_stub_mode())

# Basic evaluation
result = giac_eval("2 + 3")        # 5
factored = giac_eval("factor(x^2 - 1)")  # (x-1)*(x+1)

# Arithmetic
x = giac_eval("x")
y = giac_eval("y")
println(x + y)   # x+y
println(x * y)   # x*y
println(x ^ 2)   # x^2

# Calculus
f = giac_eval("x^3")
df = giac_diff(f, x)               # 3*x^2
F = giac_integrate(f, x)           # x^4/4
lim = giac_limit(giac_eval("sin(x)/x"), x, giac_eval("0"))  # 1

# Algebra
giac_factor(giac_eval("x^2 - 1"))      # (x-1)*(x+1)
giac_expand(giac_eval("(x+1)^3"))      # x^3+3*x^2+3*x+1
giac_simplify(giac_eval("(x^2-1)/(x-1)"))  # x+1
giac_solve(giac_eval("x^2 - 4"), x)    # list[-2,2]

# Convert to Julia types
to_julia(giac_eval("42"))    # 42::Int64
to_julia(giac_eval("3/4"))   # 3//4::Rational{Int64}
```

## Linear Algebra

```julia
using Giac, LinearAlgebra

A = GiacMatrix([1 2; 3 4])
det(A)        # -2
tr(A)         # 5
inv(A)        # inverse matrix
transpose(A)  # transposed matrix

# Symbolic matrix
B = GiacMatrix([[giac_eval("a"), giac_eval("b")],
                [giac_eval("c"), giac_eval("d")]])
det(B)  # a*d-b*c
```

## Symbolics.jl Integration

```julia
using Giac, Symbolics

@variables x y
giac_expr = to_giac(x^2 + 2*x + 1)
factored = giac_factor(giac_expr)  # (x+1)^2
sym_result = to_symbolics(factored)  # Num: (1+x)^2
```

## API Reference

### Core Functions

| Function | Description |
|----------|-------------|
| `giac_eval(expr)` | Evaluate a GIAC expression string |
| `is_stub_mode()` | Check if running without GIAC library |
| `to_julia(expr)` | Convert GiacExpr to Julia type |

### Calculus

| Function | Description |
|----------|-------------|
| `giac_diff(f, x, n=1)` | nth derivative of f with respect to x |
| `giac_integrate(f, x)` | Indefinite integral |
| `giac_integrate(f, x, a, b)` | Definite integral from a to b |
| `giac_limit(f, x, point)` | Limit as x approaches point |
| `giac_series(f, x, point, order)` | Taylor series expansion |

### Algebra

| Function | Description |
|----------|-------------|
| `giac_factor(expr)` | Factor polynomial |
| `giac_expand(expr)` | Expand expression |
| `giac_simplify(expr)` | Simplify expression |
| `giac_solve(expr, x)` | Solve equation for x |
| `giac_gcd(a, b)` | Greatest common divisor |

### Linear Algebra

| Function | Description |
|----------|-------------|
| `GiacMatrix(array)` | Create symbolic matrix |
| `det(M)` | Determinant |
| `inv(M)` | Inverse |
| `tr(M)` | Trace |
| `transpose(M)` | Transpose |

## License

MIT License

## Related Projects

- [GIAC](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) - The underlying computer algebra system
- [libgiac-julia-wrapper](https://github.com/s-celles/libgiac-julia-wrapper) - CxxWrap bindings for GIAC
- [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) - C++ wrapper generator for Julia
