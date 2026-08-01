# TermInterface.jl Integration

Giac.jl implements [TermInterface.jl](https://github.com/JuliaSymbolics/TermInterface.jl)'s
expression protocol for `GiacExpr`, so packages built on it —
[Metatheory.jl](https://github.com/JuliaSymbolics/Metatheory.jl),
[SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl), and
anything else that speaks the protocol — can traverse and rewrite Giac
expressions as syntax trees.

It is an optional package extension: it loads as soon as `TermInterface` is in
scope, and costs nothing otherwise.

```julia
using Giac, TermInterface

@giac_var x
e = sin(x + 1)

iscall(e)       # true
operation(e)    # sin
arguments(e)    # GiacExpr[x+1]
head(e)         # sin
children(e)     # GiacExpr[x+1]
```

## The protocol, as Giac implements it

| TermInterface | `GiacExpr` behaviour |
|---|---|
| `isexpr(g)` | `true` for a function-call node, `false` for a leaf |
| `iscall(g)` | same as `isexpr` — see below |
| `head(g)` | the called function; same as `operation` |
| `children(g)` | the arguments; same as `arguments` |
| `operation(g)` | the called function, resolved in `Giac.Commands`, `Giac`, `Base` or `LinearAlgebra` |
| `arguments(g)` | `Vector{GiacExpr}` of the operands |
| `sorted_children(g)` | TermInterface's default, which forwards to `children` |
| `maketerm(GiacExpr, op, args)` | rebuilds an expression from an operation and its arguments |

Giac is a language in which **every expression node is a function call**, so
`head`/`children` and `operation`/`arguments` coincide, and `isexpr` and
`iscall` agree. TermInterface's own documentation names this case: the two
spellings diverge only in languages that do not represent a call in their
head, such as Julia's `Expr(:call, :f, :x)`, whose `head` is `:call` while its
`operation` is `:f`.

On a leaf — an identifier, a literal, a constant — `isexpr` is `false`, so the
protocol does not require `head`/`children` to answer. They raise an
`ArgumentError`, exactly as `operation`/`arguments` do, rather than inventing a
head for a node that has none.

```julia
julia> head(giac_eval("x"))
ERROR: ArgumentError: expression is not a function call
```

## Writing a traversal: literals are not `Number`s

A Giac numeric literal is a `GiacExpr`, **not** a `Number`:

```julia
julia> giac_eval("42") isa Number
false

julia> to_julia(giac_eval("42"))
42
```

A walk written over the three cases `Number` / symbol / call therefore *looks*
exhaustive while silently dropping every literal. Dispatch on `isexpr` (or
`iscall`) and treat whatever is left as a leaf, unwrapping it with `to_julia`:

```julia
using Giac, TermInterface

function leaves(e)
    isexpr(e) || return [to_julia(e)]
    return reduce(vcat, leaves(c) for c in children(e))
end

leaves(giac_eval("2*x+3"))   # Any[2, x, 3] — the literals are there
```

The same shape caught SymbolicUtils.jl; see
[JuliaSymbolics/SymbolicUtils.jl#1024](https://github.com/JuliaSymbolics/SymbolicUtils.jl/issues/1024).

## Rebuilding expressions

`maketerm` closes the loop, so a rewrite can put a tree back together:

```julia
using Giac, TermInterface

@giac_var x
e = sin(x + 1)
rebuilt = maketerm(GiacExpr, operation(e), Tuple(arguments(e)))
string(rebuilt) == string(e)   # true
```
