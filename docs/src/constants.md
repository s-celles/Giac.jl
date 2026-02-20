# Symbolic Constants

The `Giac.Constants` module provides symbolic mathematical constants (`pi`, `e`, `i`) as `GiacExpr` values that preserve their symbolic form in expressions.

## Why Use Symbolic Constants?

When you use Julia's native constants (like `Base.pi`) with GIAC expressions, they are converted to floating-point approximations:

```julia
using Giac

x = giac_eval("x")

# Using Julia's pi results in float conversion
expr = 2 * Base.pi * x
# Output: GiacExpr: 6.283185307179586*x  (FLOAT!)
```

With `Giac.Constants`, the symbolic form is preserved:

```julia
using Giac
using Giac.Constants: pi

x = giac_eval("x")

# Using Giac.Constants.pi stays symbolic
expr = 2 * pi * x
# Output: GiacExpr: 2*pi*x  (SYMBOLIC!)
```

## Available Constants

| Constant | Description | Mathematical Symbol |
|----------|-------------|---------------------|
| `pi` | Circle constant (ratio of circumference to diameter) | π |
| `e` | Euler's number (base of natural logarithm) | ℯ |
| `i` | Imaginary unit (square root of -1) | i |

## Usage

### Importing Constants

Constants are NOT exported from the main `Giac` module to avoid accidentally shadowing Julia's `Base.pi`. You must explicitly import them:

```julia
using Giac

# Option 1: Qualified access (recommended for clarity)
Giac.Constants.pi

# Option 2: Selective import
using Giac.Constants: pi, e, i

# Option 3: Import all constants
using Giac.Constants
```

### Basic Operations

```julia
using Giac
using Giac.Constants: pi, e, i

# Arithmetic with symbolic constants
2 * pi                    # GiacExpr: 2*pi
pi / 2                    # GiacExpr: pi/2
3 * pi                    # GiacExpr: 3*pi

# Using in expressions with variables
x = giac_eval("x")
expr = 2 * pi * x         # GiacExpr: 2*pi*x
```

### Trigonometric Functions

Trigonometric functions evaluate exactly when applied to symbolic constants:

```julia
using Giac
using Giac.Commands: sin, cos
using Giac.Constants: pi

# Convert to GiacExpr for use with invoke_cmd
pi_expr = convert(GiacExpr, pi)

invoke_cmd(:sin, pi_expr)      # GiacExpr: 0
invoke_cmd(:cos, pi_expr)      # GiacExpr: -1
invoke_cmd(:sin, pi_expr / 2)  # GiacExpr: 1
```

### Euler's Formula

The classic identity e^(i*π) = -1 works symbolically:

```julia
using Giac
using Giac.Commands: exp
using Giac.Constants: pi, e, i

# Euler's formula
result = invoke_cmd(:exp, i * pi)
# Output: GiacExpr: -1
```

## Notes on GIAC Behavior

GIAC normalizes some expressions automatically:

- `e` is often displayed as `exp(1)` in output
- `e^2` becomes `exp(2)` (equivalent but normalized form)
- `pi` remains symbolic and displays as `pi`
- `i` remains symbolic and displays as `i`

This normalization is correct mathematical behavior - the expressions are equivalent.

## Integration with Symbolics.jl

When using the GiacSymbolicsExt extension, constants convert correctly:

```julia
using Giac
using Symbolics
using Giac.Constants: pi

# Convert GIAC's symbolic pi to Symbolics.jl
pi_expr = convert(GiacExpr, pi)
sym_pi = to_symbolics(pi_expr)  # Returns Symbolics.pi

# Use in Symbolics.jl expressions
@variables x
expr = 2 * sym_pi * x  # Symbolics expression with π
```
