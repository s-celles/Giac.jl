# UnitRange Support for Symbolic Indices Tests (037-unitrange-indices)
# Verifies that GiacMatrix and @giac_several_vars support UnitRange arguments

@testset "UnitRange Indices Support" begin

    # ========================================================================
    # User Story 1: GiacMatrix with Custom Index Range (P1)
    # ========================================================================

    @testset "GiacMatrix with UnitRange" begin

        @testset "0-based UnitRange (0:2, 0:2)" begin
            # T006: GiacMatrix with 0-based indices
            M = GiacMatrix(:m, 0:2, 0:2)
            @test M isa GiacMatrix
            @test size(M) == (3, 3)

            if !is_stub_mode()
                # Indices 0-9 don't need underscore separators
                @test string(M[1, 1]) == "m00"
                @test string(M[1, 2]) == "m01"
                @test string(M[2, 1]) == "m10"
                @test string(M[3, 3]) == "m22"
            end
        end

        @testset "Arbitrary range (5:7, 1:3)" begin
            # T007: GiacMatrix with arbitrary ranges
            A = GiacMatrix(:A, 5:7, 1:3)
            @test A isa GiacMatrix
            @test size(A) == (3, 3)

            if !is_stub_mode()
                # All indices ≤ 9, no separator needed
                @test string(A[1, 1]) == "A51"
                @test string(A[1, 3]) == "A53"
                @test string(A[3, 1]) == "A71"
                @test string(A[3, 3]) == "A73"
            end
        end

        @testset "Vector with 0-based UnitRange (0:4)" begin
            # T008: GiacMatrix vector with 0-based indices
            v = GiacMatrix(:v, 0:4)
            @test v isa GiacMatrix
            @test size(v) == (5, 1)

            if !is_stub_mode()
                # Single dimension indices 0-9 don't need separator
                @test string(v[1, 1]) == "v0"
                @test string(v[3, 1]) == "v2"
                @test string(v[5, 1]) == "v4"
            end
        end

        @testset "StepRange (0:2:6)" begin
            # T009: GiacMatrix with StepRange
            s = GiacMatrix(:s, 0:2:6)
            @test s isa GiacMatrix
            @test size(s) == (4, 1)  # 0, 2, 4, 6 = 4 elements

            if !is_stub_mode()
                # Indices 0-9 don't need separator
                @test string(s[1, 1]) == "s0"
                @test string(s[2, 1]) == "s2"
                @test string(s[3, 1]) == "s4"
                @test string(s[4, 1]) == "s6"
            end
        end

        @testset "Negative indices (-1:1)" begin
            # T010: GiacMatrix with negative indices
            x = GiacMatrix(:x, -1:1)
            @test x isa GiacMatrix
            @test size(x) == (3, 1)

            if !is_stub_mode()
                # Negative indices use 'm' prefix (m = minus) to avoid GIAC parsing issues
                @test string(x[1, 1]) == "x_m1"
                @test string(x[2, 1]) == "x_0"
                @test string(x[3, 1]) == "x_1"
            end
        end

        @testset "Mixed arguments (3, 0:2)" begin
            # T011: GiacMatrix with mixed integer and range
            M = GiacMatrix(:M, 3, 0:2)
            @test M isa GiacMatrix
            @test size(M) == (3, 3)

            if !is_stub_mode()
                # First dimension uses 1:3, second uses 0:2
                # All indices ≤ 9, no separator needed
                @test string(M[1, 1]) == "M10"
                @test string(M[1, 3]) == "M12"
                @test string(M[3, 1]) == "M30"
            end
        end

        @testset "Large range requiring separator (5:15)" begin
            # GiacMatrix with indices > 9 requiring separator
            L = GiacMatrix(:L, 5:15)
            @test L isa GiacMatrix
            @test size(L) == (11, 1)

            if !is_stub_mode()
                # Indices > 9 require underscore separator
                @test string(L[1, 1]) == "L_5"
                @test string(L[6, 1]) == "L_10"
                @test string(L[11, 1]) == "L_15"
            end
        end

        @testset "Single-element range (5:5)" begin
            # T013: GiacMatrix with single-element range
            S = GiacMatrix(:S, 5:5, 5:5)
            @test S isa GiacMatrix
            @test size(S) == (1, 1)

            if !is_stub_mode()
                # Single digit indices, no separator
                @test string(S[1, 1]) == "S55"
            end
        end
    end

    # ========================================================================
    # User Story 2: @giac_several_vars with Custom Index Range (P2)
    # ========================================================================

    @testset "@giac_several_vars with UnitRange" begin

        @testset "0-based 1D range (0:2)" begin
            # T019: @giac_several_vars with 0-based 1D range
            result = @giac_several_vars psi 0:2
            @test length(result) == 3
            @test result isa Tuple

            if !is_stub_mode()
                @test string(result[1]) == "psi0"
                @test string(result[2]) == "psi1"
                @test string(result[3]) == "psi2"
            end
        end

        @testset "2D custom ranges (0:1, 0:2)" begin
            # T020: @giac_several_vars with 2D custom ranges
            result = @giac_several_vars T 0:1 0:2
            @test length(result) == 6

            if !is_stub_mode()
                # Row-major order: T00, T01, T02, T10, T11, T12
                @test string(result[1]) == "T00"
                @test string(result[2]) == "T01"
                @test string(result[3]) == "T02"
                @test string(result[4]) == "T10"
            end
        end

        @testset "Indices 5:7" begin
            # T021: @giac_several_vars with indices 5:7
            result = @giac_several_vars x 5:7
            @test length(result) == 3

            if !is_stub_mode()
                @test string(result[1]) == "x5"
                @test string(result[2]) == "x6"
                @test string(result[3]) == "x7"
            end
        end

        @testset "Negative indices (-1:1)" begin
            # T022: @giac_several_vars with negative indices
            result = @giac_several_vars c -1:1
            @test length(result) == 3

            if !is_stub_mode()
                # Negative indices use 'm' prefix (m = minus) to avoid GIAC parsing issues
                @test string(result[1]) == "c_m1"
                @test string(result[2]) == "c_0"
                @test string(result[3]) == "c_1"
            end
        end

        @testset "StepRange (0:2:4)" begin
            # T023: @giac_several_vars with StepRange
            result = @giac_several_vars q 0:2:4
            @test length(result) == 3  # 0, 2, 4

            if !is_stub_mode()
                @test string(result[1]) == "q0"
                @test string(result[2]) == "q2"
                @test string(result[3]) == "q4"
            end
        end

        @testset "Mixed arguments (2, 0:1)" begin
            # T024: @giac_several_vars with mixed arguments
            result = @giac_several_vars mixed 2 0:1
            @test length(result) == 4  # 2 × 2

            if !is_stub_mode()
                # First dim: 1:2, second dim: 0:1
                @test string(result[1]) == "mixed10"
                @test string(result[2]) == "mixed11"
                @test string(result[3]) == "mixed20"
                @test string(result[4]) == "mixed21"
            end
        end

        @testset "Empty range (5:4)" begin
            # T025: @giac_several_vars with empty range
            result = @giac_several_vars empty 5:4
            @test result == ()
            @test length(result) == 0
        end

        @testset "Large range requiring separator (5:15)" begin
            # @giac_several_vars with indices > 9
            result = @giac_several_vars w 5:15
            @test length(result) == 11

            if !is_stub_mode()
                # Indices > 9 require underscore separator
                @test string(result[1]) == "w_5"
                @test string(result[6]) == "w_10"
                @test string(result[11]) == "w_15"
            end
        end
    end

    # ========================================================================
    # User Story 3: Backward Compatibility (P3)
    # ========================================================================

    @testset "Backward Compatibility" begin

        @testset "GiacMatrix(:m, 3, 3) unchanged" begin
            # T031: Backward compat for GiacMatrix
            M = GiacMatrix(:m, 3, 3)
            @test M isa GiacMatrix
            @test size(M) == (3, 3)

            if !is_stub_mode()
                # All indices 1-9, no separator needed (same as before)
                @test string(M[1, 1]) == "m11"
                @test string(M[2, 2]) == "m22"
                @test string(M[3, 3]) == "m33"
            end
        end

        @testset "@giac_several_vars a 2 3 unchanged" begin
            # T032: Backward compat for @giac_several_vars
            result = @giac_several_vars a 2 3
            @test length(result) == 6

            if !is_stub_mode()
                @test string(result[1]) == "a11"
                @test string(result[2]) == "a12"
                @test string(result[3]) == "a13"
                @test string(result[4]) == "a21"
            end
        end

        @testset "size() returns correct dimensions for ranges" begin
            # T033: size() returns length of ranges
            M1 = GiacMatrix(:r, 0:4, 0:2)
            @test size(M1) == (5, 3)

            M2 = GiacMatrix(:s, 5:9)
            @test size(M2) == (5, 1)

            M3 = GiacMatrix(:t, 0:2:10, 1:3)
            @test size(M3) == (6, 3)  # 0,2,4,6,8,10 = 6 elements
        end
    end

end
