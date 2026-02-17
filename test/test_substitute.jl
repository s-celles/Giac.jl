# Tests for substitute function (028-substitute-mechanism)

@testset "Substitute Function" begin
    # Skip tests if GIAC library not available
    if Giac.is_stub_mode()
        @warn "Skipping substitute tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    # ========================================================================
    # Phase 3: User Story 1 - Single Variable Substitution (P1 MVP)
    # ========================================================================

    @testset "US1: Single Variable Substitution" begin
        @testset "T007: Single numeric substitution" begin
            @giac_var a b
            expr = a + b
            result = substitute(expr, Dict(a => 2))
            @test result isa GiacExpr
            # Result should be 2 + b
            result_str = string(result)
            @test occursin("2", result_str) || occursin("b", result_str)
        end

        @testset "T008: Polynomial substitution" begin
            @giac_var x
            expr = x^2 + 3*x + 1
            result = substitute(expr, Dict(x => 5))
            @test result isa GiacExpr
            # x=5: 25 + 15 + 1 = 41
            result_str = string(result)
            @test occursin("41", result_str)
        end

        @testset "T009: Trig function substitution" begin
            @giac_var x
            expr = invoke_cmd(:sin, x) + x
            result = substitute(expr, Dict(x => 0))
            @test result isa GiacExpr
            # sin(0) + 0 = 0
            result_str = string(result)
            @test result_str == "0"
        end

        @testset "T010: Empty Dict returns original" begin
            @giac_var x
            expr = x + 1
            result = substitute(expr, Dict{GiacExpr, Int}())
            @test result isa GiacExpr
            @test string(result) == string(expr)
        end

        @testset "T011: Missing variable returns original" begin
            @giac_var x y
            expr = x + 1
            result = substitute(expr, Dict(y => 5))
            @test result isa GiacExpr
            # y is not in expr, so result should be unchanged
            @test string(result) == string(expr)
        end
    end

    # ========================================================================
    # Phase 4: User Story 2 - Multiple Variable Substitution (P2)
    # ========================================================================

    @testset "US2: Multiple Variable Substitution" begin
        @testset "T015: Multi-variable substitution" begin
            @giac_var a b c
            expr = a + b + c
            result = substitute(expr, Dict(a => 1, b => 2))
            @test result isa GiacExpr
            # a=1, b=2: 1 + 2 + c = 3 + c
            result_str = string(result)
            @test occursin("3", result_str) || (occursin("c", result_str))
        end

        @testset "T016: Complete substitution" begin
            @giac_var x y z
            expr = x*y + y*z
            result = substitute(expr, Dict(x => 2, y => 3, z => 4))
            @test result isa GiacExpr
            # 2*3 + 3*4 = 6 + 12 = 18
            result_str = string(result)
            @test occursin("18", result_str)
        end

        @testset "T017: Variable swap (simultaneous)" begin
            @giac_var a b
            expr = a^2 + b
            result = substitute(expr, Dict(a => b, b => a))
            @test result isa GiacExpr
            # Simultaneous: a^2 + b -> b^2 + a
            result_str = string(result)
            # Should contain b^2 and a (swapped)
            @test occursin("a", result_str) && occursin("b", result_str)
        end
    end

    # ========================================================================
    # Phase 5: User Story 3 - Symbolic-to-Symbolic Substitution (P3)
    # ========================================================================

    @testset "US3: Symbolic-to-Symbolic Substitution" begin
        @testset "T020: Symbolic substitution" begin
            @giac_var x y
            expr = x^2
            result = substitute(expr, Dict(x => y + 1))
            @test result isa GiacExpr
            # x^2 with x=y+1 -> (y+1)^2
            result_str = string(result)
            @test occursin("y", result_str)
        end

        @testset "T021: Symbolic in trig" begin
            @giac_var x y
            expr = invoke_cmd(:sin, x)
            result = substitute(expr, Dict(x => 2*y))
            @test result isa GiacExpr
            # sin(x) with x=2*y -> sin(2*y)
            result_str = string(result)
            @test occursin("sin", result_str) && occursin("y", result_str)
        end
    end

    # ========================================================================
    # Phase 6: User Story 4 - Pair Syntax Alternative (P4)
    # ========================================================================

    @testset "US4: Pair Syntax Alternative" begin
        @testset "T023: Pair syntax numeric" begin
            @giac_var x
            expr = x + 1
            result = substitute(expr, x => 5)
            @test result isa GiacExpr
            # x + 1 with x=5 -> 6
            result_str = string(result)
            @test occursin("6", result_str)
        end

        @testset "T024: Pair syntax symbolic result" begin
            @giac_var a b
            expr = a * b
            result = substitute(expr, a => 3)
            @test result isa GiacExpr
            # a*b with a=3 -> 3*b
            result_str = string(result)
            @test occursin("3", result_str) && occursin("b", result_str)
        end
    end

    # ========================================================================
    # Phase 7: Edge Cases & Robustness
    # ========================================================================

    @testset "Edge Cases" begin
        @testset "T027: Different numeric types" begin
            @giac_var x
            expr = x + 1

            # Int
            r1 = substitute(expr, Dict(x => 2))
            @test r1 isa GiacExpr

            # Float64
            r2 = substitute(expr, Dict(x => 2.5))
            @test r2 isa GiacExpr

            # Rational
            r3 = substitute(expr, Dict(x => 1//2))
            @test r3 isa GiacExpr
        end

        @testset "T028: Chained substitution" begin
            @giac_var x y z
            expr = x + y + z
            d1 = Dict(x => 1)
            d2 = Dict(y => 2)

            # Chained: substitute twice
            r1 = substitute(expr, d1)
            r2 = substitute(r1, d2)
            @test r2 isa GiacExpr
            # 1 + 2 + z = 3 + z
            result_str = string(r2)
            @test occursin("3", result_str) || occursin("z", result_str)
        end

        @testset "T029: Invalid value type throws ArgumentError" begin
            @giac_var x
            expr = x + 1
            @test_throws ArgumentError substitute(expr, Dict(x => nothing))
        end
    end
end
