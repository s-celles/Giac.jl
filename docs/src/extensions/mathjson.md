# MathJSON.jl Integration

Giac.jl provides integration with [MathJSON.jl](https://github.com/s-celles/MathJSON.jl) through bidirectional conversion functions, enabling interoperability between GIAC's symbolic computation engine and the MathJSON expression format.

## Basic Usage

```julia
using Giac, MathJSON

# GiacExpr -> MathJSON
@giac_var x
expr = x^2 + 1
mj = to_mathjson(expr)  # FunctionExpr(:Add, [FunctionExpr(:Power, ...), NumberExpr(1)])

# MathJSON -> GiacExpr
mj = FunctionExpr(:Sin, AbstractMathJSONExpr[SymbolExpr("x")])
giac_expr = to_giac(mj)  # GiacExpr: sin(x)
```

## GiacExpr to MathJSON

The `to_mathjson` function converts a `GiacExpr` to a `MathJSON.AbstractMathJSONExpr` tree using direct Gen introspection (no string serialization).

### Numeric Types

```julia
to_mathjson(giac_eval("42"))    # NumberExpr(42)
to_mathjson(giac_eval("3.14"))  # NumberExpr(3.14)
to_mathjson(giac_eval("3/4"))   # FunctionExpr(:Rational, [NumberExpr(3), NumberExpr(4)])
to_mathjson(giac_eval("3+4*i")) # FunctionExpr(:Complex, [NumberExpr(3), NumberExpr(4)])
```

### Identifiers and Constants

```julia
to_mathjson(giac_eval("x"))   # SymbolExpr("x")
to_mathjson(giac_eval("pi"))  # SymbolExpr("Pi")
```

!!! note
    GIAC evaluates `e` to `exp(1)` and `i` to the complex number `0+1*i` internally. These convert to `FunctionExpr(:Exp, [NumberExpr(1)])` and `FunctionExpr(:Complex, [NumberExpr(0), NumberExpr(1)])` respectively.

### Symbolic Expressions

```julia
to_mathjson(giac_eval("sin(x)"))    # FunctionExpr(:Sin, [SymbolExpr("x")])
to_mathjson(giac_eval("sqrt(x)"))   # FunctionExpr(:Sqrt, [SymbolExpr("x")])

@giac_var x
to_mathjson(x + 1)     # FunctionExpr(:Add, ...)
to_mathjson(x^2)       # FunctionExpr(:Power, ...)
```

### Vectors and Matrices

```julia
# Vectors
to_mathjson(giac_eval("[1,2,3]"))  # FunctionExpr(:List, [NumberExpr(1), ...])

# Matrices
m = GiacMatrix([[1, 2], [3, 4]])
to_mathjson(m)  # FunctionExpr(:Matrix, [FunctionExpr(:List, ...), ...])
```

### Equations

```julia
@giac_var x
to_mathjson(x ~ 1)  # FunctionExpr(:Equal, [SymbolExpr("x"), NumberExpr(1)])
```

## MathJSON to GiacExpr

The `to_giac` function converts MathJSON expression types to `GiacExpr`.

### Numbers and Symbols

```julia
to_giac(NumberExpr(42))              # GiacExpr: 42
to_giac(NumberExpr(3.14))            # GiacExpr: 3.14
to_giac(SymbolExpr("x"))            # GiacExpr: x
to_giac(SymbolExpr("Pi"))           # GiacExpr: pi
to_giac(SymbolExpr("ExponentialE")) # GiacExpr: exp(1)
to_giac(SymbolExpr("ImaginaryUnit"))# GiacExpr: i
```

### Function Expressions

```julia
# Simple function
expr = FunctionExpr(:Sin, AbstractMathJSONExpr[SymbolExpr("x")])
to_giac(expr)  # GiacExpr: sin(x)

# Arithmetic
expr = FunctionExpr(:Add, AbstractMathJSONExpr[SymbolExpr("x"), NumberExpr(1)])
to_giac(expr)  # GiacExpr: x+1

# Nested
inner = FunctionExpr(:Power, AbstractMathJSONExpr[SymbolExpr("x"), NumberExpr(2)])
expr = FunctionExpr(:Sin, AbstractMathJSONExpr[inner])
to_giac(expr)  # GiacExpr: sin(x^2)
```

### Special Types

```julia
# Rational
to_giac(FunctionExpr(:Rational, AbstractMathJSONExpr[NumberExpr(3), NumberExpr(4)]))
# GiacExpr: 3/4

# Complex
to_giac(FunctionExpr(:Complex, AbstractMathJSONExpr[NumberExpr(3), NumberExpr(4)]))
# GiacExpr: 3+4*i

# List/Vector
to_giac(FunctionExpr(:List, AbstractMathJSONExpr[NumberExpr(1), NumberExpr(2), NumberExpr(3)]))
# GiacExpr: [1,2,3]

# Equation
to_giac(FunctionExpr(:Equal, AbstractMathJSONExpr[SymbolExpr("x"), NumberExpr(1)]))
# GiacExpr: x=1
```

## Operator Mapping

Over 100 operators are mapped bidirectionally between GIAC and MathJSON:

| Category | GIAC | MathJSON |
|----------|------|----------|
| Arithmetic | `+`, `*`, `-`, `/`, `^` | `:Add`, `:Multiply`, `:Subtract`, `:Divide`, `:Power` |
| Trigonometric | `sin`, `cos`, `tan`, `cot` | `:Sin`, `:Cos`, `:Tan`, `:Cot` |
| Inverse Trig | `asin`, `acos`, `atan` | `:Arcsin`, `:Arccos`, `:Arctan` |
| Hyperbolic | `sinh`, `cosh`, `tanh` | `:Sinh`, `:Cosh`, `:Tanh` |
| Calculus | `diff`, `integrate`, `limit` | `:D`, `:Integrate`, `:Limit` |
| Algebra | `factor`, `expand`, `simplify` | `:Factor`, `:Expand`, `:Simplify` |
| Linear Algebra | `det`, `inv`, `transpose` | `:Determinant`, `:Inverse`, `:Transpose` |
| Special | `Gamma`, `zeta`, `erf` | `:Gamma`, `:Zeta`, `:Erf` |
| Logic | `and`, `or`, `not` | `:And`, `:Or`, `:Not` |
| Relations | `=`, `<`, `<=`, `>`, `>=` | `:Equal`, `:Less`, `:LessEqual`, `:Greater`, `:GreaterEqual` |

Unsupported MathJSON operators produce a warning and fall back to string-based evaluation.

## Round-Trip Fidelity

Expressions can be converted back and forth while preserving mathematical equivalence:

```julia
@giac_var x

# GiacExpr -> MathJSON -> GiacExpr
original = x^2 + 2 * x + 1
roundtrip = to_giac(to_mathjson(original))
# roundtrip is mathematically equivalent to original

# MathJSON -> GiacExpr -> MathJSON
mj = FunctionExpr(:Sin, AbstractMathJSONExpr[SymbolExpr("x")])
roundtrip = to_mathjson(to_giac(mj))
# roundtrip.operator == :Sin
```

## Error Handling

```julia
# StringExpr cannot be converted (throws ErrorException)
to_giac(StringExpr("hello"))  # ERROR

# Unsupported GIAC types throw ErrorException
to_mathjson(giac_eval("\"hello\""))  # ERROR

# Unsupported MathJSON operators produce a warning and fallback
to_giac(FunctionExpr(:UnknownOp, AbstractMathJSONExpr[NumberExpr(1)]))
# Warning: Unsupported MathJSON operator 'UnknownOp' -- falls back to string eval
```

## API Reference

See the [Conversion Functions](../api/core.md#conversion-functions) section in the Core API documentation for the full API reference of `to_giac` and `to_mathjson`.
