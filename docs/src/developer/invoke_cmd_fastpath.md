# `invoke_cmd` Fast Path

*Internal documentation. This page describes a routing change inside the
universal command dispatcher; there is no public-API change.*

## What it does

When you call any GIAC command through Giac.jl — `simplify(g)`, `factor(g)`,
`evalf(g, 50)`, `invoke_cmd(:eval, x)`, `giac_cmd(...)`, or any of the
~2000 generated wrappers — the call funnels through `invoke_cmd` in
`src/Commands.jl`.

The historical implementation always:

1. Called `_arg_to_giac_string(arg)` on each argument (printing each `GiacExpr`
   via the C++ `to_string`),
2. Concatenated a GIAC command string like `"factor((x-1)*(x+1)*(x^2+1))"`,
3. Handed the string back to GIAC's parser via `giac_eval`.

So every call performed a full `Gen → C++ to_string → Julia String → GIAC
parser → Gen` round trip before any symbolic work began.

The fast path (spec 069, since v0.14.2-unreleased) skips that round trip when
**every** argument has a direct `Gen` representation. The cached `Gen` is
passed positionally to one of the specialized `apply_func0/1/2/3` bindings,
or — for arity ≥ 4 — wrapped in an `StdVector{Gen}` and passed to
`apply_funcN`. The result `Gen` is wrapped into a `GiacExpr` via the existing
`_make_gen_ptr` registry exactly as the string path does.

## Eligibility rules

The per-call check is `all(_has_direct_gen, args)`. The eligibility predicate
is:

| Argument type | Fast path? | Conversion |
|---------------|------------|------------|
| `GiacExpr` | yes | `_get_gen_or_eval(x)` (reuses cached `Gen`) |
| `Int32` | yes | `GiacCxxBindings.Gen(x)` |
| `Int64` in Int32 range | yes | `GiacCxxBindings.Gen(Int32(x))` (CxxWrap dispatches `Gen(::Int64)` to the `Float64` constructor — must convert) |
| finite `Float64` | yes | `GiacCxxBindings.Gen(x)` |
| anything else | **no — string path** | unchanged |

The string path continues to handle: `Rational`, `Complex`,
`AbstractIrrational` (`π`, `ℯ`, golden ratio, …), `AbstractVector`,
`GiacMatrix`, `±Inf`, `NaN`, `BigInt`, `Int128`, `UInt`, out-of-Int32-range
`Int64`, `Symbol`, `String`, `DerivativeCondition`, `DerivativePoint`,
`Function`. All existing `_arg_to_giac_string` specializations are preserved.

If **any** argument in a call is not fast-path-eligible, the entire call
takes the string path. There is no per-argument hybrid path.

## Disabling the fast path

Set the environment variable `GIAC_INVOKE_CMD_STRING_PATH=1` (or `true`,
`yes`) before loading the package to force every `invoke_cmd` call onto the
string path:

```bash
GIAC_INVOKE_CMD_STRING_PATH=1 julia --project -e 'using Giac; ...'
```

The value is read once at module init and cached in `Giac._fastpath_disabled
:: Ref{Bool}`. To toggle from within Julia (test-only):

```julia
ENV["GIAC_INVOKE_CMD_STRING_PATH"] = "1"
Giac._refresh_fastpath_flag!()
# … now every invoke_cmd call takes the string path …
delete!(ENV, "GIAC_INVOKE_CMD_STRING_PATH")
Giac._refresh_fastpath_flag!()
```

## Performance

The speed-up is workload-dependent. On the standard benchmark
(`bench/invoke_cmd_fastpath.jl`):

- **Commands returning long symbolic expressions** (`factor`, `expand` on
  non-trivial polynomials, multi-arg `series`): the fast path is typically
  ≈ 1.5–2.5× faster because the string path's dominant cost is GIAC
  reparsing the input AST.
- **Commands returning numeric values** (`evalf` with a small precision
  spec, `sum` of a finite series): typically ≈ 1.2–2× faster.
- **Very small inputs / cheap C++ work** (`simplify(x^2+1)`, `diff(x^3,x)`):
  approximately neutral. The parse cost saved is comparable to the fast
  path's setup overhead.

Geometric mean across the workload mix: ≈ 1.5×.

The benchmark gates on (a) geomean ≥ 1.0× *and* (b) at least one workload
≥ 1.5×. A stricter per-workload 2× target is not achievable because GIAC
internally memoizes repeated identical calls and because the parse cost
the fast path saves is highly workload-dependent.

## Why this also matters for correctness

The same root cause that motivated `_giac_subst_vec_tier1`
([spec 065](https://github.com/s-celles/Giac.jl/blob/main/specs/065-substitute-tier1/spec.md))
applies to every multi-argument `invoke_cmd` call routed through the string
path: a `Gen`'s printed form is **not** guaranteed to round-trip through
GIAC's parser back into the same `Gen`. For substitution this manifested as
simultaneous-substitution semantics being silently broken by a `Dict(x => y,
y => x)`-style swap. The fast path eliminates that whole class of bug across
the dispatch surface — the cached `Gen` is passed directly, never printed
and reparsed.

## Diagnostic logging

Every `invoke_cmd` call emits exactly one `@debug` log line identifying the
chosen path:

```julia
using Logging
with_logger(ConsoleLogger(stderr, Logging.Debug)) do
    invoke_cmd(:simplify, g)       # "invoke_cmd fast path"   cmd=simplify nargs=1
    invoke_cmd(:eval, 1//2)        # "invoke_cmd string path" cmd=eval     nargs=1
end
```

Use this when reproducing a parity issue to confirm which path the offending
call took.

## Implementation locations

- **Helpers** (`src/wrapper.jl`, after `_giac_subst_vec_tier1`):
  - `_has_direct_gen(x) :: Bool`
  - `_to_gen_direct(x) :: GiacCxxBindings.Gen`
  - `_fastpath_disabled :: Ref{Bool}`
  - `_refresh_fastpath_flag!() :: Bool`
  - `_invoke_cmd_direct(cmd::Symbol, args::Tuple) :: GiacExpr`
- **Dispatch site** (`src/Commands.jl`, body of `invoke_cmd`): a two-line
  branch after `_warn_conflict` calls `_invoke_cmd_direct` when eligible.
- **Tests**: `test/test_invoke_cmd_fastpath.jl`
- **Benchmark**: `bench/invoke_cmd_fastpath.jl`

## Adding eligibility for a new type

To enable fast-path conversion for a new Julia type `T`:

```julia
# in src/wrapper.jl, alongside the existing _has_direct_gen / _to_gen_direct methods
_has_direct_gen(::T) = true               # or a predicate on x::T
_to_gen_direct(x::T) = ...                # produce a GiacCxxBindings.Gen
```

The dispatch in `invoke_cmd` does not need to change. Add a test in
`test/test_invoke_cmd_fastpath.jl` asserting (a) the predicate, (b) the
conversion is faithful, and (c) parity with the string path for at least one
representative `(cmd, args)` shape involving the new type.
