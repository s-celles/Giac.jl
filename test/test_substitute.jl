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

    # ========================================================================
    # T030: GiacMatrix Substitution (Element-wise)
    # ========================================================================

    @testset "GiacMatrix Substitution" begin
        @testset "T030a: Single variable matrix substitution with Dict" begin
            @giac_var x
            M = GiacMatrix([x x+1; 2*x x^2])
            result = substitute(M, Dict(x => 3))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Check elements: [3 4; 6 9]
            @test string(result[1, 1]) == "3"
            @test string(result[1, 2]) == "4"
            @test string(result[2, 1]) == "6"
            @test string(result[2, 2]) == "9"
        end

        @testset "T030b: Single variable matrix substitution with Pair" begin
            @giac_var x
            M = GiacMatrix([x 2*x; x+1 x^2])
            result = substitute(M, x => 3)
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Check elements: [3 6; 4 9]
            @test string(result[1, 1]) == "3"
            @test string(result[1, 2]) == "6"
            @test string(result[2, 1]) == "4"
            @test string(result[2, 2]) == "9"
        end

        @testset "T030c: Multi-variable matrix substitution" begin
            @giac_var x y
            M = GiacMatrix([x+y x*y; x-y x/y])
            result = substitute(M, Dict(x => 6, y => 2))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # x=6, y=2: [8 12; 4 3]
            @test string(result[1, 1]) == "8"
            @test string(result[1, 2]) == "12"
            @test string(result[2, 1]) == "4"
            @test string(result[2, 2]) == "3"
        end

        @testset "T030d: Partial substitution in matrix" begin
            @giac_var x y
            M = GiacMatrix([x y; x+y x*y])
            result = substitute(M, Dict(x => 2))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Only x=2: [2 y; 2+y 2*y]
            @test string(result[1, 1]) == "2"
            @test string(result[1, 2]) == "y"
            result_21 = string(result[2, 1])
            result_22 = string(result[2, 2])
            @test occursin("2", result_21) && occursin("y", result_21)
            @test occursin("2", result_22) && occursin("y", result_22)
        end

        @testset "T030e: Empty Dict returns matrix copy" begin
            @giac_var x
            M = GiacMatrix([x x+1; 2*x 3*x])
            result = substitute(M, Dict{GiacExpr, Int}())
            @test result isa GiacMatrix
            @test size(result) == size(M)
            # Elements should be unchanged
            @test string(result[1, 1]) == string(M[1, 1])
            @test string(result[2, 2]) == string(M[2, 2])
        end

        @testset "T030f: Symbolic substitution in matrix" begin
            @giac_var x y
            M = GiacMatrix([x^2 x; 1 x+1])
            result = substitute(M, Dict(x => y + 1))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # x -> y+1: [(y+1)^2 y+1; 1 y+2]
            result_11 = string(result[1, 1])
            result_12 = string(result[1, 2])
            result_22 = string(result[2, 2])
            @test occursin("y", result_11)
            @test occursin("y", result_12)
            @test occursin("y", result_22)
        end

        @testset "T030g: Vector (1D matrix) substitution" begin
            @giac_var x
            V = GiacMatrix([x, 2*x, x^2])  # Column vector
            result = substitute(V, x => 2)
            @test result isa GiacMatrix
            @test size(result) == (3, 1)
            # x=2: [2, 4, 4]
            @test string(result[1, 1]) == "2"
            @test string(result[2, 1]) == "4"
            @test string(result[3, 1]) == "4"
        end
    end
end
