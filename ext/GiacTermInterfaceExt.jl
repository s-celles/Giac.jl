# Extension module for TermInterface.jl integration.
#
# Implements TermInterface's isexpr / head / children / iscall / operation /
# arguments / maketerm methods for `GiacExpr`, so that downstream packages
# built on TermInterface (Metatheory.jl, SymbolicUtils.jl, …) can traverse and
# rewrite Giac expressions as syntax trees.
#
# The core methods are defined in `Giac` itself (introspection.jl) so that
# `Giac.iscall(expr)` etc. always work without an extra dependency. This
# extension just bridges those into TermInterface's namespace when the user
# has TermInterface loaded.
#
# TRAVERSAL CAVEAT. A Giac numeric literal is a `GiacExpr`, not a `Number`:
# `giac_eval("42") isa Number` is `false`, and `to_julia` is what unwraps it.
# A walk written over the three cases Number / symbol / call therefore *looks*
# exhaustive while silently dropping every literal. Dispatch on `isexpr` (or
# `iscall`) and treat whatever is left as a leaf, unwrapping it with
# `to_julia`. The same shape bit SymbolicUtils.jl — see
# JuliaSymbolics/SymbolicUtils.jl#1024.

module GiacTermInterfaceExt

using Giac
using TermInterface

TermInterface.iscall(g::GiacExpr)::Bool = Giac.iscall(g)

TermInterface.operation(g::GiacExpr) = Giac.operation(g)

TermInterface.arguments(g::GiacExpr)::Vector{GiacExpr} = Giac.arguments(g)

# `iscall` and `isexpr` typically agree for languages without explicit
# `term`-vs-`call` distinction. Giac doesn't carry that distinction either.
TermInterface.isexpr(g::GiacExpr)::Bool = Giac.iscall(g)

# `head`/`children` are not optional. TermInterface's `iscall` docstring
# requires them wherever `isexpr` is true, and without them a consumer written
# against the protocol's documented spelling hit a `MethodError` exactly where
# `operation`/`arguments` would have answered (issue #41).
#
# Giac is a language in which every expression node is a function call, so the
# two spellings coincide — the case TermInterface's own docstring describes for
# SymbolicUtils-like languages, as against `Expr(:call, :f, :x)` whose `head`
# is `:call` while its `operation` is `:f`.
#
# On a leaf — an identifier, a literal, a constant — `isexpr` is false, so the
# protocol does not require these to answer. They raise the same
# `ArgumentError` that `operation`/`arguments` raise rather than inventing a
# head for a node that has none.
#
# `sorted_children` needs no method here: TermInterface defaults it to
# `children`, and Giac stores its arguments in order, so the default already
# gives the deterministic answer that spelling promises.
TermInterface.head(g::GiacExpr) = Giac.operation(g)

TermInterface.children(g::GiacExpr)::Vector{GiacExpr} = Giac.arguments(g)

# Reconstruct an expression from an op + args. Mirrors the in-core helper.
TermInterface.maketerm(::Type{<:GiacExpr}, op, args, metadata=nothing)::GiacExpr =
    Giac.maketerm(GiacExpr, op, args, metadata)

end # module GiacTermInterfaceExt
