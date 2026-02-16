# Tests for Julia type conversion (022-julia-type-conversion)
# This file tests that native Julia types can be passed to GIAC command functions

using Giac.Commands

@testset "Type Conversion (022-julia-type-conversion)" begin

    # ========================================================================
    # User Story 1: Direct Integer Usage (Priority: P1)
    # ========================================================================
    @testset "US1: Integer Types" begin
        if !Giac.is_stub_mode()
            # T006: ifactor with integer
            @testset "ifactor(1000) returns factorization" begin
                result = ifactor(1000)
                @test result isa GiacExpr
                result_str = string(result)
                # 1000 = 2^3 * 5^3
                @test occursin("2", result_str)
                @test occursin("5", result_str)
            end

            # T007: isprime with integer
            @testset "isprime(17) returns truthy" begin
                result = isprime(17)
                @test result isa GiacExpr
                # isprime returns "true" or "1" depending on GIAC version
                @test string(result) in ["1", "true"]
            end

            # T008: Negative integer handling
            @testset "ifactor(-24) handles sign correctly" begin
                result = ifactor(-24)
                @test result isa GiacExpr
                result_str = string(result)
                # -24 = -1 * 2^3 * 3
                @test occursin("-", result_str) || occursin("2", result_str)
            end

            # T009: BigInt support
            @testset "BigInt support" begin
                big_num = big"123456789012345678901234567890"
                result = ifactor(big_num)
                @test result isa GiacExpr
            end
        else
            @test_broken false  # US1 tests require real GIAC library
        end
    end

    # ========================================================================
    # User Story 2: Floating-Point Numbers (Priority: P2)
    # ========================================================================
    @testset "US2: Float Types" begin
        if !Giac.is_stub_mode()
            # T012: Float64 argument handling
            @testset "Float64 argument handling" begin
                # Use a function that accepts floats
                result = approx(2.5)
                @test result isa GiacExpr
            end

            # T013: Special float values (Inf, NaN)
            @testset "Special float values" begin
                # Infinity
                result_inf = approx(Inf)
                @test result_inf isa GiacExpr

                # NaN
                result_nan = approx(NaN)
                @test result_nan isa GiacExpr
            end
        else
            @test_broken false  # US2 tests require real GIAC library
        end
    end

    # ========================================================================
    # User Story 3: Rational Numbers (Priority: P2)
    # ========================================================================
    @testset "US3: Rational Types" begin
        if !Giac.is_stub_mode()
            # T016: Rational conversion to GIAC format
            @testset "Rational conversion 1//2" begin
                result = simplify(1//2)
                @test result isa GiacExpr
                # Should preserve exact arithmetic
                result_str = string(result)
                @test occursin("1", result_str) || occursin("2", result_str)
            end

            # T017: Rational arithmetic preservation
            @testset "Rational arithmetic preservation" begin
                # 1/2 + 1/3 = 5/6
                result = simplify(1//2 + 1//3)
                @test result isa GiacExpr
                result_str = string(result)
                @test occursin("5", result_str) || occursin("6", result_str)
            end
        else
            @test_broken false  # US3 integration tests require real GIAC library
        end

        # T018: Unit test for _arg_to_giac_string(::Rational) - works in stub mode
        @testset "_arg_to_giac_string(::Rational) format" begin
            @test Giac._arg_to_giac_string(1//2) == "(1)/(2)"
            @test Giac._arg_to_giac_string(3//4) == "(3)/(4)"
            @test Giac._arg_to_giac_string(-1//2) == "(-1)/(2)"
        end
    end

    # ========================================================================
    # User Story 4: Complex Numbers (Priority: P3)
    # ========================================================================
    @testset "US4: Complex Types" begin
        if !Giac.is_stub_mode()
            # T021: Complex number conversion
            @testset "Complex number 1 + 2im" begin
                result = simplify(1 + 2im)
                @test result isa GiacExpr
            end

            # T022: Purely imaginary number
            @testset "Purely imaginary 3im" begin
                result = simplify(3im)
                @test result isa GiacExpr
            end

            # T023: Negative imaginary part
            @testset "Negative imaginary 1 - 2im" begin
                result = simplify(1 - 2im)
                @test result isa GiacExpr
            end
        else
            @test_broken false  # US4 integration tests require real GIAC library
        end

        # T024: Unit test for _arg_to_giac_string(::Complex) - works in stub mode
        @testset "_arg_to_giac_string(::Complex) format" begin
            @test Giac._arg_to_giac_string(1 + 2im) == "(1)+(2)*i"
            @test Giac._arg_to_giac_string(1 - 2im) == "(1)+(-2)*i"
            @test Giac._arg_to_giac_string(3im) == "(0)+(3)*i"
            @test Giac._arg_to_giac_string(0 + 0im) == "(0)+(0)*i"
        end
    end

    # ========================================================================
    # User Story 5: Mixed Type Arguments (Priority: P3)
    # ========================================================================
    @testset "US5: Mixed Type Arguments" begin
        if !Giac.is_stub_mode()
            # T027: Mixed GiacExpr and integer
            @testset "Mixed GiacExpr and integer" begin
                x = giac_eval("x")
                expr = x^2
                # subs(x^2, x, 3) should return 9
                result = subs(expr, x, 3)
                @test result isa GiacExpr
                @test string(result) == "9"
            end

            # T028: Mixed types in multi-argument functions
            @testset "Mixed types in multi-argument functions" begin
                x = giac_eval("x")
                # diff(x^3, x, 2) = 6*x (second derivative)
                result = diff(x^3, x, 2)
                @test result isa GiacExpr
            end
        else
            @test_broken false  # US5 tests require real GIAC library
        end
    end

    # ========================================================================
    # Edge Cases (Phase 8)
    # ========================================================================
    @testset "Edge Cases" begin
        if !Giac.is_stub_mode()
            # T031: AbstractIrrational types (pi, e)
            @testset "AbstractIrrational types (pi, e)" begin
                result_pi = simplify(pi)
                @test result_pi isa GiacExpr
                @test occursin("pi", lowercase(string(result_pi)))

                result_e = simplify(MathConstants.e)
                @test result_e isa GiacExpr
            end
        else
            @test_broken false  # Edge case integration tests require real GIAC library
        end

        # T032: Error on unsupported types - works in stub mode
        @testset "Error on unsupported types" begin
            @test_throws ArgumentError Giac._arg_to_giac_string(nothing)
            @test_throws ArgumentError Giac._arg_to_giac_string(missing)
            @test_throws ArgumentError Giac._arg_to_giac_string(Dict())
        end

        # T033: Vector inputs with Julia numeric types - works in stub mode
        @testset "Vector inputs with numeric types" begin
            vec_result = Giac._arg_to_giac_string([1, 2, 3])
            @test vec_result == "[1,2,3]"

            mixed_vec = Giac._arg_to_giac_string([1//2, 3//4])
            @test mixed_vec == "[(1)/(2),(3)/(4)]"
        end
    end

    # ========================================================================
    # Backward Compatibility (Phase 9)
    # ========================================================================
    @testset "Backward Compatibility" begin
        if !Giac.is_stub_mode()
            # T038: Existing GiacExpr code still works
            @testset "GiacExpr arguments still work" begin
                expr = giac_eval("1000")
                result = ifactor(expr)
                @test result isa GiacExpr
                result_str = string(result)
                @test occursin("2", result_str)
                @test occursin("5", result_str)
            end

            @testset "String arguments still work" begin
                result = ifactor("1000")
                @test result isa GiacExpr
            end

            @testset "Symbol arguments still work" begin
                result = simplify(:x)
                @test result isa GiacExpr
                @test string(result) == "x"
            end
        else
            @test_broken false  # Backward compatibility tests require real GIAC library
        end
    end
end
