# Creating Julia Functions from Expressions

Giac.jl lets you build symbolic expressions and then wrap them into regular Julia functions using [`substitute`](@ref) and [`to_julia`](@ref).

## Basic Idea

A symbolic expression like `x^2 - 1` lives in the GIAC engine. To evaluate it at a specific point, substitute the symbolic variable with a value, then convert the result to a native Julia type:

```julia
using Giac

@giac_var x
expr = x^2 - 1

# Wrap into a Julia function
f(_x) = to_julia(substitute(expr, x => _x))

f(3)   # 8
f(0)   # -1
f(-2)  # 3
```

## Step by Step

### 1. Declare symbolic variables

```julia
@giac_var x
```

This creates `x` as a `GiacExpr` representing the symbolic variable `x`.

### 2. Build the expression

```julia
expr = x^2 - 1
```

Standard arithmetic operators (`+`, `-`, `*`, `/`, `^`) work on `GiacExpr` and produce new symbolic expressions.

You can also use `giac_eval` to parse more complex expressions:

```julia
expr = giac_eval("sin(x)^2 + cos(x)^2")
```

### 3. Define the Julia function

```julia
f(_x) = to_julia(substitute(expr, x => _x))
```

This function:
1. Substitutes `x` with the argument `_x` using [`substitute`](@ref)
2. Converts the resulting `GiacExpr` to a native Julia type using [`to_julia`](@ref)

!!! note
    We use `_x` as the function parameter to avoid shadowing the symbolic variable `x`.

## Multivariate Functions

For expressions with multiple variables, use a `Dict` for substitution:

```julia
@giac_var x y
expr = x^2 + 2*x*y - y^2

f(_x, _y) = to_julia(substitute(expr, Dict(x => _x, y => _y)))

f(1, 2)   # 1 + 4 - 4 = 1
f(3, 1)   # 9 + 6 - 1 = 14
```

## Staying Symbolic

If you want the result to remain a `GiacExpr` (e.g., for further symbolic manipulation), skip the `to_julia` call:

```julia
@giac_var x
expr = x^2 - 1

f(_x) = substitute(expr, x => _x)

f(3)             # GiacExpr: "8"
f(giac_eval("a"))  # GiacExpr: "a^2-1"
```

This is useful when the argument itself is symbolic.

## Using GIAC Commands in Expressions

Expressions built with GIAC commands work the same way:

```julia
using Giac.Commands: sin, cos, integrate

@giac_var x

# Build a symbolic expression using GIAC functions
expr = integrate(sin(x) * cos(x), x)

# Evaluate at specific points
f(_x) = to_julia(substitute(expr, x => _x))
```

## Matrix-Valued Functions

The pattern extends to `GiacMatrix` since [`substitute`](@ref) supports element-wise substitution:

```julia
@giac_var x
M = GiacMatrix([x x+1; 2*x x^2])

f(_x) = substitute(M, x => _x)

f(3)   # [[3, 4], [6, 9]]
```

## Performance Considerations

Each call to `f(_x)` goes through the GIAC engine (substitution + evaluation). For performance-critical code with many evaluations, consider:

- **Precompiling to a native Julia function** using `eval` and `Meta.parse` on the string representation
- **Caching results** if the same arguments are used repeatedly
- **Using `Float64` inputs** to avoid unnecessary symbolic processing

## Summary

| Pattern | Returns | Use case |
|---------|---------|----------|
| `f(_x) = to_julia(substitute(expr, x => _x))` | Native Julia type | Numerical evaluation |
| `f(_x) = substitute(expr, x => _x)` | `GiacExpr` | Further symbolic work |
| `f(_x, _y) = to_julia(substitute(expr, Dict(x => _x, y => _y)))` | Native Julia type | Multivariate evaluation |

## See Also

- [Variable Substitution](@ref) for full details on `substitute`
- [Variable Declaration](@ref) for `@giac_var` usage
