### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000001
begin
	using Giac
	using Giac.Commands
end

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000000
md"""
# Programming in the GIAC Language

Beyond single-expression evaluation, GIAC has its own programming language with control flow (`if/then/else`, `for`, `while`) and user-defined procedures. Access it from Julia through `giac_eval` with a multi-line string.
"""

# ╔═╡ 3bd303ff-74f7-40e9-a3f4-ff5c62133b3f
# ╠═╡ disabled = true
#=╠═╡
begin
	#using Pkg
	#Pkg.add("Giac")
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	#Pkg.develop(PackageSpec(path=".."))
end
  ╠═╡ =#

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000002
md"""
---

## 1. Defining a procedure

Use `proc(args) ... end` to define a GIAC procedure. The trailing `;` on the Julia side suppresses the proc listing in the cell output:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000003
giac_eval("""
  mysqcu := proc(x)
	if x > 0 then
	  x^2
	else
	  x^3
	fi
  end
""");

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000004
md"""
Now call the procedure from Julia, again via `giac_eval`:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000005
giac_eval("mysqcu(5)")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000006
giac_eval("mysqcu(-5)")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000007
md"""
---

## 2. Calling a GIAC procedure from Julia

Wrap the `giac_eval` call in a Julia function to interpolate an argument and convert the result back to a native Julia value with `to_julia`:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000008
g(v) = giac_eval("mysqcu($v)") |> to_julia

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000009
g(3)

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-30000000000a
g(-2)

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000010
md"""
---

## 3. Loops and accumulators

GIAC supports `for` loops and local variables. Example — sum the first *n* squares:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000011
giac_eval("""
  sum_of_squares := proc(n)
	local s, k;
	s := 0;
	for k from 1 to n do
	  s := s + k^2;
	od;
	s
  end
""");

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000012
giac_eval("sum_of_squares(10)")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000013
md"""
Compare with the closed form $\frac{n(n+1)(2n+1)}{6}$ for n = 10:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000014
giac_eval("10 * 11 * 21 / 6")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000099
md"""
---

## Summary

| Construct | GIAC syntax |
|-----------|-------------|
| Procedure | `name := proc(args) ... end` |
| Conditional | `if cond then ... else ... fi` |
| For loop | `for k from a to b do ... od` |
| Local var | `local x, y;` |
| Call from Julia | `giac_eval("name(arg)")` |
| Result to Julia | `to_julia(...)` |

See `01_basics.jl` for the symbolic API, and `04_plotting.jl` for plotting `GiacExpr` values.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Giac = "e4421f97-9838-4fd0-9fa5-94f11373bf78"

[compat]
Giac = "~0.14.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "2fc8c6e70d5aa2047f3a6c9e77ecfc46f96098ac"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.CommonSolve]]
git-tree-sha1 = "78ea4ddbcf9c241827e7035c3a03e2e456711470"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.6"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.CxxWrap]]
deps = ["Libdl", "MacroTools", "libcxxwrap_julia_jll"]
git-tree-sha1 = "f7a997d3959648a818c45dda059a45844300b94d"
uuid = "1f15a43c-97ca-5a2a-ae31-89f07a497df4"
version = "0.17.5"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.GIAC_jll]]
deps = ["Artifacts", "GMP_jll", "Gettext_jll", "JLLWrappers", "Libdl", "MPFR_jll", "Readline_jll"]
git-tree-sha1 = "3bbf55cfc68a6d673257a876889e0c1425011b0d"
uuid = "cf749d6c-42f5-550d-8800-4812740c2942"
version = "2.0.1+0"

[[deps.GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"
version = "6.3.0+2"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Giac]]
deps = ["CommonSolve", "CxxWrap", "GIAC_jll", "Libdl", "LinearAlgebra", "Tables", "libcxxwrap_julia_jll", "libgiac_julia_jll"]
git-tree-sha1 = "89dd61ed83bf686cfc68b280416b32cc541e1bf5"
uuid = "e4421f97-9838-4fd0-9fa5-94f11373bf78"
version = "0.14.0"

    [deps.Giac.extensions]
    GiacMathJSONExt = "MathJSON"
    GiacSymbolicsExt = "Symbolics"
    GiacTermInterfaceExt = "TermInterface"

    [deps.Giac.weakdeps]
    MathJSON = "77215b4b-6f01-425c-beac-950ae6536d4d"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    TermInterface = "8ea1fca8-c5ef-4a55-8b96-4e9afe9c9a3c"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MPFR_jll]]
deps = ["Artifacts", "GMP_jll", "Libdl"]
uuid = "3a97d323-0669-5f0c-9066-3539efd106a3"
version = "4.2.2+0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.Ncurses_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "095850bc2a585bb20cad8d8f6f9f643d11b49a3d"
uuid = "68e3532b-a499-55ff-9963-d1c0c0748b3a"
version = "6.6.0+2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Readline_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ncurses_jll"]
git-tree-sha1 = "5d26d91800500cd67d4743cdbb59749e46ed726b"
uuid = "05236dd9-4125-5232-aa7c-9ec0c9b2c25a"
version = "8.3.3+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "80d3930c6347cfce7ccf96bd3bafdf079d9c0390"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.9+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.libcxxwrap_julia_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a0b6eb05dde4ededa688ecf05e33caa5bffd42a5"
uuid = "3eaa8342-bff7-56a5-9981-c04077f7cee7"
version = "0.14.9+0"

[[deps.libgiac_julia_jll]]
deps = ["Artifacts", "GIAC_jll", "GMP_jll", "JLLWrappers", "Libdl", "MPFR_jll", "libcxxwrap_julia_jll"]
git-tree-sha1 = "0dd61605b4e1b3d39d2b79722e2c1a9c88dd3360"
uuid = "ec39d2da-6bdf-580b-ada4-cd6e059515c9"
version = "0.5.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"
"""

# ╔═╡ Cell order:
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000000
# ╟─3bd303ff-74f7-40e9-a3f4-ff5c62133b3f
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000001
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000002
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000003
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000004
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000005
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000006
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000007
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000008
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000009
# ╠═c1d2e3f4-a5b6-7890-abcd-30000000000a
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000010
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000011
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000012
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000013
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000014
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000099
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
