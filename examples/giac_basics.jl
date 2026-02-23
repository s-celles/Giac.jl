### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000001
begin
	using Pkg
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	Pkg.develop(PackageSpec(path=".."))

	using Giac
	using Giac.Commands
end

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000000
md"""
# Giac.jl Basics

A beginner's guide to symbolic computation in Julia with Giac.jl.

This notebook covers the fundamentals: creating symbolic variables, building expressions, performing calculus, and solving equations — all using the `Giac.Commands` API.

> **Note**: If GIAC is running in stub mode (wrapper library not installed), you may see placeholder results. Install the full GIAC library for actual symbolic computation.
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000002
md"""
---

## 1. Symbolic Variables

Use the `@giac_var` macro to create symbolic variables. These are `GiacExpr` objects that represent mathematical symbols.
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000003
@giac_var x y z

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000004
typeof(x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000005
md"""
Symbolic variables support standard arithmetic operators. Expressions are built lazily — no evaluation happens until you ask for it.
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000006
expr = x^2 + 2*x*y + y^2

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000007
md"""
You can also mix Julia numbers with symbolic variables:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000008
3*x + 1

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000009
2 / (1 - x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000000a
exp(x) * sin(x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000010
md"""
---

## 2. Type Conversion

### From Julia to GIAC

Use `giac_eval` to parse a string into a GIAC expression. This is useful when Julia would otherwise evaluate the expression numerically first.
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000011
md"""
For example, `sqrt(2)` in Julia gives a floating-point number:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000012
sqrt(2)  # Julia evaluates this to a Float64

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000013
md"""
But `giac_eval("sqrt(2)")` keeps it symbolic:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000014
giac_eval("sqrt(2)")

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000015
md"""
Alternatively, apply `sqrt` to a GIAC expression:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000016
sqrt(giac_eval("2"))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000017
md"""
### From GIAC to Julia

Use `to_julia` to convert a GIAC expression back to a native Julia type:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000018
begin
	val = giac_eval("17 + 25")
	julia_val = to_julia(val)
	(julia_val, typeof(julia_val))
end

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000019
md"""
`to_julia` handles integers, floats, rationals, complex numbers, booleans, and vectors:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000001a
to_julia(giac_eval("[1, 2, 3, 4, 5]"))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000020
md"""
---

## 3. Arbitrary-Precision Arithmetic

Julia's `Int64` overflows for large numbers:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000021
2^63  # Overflow!

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000022
md"""
GIAC handles arbitrary-precision arithmetic natively:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000023
giac_eval("2")^200

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000024
md"""
Compare with Julia's `BigInt`:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000025
BigInt(2)^200

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000026
md"""
You can convert GIAC big integers back to Julia `BigInt`:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000027
begin
	big_giac = giac_eval("2")^200
	big_julia = to_julia(big_giac)
	(big_julia, typeof(big_julia))
end

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000030
md"""
---

## 4. Polynomial Operations

GIAC provides powerful polynomial manipulation through `Giac.Commands`:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000031
md"""
### `factor` — Factorize a polynomial
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000032
factor(x^4 - 1)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000033
factor(x^4 + 12*x^3 + 54*x^2 + 108*x + 81)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000034
md"""
### `expand` — Distribute multiplication over addition
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000035
expand((x + y) * (z + 1))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000036
expand((x + 3)^4)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000037
md"""
### `simplify` — Simplify an expression
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000038
simplify(giac_eval("4*atan(1/5) - atan(1/239)"))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000039
md"""
### `collect` — Collect like terms
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000003a
collect(x^2 - 9*x + 5*x + 3 + 1)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000040
md"""
---

## 5. Calculus

### Differentiation with `diff`
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000041
diff(x^3 - x, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000042
md"""
Higher-order derivatives:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000043
diff(x^3 - x, x, 2)  # Second derivative

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000044
md"""
Multivariate derivatives:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000045
diff(exp(x*y), x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000046
md"""
### Integration with `integrate`

Indefinite integral:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000047
integrate(x^2, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000048
integrate(1/x, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000049
md"""
Definite integral with bounds:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000004a
integrate(x^2, x, 0, 1)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000004b
integrate(giac_eval("1/(1-x^4)"), x, 2, 3)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000050
md"""
---

## 6. Equation Solving

Create equations using the `~` operator and solve with `solve`:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000051
md"""
### Simple equation
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000052
eq = x^2 - 3 ~ 1

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000053
solve(eq, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000054
md"""
### System of equations
"""

# ╔═╡ 5da29e53-fda6-4ef9-90b0-e20e42879c70
system = [
	y - z ~ 0, 
	z - x ~ 0, 
	x - y ~ 0,
	x - 1 + y + z ~ 0
]

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000055
solve(system, [x,y,z])

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000056
md"""
### Numerical solving with `fsolve`
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000057
fsolve(cos(x) ~ x, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000060
md"""
---

## 7. String-Based Evaluation

For complex operations or features that don't have a direct Julia API, use `giac_eval` with a string:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000061
md"""
### Partial fraction decomposition
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000062
partfrac(x / (4 - x^2))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000063
md"""
### Integer factorization
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000064
ifactors(120)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000065
md"""
### Giac programs (ToFix)

You can write multi-line GIAC programs using string evaluation:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000066
begin
	mysqcu = giac_eval("""
	  proc(x)
	    if x > 0 then
	      x^2
	    else
	      x^3
	    fi
	  end
	""")
	(mysqcu, typeof(mysqcu))
end

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000067
giac_eval("mysqcu(5)")

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000068
giac_eval("mysqcu(-5)")

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000069
md"""
---

## Summary

| Feature | How to use |
|---------|------------|
| Create variables | `@giac_var x y z` |
| Build expressions | `x^2 + 2*x + 1` (operator overloading) |
| Parse strings | `giac_eval("sqrt(2)")` |
| Convert to Julia | `to_julia(expr)` |
| Factor | `factor(expr)` |
| Expand | `expand(expr)` |
| Simplify | `simplify(expr)` |
| Differentiate | `diff(expr, x)` |
| Integrate | `integrate(expr, x)` or `integrate(expr, x, a, b)` |
| Solve | `solve(eq, x)` |

All commands are available via `using Giac.Commands`.
"""

# ╔═╡ Cell order:
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000000
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000001
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000002
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000003
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000004
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000005
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000006
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000007
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000008
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000009
# ╠═a0b1c2d3-e4f5-6789-abcd-10000000000a
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000010
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000011
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000012
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000013
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000014
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000015
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000016
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000017
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000018
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000019
# ╠═a0b1c2d3-e4f5-6789-abcd-10000000001a
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000020
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000021
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000022
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000023
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000024
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000025
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000026
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000027
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000030
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000031
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000032
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000033
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000034
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000035
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000036
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000037
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000038
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000039
# ╠═a0b1c2d3-e4f5-6789-abcd-10000000003a
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000040
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000041
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000042
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000043
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000044
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000045
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000046
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000047
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000048
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000049
# ╠═a0b1c2d3-e4f5-6789-abcd-10000000004a
# ╠═a0b1c2d3-e4f5-6789-abcd-10000000004b
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000050
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000051
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000052
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000053
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000054
# ╠═5da29e53-fda6-4ef9-90b0-e20e42879c70
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000055
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000056
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000057
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000060
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000061
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000062
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000063
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000064
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000065
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000066
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000067
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000068
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000069
