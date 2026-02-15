# TempApi Submodule

```@docs
Giac.TempApi
```

The `Giac.TempApi` submodule provides convenience functions with simplified names
for common symbolic computation operations.

## Usage

### Selective Import (Recommended)

```julia
using Giac
using Giac.TempApi: diff, factor, integrate

x = giac_eval("x")
expr = giac_eval("x^2 - 1")
diff(expr, x)     # 2*x
factor(expr)      # (x-1)*(x+1)
```

### Full Import

```julia
using Giac
using Giac.TempApi

x = giac_eval("x")
diff(giac_eval("x^3"), x)  # 3*x^2
```

## Calculus Functions

```@docs
Giac.TempApi.diff
Giac.TempApi.integrate
Giac.TempApi.limit
```

## Algebra Functions

```@docs
Giac.TempApi.factor
Giac.TempApi.expand
Giac.TempApi.simplify
Giac.TempApi.solve
```
