### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ b2c3d4e5-f6a7-8901-bcde-f12345678901
begin
	using Pkg
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	Pkg.develop(PackageSpec(path=".."))

	using Giac
	using Giac.Commands
	using LinearAlgebra
end

# ╔═╡ a1b2c3d4-e5f6-7890-abcd-ef1234567890
md"""
# GIAC LaTeX Rendering Demo

This notebook demonstrates how GIAC expressions automatically render as LaTeX in Pluto.

Giac.jl implements `Base.show(io, ::MIME"text/latex", expr::GiacExpr)` which means expressions display beautifully without any extra code!
"""

# ╔═╡ c3d4e5f6-a7b8-9012-cdef-123456789012
md"""
## Creating a Mathematical Expression

Let's define the expression ``\frac{2}{1-x}`` using GIAC's `giac_eval` function.
"""

# ╔═╡ 1215212c-c55f-4e1c-9b54-ac2141fd7577
@giac_var x

# ╔═╡ 92f3eda7-781f-4dff-9698-47a375e22139
f = 2 / (1 - x)

# ╔═╡ e5f6a7b8-c9d0-1234-efab-345678901234
md"""
The expression above is automatically rendered as LaTeX! No conversion needed.
"""

# ╔═╡ c9d0e1f2-a3b4-5678-cdef-789012345678
md"""
---

## Computing the Derivative

GIAC can compute symbolic derivatives using `giac_diff`. Let's find the derivative with respect to ``x``.
"""

# ╔═╡ e1f2a3b4-c5d6-7890-efab-901234567890
df = diff(f, x)

# ╔═╡ f2a3b4c5-d6e7-8901-fabc-012345678901
md"""
The derivative is also automatically displayed as LaTeX!
"""

# ╔═╡ a3b4c5d6-e7f8-9012-abcd-123456789012
md"""
## Matrices Too!

GiacMatrix also renders as LaTeX:
"""

# ╔═╡ b4c5d6e7-f8a9-0123-bcde-234567890123
@giac_var a b c d

# ╔═╡ c5d6e7f8-a9b0-1234-cdef-345678901234
M = GiacMatrix([[a, b], [c, d]])

# ╔═╡ 54a28ee1-cf11-456c-91c5-def28da697f2
det(M)

# ╔═╡ d6e7f8a9-b0c1-2345-defa-456789012345
md"""
---

## How It Works

Giac.jl defines:
```julia
Base.show(io::IO, ::MIME"text/latex", expr::GiacExpr)
```

This method calls GIAC's `latex` command internally via `invoke_cmd(:latex, expr)` and outputs proper LaTeX that Pluto renders with KaTeX.

You can still manually get the LaTeX string if needed:
"""

# ╔═╡ e7f8a9b0-c1d2-3456-efab-567890123456
latex_str = string(invoke_cmd(:latex, f))

# ╔═╡ f8a9b0c1-d2e3-4567-fabc-678901234567
md"""
---

## Summary

With Giac.jl, mathematical expressions render automatically in Pluto:

1. **Create expressions** with `giac_eval("...")` → displays as LaTeX
2. **Compute derivatives** with `diff(expr, var)` → displays as LaTeX
3. **Create matrices** with `GiacMatrix(...)` → displays as LaTeX

No manual LaTeX conversion needed!
"""

# ╔═╡ a9b0c1d2-e3f4-5678-abcd-789012345678
md"""
> **Note**: If GIAC is running in stub mode (wrapper library not installed), you may see placeholder results. Install the full GIAC library for actual symbolic computation.
"""

# ╔═╡ Cell order:
# ╟─a1b2c3d4-e5f6-7890-abcd-ef1234567890
# ╠═b2c3d4e5-f6a7-8901-bcde-f12345678901
# ╟─c3d4e5f6-a7b8-9012-cdef-123456789012
# ╠═1215212c-c55f-4e1c-9b54-ac2141fd7577
# ╠═92f3eda7-781f-4dff-9698-47a375e22139
# ╟─e5f6a7b8-c9d0-1234-efab-345678901234
# ╟─c9d0e1f2-a3b4-5678-cdef-789012345678
# ╠═e1f2a3b4-c5d6-7890-efab-901234567890
# ╟─f2a3b4c5-d6e7-8901-fabc-012345678901
# ╟─a3b4c5d6-e7f8-9012-abcd-123456789012
# ╠═b4c5d6e7-f8a9-0123-bcde-234567890123
# ╠═c5d6e7f8-a9b0-1234-cdef-345678901234
# ╠═54a28ee1-cf11-456c-91c5-def28da697f2
# ╟─d6e7f8a9-b0c1-2345-defa-456789012345
# ╠═e7f8a9b0-c1d2-3456-efab-567890123456
# ╟─f8a9b0c1-d2e3-4567-fabc-678901234567
# ╟─a9b0c1d2-e3f4-5678-abcd-789012345678
