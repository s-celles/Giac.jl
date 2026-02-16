# Tests for equation syntax using ~ operator (024-equation-syntax)
# This file tests the tilde operator for creating symbolic equations.

using Test
using Giac

@testset "Equation Syntax (024-equation-syntax)" begin

    # ========================================================================
    # User Story 1: Create Symbolic Equations (Priority: P1) - MVP
    # ========================================================================
    @testset "US1: Tilde operator creates equations" begin
        if !Giac.is_stub_mode()
            @testset "GiacExpr ~ GiacExpr returns GiacExpr" begin
                x = giac_eval("x")
                zero_expr = giac_eval("0")
                result = x ~ zero_expr
                @test result isa GiacExpr
            end

            @testset "Equation string contains =" begin
                x = giac_eval("x")
                result = x^2 - 1 ~ giac_eval("0")
                result_str = string(result)
                @test occursin("=", result_str)
            end

            @testset "GiacExpr ~ Number works" begin
                x = giac_eval("x")
                result = x ~ 5
                @test result isa GiacExpr
                result_str = string(result)
                @test occursin("=", result_str)
                @test occursin("5", result_str)
            end

            @testset "Number ~ GiacExpr works" begin
                x = giac_eval("x")
                result = 0 ~ x^2 - 1
                @test result isa GiacExpr
                result_str = string(result)
                @test occursin("=", result_str)
            end
        else
            @test_broken false  # US1 tests require real GIAC library
        end
    end

    # ========================================================================
    # User Story 2: Distinguish from Boolean Comparison (Priority: P2)
    # ========================================================================
    @testset "US2: Tilde vs equality distinction" begin
        if !Giac.is_stub_mode()
            @testset "Equality (==) returns Bool" begin
                x = giac_eval("x")
                y = giac_eval("x")
                result = x == y
                @test result isa Bool
            end

            @testset "Tilde (~) returns GiacExpr" begin
                x = giac_eval("x")
                y = giac_eval("y")
                result = x ~ y
                @test result isa GiacExpr
            end

            @testset "Equality and tilde return different types" begin
                x = giac_eval("x")
                y = giac_eval("y")
                eq_result = x == y
                tilde_result = x ~ y
                @test typeof(eq_result) != typeof(tilde_result)
            end
        else
            @test_broken false  # US2 tests require real GIAC library
        end
    end

    # ========================================================================
    # Integration Tests
    # ========================================================================
    @testset "Integration: Equations with GIAC commands" begin
        if !Giac.is_stub_mode()
            @testset "solve with tilde equation" begin
                x = giac_eval("x")
                eq = x^2 - 1 ~ giac_eval("0")
                # Use invoke_cmd since solve might conflict
                result = invoke_cmd(:solve, eq, x)
                @test result isa GiacExpr
                result_str = string(result)
                # Should contain roots -1 and 1
                @test occursin("1", result_str)
            end

            @testset "Complex equation x^2 ~ x + 1" begin
                x = giac_eval("x")
                eq = x^2 ~ x + 1
                @test eq isa GiacExpr
                result_str = string(eq)
                @test occursin("=", result_str)
            end
        else
            @test_broken false  # Integration tests require real GIAC library
        end
    end

end
