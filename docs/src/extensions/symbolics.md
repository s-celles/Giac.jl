# Symbolics.jl Integration

```julia
using Giac, Symbolics

@variables x y
giac_expr = to_giac(x^2 + 2*x + 1)
factored = invoke_cmd(:factor, giac_expr)  # (x+1)^2
sym_result = to_symbolics(factored)  # Num: (1+x)^2
```