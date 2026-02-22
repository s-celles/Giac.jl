# Tests for HeldCmd type, hold_cmd, release, and display (055-held-cmd-display)

@testset "HeldCmd (055-held-cmd-display)" begin
    @giac_var x t s n z f F

    # ========================================================================
    # US1: hold_cmd returns HeldCmd, stores cmd and args correctly
    # ========================================================================
    @testset "hold_cmd basics" begin
        h = hold_cmd(:integrate, x, x)
        @test h isa HeldCmd
        @test h.cmd === :integrate
        @test length(h.args) == 2

        # Zero args
        h0 = hold_cmd(:rand)
        @test h0 isa HeldCmd
        @test h0.cmd === :rand
        @test length(h0.args) == 0

        # Various argument types (same as invoke_cmd: GiacExpr, Symbol, Number, String, Vector)
        h_expr = hold_cmd(:factor, giac_eval("x^2-1"))
        @test h_expr isa HeldCmd

        h_num = hold_cmd(:ifactor, 120)
        @test h_num isa HeldCmd
        @test h_num.args[1] == 120

        h_sym = hold_cmd(:diff, x, :x)
        @test h_sym isa HeldCmd

        h_str = hold_cmd(:factor, "x^2-1")
        @test h_str isa HeldCmd

        h_vec = hold_cmd(:sum, [1, 2, 3])
        @test h_vec isa HeldCmd
    end

    @testset "hold_cmd validation" begin
        # Unknown command should throw GiacError (only when command registry is populated)
        if !isempty(Giac.VALID_COMMANDS)
            @test_throws GiacError hold_cmd(:this_command_does_not_exist_xyz)
        end

        # String variant
        h = hold_cmd("integrate", x, x)
        @test h isa HeldCmd
        @test h.cmd === :integrate
    end

    # ========================================================================
    # US3: LaTeX rendering for specialized commands
    # ========================================================================
    @testset "LaTeX: integrate" begin
        # Indefinite integral
        h = hold_cmd(:integrate, f, x)
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\int", latex)
        @test occursin("dx", latex)

        # Definite integral with bounds
        h_def = hold_cmd(:integrate, f, x, 0, 1)
        latex_def = sprint(show, MIME("text/latex"), h_def)
        @test occursin("\\int_{", latex_def)
        @test occursin("}^{", latex_def)
        @test occursin("dx", latex_def)
    end

    @testset "LaTeX: diff" begin
        h = hold_cmd(:diff, f, x)
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\frac{d}{dx}", latex)

        # Higher order
        h2 = hold_cmd(:diff, f, x, 2)
        latex2 = sprint(show, MIME("text/latex"), h2)
        @test occursin("\\frac{d^{2}}{dx^{2}}", latex2)
    end

    @testset "LaTeX: laplace" begin
        h = hold_cmd(:laplace, f, t, s)
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\mathcal{L}", latex)
    end

    @testset "LaTeX: invlaplace" begin
        h = hold_cmd(:invlaplace, F, s, t)
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\mathcal{L}^{-1}", latex)
    end

    @testset "LaTeX: ztrans" begin
        h = hold_cmd(:ztrans, f, n, z)
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\mathcal{Z}", latex)
    end

    @testset "LaTeX: invztrans" begin
        h = hold_cmd(:invztrans, F, z, n)
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\mathcal{Z}^{-1}", latex)
    end

    # ========================================================================
    # US1: Generic fallback LaTeX
    # ========================================================================
    @testset "LaTeX: generic fallback" begin
        h = hold_cmd(:factor, giac_eval("x^2-1"))
        latex = sprint(show, MIME("text/latex"), h)
        @test occursin("\\mathrm{factor}", latex)
    end

    # ========================================================================
    # US2: release executes the held command
    # ========================================================================
    @testset "release" begin
        # release should produce same result as invoke_cmd
        h = hold_cmd(:factor, giac_eval("x^2-1"))
        result = release(h)
        expected = invoke_cmd(:factor, giac_eval("x^2-1"))
        @test string(result) == string(expected)

        # Integration
        h_int = hold_cmd(:integrate, x, x)
        result_int = release(h_int)
        expected_int = invoke_cmd(:integrate, x, x)
        @test string(result_int) == string(expected_int)
    end

    # ========================================================================
    # US4: Plain text display
    # ========================================================================
    @testset "Plain text show" begin
        h = hold_cmd(:integrate, x)
        txt = sprint(show, h)
        @test occursin("integrate", txt)
        @test occursin("[held]", txt)

        h2 = hold_cmd(:factor, giac_eval("x^2-1"))
        txt2 = sprint(show, h2)
        @test occursin("factor", txt2)
        @test occursin("[held]", txt2)

        # Zero-arg command
        h0 = hold_cmd(:rand)
        txt0 = sprint(show, h0)
        @test occursin("rand", txt0)
        @test occursin("[held]", txt0)
    end
end
