### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000001
begin
	using Pkg
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	Pkg.develop(PackageSpec(path=".."))

	using Giac
	using Giac.Commands

	using PlutoUI
	using Plots
	plotlyjs()
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
@giac_var x y z a b c

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000004
typeof(x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000005
md"""
Symbolic variables support standard arithmetic operators. Expressions are built lazily — no evaluation happens until you ask for it.
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000006
# ╠═╡ disabled = true
#=╠═╡
expr = x^2 + 2*x*y + y^2
  ╠═╡ =#

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

# ╔═╡ ca8643a8-ec11-411d-ad5b-2f0e06eca927
md"""Let's factorize this polynomial"""

# ╔═╡ 3e96d232-3daa-4af5-99eb-f753c189d7f7
hold_cmd(:factor, x^4 - 1)

# ╔═╡ 975357e4-95ab-4e93-99a2-fa1ddbe312b2
factor(x^4 - 1)

# ╔═╡ 98a772aa-d6ee-4620-805a-b4d5dbea32fa
md"""And this one also"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000033
hold_cmd(:factor, x^4 + 12*x^3 + 54*x^2 + 108*x + 81) ~ factor(x^4 + 12*x^3 + 54*x^2 + 108*x + 81)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000034
md"""
### `expand` — Distribute multiplication over addition
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000035
hold_cmd(:expand, (x + y) * (z + 1)) ~ expand((x + y) * (z + 1))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000036
hold_cmd(:expand, (x + 3)^4) ~ expand((x + 3)^4)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000037
md"""
### `simplify` — Simplify an expression
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000038
giac_eval("4*atan(1/5) - atan(1/239)") ~ simplify(giac_eval("4*atan(1/5) - atan(1/239)"))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000039
md"""
### `collect` — Collect like terms
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000003a
hold_cmd(:collect, x^2 - 9*x + 5*x + 3 + 1) ~ collect(x^2 - 9*x + 5*x + 3 + 1)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000040
md"""
---

## 5. Calculus

### Differentiation with `diff`
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000041
hold_cmd(:diff, x^3 - x, x) ~ diff(x^3 - x, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000042
md"""
Higher-order derivatives:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000043
hold_cmd(:diff, x^3 - x, x, 2) ~ diff(x^3 - x, x, 2)  # Second derivative

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000044
md"""
Multivariate derivatives:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000045
hold_cmd(:diff, exp(x*y), x) ~ diff(exp(x*y), x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000046
md"""
### Integration with `integrate`

Indefinite integral:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000047
hold_cmd(:integrate, x^2, x)

# ╔═╡ cc66e884-9920-41a4-a583-b72283d8e282
integrate(x^2, x)

# ╔═╡ 86928574-b2d9-42da-8803-5154dfceaa3b
hold_cmd(:integrate, 1/x, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000048
integrate(1/x, x)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000049
md"""
Definite integral with bounds:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000004a
hold_cmd(:integrate, x^2, x, 0, 1) ~ integrate(x^2, x, 0, 1)

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-10000000004b
hold_cmd(:integrate, 1/(1-x^4), x, 2, 3) ~ integrate(1/(1-x^4), x, 2, 3)

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
hold_cmd(:solve, eq, x) ~ solve(eq, x)

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
hold_cmd(:solve, system, [x,y,z])

# ╔═╡ a2099ebb-ed5c-43dc-9a1d-026095cccd59
solve(system, [x,y,z])

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000056
md"""
### Numerical solving with `fsolve`
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000057
hold_cmd(:fsolve, cos(x) ~ x, x) ~ fsolve(cos(x) ~ x, x)

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
hold_cmd(:partfrac, x / (4 - x^2)) ~ partfrac(x / (4 - x^2))

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000063
md"""
### Integer factorization
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000064
hold_cmd(:ifactors, 120) ~ ifactors(120)

# ╔═╡ 1cebf4e2-5038-4164-a5cc-815a431906de
md"""
### Julia functions from a `GiacExpr`

You can define a Julia function from a `GiacExpr` using `substitute`:
"""

# ╔═╡ 637ee8a7-c218-4086-8a8b-a676ab885895
expr = a * x^2 + b * x + c

# ╔═╡ 0ffcd6e9-12ff-4c08-af41-70427e14fd84
begin
	slider_a = @bind _a Slider(-10:0.1:10, default=1, show_value=true)
	slider_b = @bind _b Slider(-10:0.1:10, default=1, show_value=true)
	slider_c = @bind _c Slider(-10:0.1:10, default=-2, show_value=true)
	md""
end

# ╔═╡ 2fe0843c-1ed1-4a7e-aaa9-d30c8c8998af


# ╔═╡ 89755bd7-174c-42e3-9764-c2c6dd02c529
num_expr = substitute(expr, Dict(a => _a, b => _b, c => _c))

# ╔═╡ df72e3d0-2118-4853-a9b1-a1398a0d6f4c
f(_x) = to_julia(substitute(num_expr, x => _x))

# ╔═╡ fa02ef0c-9870-43ea-a906-894bb383dd94
begin
	_x = range(-10, 10, length=100)
	Plots.plot(_x, f.(_x))
end

# ╔═╡ d42fefb3-f65d-404b-bd86-f4ae7f011844
md"""
a= $slider_a

b= $slider_b

c= $slider_c
"""


# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000065
md"""
### GIAC programs

You can write multi-line GIAC programs using string evaluation:
"""

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000066
giac_eval("""
  mysqcu := proc(x)
	if x > 0 then
	  x^2
	else
	  x^3
	fi
  end
""");

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000067
giac_eval("mysqcu(5)")

# ╔═╡ a0b1c2d3-e4f5-6789-abcd-100000000068
giac_eval("mysqcu(-5)")

# ╔═╡ bee4b6d5-d4a5-479f-b564-be5ddca74e74
begin
	g(_x) = giac_eval("mysqcu($_x)") |> to_julia
	_y = g.(collect(_x))
	Plots.plot(_x, _y)
end

# ╔═╡ 22bc7d82-d9e3-4a4e-a631-d7f6d1a7a834
begin
	function plot3d()
		# Function z = f(x, y)
		expr = sin(√(a * x^2 + b * y^2)) * cos(x/2)
		num_expr = substitute(expr, Dict(a => _a, b => _b))
		f(_x, _y) = to_julia(substitute(num_expr, Dict(x => _x, y => _y)))

		# Define grid
		x_ = range(-3, 3, length=100)
		y_ = range(-3, 3, length=100)
		
		# Draw surface
		surface(x_, y_, f,
		    xlabel = "x", ylabel = "y", zlabel = "z",
		    title = "Surface z = $num_expr",
		    colorbar = true,
		    camera = (30, 45),       # viewing angle (azimuth, elevation)
		    color = :viridis,        # color palette
		    size = (800, 600)
		)
	end

	plot3d()
end

# ╔═╡ dbaed88e-2bbc-403a-92dd-ad9f8c613fbc
md"""
a= $slider_a

b= $slider_b
"""

# ╔═╡ 1f0ce723-24eb-4214-ae11-8f8d96286e5b
begin
	function plot_vector_field()
		dx = 0.1
		sc = 0.1
	    expr = a*x^2 - b*y^2
	    grad_x = diff(expr, x)
	    grad_y = diff(expr, y)
	
	    d_subs = Dict(a => _a, b => _b)
	    num_expr   = substitute(expr, d_subs)
	    num_grad_x = substitute(grad_x, d_subs)
	    num_grad_y = substitute(grad_y, d_subs)
	
	    V(xv, yv)  = to_julia(substitute(num_expr,   Dict(x => xv, y => yv)))
	    fu(xv, yv) = to_julia(substitute(num_grad_x, Dict(x => xv, y => yv)))
	    fv(xv, yv) = to_julia(substitute(num_grad_y, Dict(x => xv, y => yv)))
	
	    xr = -2:dx:2      # dx instead of step
	    yr = -2:dx:2
	    xx = [xi for xi in xr, yi in yr][:]
	    yy = [yi for xi in xr, yi in yr][:]
	
	    u = fu.(xx, yy)
	    v = fv.(xx, yy)
	
	    xf = range(-2, 2, length=100)
	    yf = range(-2, 2, length=100)
	
	    contourf(xf, yf, V, levels=15, color=:coolwarm, alpha=0.5,
	        aspect_ratio=:equal, size=(650, 600))
	
		s = sc / maximum(sqrt.(u.^2 + v.^2))
		quiver!(xx, yy, quiver=(s .* u, s .* v),
			color=:black, lw=1.2,
			title="Gradient field of $(_a)x² - $(_b)y²")
	end
	
	plot_vector_field()
end

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
# ╟─ca8643a8-ec11-411d-ad5b-2f0e06eca927
# ╟─3e96d232-3daa-4af5-99eb-f753c189d7f7
# ╟─975357e4-95ab-4e93-99a2-fa1ddbe312b2
# ╟─98a772aa-d6ee-4620-805a-b4d5dbea32fa
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
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000047
# ╠═cc66e884-9920-41a4-a583-b72283d8e282
# ╟─86928574-b2d9-42da-8803-5154dfceaa3b
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
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000055
# ╠═a2099ebb-ed5c-43dc-9a1d-026095cccd59
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000056
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000057
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000060
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000061
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000062
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000063
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000064
# ╟─1cebf4e2-5038-4164-a5cc-815a431906de
# ╠═637ee8a7-c218-4086-8a8b-a676ab885895
# ╠═0ffcd6e9-12ff-4c08-af41-70427e14fd84
# ╠═2fe0843c-1ed1-4a7e-aaa9-d30c8c8998af
# ╠═89755bd7-174c-42e3-9764-c2c6dd02c529
# ╠═df72e3d0-2118-4853-a9b1-a1398a0d6f4c
# ╠═fa02ef0c-9870-43ea-a906-894bb383dd94
# ╠═d42fefb3-f65d-404b-bd86-f4ae7f011844
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000065
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000066
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000067
# ╠═a0b1c2d3-e4f5-6789-abcd-100000000068
# ╠═bee4b6d5-d4a5-479f-b564-be5ddca74e74
# ╠═22bc7d82-d9e3-4a4e-a631-d7f6d1a7a834
# ╟─dbaed88e-2bbc-403a-92dd-ad9f8c613fbc
# ╟─1f0ce723-24eb-4214-ae11-8f8d96286e5b
# ╟─a0b1c2d3-e4f5-6789-abcd-100000000069
