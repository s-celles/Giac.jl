## Quick Start

```julia
using Giac
using Giac.Commands: factor, expand, diff, integrate, limit, simplify, solve

# Check mode
println("Stub mode: ", is_stub_mode())

# Basic evaluation
result = giac_eval("2 + 3")        # 5
factored = giac_eval("factor(x^2 - 1)")  # (x-1)*(x+1)

# Arithmetic
@giac_var x
@giac_var y
println(x + y)   # x+y
println(x * y)   # x*y
println(x ^ 2)   # x^2

# Calculus using Giac.Commands
f = giac_eval("x^3")
df = diff(f, x)                    # 3*x^2
F = integrate(f, x)                # x^4/4
f = giac_eval("sin(x)/x")
lim = limit(f, x, giac_eval("0"))  # 1

# Algebra using Giac.Commands
factor(giac_eval("x^2 - 1"))           # (x-1)*(x+1)
expand(giac_eval("(x+1)^3"))           # x^3+3*x^2+3*x+1
simplify(giac_eval("(x^2-1)/(x-1)"))   # x+1
solve(giac_eval("x^2 - 4"), x)         # list[-2,2]

# Or use invoke_cmd for any command
invoke_cmd(:factor, giac_eval("x^2 - 1"))  # (x-1)*(x+1)

# Convert to Julia types
to_julia(giac_eval("42"))    # 42::Int64
to_julia(giac_eval("3/4"))   # 3//4::Rational{Int64}
```
