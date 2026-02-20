# Symbolics.jl Integration

Giac.jl provides seamless integration with [Symbolics.jl](https://symbolics.juliasymbolics.org/) through bidirectional conversion functions.

## Basic Usage

```julia
using Giac, Symbolics

@variables x y
giac_expr = to_giac(x^2 + 2*x + 1)
factored = invoke_cmd(:factor, giac_expr)  # (x+1)^2
sym_result = to_symbolics(factored)  # Num: (1+x)^2
```

## Symbolic Preservation

As of version 0.8.1, `to_symbolics` preserves symbolic mathematical functions instead of evaluating them to floating-point approximations.

### Factorization Preservation (Feature 044)

As of version 0.8.2, `to_symbolics` also preserves factorized expression structure from GIAC:

```julia
using Giac, Symbolics
using Giac.Commands: ifactor, factor

# Integer factorization is preserved
result = ifactor(1000000)
sym = to_symbolics(result)
# Result: (2^6)*(5^6), NOT 1000000

# Polynomial factorization is preserved
x = giac_eval("x")
result = factor(x^2 - 1)
sym = to_symbolics(result)
# Result: (-1 + x)*(1 + x), NOT x^2 - 1
```

### Square Roots and Other Roots

```julia
using Giac, Symbolics

# sqrt(2) is preserved symbolically
result = giac_eval("sqrt(2)")
sym = to_symbolics(result)
# Result: sqrt(2), NOT 1.4142135623730951

# Works with factorization too
result = giac_eval("factor(x^8-1)")
sym = to_symbolics(result)
# Result contains sqrt(2) symbolically in factors
```

### Nested Expressions

```julia
# Nested sqrt preserved
result = giac_eval("sqrt(sqrt(2))")
sym = to_symbolics(result)
# Result: sqrt(sqrt(2)), NOT 1.189...

# Mixed expressions
result = giac_eval("x^2 + sqrt(2)*x + 1")
sym = to_symbolics(result)
# Result: 1 + sqrt(2)*x + x^2
```

### Exponentials and Logarithms

```julia
# exp(1) = e preserved
result = giac_eval("exp(1)")
sym = to_symbolics(result)
# Result: exp(1), NOT 2.718...

# log(2) preserved
result = giac_eval("log(2)")
sym = to_symbolics(result)
# Result: log(2), NOT 0.693...
```

### Trigonometric Functions

```julia
# sin, cos, tan preserved
result = giac_eval("sin(1)")
sym = to_symbolics(result)
# Result: sin(1), NOT 0.841...

result = giac_eval("cos(pi/4)")
sym = to_symbolics(result)
# Result: cos(π/4), NOT 0.707...
```

### Mathematical Constants

```julia
# pi preserved as symbolic constant
result = giac_eval("pi")
sym = to_symbolics(result)
# Result: π (Symbolics.pi)

# Works in expressions
result = giac_eval("2*pi")
sym = to_symbolics(result)
# Result: 2π
```

## Preserved Functions

The following GIAC functions are preserved symbolically when converting to Symbolics.jl:

| Function | Description |
|----------|-------------|
| `sqrt` | Square root |
| `exp` | Exponential |
| `log`, `ln` | Natural logarithm |
| `sin`, `cos`, `tan` | Trigonometric |
| `asin`, `acos`, `atan` | Inverse trigonometric |
| `sinh`, `cosh`, `tanh` | Hyperbolic |
| `abs` | Absolute value |

Mathematical constants:
- `pi` → `Symbolics.pi` (π)
- `i` → `im` (Julia imaginary unit)

## API Reference

See the [Conversion Functions](../api/core.md#conversion-functions) section in the Core API documentation for the full API reference of `to_giac` and `to_symbolics`.
