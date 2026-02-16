# Tests for TempApi submodule (010-tempapi-submodule)

@testset "TempApi Submodule" begin
    # ==========================================================================
    # User Story 1: Access Functions via TempApi
    # ==========================================================================

    @testset "US1: TempApi Module Existence" begin
        @test isdefined(Giac, :TempApi)
        @test Giac.TempApi isa Module
    end

    @testset "US1: TempApi Exports" begin
        # Verify all 7 functions are exported
        @test isdefined(Giac.TempApi, :diff)
        @test isdefined(Giac.TempApi, :integrate)
        @test isdefined(Giac.TempApi, :limit)
        @test isdefined(Giac.TempApi, :factor)
        @test isdefined(Giac.TempApi, :expand)
        @test isdefined(Giac.TempApi, :simplify)
        @test isdefined(Giac.TempApi, :solve)
    end

    @testset "US1: diff function" begin
        if !Giac.is_stub_mode()
            f = giac_eval("x^3")
            x = giac_eval("x")

            # Basic differentiation
            df = Giac.TempApi.diff(f, x)
            @test string(df) == "3*x^2"

            # Higher order differentiation
            d2f = Giac.TempApi.diff(f, x, 2)
            @test string(d2f) == "6*x"

            # String input
            df_str = Giac.TempApi.diff("x^3", "x")
            @test string(df_str) == "3*x^2"
        else
            @test_skip "Skipped in stub mode"
        end
    end

    @testset "US1: integrate function" begin
        if !Giac.is_stub_mode()
            f = giac_eval("x^2")
            x = giac_eval("x")

            # Indefinite integral
            F = Giac.TempApi.integrate(f, x)
            @test occursin("x^3", string(F))

            # Definite integral
            area = Giac.TempApi.integrate(f, x, 0, 1)
            @test string(area) == "1/3"

            # String input
            F_str = Giac.TempApi.integrate("x^2", "x")
            @test occursin("x^3", string(F_str))
        else
            @test_skip "Skipped in stub mode"
        end
    end

    @testset "US1: limit function" begin
        if !Giac.is_stub_mode()
            f = giac_eval("sin(x)/x")
            x = giac_eval("x")
            zero = giac_eval("0")

            lim = Giac.TempApi.limit(f, x, zero)
            @test string(lim) == "1"

            # String input
            lim_str = Giac.TempApi.limit("sin(x)/x", "x", 0)
            @test string(lim_str) == "1"
        else
            @test_skip "Skipped in stub mode"
        end
    end

    @testset "US1: factor function" begin
        if !Giac.is_stub_mode()
            p = giac_eval("x^2 - 1")

            f = Giac.TempApi.factor(p)
            @test string(f) == "(x-1)*(x+1)"

            # String input
            f_str = Giac.TempApi.factor("x^2 - 1")
            @test string(f_str) == "(x-1)*(x+1)"
        else
            @test_skip "Skipped in stub mode"
        end
    end

    @testset "US1: expand function" begin
        if !Giac.is_stub_mode()
            p = giac_eval("(x+1)^2")

            e = Giac.TempApi.expand(p)
            @test string(e) == "x^2+2*x+1"

            # String input
            e_str = Giac.TempApi.expand("(x+1)^2")
            @test string(e_str) == "x^2+2*x+1"
        else
            @test_skip "Skipped in stub mode"
        end
    end

    @testset "US1: simplify function" begin
        if !Giac.is_stub_mode()
            expr = giac_eval("(x^2 - 1)/(x - 1)")

            s = Giac.TempApi.simplify(expr)
            @test string(s) == "x+1"

            # String input
            s_str = Giac.TempApi.simplify("(x^2 - 1)/(x - 1)")
            @test string(s_str) == "x+1"
        else
            @test_skip "Skipped in stub mode"
        end
    end

    @testset "US1: solve function" begin
        if !Giac.is_stub_mode()
            eq = giac_eval("x^2 - 4")
            x = giac_eval("x")

            sols = Giac.TempApi.solve(eq, x)
            sols_str = string(sols)
            @test occursin("-2", sols_str) && occursin("2", sols_str)

            # String input
            sols_str2 = Giac.TempApi.solve("x^2 - 4", "x")
            @test occursin("-2", string(sols_str2)) && occursin("2", string(sols_str2))
        else
            @test_skip "Skipped in stub mode"
        end
    end

    # ==========================================================================
    # User Story 2: Selective Import
    # ==========================================================================

    @testset "US2: Selective Import Pattern" begin
        # Verify the exports are in the module
        exports = names(Giac.TempApi)
        @test :diff in exports
        @test :integrate in exports
        @test :limit in exports
        @test :factor in exports
        @test :expand in exports
        @test :simplify in exports
        @test :solve in exports
    end

    @testset "US2: All 7 Functions Exported" begin
        exports = names(Giac.TempApi)
        expected_exports = [:diff, :integrate, :limit, :factor, :expand, :simplify, :solve]
        for fn in expected_exports
            @test fn in exports
        end
    end

    # ==========================================================================
    # User Story 3: Equivalence with invoke_cmd
    # ==========================================================================

    @testset "US3: Equivalence with invoke_cmd" begin
        if !Giac.is_stub_mode()
            expr = giac_eval("x^2 - 1")
            x = giac_eval("x")

            # diff equivalence
            @test string(Giac.TempApi.diff(expr, x)) == string(invoke_cmd(:diff, expr, x))

            # factor equivalence
            @test string(Giac.TempApi.factor(expr)) == string(invoke_cmd(:factor, expr))

            # expand equivalence (use a different expr)
            expr2 = giac_eval("(x+1)^2")
            @test string(Giac.TempApi.expand(expr2)) == string(invoke_cmd(:expand, expr2))

            # simplify equivalence
            expr3 = giac_eval("(x^2-1)/(x-1)")
            @test string(Giac.TempApi.simplify(expr3)) == string(invoke_cmd(:simplify, expr3))

            # integrate equivalence
            f = giac_eval("x^2")
            @test string(Giac.TempApi.integrate(f, x)) == string(invoke_cmd(:integrate, f, x))

            # solve equivalence
            eq = giac_eval("x^2 - 4")
            @test string(Giac.TempApi.solve(eq, x)) == string(invoke_cmd(:solve, eq, x))

            # limit equivalence
            lim_expr = giac_eval("sin(x)/x")
            zero = giac_eval("0")
            @test string(Giac.TempApi.limit(lim_expr, x, zero)) == string(invoke_cmd(:limit, lim_expr, x, zero))
        else
            @test_skip "Skipped in stub mode"
        end
    end
end
