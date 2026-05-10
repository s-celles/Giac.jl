### A Pluto.jl notebook ###
# v0.20.24

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

# ╔═╡ 041f89da-c388-4a22-8ee5-6bf98b2382f8
# ╠═╡ disabled = true
#=╠═╡
begin
    import Pkg
    Pkg.activate(dirname(@__FILE__))  # activates the notebook environment
    # Remove the overly strict constraint on Giac
    Pkg.compat("Giac", "0.14")
    Pkg.update("Giac")
end
  ╠═╡ =#

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000001
begin
	using Giac
	using Giac.Commands
	using PlutoUI
	using Plots
	plotly()
end

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000000
md"""
# Giac.jl Plotting

Turn symbolic `GiacExpr` values into Julia functions and plot them with `Plots.jl`.

The bridge is `substitute` (to plug in numeric parameters) and `to_julia` (to convert the result to a native Julia number that `Plots` understands).
"""

# ╔═╡ bea8e64f-24ef-4e05-84f3-578c669382c5
# ╠═╡ disabled = true
#=╠═╡
begin
    #using Pkg
	#Pkg.add("Giac")
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	#Pkg.develop(PackageSpec(path=".."))
	#Pkg.add("Plots")
	#Pkg.add("PlutoUI")
end
  ╠═╡ =#

# ╔═╡ bb234415-4b3a-45bf-9e87-4fad2d41a6af


# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000002
md"""
---

## 1. Julia functions from a `GiacExpr`

Start with a parametric symbolic expression:
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000003
@giac_var x y a b c

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000004
expr = a * x^2 + b * x + c

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000005
md"""
Bind numeric values for the parameters `a`, `b`, `c` with sliders:
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000006
begin
	slider_a = @bind _a Slider(-10:0.1:10, default=1, show_value=true)
	slider_b = @bind _b Slider(-10:0.1:10, default=1, show_value=true)
	slider_c = @bind _c Slider(-10:0.1:10, default=-2, show_value=true)
	md""
end

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000007
md"""
a= $slider_a

b= $slider_b

c= $slider_c
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000008
num_expr = substitute(expr, Dict(a => _a, b => _b, c => _c))

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000009
f(_x) = to_julia(substitute(num_expr, x => _x))

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-20000000000a
begin
	_x = range(-10, 10, length=100)
	Plots.plot(_x, f.(_x))
end

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000010
md"""
---

## 2. Surface plot

A 3D surface `z = f(x, y)` built the same way:
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000011
md"""
a= $slider_a

b= $slider_b
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000012
begin
	function plot3d()
		expr = sin(√(a * x^2 + b * y^2)) * cos(x/2)
		num_expr = substitute(expr, Dict(a => _a, b => _b))
		f(_x, _y) = to_julia(substitute(num_expr, Dict(x => _x, y => _y)))

		x_ = range(-3, 3, length=100)
		y_ = range(-3, 3, length=100)

		Plots.surface(x_, y_, f,
			xlabel = "x", ylabel = "y", zlabel = "z",
			title = "Surface z = $num_expr",
			colorbar = true,
			camera = (30, 45),
			color = :viridis,
			size = (800, 600)
		)
	end

	plot3d()
end

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000050
md"""
---

## 2b. Same surface, with `build_function`

`build_function(expr, vars...)` is the named one-liner for exactly the
`substitute` + `to_julia` pattern you saw above. It returns a Julia callable
that you can pass straight to `Plots.surface` (or broadcast over an array,
or use in a comprehension), without writing the wrapper closure by hand.

The two cells below produce visually identical plots — the only difference
is that `build_function` makes the symbolic-to-numeric step a single named
call.
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000051
md"""
a= $slider_a

b= $slider_b
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000052
begin
	function plot3d_build_function()
		expr = sin(√(a * x^2 + b * y^2)) * cos(x/2)
		num_expr = substitute(expr, Dict(a => _a, b => _b))

		# One named call replaces the manual `f(_x, _y) = to_julia(...)` closure.
		f = build_function(num_expr, x, y)

		x_ = range(-3, 3, length=100)
		y_ = range(-3, 3, length=100)

		Plots.surface(x_, y_, f,
			xlabel = "x", ylabel = "y", zlabel = "z",
			title = "Surface (build_function) z = $num_expr",
			colorbar = true,
			camera = (30, 45),
			color = :viridis,
			size = (800, 600)
		)
	end

	plot3d_build_function()
end

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000020
md"""
---

## 3. Gradient vector field

Compute the symbolic gradient with `diff`, then evaluate numerically to draw a vector field overlaid on a contour plot:
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000021
md"""
a= $slider_a

b= $slider_b
"""

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000022
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

		V = build_function(num_expr, x, y)
		fu = build_function(num_grad_x, x, y)
		fv = build_function(num_grad_y, x, y)

		xr = -2:dx:2
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

# ╔═╡ b1c2d3e4-f5a6-7890-abcd-200000000099
md"""
---

## Summary

| Step | How |
|------|-----|
| Numeric parameters | `substitute(expr, Dict(a => _a, b => _b, ...))` |
| Julia-callable function (named) | `f = build_function(num_expr, x)` (or `..., x, y` for multivariate) |
| Julia-callable function (manual) | `f(_x) = to_julia(substitute(num_expr, x => _x))` |
| 1D plot | `Plots.plot(_x, f.(_x))` |
| Surface | `Plots.surface(x_, y_, f)` |
| Vector field | `diff` + `quiver!` over a grid |

See `01_basics.jl` for the symbolic operations, and `05_programming.jl` for multi-line GIAC programs.
"""

# ╔═╡ Cell order:
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000000
# ╟─bea8e64f-24ef-4e05-84f3-578c669382c5
# ╟─041f89da-c388-4a22-8ee5-6bf98b2382f8
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000001
# ╠═bb234415-4b3a-45bf-9e87-4fad2d41a6af
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000002
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000003
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000004
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000005
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000006
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000007
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000008
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000009
# ╠═b1c2d3e4-f5a6-7890-abcd-20000000000a
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000010
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000011
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000012
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000050
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000051
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000052
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000020
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000021
# ╠═b1c2d3e4-f5a6-7890-abcd-200000000022
# ╟─b1c2d3e4-f5a6-7890-abcd-200000000099
