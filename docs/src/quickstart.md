## Quick Start

```julia
using Giac
using Giac.Commands: factor, expand, diff, integrate, limit, simplify, solve

# Check mode
println("Stub mode: ", is_stub_mode())

# Basic evaluation through GIAC
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
# or using
f = x^3
df = diff(f, x)                    # 3*x^2
F = integrate(f, x)                # x^4/4
f = sin(x)/x  # or using more heavy syntax giac_eval("sin(x)/x")
lim = limit(f, x, 0)  # 1

# Algebra using Giac.Commands
factor(x^2 - 1)           # (x-1)*(x+1)
expand((x+1)^3)           # x^3+3*x^2+3*x+1
simplify((x^2-1)/(x-1))   # x+1
solve(x^2 - 4, x)         # list[-2,2]

# Equation syntax using ~ operator (Symbolics.jl convention)
eq = x^2 - 1 ~ 0                       # Creates equation: x^2-1=0
solve(eq, x)                           # Solves: [-1, 1]

# ~ works with mixed types
eq1 = x ~ 5                            # x=5
eq2 = 0 ~ x^2 - 4                      # 0=x^2-4

# Or use invoke_cmd for any command
invoke_cmd(:factor, giac_eval("x^2 - 1"))  # (x-1)*(x+1)

# Convert to Julia types
to_julia(giac_eval("42"))    # 42::Int64
to_julia(giac_eval("3/4"))   # 3//4::Rational{Int64}
```
