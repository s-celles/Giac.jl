# Test Inf and -Inf support in Giac.jl
# Feature: 038-inf-support

using Test
using Giac
using Giac.Commands: limit, integrate

@testset "Inf Support" begin

    @testset "Basic Conversion" begin
        # T004: Basic conversion tests
        @test string(convert(GiacExpr, Inf)) == "+infinity"
        @test string(convert(GiacExpr, -Inf)) == "-infinity"

        # Verify giac_eval("inf") produces same result
        @test string(giac_eval("inf")) == "+infinity"
        @test string(giac_eval("-inf")) == "-infinity"
    end

    @testset "User Story 1: Limits with Inf" begin
        @giac_var x

        # T006: limit(1/x, x, Inf) returns 0
        @test string(limit(1/x, x, Inf)) == "0"

        # T007: limit(1/x, x, -Inf) returns 0
        @test string(limit(1/x, x, -Inf)) == "0"

        # T008: limit(exp(-x), x, Inf) returns 0
        @test string(limit(exp(giac_eval("-x")), giac_eval("x"), Inf)) == "0"

        # T009: limit(x^2, x, Inf) returns infinity
        result = limit(x^2, x, Inf)
        @test string(result) == "+infinity"
    end

    @testset "User Story 2: Integrals with Inf" begin
        @giac_var x

        # T011: integrate(exp(-x), x, 0, Inf) returns 1
        result = integrate(exp(giac_eval("-x")), giac_eval("x"), 0, Inf)
        @test string(result) == "1"

        # T012: integrate(1/x^2, x, 1, Inf) returns 1
        result = integrate(1/x^2, x, 1, Inf)
        @test string(result) == "1"

        # T013: integrate(exp(x), x, -Inf, 0) returns 1
        result = integrate(exp(x), x, -Inf, 0)
        @test string(result) == "1"
    end

    @testset "User Story 3: Consistency with giac_eval(\"inf\")" begin
        @giac_var x

        # T015: Consistency for positive infinity in limits
        result_julia_inf = limit(1/x, x, Inf)
        result_giac_inf = limit(1/x, x, giac_eval("inf"))
        @test string(result_julia_inf) == string(result_giac_inf)

        # T016: Consistency for negative infinity in limits
        result_julia_neg_inf = limit(1/x, x, -Inf)
        result_giac_neg_inf = limit(1/x, x, giac_eval("-inf"))
        @test string(result_julia_neg_inf) == string(result_giac_neg_inf)

        # T017: Consistency for integrate with both notations
        result_julia = integrate(exp(giac_eval("-x")), giac_eval("x"), 0, Inf)
        result_giac = integrate(exp(giac_eval("-x")), giac_eval("x"), 0, giac_eval("inf"))
        @test string(result_julia) == string(result_giac)
    end

end
