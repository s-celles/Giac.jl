# GIAC commands

## Dynamic Command Invocation

Call any of GIAC's 2200+ commands dynamically:

```julia
using Giac

@giac_var x
expr = giac_eval("x^2 - 1")

# Function syntax with invoke_cmd (works for ALL commands)
result = invoke_cmd(:factor, expr)           # (x-1)*(x+1)
deriv = invoke_cmd(:diff, expr, x)           # 2*x
integral = invoke_cmd(:integrate, expr, x)   # x^3/3-x

# Method syntax on GiacExpr (equivalent to invoke_cmd)
result = expr.factor()                     # (x-1)*(x+1)
deriv = expr.diff(x)                       # 2*x

# Chaining methods
result = giac_eval("(x+1)^3").expand().simplify()

# Natural Julia syntax with Base extensions
@giac_var y
sin(y)         # sin(y)
cos(y)         # cos(y)
exp(y)         # exp(y)
log(y)         # ln(y)
sqrt(y)        # sqrt(y)
sin(y) + cos(y)  # sin(y)+cos(y)
```

## Commands Submodule

Giac.jl provides **three ways** to access GIAC's 2200+ commands via the `Giac.Commands` submodule:

### 1. Qualified Access (Cleanest Namespace - ToDo - not yet implemented)

Access commands via `Giac.Commands.commandname`:

```julia
using Giac

@giac_var x
expr = giac_eval("x^2 - 1")

# Access commands via Giac.Commands
Giac.Commands.factor(expr)          # (x-1)*(x+1)
Giac.Commands.expand(giac_eval("(x+1)^2"))  # x^2+2*x+1
Giac.Commands.diff(expr, x)         # 2*x
Giac.Commands.integrate(expr, x)    # x^3/3-x
Giac.Commands.ifactor(giac_eval("120"))  # 2^3*3*5
```

### 2. Selective Import (Recommended - ToDo - not yet implemented)

Import specific commands you need:

```julia
using Giac
using Giac.Commands: factor, expand, diff, integrate

@giac_var x
expr = giac_eval("x^2 - 1")

# Direct function syntax (no prefix needed)
factor(expr)              # (x-1)*(x+1)
expand(giac_eval("(x+1)^2"))  # x^2+2*x+1
diff(expr, x)             # 2*x
integrate(expr, x)        # x^3/3-x
```

### 3. Full Import (Interactive Use)

Import all ~2000+ commands for interactive exploration:

```julia
using Giac
using Giac.Commands  # Imports ALL exportable commands

@giac_var x
factor(giac_eval("x^2 - 1"))    # (x-1)*(x+1)
ifactor(giac_eval("120"))       # 2^3*3*5
nextprime(giac_eval("100"))     # 101
airy_ai(giac_eval("0"))         # Airy function

# Discover available commands
exportable_commands()            # ~2000+ command names
```

### invoke_cmd for ALL Commands

For commands that conflict with Julia (like `sin`, `cos`, `eval`, `det`), use `invoke_cmd`:

```julia
using Giac

@giac_var k n

# Conflicting commands must use invoke_cmd
invoke_cmd(:eval, giac_eval("2+3"))      # 5
invoke_cmd(:sin, giac_eval("pi/6"))      # 1/2
invoke_cmd(:det, giac_eval("[[1,2],[3,4]]"))  # -2
invoke_cmd(:det, giac_eval("[[a,b],[c,d]]"))  # a*d-b*c
invoke_cmd(:sum, k, k, giac_eval("1"), n)  # 1/2*n^2+1/2*n
invoke_cmd(:product, k, k, giac_eval("1"), n)  # n!

# invoke_cmd works for ANY command
invoke_cmd(:factor, giac_eval("x^2-1"))  # (x-1)*(x+1)
```

## TempApi Submodule

The `Giac.TempApi` submodule provides convenience functions with simplified names for some common symbolic computation operations. These are wrappers around the `giac_*` functions.

```julia
using Giac.TempApi: diff, expand, factor, integrate, limit, simplify, solve
#Overlapping with Julia: eval, include, 
@giac_var x a b
diff(x^2, x)  # 2*x
expand((a+b)^2)  # a^2+b^2+2*a*b
factor(x^2-1)  # (x-1)*(x+1)
integrate(x^2, x)  # x^3/3
integrate(x^2, x, 0, 1)  # returns
    // ∫ ~= 0.333333333333
    GiacExpr: 1/3
limit(sin(x)/x, x, giac_eval("0"))  # 1
simplify(a + b - a)  # b
solve(x^2 - 1)
solve(x^2 - 1, x)  # list[-1,1]
```

### Available Functions

| TempApi Function | Delegates To | Description |
|-----------------|--------------|-------------|
| `diff(expr, var, n=1)` | `giac_diff` | Differentiate expression |
| `integrate(expr, var)` | `giac_integrate` | Indefinite integral |
| `integrate(expr, var, a, b)` | `giac_integrate` | Definite integral |
| `limit(expr, var, point)` | `giac_limit` | Compute limit |
| `factor(expr)` | `giac_factor` | Factor polynomial |
| `expand(expr)` | `giac_expand` | Expand expression |
| `simplify(expr)` | `giac_simplify` | Simplify expression |
| `solve(expr, var)` | `giac_solve` | Solve equation |

### Usage Patterns

```julia
using Giac

# 1. Selective import (recommended)
using Giac.TempApi: diff, factor, integrate, limit

@giac_var x
expr = giac_eval("x^2 - 1")

diff(expr, x)           # 2*x
factor(expr)            # (x-1)*(x+1)
integrate(expr, x)      # x^3/3-x
limit(giac_eval("sin(x)/x"), x, giac_eval("0"))  # 1

# 2. Qualified access
Giac.TempApi.diff(expr, x)
Giac.TempApi.factor(expr)
```

### Comparison: TempApi vs giac_* vs Commands

| Pattern | Import | Usage | Best For |
|---------|--------|-------|----------|
| TempApi | `using Giac.TempApi` | `diff(expr, x)` | Clean, simple names for common operations |
| giac_* | `using Giac` | `giac_diff(expr, x)` | Main module, explicit prefixes |
| Commands | `using Giac.Commands` | `diff(expr, x)` | Access to ALL 2200+ GIAC commands |

**Note**: Both TempApi and Commands export `diff`, `factor`, etc. Use selective imports to avoid conflicts, or choose one submodule based on your needs.

### Commands That Conflict with Julia

Some GIAC commands have the same name as Julia built-ins. These are **not exported** from `Giac.Commands` to avoid shadowing Julia's functions:

| Category | Conflicting Commands |
|----------|---------------------|
| Keywords | `if`, `for`, `while`, `end`, `in`, `or`, `and`, `not` |
| Builtins | `eval`, `float`, `sum`, `prod`, `collect`, `abs`, `sign` |
| Math | `sin`, `cos`, `tan`, `exp`, `log`, `sqrt`, `gcd`, `lcm` |
| LinearAlgebra | `det`, `inv`, `trace`, `rank`, `transpose`, `norm` |
| Statistics | `mean`, `median`, `var`, `std` |

Use `invoke_cmd(:name, args...)` for these commands. A warning is shown on first use to remind you:

```julia
invoke_cmd(:eval, giac_eval("2+3"))
# ┌ Warning: GIAC command 'eval' conflicts with Julia (builtin).
# │ Use invoke_cmd(:eval, args...) to call it.
```