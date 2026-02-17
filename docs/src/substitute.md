# Variable Substitution

Giac.jl provides a `substitute` function with a Symbolics.jl-compatible interface for variable substitution in symbolic expressions.

## Basic Usage

### Single Variable Substitution

```julia
using Giac

# Create symbolic variables
@giac_var x y

# Create an expression
expr = x^2 + 2*x + 1

# Substitute x = 3
result = substitute(expr, Dict(x => 3))
# Returns: 16 (which is 9 + 6 + 1)

# Substitute with symbolic value
result = substitute(expr, Dict(x => y))
# Returns: y^2 + 2*y + 1
```

### Pair Syntax (Shorthand)

For single-variable substitutions, you can use the Pair syntax:

```julia
@giac_var x

substitute(x + 1, x => 5)  # Returns: 6
```

### Multiple Variable Substitution

Substitute multiple variables simultaneously:

```julia
@giac_var x y z

expr = x*y + y*z + x*z

# Substitute multiple variables at once
result = substitute(expr, Dict(x => 1, y => 2, z => 3))
# Returns: 11 (which is 2 + 6 + 3)
```

### Variable Swapping

The substitution is performed simultaneously, making variable swapping work correctly:

```julia
@giac_var a b

expr = a^2 + b

# Simultaneous substitution correctly swaps variables
result = substitute(expr, Dict(a => b, b => a))
# Returns: b^2 + a
```

## With GIAC Functions

The substitute function works with any GIAC-supported functions:

```julia
@giac_var θ

expr = invoke_cmd(:sin, θ) + invoke_cmd(:cos, θ)

# Substitute θ = π/4
using Giac.Commands: simplify
result = substitute(expr, Dict(θ => giac_eval("pi/4"))) |> simplify
# Returns: sqrt(2)
```

## Symbolic-to-Symbolic Substitution

Replace variables with complex expressions:

```julia
@giac_var x y

# x^2 with x = y + 1
result = substitute(x^2, Dict(x => y + 1))
# Returns: (y + 1)^2
```

## Chained Substitution

Apply multiple substitutions in sequence:

```julia
@giac_var x y z

expr = x + y + z

step1 = substitute(expr, x => 1)
step2 = substitute(step1, y => 2)
final = substitute(step2, z => 3)
# Returns: 6
```

## Comparison with Symbolics.jl

The API is designed to match [Symbolics.jl](https://docs.sciml.ai/Symbolics/v6.20/manual/expression_manipulation/)'s `substitute` function:

```julia
# Symbolics.jl style (works in Giac.jl)
substitute(expr, Dict(x => 2, y => 3))

# Single variable shorthand
substitute(expr, x => value)
```

## Edge Cases

```julia
@giac_var x y

# Empty Dict returns original expression
substitute(x + 1, Dict{GiacExpr, Int}())  # Returns: x + 1

# Missing variable is ignored
substitute(x + 1, Dict(y => 5))  # Returns: x + 1 (y not in expr)
```

## API Reference

```@docs
substitute
```
