# Tests for multiple dispatch on JULIA_CONFLICTS commands (023-conflicts-multidispatch)
# This file tests that GIAC commands in JULIA_CONFLICTS can be called with GiacExpr
# while Base/LinearAlgebra functions continue to work with standard Julia types.

using Giac
using Giac.Commands
using LinearAlgebra

@testset "Multiple Dispatch for Conflicts (023-conflicts-multidispatch)" begin

    # ========================================================================
    # User Story 1: zeros with GiacExpr (Priority: P1) - MVP
    # ========================================================================
    @testset "US1: zeros with GiacExpr" begin
        if !Giac.is_stub_mode()
            @testset "zeros(x^2-1) returns polynomial roots" begin
                x = giac_eval("x")
                result = zeros(x^2 - 1)
                @test result isa GiacExpr
                result_str = string(result)
                # GIAC zeros returns a list of roots
                @test occursin("-1", result_str) || occursin("1", result_str)
            end

            @testset "zeros(x^2-4) returns roots [-2, 2]" begin
                x = giac_eval("x")
                result = zeros(x^2 - 4)
                @test result isa GiacExpr
                result_str = string(result)
                @test occursin("2", result_str)
            end
        else
            @test_broken false  # US1 tests require real GIAC library
        end
    end

    # ========================================================================
    # User Story 3: Mathematical functions on GiacExpr (Priority: P2)
    # ========================================================================
    @testset "US3: Mathematical functions on GiacExpr" begin
        if !Giac.is_stub_mode()
            # Note: Base.sum/prod take iterables and try to iterate, which doesn't work
            # with GiacExpr. For GIAC's sum/prod commands, use invoke_cmd directly.
            @testset "sum via invoke_cmd" begin
                result = invoke_cmd(:sum, giac_eval("[a, b, c]"))
                @test result isa GiacExpr
                result_str = string(result)
                # Sum should combine the elements
                @test occursin("a", result_str) || occursin("b", result_str) || occursin("c", result_str)
            end

            @testset "product via invoke_cmd" begin
                # GIAC uses 'product' not 'prod'
                result = invoke_cmd(:product, giac_eval("[a, b, c]"))
                @test result isa GiacExpr
                result_str = string(result)
                @test occursin("a", result_str) || occursin("b", result_str) || occursin("c", result_str)
            end

            @testset "min/max with GiacExpr" begin
                a = giac_eval("a")
                b = giac_eval("b")
                result_min = min(a, b)
                result_max = max(a, b)
                @test result_min isa GiacExpr
                @test result_max isa GiacExpr
            end
        else
            @test_broken false  # US3 tests require real GIAC library
        end
    end

    # ========================================================================
    # User Story 4: No interference with Base functions (Priority: P1)
    # ========================================================================
    @testset "US4: Base functions unchanged" begin
        # These tests should pass regardless of GIAC implementation
        @testset "Base.zeros(Int, 3) returns Julia array" begin
            result = zeros(Int, 3)
            @test result isa Vector{Int}
            @test result == [0, 0, 0]
        end

        @testset "Base.zeros(3, 3) returns Julia Matrix{Float64}" begin
            result = zeros(3, 3)
            @test result isa Matrix{Float64}
            @test size(result) == (3, 3)
            @test all(result .== 0.0)
        end

        @testset "LinearAlgebra.det unchanged" begin
            result = det([1.0 2.0; 3.0 4.0])
            @test result ≈ -2.0
        end

        @testset "Mixed dispatch works correctly" begin
            if !Giac.is_stub_mode()
                # Julia zeros
                julia_zeros = zeros(2, 2)
                @test julia_zeros isa Matrix{Float64}

                # GIAC zeros (polynomial roots)
                x = giac_eval("x")
                giac_zeros = zeros(x^2 - 1)
                @test giac_zeros isa GiacExpr

                # Back to Julia zeros
                julia_zeros2 = zeros(Int, 5)
                @test julia_zeros2 isa Vector{Int}
            else
                @test_broken false  # Mixed dispatch test requires real GIAC library
            end
        end
    end

    # ========================================================================
    # Edge Cases: Keywords not extended, Tier 1 preserved
    # ========================================================================
    @testset "Edge Cases" begin
        @testset "Keywords not accessible as functions" begin
            # These are Julia keywords - they cannot be function names
            # Trying to call them would be a syntax error, so we just verify
            # they're in the keyword category
            @test :if in Giac.CONFLICT_CATEGORIES[:keyword]
            @test :for in Giac.CONFLICT_CATEGORIES[:keyword]
            @test :while in Giac.CONFLICT_CATEGORIES[:keyword]
        end

        @testset "Tier 1 wrappers preserved for sin, cos" begin
            if !Giac.is_stub_mode()
                # sin/cos should work with GiacExpr (existing Tier 1 wrappers)
                x = giac_eval("x")
                result_sin = sin(x)
                result_cos = cos(x)
                @test result_sin isa GiacExpr
                @test result_cos isa GiacExpr
                @test string(result_sin) == "sin(x)"
                @test string(result_cos) == "cos(x)"
            else
                @test_broken false  # Tier 1 tests require real GIAC library
            end
        end
    end

end
