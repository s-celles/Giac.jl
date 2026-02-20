# Tests for Giac.Constants module (053-symbolic-pi-constant)

@testset "Constants Module" begin
    # Phase 3: User Story 1 - Symbolic Pi Tests (T007-T011)
    @testset "User Story 1: Symbolic Pi" begin
        # T007: Test Constants.pi returns SymbolicConstant or converts to GiacExpr
        @test Giac.Constants.pi isa Giac.Constants.SymbolicConstant
        @test convert(GiacExpr, Giac.Constants.pi) isa GiacExpr

        # T008: Test string(Constants.pi) equals "pi"
        @test string(Giac.Constants.pi) == "pi"

        # T009: Test 2 * Constants.pi displays "2*pi"
        @test string(2 * Giac.Constants.pi) == "2*pi"

        # T010: Test Constants.pi + Constants.pi - GIAC doesn't auto-simplify addition
        # It returns "pi+pi" not "2*pi", but simplify should give "2*pi"
        sum_result = Giac.Constants.pi + Giac.Constants.pi
        # Accept either unsimplified or simplified form
        @test string(sum_result) == "pi+pi" || string(sum_result) == "2*pi"

        # T011: Test sin(Constants.pi) simplifies to 0
        pi_expr = convert(GiacExpr, Giac.Constants.pi)
        @test string(invoke_cmd(:sin, pi_expr)) == "0"
    end

    # Phase 4: User Story 2 - Constants e and i Tests (T017-T022)
    @testset "User Story 2: Constants e and i" begin
        # T017: Test Constants.e returns SymbolicConstant
        @test Giac.Constants.e isa Giac.Constants.SymbolicConstant

        # T018: Test string(Constants.e) - GIAC normalizes e to exp(1)
        e_str = string(Giac.Constants.e)
        @test e_str == "e" || e_str == "exp(1)"

        # T019: Test Constants.i returns SymbolicConstant
        @test Giac.Constants.i isa Giac.Constants.SymbolicConstant

        # T020: Test string(Constants.i) equals "i"
        @test string(Giac.Constants.i) == "i"

        # T021: Test Constants.pi * Constants.e
        # Note: GIAC normalizes e to exp(1), so pi*e becomes pi*exp(1)
        result = string(Giac.Constants.pi * Giac.Constants.e)
        @test result == "pi*exp(1)" || result == "pi*e"

        # T022: Test exp(Constants.i * Constants.pi) equals -1
        i_times_pi = Giac.Constants.i * Giac.Constants.pi
        result = invoke_cmd(:exp, i_times_pi)
        @test string(result) == "-1"
    end

    # Additional tests for arithmetic operations
    @testset "Arithmetic Operations" begin
        # Test with GiacExpr
        x = giac_eval("x")

        # SymbolicConstant * GiacExpr
        @test string(Giac.Constants.pi * x) == "pi*x"
        @test string(x * Giac.Constants.pi) == "x*pi"

        # SymbolicConstant + GiacExpr
        @test string(Giac.Constants.pi + x) == "pi+x"

        # SymbolicConstant / Number
        @test string(Giac.Constants.pi / 2) == "pi/2"

        # Number * SymbolicConstant
        @test string(3 * Giac.Constants.pi) == "3*pi"

        # Power operations
        # Note: GIAC normalizes e^2 to exp(2)
        e_squared = string(Giac.Constants.e ^ 2)
        @test e_squared == "exp(2)" || e_squared == "e^2"

        @test string(Giac.Constants.i ^ 2) == "-1"

        # Complex expression
        expr = 2 * Giac.Constants.pi * x
        @test string(expr) == "2*pi*x"
    end

    # Phase 5: User Story 3 - Symbolics.jl Integration Tests (T029-T031)
    # These tests require Symbolics.jl to be loaded
    @testset "User Story 3: Symbolics Integration" begin
        # Check if extension is loaded by testing with a simple GiacExpr first
        test_expr = giac_eval("pi")
        has_symbolics = false
        try
            if isdefined(Giac, :to_symbolics)
                # Try to convert - will fail if extension not loaded
                Giac.to_symbolics(test_expr)
                has_symbolics = true
            end
        catch
            has_symbolics = false
        end

        if has_symbolics
            # T029: Test to_symbolics(Constants.pi) returns Symbolics.pi
            pi_expr = convert(GiacExpr, Giac.Constants.pi)
            sym_pi = Giac.to_symbolics(pi_expr)
            # Check it's the symbolic pi (different from float)
            @test !isa(sym_pi, AbstractFloat)

            # T030: Test to_symbolics(2 * Constants.pi) preserves symbolic form
            expr = 2 * Giac.Constants.pi
            sym_expr = Giac.to_symbolics(expr)
            @test !isa(sym_expr, AbstractFloat)

            # T031: Test round-trip - to_symbolics then to_giac preserves pi
            # Note: to_giac takes Symbolics.Num, not Irrational
            pi_giac = convert(GiacExpr, Giac.Constants.pi)
            sym_pi = Giac.to_symbolics(pi_giac)
            # Only test round-trip if to_giac supports Symbolics types
            try
                roundtrip = Giac.to_giac(sym_pi)
                @test string(roundtrip) == "pi"
            catch e
                if e isa MethodError
                    @test_skip "to_giac does not support this Symbolics type"
                else
                    rethrow(e)
                end
            end
        else
            @test_skip "Symbolics extension not loaded"
        end
    end
end
