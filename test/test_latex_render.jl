# Tests for LaTeX/MathML rendering of unevaluated GIAC results
# (071-latex-render-form).
#
# GIAC evaluates command arguments, so handing a result such as
# `ifactor(360)` (the product 2^3*3^2*5) to `latex` used to collapse it back
# to 360 before rendering. Rendering commands must print the expression they
# are given, not a re-evaluated copy of it.
#
# Reported by @kahliburke.

using Test
using Giac
using Giac: GiacExpr, GiacMatrix, giac_eval, invoke_cmd
using Giac.Commands: ifactor

# Force the string path for a single block of code (mirrors the helper in
# test_invoke_cmd_fastpath.jl) so both invoke_cmd paths are covered.
function _latex_with_string_path(f::Function)
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

@testset "LaTeX rendering preserves expression form (071-latex-render-form)" begin

    # ------------------------------------------------------------------
    # Foundational: _quote_gen / _hold_render_arg helpers
    # ------------------------------------------------------------------
    @testset "Foundational: _quote_gen" begin
        f = ifactor(360)
        q = Giac._quote_gen(f)
        @test q isa GiacExpr
        # GIAC prints a quoted expression with surrounding single quotes
        @test string(q) == "'2^3*3^2*5'"
        # The original expression is untouched
        @test string(f) == "2^3*3^2*5"
    end

    @testset "Foundational: _hold_render_arg" begin
        f = ifactor(360)
        @test string(Giac._hold_render_arg(f)) == "'2^3*3^2*5'"
        # Non-GiacExpr arguments pass through unchanged (identity)
        @test Giac._hold_render_arg(360) === 360
        @test Giac._hold_render_arg("x^2") === "x^2"
        @test :latex in Giac.RENDER_COMMANDS
        @test :mathml in Giac.RENDER_COMMANDS
    end

    # ------------------------------------------------------------------
    # US1: latex(ifactor(n)) keeps the factorisation
    # ------------------------------------------------------------------
    @testset "US1: invoke_cmd(:latex, ifactor(360))" begin
        f = ifactor(360)
        @test string(f) == "2^3*3^2*5"

        tex = string(invoke_cmd(:latex, f))
        @test occursin("2^{3}", tex)
        @test occursin("3^{2}", tex)
        @test !occursin("360", tex)
    end

    @testset "US1: Commands.latex(ifactor(360))" begin
        tex = string(Giac.Commands.latex(ifactor(360)))
        @test occursin("2^{3}", tex)
        @test occursin("3^{2}", tex)
        @test !occursin("360", tex)
    end

    @testset "US1: other ifactor values" begin
        tex = string(invoke_cmd(:latex, ifactor(1000)))
        @test occursin("2^{3}", tex)
        @test occursin("5^{3}", tex)
        @test !occursin("1000", tex)
    end

    @testset "US1: string path parity" begin
        f = ifactor(360)
        fast = string(invoke_cmd(:latex, f))
        slow = _latex_with_string_path() do
            string(invoke_cmd(:latex, f))
        end
        @test slow == fast
        @test occursin("2^{3}", slow)
        @test !occursin("360", slow)
    end

    # ------------------------------------------------------------------
    # US2: notebook display (MIME"text/latex") keeps the factorisation
    # ------------------------------------------------------------------
    @testset "US2: show(MIME\"text/latex\", ifactor(360))" begin
        s = sprint(show, MIME("text/latex"), ifactor(360))
        @test startswith(s, "\$\$")
        @test endswith(s, "\$\$")
        @test occursin("2^{3}", s)
        @test occursin("3^{2}", s)
        @test !occursin("360", s)
    end

    # ------------------------------------------------------------------
    # US3: mathml gets the same treatment
    # ------------------------------------------------------------------
    @testset "US3: mathml(ifactor(360))" begin
        ml = string(invoke_cmd(:mathml, ifactor(360)))
        @test occursin("<mn>3</mn>", ml)
        @test !occursin("<mn>360</mn>", ml)
    end

    # ------------------------------------------------------------------
    # US4: no regression for ordinary expressions
    # ------------------------------------------------------------------
    @testset "US4: symbolic expressions unchanged" begin
        x = giac_eval("x")
        @test string(invoke_cmd(:latex, x^2 + 1)) == "\"x^{2}+1\""
        @test occursin("\\frac", string(invoke_cmd(:latex, giac_eval("1/(1-x)"))))
        @test occursin("\\sqrt", string(invoke_cmd(:latex, giac_eval("sqrt(2)"))))
        @test occursin("\\sin", string(invoke_cmd(:latex, giac_eval("sin(x)"))))
    end

    @testset "US4: numbers and lists unchanged" begin
        @test string(invoke_cmd(:latex, giac_eval("360"))) == "\"360\""
        @test string(invoke_cmd(:latex, giac_eval("1/2"))) == "\"\\frac{1}{2}\""
        # Plain Julia arguments never go through quoting
        @test string(invoke_cmd(:latex, 360)) == "\"360\""
        @test occursin("360", string(invoke_cmd(:latex, "360")))
    end

    @testset "US4: matrices unchanged" begin
        tex = string(invoke_cmd(:latex, giac_eval("[[1,2],[3,4]]")))
        @test occursin("array", tex)
        @test occursin("1", tex) && occursin("4", tex)

        M = GiacMatrix([1 2; 3 4])
        s = sprint(show, MIME("text/latex"), M)
        @test occursin("array", s)
    end

    @testset "US4: equations unchanged" begin
        tex = string(invoke_cmd(:latex, giac_eval("x^2=4")))
        @test occursin("x^{2}", tex)
        @test occursin("4", tex)
    end
end
