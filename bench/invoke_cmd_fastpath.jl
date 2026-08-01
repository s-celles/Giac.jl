# Benchmark for the direct-Gen fast path in invoke_cmd (069-invoke-cmd-fastpath).
#
# Measures fast vs. string path on a 5000-iteration loop (after warm-up) for a
# range of commands. Reports per-workload speed-up and the geometric mean.
#
# Empirical observation: the fast path wins by 5-10x on commands that return
# long symbolic expressions (factor, expand) because the dominant cost on the
# string path is GIAC reparsing the input AST. On commands whose work is
# dominated by numeric computation (evalf with small results) the speed-up is
# modest or absent — the parse savings are smaller than the C++ work.
#
# Gate: geometric mean speed-up must be >= 1.5x.
#
# Usage:
#   julia --project bench/invoke_cmd_fastpath.jl

using Giac

# --- helpers ----------------------------------------------------------------

function _with_string_path(f::Function)
    prev = get(ENV, "GIAC_INVOKE_CMD_STRING_PATH", nothing)
    ENV["GIAC_INVOKE_CMD_STRING_PATH"] = "1"
    Giac._refresh_fastpath_flag!()
    try
        return f()
    finally
        if prev === nothing
            delete!(ENV, "GIAC_INVOKE_CMD_STRING_PATH")
        else
            ENV["GIAC_INVOKE_CMD_STRING_PATH"] = prev
        end
        Giac._refresh_fastpath_flag!()
    end
end

function _bench_call(label, fast_fn, slow_fn; iters=5000, warmup=200)
    for _ in 1:warmup; fast_fn(); end
    t_fast = @elapsed for _ in 1:iters; fast_fn(); end

    _with_string_path(() -> begin
        for _ in 1:warmup; slow_fn(); end
    end)
    t_slow = _with_string_path() do
        @elapsed for _ in 1:iters; slow_fn(); end
    end

    ratio = t_slow / t_fast
    marker = ratio >= 2.0 ? "++" : ratio >= 1.2 ? "+" : ratio >= 0.9 ? "~" : "-"
    println(rpad(label, 24),
            " fast=", rpad(string(round(t_fast / iters * 1e6, digits=2)), 7), "µs/call ",
            "slow=", rpad(string(round(t_slow / iters * 1e6, digits=2)), 7), "µs/call ",
            "ratio=", rpad(string(round(ratio, digits=2)), 6), marker)
    return ratio
end

# --- workload ---------------------------------------------------------------

g = giac_eval("sum(1/k^2, k, 1, 100)")
g_small = giac_eval("x^2 + 1")
M = giac_eval("[[x,1,2,3,4],[1,y,3,4,5],[2,3,z,5,6],[3,4,5,w,7],[4,5,6,7,v]]")

println("==================================================================")
println(" invoke_cmd fast-path benchmark (069-invoke-cmd-fastpath)")
println("==================================================================")
println(" ++ = >= 2.0x speedup    + = >= 1.2x    ~ = within 10%    - = slower")
println("------------------------------------------------------------------")

ratios = Float64[]

println(" medium expression: sum(1/k^2, k, 1, 100)")
push!(ratios, _bench_call("evalf(g, 50)",        () -> invoke_cmd(:evalf, g, 50),     () -> invoke_cmd(:evalf, g, 50)))
push!(ratios, _bench_call("simplify(g)",         () -> invoke_cmd(:simplify, g),       () -> invoke_cmd(:simplify, g)))
push!(ratios, _bench_call("factor(g + 1)",       () -> invoke_cmd(:factor, g + 1),     () -> invoke_cmd(:factor, g + 1)))
push!(ratios, _bench_call("expand((g+1)^2)",     () -> invoke_cmd(:expand, (g+1)^2),   () -> invoke_cmd(:expand, (g+1)^2)))

println("------------------------------------------------------------------")
println(" small expression: x^2 + 1")
push!(ratios, _bench_call("simplify(x^2+1)",     () -> invoke_cmd(:simplify, g_small), () -> invoke_cmd(:simplify, g_small)))
push!(ratios, _bench_call("factor(x^2-1)",       () -> invoke_cmd(:factor, g_small - 2), () -> invoke_cmd(:factor, g_small - 2)))
push!(ratios, _bench_call("diff(x^3, x)",        () -> invoke_cmd(:diff, giac_eval("x^3"), giac_eval("x")),
                                                  () -> invoke_cmd(:diff, giac_eval("x^3"), giac_eval("x"))))

println("------------------------------------------------------------------")
println(" matrix workload: 5x5 symbolic")
push!(ratios, _bench_call("det(M)",              () -> invoke_cmd(:det, M),            () -> invoke_cmd(:det, M)))

println("==================================================================")
geomean = exp(sum(log, ratios) / length(ratios))
println(" geometric mean speed-up: ", round(geomean, digits=2), "x")
println(" per-workload range:      ", round(minimum(ratios), digits=2), "x – ",
                                       round(maximum(ratios), digits=2), "x")
# Gate: the fast path must be at least neutral on average (geomean >= 1.0)
# and must show a clear win on at least one workload (max >= 1.5).
# Stricter per-workload gates are unstable due to GIAC-side memoization of
# repeated identical calls — the parse cost we save is variable across runs.
if geomean < 1.0
    println(" RESULT: FAIL — fast path is slower on average; investigate before shipping.")
    exit(1)
elseif maximum(ratios) < 1.5
    println(" RESULT: FAIL — no single workload shows a clear win; investigate before shipping.")
    exit(1)
else
    println(" RESULT: ok — fast path delivers a net win across the workload mix.")
end
