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

## Direct Conversion (Feature 051)

As of version 0.9.0, `to_giac` uses direct tree traversal and C++ Gen construction functions for efficient conversion without string serialization. This provides:

- **Better performance**: Expression trees are built directly using the C++ wrapper's Gen construction functions (`make_identifier`, `make_symbolic_unevaluated`, etc.)
- **Type preservation**: Integers are preserved as GIAC integers (not converted to floats)
- **BigInt support**: Arbitrary precision integers are transferred using direct GMP binary transfer

### Supported Types

The direct conversion handles all standard Symbolics.jl constructs:

| Julia/Symbolics Type | GIAC Type |
|---------------------|-----------|
| `Int32`, `Int64` (small) | `_INT_` (GIAC integer) |
| `BigInt` | `_ZINT` (GIAC big integer) |
| `Float64` | `_DOUBLE_` |
| `Rational` | `_FRAC` |
| `Complex` | `_CPLX` |
| Symbolic variable | `_IDNT` (identifier) |
| Expression (`+`, `-`, `*`, `/`, `^`) | `_SYMB` (symbolic) |
| Function call (`sin`, `cos`, etc.) | `_SYMB` (symbolic) |

### Example: Direct Integer Preservation

```julia
using Giac, Symbolics

# Integers are preserved as GIAC integers
result = to_giac(Num(42))
# Result: "42" (not "42.0")

# BigInt works directly
big = BigInt(2)^100
result = to_giac(Num(big))
# Result: "1267650600228229401496703205376"
```

### Example: Expression Tree Conversion

```julia
using Giac, Symbolics

@variables x y

# Expressions are converted via tree traversal
poly = x^2 + 2*x + 1
giac_poly = to_giac(poly)
# Result: "1+x^2+2*x"

# Mathematical functions are mapped correctly
expr = sin(x) + cos(y)
giac_expr = to_giac(expr)
# Result: "sin(x)+cos(y)"

# log maps to ln (GIAC naming)
expr = log(x)
giac_expr = to_giac(expr)
# Result: "ln(x)"
```

## API Reference

See the [Conversion Functions](../api/core.md#conversion-functions) section in the Core API documentation for the full API reference of `to_giac` and `to_symbolics`.
