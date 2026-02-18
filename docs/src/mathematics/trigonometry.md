# Trigonometry

Giac.jl provides comprehensive tools for trigonometric simplification, expansion, and identity verification.

## Setup

```julia
using Giac
using Giac.Commands: simplify, solve, trigexpand, tlin, tcollect, asin, acos, atan, sinh, cosh

@giac_var x y
```

## Fundamental Identities

### Pythagorean Identity

Verify the fundamental Pythagorean identity:

```julia
@giac_var x

simplify(sin(x)^2 + cos(x)^2)
# Output: 1
```

### Other Pythagorean Identities

```julia
@giac_var x

# 1 + tan²(x) = sec²(x)
simplify(1 + tan(x)^2 - 1/cos(x)^2)
# Should simplify to 0

# 1 + cot²(x) = csc²(x)
simplify(1 + cot(x)^2 - 1/sin(x)^2)
```

## Trigonometric Expansion (trigexpand)

### Double Angle Formulas

Use `trigexpand` to expand trigonometric functions:

```julia
@giac_var x

# sin(2x) = 2*sin(x)*cos(x)
trigexpand(sin(2*x))
# Output: 2*cos(x)*sin(x)

# cos(2x) = cos²(x) - sin²(x)
trigexpand(cos(2*x))
# Output: cos(x)^2-sin(x)^2
```

### Triple Angle Formulas

```julia
@giac_var x

# sin(3x) expansion
trigexpand(sin(3*x))
# Output: (4*cos(x)^2-1)*sin(x)

# cos(3x) expansion
trigexpand(cos(3*x))
```

### Sum Formulas

```julia
@giac_var x y

# sin(x+y) = sin(x)cos(y) + cos(x)sin(y)
trigexpand(sin(x+y))
# Output: sin(x)*cos(y)+cos(x)*sin(y)

# cos(x+y) = cos(x)cos(y) - sin(x)sin(y)
trigexpand(cos(x+y))
```

## Product to Sum Conversion (tlin)

Convert products of trigonometric functions to sums:

```julia
@giac_var x y

# sin(x)*cos(x) = (1/2)*sin(2x)
tlin(sin(x)*cos(x))
# Output: (1/2)*sin(2*x)

# cos(x)*cos(x) = (1/2)*(1 + cos(2x))
tlin(cos(x)^2)
# Output: (1/2)*cos(2*x)+1/2

# sin(x)*sin(y)
tlin(sin(x)*sin(y))
# Output in terms of cos(x-y) and cos(x+y)
```

## Sum to Product Conversion (tcollect)

Convert sums of trigonometric functions to products:

```julia
@giac_var x

# sin(x) + cos(x) = sqrt(2)*cos(x - π/4)
tcollect(sin(x)+cos(x))
# Output: sqrt(2)*cos(x-1/4*pi)

# More complex expressions
tcollect(2*sin(x)*cos(x))
```

## Simplification

### Basic Simplification

Simplify trigonometric expressions:

```julia
@giac_var x

# tan(x)*cos(x) = sin(x)
simplify(tan(x)*cos(x))
# Output: sin(x)

# sin(x)/cos(x) = tan(x)
simplify(sin(x)/cos(x))
# Output: tan(x)
```

### Complex Expressions

```julia
@giac_var x

# (1 - cos(2x))/(2*sin(x)) simplifies
simplify((1-cos(2*x))/(2*sin(x)))

# tan(x) + cot(x)
simplify(tan(x)+cot(x))
```

## Solving Trigonometric Equations

### Basic Equations

```julia
@giac_var x

# sin(x) = 0
julia> solve(sin(x) ~ 0, x)
# Output: list[0,pi]

# cos(x) = 0
solve(cos(x) ~ 0 , x)
# Output: list[-1/2*pi,1/2*pi]
```

### More Complex Equations

```julia
@giac_var x

# sin(x) = 1/2 - create 1/2 as GiacExpr
half = giac_eval("1/2")
solve(sin(x) - half, x)
# Output: π/6 and 5π/6

# cos(2x) = 0
solve(cos(2*x), x)
# Output: π/4, 3π/4, etc.
```

### Equations in Intervals

```julia
# Find all solutions of sin(x) = 1/2 in [0, 2π]
# Use solve with constraints or numerical methods
```

## Inverse Trigonometric Functions

### Basic Evaluations

```julia
@giac_var x

# asin(1/2) = π/6 - create 1/2 as GiacExpr
half = giac_eval("1/2")
asin(half)
# Output: pi/6

# acos(0) - create 0 as GiacExpr
zero_expr = 0 * x + 0
acos(zero_expr)
# Output: pi/2

# atan(1) - create 1 as GiacExpr
one_expr = 0 * x + 1
atan(one_expr)
# Output: pi/4
```

### Compositions

```julia
@giac_var x

# sin(asin(x)) = x
simplify(sin(asin(x)))
# Should return x (with domain restrictions)
```

## Hyperbolic Functions

GIAC also supports hyperbolic trigonometric functions:

```julia
@giac_var x

# sinh(x) expression
sinh(x)

# cosh(x) + sinh(x) = exp(x)
simplify(cosh(x)+sinh(x)-exp(x))
# Output: 0
```

## Table of Commands

| Command | Description |
|---------|-------------|
| `trigexpand(expr)` | Expand trig functions (double/triple angle) |
| `tlin(expr)` | Product to sum conversion |
| `tcollect(expr)` | Sum to product conversion |
| `simplify(expr)` | General simplification |
| `texpand(expr)` | Alternative expansion |

## Notes

- Trigonometric functions work with symbolic arguments from `@giac_var`
- To create fractional GiacExpr values, use arithmetic: `(1 + 0*x) / 2` for 1/2
- Solutions to trig equations may include principal values or general solutions with n*π terms
- For numerical evaluation of inverse trig functions, convert results to Julia floats
