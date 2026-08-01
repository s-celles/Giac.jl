# Tests for the direct-Gen fast path for invoke_cmd (069-invoke-cmd-fastpath).
#
# The file is structured as one @testset per user story / phase:
#   - "Foundational: _has_direct_gen"
#   - "Foundational: _to_gen_direct"
#   - "Foundational: _fastpath_disabled and _refresh_fastpath_flag!"
#   - "Foundational: _invoke_cmd_direct (helper-level)"
#   - "US1: hot-loop parity"
#   - "US1: path selection"
#   - "US1: allocation budget"
#   - "US2: Gen identity"
#   - "US2: parity battery"
#   - "US2: structural-divergence regression"
#   - "US3: pure-fallback types"
#   - "US3: mixed-args fallback"
#   - "US3: existing test surface intact"
#   - "US4: env-var kill switch"

using Test
using Giac
using Giac: GiacExpr, giac_eval, invoke_cmd, GiacMatrix

# Use Base.CoreLogging directly so we do not have to add stdlib Logging to the
# test target in Project.toml. TestLogger is exported from Test.
const _DEBUG_LEVEL = Base.CoreLogging.Debug
using Base.CoreLogging: with_logger

# ---------------------------------------------------------------------------
# Private test helpers (used across multiple testsets)
# ---------------------------------------------------------------------------

# Force the string path for a single block of code by flipping _fastpath_disabled.
# Uses a try/finally to restore the env var and the cached Ref.
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

# Force the fast path for a single block (mirror of _with_string_path).
function _with_fast_path(f::Function)
    prev = get(ENV, "GIAC_INVOKE_CMD_STRING_PATH", nothing)
    if prev !== nothing
        delete!(ENV, "GIAC_INVOKE_CMD_STRING_PATH")
    end
    Giac._refresh_fastpath_flag!()
    try
        return f()
    finally
        if prev !== nothing
            ENV["GIAC_INVOKE_CMD_STRING_PATH"] = prev
        end
        Giac._refresh_fastpath_flag!()
    end
end

# Invoke a command, forcing the string path, and return the result.
_invoke_cmd_string_only(cmd::Symbol, args...) = _with_string_path(() -> invoke_cmd(cmd, args...))

# GIAC-level "are these two expressions semantically equal?"
# Tries string equality first (handles evalf'd numerics and any byte-identical Gen),
# then falls back to simplify(a - b) == 0 for structurally different but equivalent
# symbolic expressions (where the two paths produce different but algebraically
# equivalent canonical forms).
function _giac_equal(a::GiacExpr, b::GiacExpr)
    sa = strip(string(a))
    sb = strip(string(b))
    sa == sb && return true
    try
        z = invoke_cmd(:simplify, a - b)
        z_str = strip(string(z))
        return z_str == "0" || z_str == "0.0" || z_str == "0e0" || tryparse(Float64, z_str) === 0.0
    catch
        return false
    end
end

# Capture @debug logs emitted by `body` and return them as a Vector{String} of messages.
function _capture_debug_logs(body::Function)
    logger = Test.TestLogger(min_level=_DEBUG_LEVEL)
    with_logger(body, logger)
    return [string(r.message) for r in logger.logs]
end

# ---------------------------------------------------------------------------

@testset "069-invoke-cmd-fastpath" begin

    # =====================================================================
    # Foundational: predicate _has_direct_gen
    # =====================================================================
    @testset "Foundational: _has_direct_gen" begin
        g = giac_eval("x^2 + 1")

        # Fast-path-eligible types
        @test Giac._has_direct_gen(g)
        @test Giac._has_direct_gen(Int32(42))
        @test Giac._has_direct_gen(42)                       # Int64 in Int32 range
        @test Giac._has_direct_gen(-50)
        @test Giac._has_direct_gen(0)
        @test Giac._has_direct_gen(3.14)
        @test Giac._has_direct_gen(0.0)
        @test Giac._has_direct_gen(-1.5)

        # Edge: Int64 outside Int32 range → ineligible
        @test !Giac._has_direct_gen(Int64(typemax(Int32)) + 1)
        @test !Giac._has_direct_gen(Int64(typemin(Int32)) - 1)

        # Edge: non-finite Float64 → ineligible
        @test !Giac._has_direct_gen(Inf)
        @test !Giac._has_direct_gen(-Inf)
        @test !Giac._has_direct_gen(NaN)

        # Numeric types that need the string path
        @test !Giac._has_direct_gen(big"123456789012345678901234567890")
        @test !Giac._has_direct_gen(Int128(1) << 70)
        @test !Giac._has_direct_gen(UInt64(42))
        @test !Giac._has_direct_gen(1//2)
        @test !Giac._has_direct_gen(1 + 2im)
        @test !Giac._has_direct_gen(π)
        @test !Giac._has_direct_gen(ℯ)

        # Containers and non-numeric scalars
        @test !Giac._has_direct_gen([1, 2, 3])
        @test !Giac._has_direct_gen(:x)
        @test !Giac._has_direct_gen("x+1")
        @test !Giac._has_direct_gen(sin)
        @test !Giac._has_direct_gen(nothing)
    end

    # =====================================================================
    # Foundational: _to_gen_direct
    # =====================================================================
    @testset "Foundational: _to_gen_direct" begin
        # Int32 → Gen
        gi = Giac._to_gen_direct(Int32(42))
        @test Giac.GiacCxxBindings.to_string(gi) == "42"

        # Int64 in Int32 range → Gen
        gi2 = Giac._to_gen_direct(42)
        @test Giac.GiacCxxBindings.to_string(gi2) == "42"

        # Float64 → Gen
        gf = Giac._to_gen_direct(3.14)
        @test Giac.GiacCxxBindings.to_string(gf) == "3.14"

        # GiacExpr → cached Gen reuse (no clone, no eval)
        g = giac_eval("x^2 + 1")
        gen_before = Giac._get_gen_or_eval(g)
        gen_via_direct = Giac._to_gen_direct(g)
        @test gen_via_direct === gen_before
    end

    # =====================================================================
    # Foundational: _fastpath_disabled and _refresh_fastpath_flag!
    # =====================================================================
    @testset "Foundational: _fastpath_disabled and _refresh_fastpath_flag!" begin
        # Make sure we start from a known state
        prev = get(ENV, "GIAC_INVOKE_CMD_STRING_PATH", nothing)
        try
            # Unset → false
            delete!(ENV, "GIAC_INVOKE_CMD_STRING_PATH")
            Giac._refresh_fastpath_flag!()
            @test Giac._fastpath_disabled[] == false

            # Empty string → false
            ENV["GIAC_INVOKE_CMD_STRING_PATH"] = ""
            Giac._refresh_fastpath_flag!()
            @test Giac._fastpath_disabled[] == false

            # "0" → false
            ENV["GIAC_INVOKE_CMD_STRING_PATH"] = "0"
            Giac._refresh_fastpath_flag!()
            @test Giac._fastpath_disabled[] == false

            # "no" → false
            ENV["GIAC_INVOKE_CMD_STRING_PATH"] = "no"
            Giac._refresh_fastpath_flag!()
            @test Giac._fastpath_disabled[] == false

            # "1" → true
            ENV["GIAC_INVOKE_CMD_STRING_PATH"] = "1"
            Giac._refresh_fastpath_flag!()
            @test Giac._fastpath_disabled[] == true

            # "true" / "True" / "TRUE" → true (case-insensitive)
            for v in ("true", "True", "TRUE")
                ENV["GIAC_INVOKE_CMD_STRING_PATH"] = v
                Giac._refresh_fastpath_flag!()
                @test Giac._fastpath_disabled[] == true
            end

            # "yes" / "YES" → true
            for v in ("yes", "YES", "Yes")
                ENV["GIAC_INVOKE_CMD_STRING_PATH"] = v
                Giac._refresh_fastpath_flag!()
                @test Giac._fastpath_disabled[] == true
            end
        finally
            if prev === nothing
                delete!(ENV, "GIAC_INVOKE_CMD_STRING_PATH")
            else
                ENV["GIAC_INVOKE_CMD_STRING_PATH"] = prev
            end
            Giac._refresh_fastpath_flag!()
        end
    end

    # =====================================================================
    # Foundational: _invoke_cmd_direct exercises the arity-branched fast path
    # =====================================================================
    @testset "Foundational: _invoke_cmd_direct (helper-level)" begin
        g = giac_eval("x^2 + 1")

        # Arity 1: simplify(x^2 - 1)
        g1 = giac_eval("(x^2 - 1)/(x - 1)")
        r1 = Giac._invoke_cmd_direct(:simplify, (g1,))
        @test r1 isa GiacExpr
        @test string(r1) == "x+1"

        # Arity 1: factor(x^2 - 1)
        gf = giac_eval("x^2 - 1")
        rf = Giac._invoke_cmd_direct(:factor, (gf,))
        @test r1 isa GiacExpr
        @test string(rf) == "(x-1)*(x+1)"

        # Arity 2: diff(x^3, x)
        g2a = giac_eval("x^3")
        g2b = giac_eval("x")
        r2 = Giac._invoke_cmd_direct(:diff, (g2a, g2b))
        @test string(r2) == "3*x^2"

        # Arity 2: evalf(pi, 15)
        gpi = giac_eval("pi")
        rpi = Giac._invoke_cmd_direct(:evalf, (gpi, Int32(15)))
        @test startswith(string(rpi), "3.14159265358979")

        # Arity 3: diff(x^5, x, 2)
        g3a = giac_eval("x^5")
        g3b = giac_eval("x")
        r3  = Giac._invoke_cmd_direct(:diff, (g3a, g3b, Int32(2)))
        @test string(r3) == "20*x^3"

        # Arity 4 (apply_funcN path): sum(k, k, 1, 10) = 55
        sumk = giac_eval("k")
        sumv = giac_eval("k")
        rN = Giac._invoke_cmd_direct(:sum, (sumk, sumv, Int32(1), Int32(10)))
        @test string(rN) == "55"

        # Arity 0: rand() returns a numeric value (random; we just check it parses as Float)
        r0 = Giac._invoke_cmd_direct(:rand, ())
        @test r0 isa GiacExpr
        v0 = tryparse(Float64, string(r0))
        @test v0 !== nothing
    end

    # =====================================================================
    # US1: hot-loop parity — fast and string paths produce the same result
    # =====================================================================
    @testset "US1: hot-loop parity" begin
        g = giac_eval("sum(1/k^2, k, 1, 100)")

        # Arity 1
        for cmd in (:simplify, :factor, :expand, :normal, :ratnormal)
            fast = invoke_cmd(cmd, g)
            slow = _invoke_cmd_string_only(cmd, g)
            @test _giac_equal(fast, slow)
        end

        # Arity 2: evalf(g, n)
        for n in (15, 30, 50)
            fast = invoke_cmd(:evalf, g, n)
            slow = _invoke_cmd_string_only(:evalf, g, n)
            @test _giac_equal(fast, slow)
        end

        # Arity 2 on polynomial: diff
        p = giac_eval("x^3 + 2*x^2 + x + 1")
        x = giac_eval("x")
        @test _giac_equal(invoke_cmd(:diff, p, x), _invoke_cmd_string_only(:diff, p, x))

        # Arity 3: diff(p, x, 2)
        @test _giac_equal(invoke_cmd(:diff, p, x, 2), _invoke_cmd_string_only(:diff, p, x, 2))

        # Compound expressions exercising factor/expand on a polynomial
        h = giac_eval("(x-1)*(x+1)*(x^2+1)")
        @test _giac_equal(invoke_cmd(:expand, h), _invoke_cmd_string_only(:expand, h))
        @test _giac_equal(invoke_cmd(:factor, h), _invoke_cmd_string_only(:factor, h))
    end

    # =====================================================================
    # US1: path selection — @debug log reveals which path each call took
    # =====================================================================
    @testset "US1: path selection" begin
        g = giac_eval("x^2 + 1")

        # Force fast path on for this testset, regardless of the env-var state
        # at test-runtime (so the suite runs identically under default and
        # under GIAC_INVOKE_CMD_STRING_PATH=1).
        logs = _with_fast_path() do
            _capture_debug_logs() do
                invoke_cmd(:simplify, g)            # all-GiacExpr → fast
                invoke_cmd(:evalf, g, 20)           # GiacExpr+Int → fast
                invoke_cmd(:eval, 1//2)             # Rational      → string
                invoke_cmd(:eval, [1, 2, 3])        # Vector        → string
            end
        end

        msgs = filter(m -> startswith(m, "invoke_cmd "), logs)
        @test length(msgs) == 4
        @test msgs[1] == "invoke_cmd fast path"
        @test msgs[2] == "invoke_cmd fast path"
        @test msgs[3] == "invoke_cmd string path"
        @test msgs[4] == "invoke_cmd string path"
    end

    # =====================================================================
    # US1: allocation budget — fast path allocates substantially less
    # =====================================================================
    @testset "US1: allocation budget" begin
        g = giac_eval("sum(1/k^2, k, 1, 100)")

        # Force fast path on for the fast-side measurement so the test passes
        # uniformly under default and GIAC_INVOKE_CMD_STRING_PATH=1 environments.
        fast_allocs = _with_fast_path() do
            for _ in 1:5; invoke_cmd(:simplify, g); end
            @allocations invoke_cmd(:simplify, g)
        end
        slow_allocs = _with_string_path() do
            for _ in 1:5; invoke_cmd(:simplify, g); end
            @allocations invoke_cmd(:simplify, g)
        end

        # Fast path must allocate strictly less than the string path. Aggressive
        # targets (e.g. "≥ 50 % fewer") are unstable across Julia versions because
        # the string path's per-call allocations depend on Base internals; "< slow"
        # is what the contract actually guarantees.
        @test fast_allocs < slow_allocs
    end

    # =====================================================================
    # US2: Gen identity — fast path reuses the cached Gen, no clone
    # =====================================================================
    @testset "US2: Gen identity" begin
        g = giac_eval("x^2 + sin(x)")
        original = Giac._get_gen_or_eval(g)

        # Pre-call: cached Gen is `original`
        @test Giac._get_gen_or_eval(g) === original

        # Run a fast-path call
        _ = invoke_cmd(:simplify, g)

        # Post-call: same cached Gen
        @test Giac._get_gen_or_eval(g) === original

        # And the helper itself does not clone
        @test Giac._to_gen_direct(g) === original
    end

    # =====================================================================
    # US2: parity battery — broad coverage of expression × command pairs
    # =====================================================================
    @testset "US2: parity battery" begin
        exprs = Dict{Symbol, GiacExpr}(
            :int       => giac_eval("42"),
            :poly1     => giac_eval("x^2 - 2*x + 1"),
            :poly2     => giac_eval("(x-1)*(x+1)*(x^2+1)"),
            :ratfun    => giac_eval("(x^2 + 2*x + 1)/(x + 1)"),
            :trig      => giac_eval("sin(x)^2 + cos(x)^2"),
            :exp_ln    => giac_eval("exp(x)*ln(x)"),
            :sum_zeta  => giac_eval("sum(1/k^2, k, 1, 100)"),
            :pi_quart  => giac_eval("pi/4"),
            :multivar  => giac_eval("x*y + x + y + 1"),
        )

        # Single-argument commands
        for cmd in (:simplify, :factor, :expand, :normal, :ratnormal, :eval)
            for (name, e) in exprs
                fast = invoke_cmd(cmd, e)
                slow = _invoke_cmd_string_only(cmd, e)
                @test _giac_equal(fast, slow)
            end
        end

        # evalf with precision
        for (name, e) in exprs
            for n in (10, 30, 50)
                fast = invoke_cmd(:evalf, e, n)
                slow = _invoke_cmd_string_only(:evalf, e, n)
                @test _giac_equal(fast, slow)
            end
        end

        # diff w.r.t. x (only meaningful for exprs containing x)
        x = giac_eval("x")
        for (name, e) in exprs
            name == :int && continue
            fast = invoke_cmd(:diff, e, x)
            slow = _invoke_cmd_string_only(:diff, e, x)
            @test _giac_equal(fast, slow)
        end
    end

    # =====================================================================
    # US2: structural-divergence regression
    # =====================================================================
    @testset "US2: structural-divergence regression" begin
        # The _giac_subst_vec_tier1 precedent (065-substitute-tier1) was added because
        # a Gen's printed form did not round-trip through the GIAC parser in a way
        # that preserved simultaneous substitution semantics. The same class of bug
        # could in principle affect any invoke_cmd call routed through the string
        # path on a Gen whose printed form is ambiguous to the parser.
        #
        # The fast path eliminates this class structurally: the cached Gen is passed
        # to apply_func* without ever going through to_string + giac_eval.
        #
        # No concrete divergence case is reproducible in v1 with current giac builds,
        # but the test exists to document the intent and guard against future drift.

        g = giac_eval("sin(x) + cos(x)")
        fast = invoke_cmd(:simplify, g)
        slow = _invoke_cmd_string_only(:simplify, g)
        @test _giac_equal(fast, slow)
    end

    # =====================================================================
    # US3: pure-fallback types — each ineligible type takes the string path
    # =====================================================================
    @testset "US3: pure-fallback types" begin
        # Each call below contains exactly one argument that is not fast-path-eligible.
        # Verify (a) the string path is taken via @debug capture, and (b) the result
        # matches the current (string-path) implementation.
        cases = [
            (:eval, (1//2,)),
            (:eval, (1 + 2im,)),
            (:eval, (π,)),
            (:eval, ([1, 2, 3],)),
            (:eval, (Inf,)),
            (:eval, (NaN,)),
            (:eval, (:x,)),
            (:eval, ("x+1",)),
            (:eval, (big"123456789012345678901234567890",)),
            (:eval, (Int128(1) << 70,)),
            (:eval, (Int64(typemax(Int32)) + 100,)),
        ]

        for (cmd, args) in cases
            logs = _capture_debug_logs() do
                invoke_cmd(cmd, args...)
            end
            msgs = filter(m -> startswith(m, "invoke_cmd "), logs)
            @test length(msgs) == 1
            @test msgs[1] == "invoke_cmd string path"

            # Result parity: running it again under the kill switch must yield the same value.
            fast = invoke_cmd(cmd, args...)
            slow = _invoke_cmd_string_only(cmd, args...)
            @test strip(string(fast)) == strip(string(slow))
        end
    end

    # =====================================================================
    # US3: mixed-args fallback — any ineligible arg forces string path
    # =====================================================================
    @testset "US3: mixed-args fallback" begin
        g = giac_eval("x^2 + 1")

        # GiacExpr + Rational → string path (one valid mixed-arg shape: evalf with Rational precision is not real;
        # use eval with [a, 1//2] which is a valid 2-arg call: eval(expr, mode).
        # Simplest reliable case: a multi-arg command whose Julia surface accepts a Rational.
        # We just need to confirm path selection, not GIAC's acceptance of the call,
        # so use a 1-arg call where the single arg is Rational.
        logs = _capture_debug_logs() do
            invoke_cmd(:eval, 1//2)
        end
        msgs = filter(m -> startswith(m, "invoke_cmd "), logs)
        @test msgs[1] == "invoke_cmd string path"

        # GiacExpr + Symbol → string path
        logs2 = _capture_debug_logs() do
            invoke_cmd(:integrate, g, :x)
        end
        msgs2 = filter(m -> startswith(m, "invoke_cmd "), logs2)
        @test msgs2[1] == "invoke_cmd string path"

        # GiacExpr + Inf → string path: GIAC accepts inf as a 2nd evalf arg
        # (no-op, but exercises the dispatch correctly)
        logs3 = _capture_debug_logs() do
            try
                invoke_cmd(:evalf, g, Inf)
            catch
                # Some commands reject Inf; we only care that the path is "string"
            end
        end
        msgs3 = filter(m -> startswith(m, "invoke_cmd "), logs3)
        @test msgs3[1] == "invoke_cmd string path"

        # GiacExpr + Complex → string path
        logs4 = _capture_debug_logs() do
            try
                invoke_cmd(:evalf, g, 1 + 0im)
            catch
            end
        end
        msgs4 = filter(m -> startswith(m, "invoke_cmd "), logs4)
        @test msgs4[1] == "invoke_cmd string path"
    end

    # =====================================================================
    # US4: env-var kill switch
    # =====================================================================
    @testset "US4: env-var kill switch" begin
        g = giac_eval("x^2 + 1")

        # With kill switch, every call (even pure-GiacExpr) takes string path
        logs = _capture_debug_logs() do
            _with_string_path() do
                invoke_cmd(:simplify, g)
                invoke_cmd(:factor, g - 1)
                invoke_cmd(:evalf, g, 20)
            end
        end

        msgs = filter(m -> startswith(m, "invoke_cmd "), logs)
        @test length(msgs) == 3
        @test all(m -> m == "invoke_cmd string path", msgs)

        # Without kill switch, the same pure-GiacExpr calls take fast path
        logs2 = _capture_debug_logs() do
            _with_fast_path() do
                invoke_cmd(:simplify, g)
                invoke_cmd(:factor, g - 1)
                invoke_cmd(:evalf, g, 20)
            end
        end
        msgs2 = filter(m -> startswith(m, "invoke_cmd "), logs2)
        @test length(msgs2) == 3
        @test all(m -> m == "invoke_cmd fast path", msgs2)
    end

end  # @testset "069-invoke-cmd-fastpath"
