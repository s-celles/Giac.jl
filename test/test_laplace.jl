# Tests for Laplace transform and inverse Laplace transform (laplace/ilaplace)
# Feature: 040-laplace-transform
# Tests GIAC's native laplace and ilaplace commands

using Giac.Commands: laplace, ilaplace, simplify

@testset "Laplace Transform Functions (laplace/ilaplace)" begin

    # =========================================================================
    # User Story 1: Forward Laplace Transform Tests (laplace)
    # =========================================================================
    @testset "US1: laplace - Forward Laplace Transform" begin
        @giac_var t s a w

        # Laplace transform of constant 1 → 1/s
        @testset "laplace(1, t, s) → 1/s" begin
            result = laplace(giac_eval("1"), t, s)
            expected = giac_eval("1") / s
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Laplace transform of exponential exp(-a*t) → 1/(s+a)
        @testset "laplace(exp(-a*t), t, s) → 1/(s+a)" begin
            result = laplace(exp(-a * t), t, s)
            expected = giac_eval("1") / (s + a)
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Laplace transform of polynomial t^2 → 2!/s^3 = 2/s^3
        @testset "laplace(t^2, t, s) → 2/s^3" begin
            result = laplace(t^2, t, s)
            expected = giac_eval("2") / s^3
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Laplace transform of sinusoid sin(w*t) → w/(s^2+w^2)
        @testset "laplace(sin(w*t), t, s) → w/(s^2+w^2)" begin
            result = laplace(sin(w * t), t, s)
            expected = w / (s^2 + w^2)
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end
    end

    # =========================================================================
    # User Story 2: Inverse Laplace Transform Tests (ilaplace)
    # =========================================================================
    @testset "US2: ilaplace - Inverse Laplace Transform" begin
        @giac_var t s a

        # Inverse Laplace transform of 1/s → 1 (unit step)
        @testset "ilaplace(1/s, s, t) → 1" begin
            one = giac_eval("1")
            expr = one / s
            result = ilaplace(expr, s, t)
            @test string(result) == "1"
        end

        # Inverse Laplace transform of 1/(s+a) → exp(-a*t)
        @testset "ilaplace(1/(s+a), s, t) → exp(-a*t)" begin
            one = giac_eval("1")
            expr = one / (s + a)
            result = ilaplace(expr, s, t)
            expected = exp(-a * t)
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Inverse Laplace transform of 1/s^2 → t (ramp)
        @testset "ilaplace(1/s^2, s, t) → t" begin
            one = giac_eval("1")
            expr = one / s^2
            result = ilaplace(expr, s, t)
            diff_result = simplify(result - t)
            @test string(diff_result) == "0"
        end
    end

    # =========================================================================
    # User Story 3: Round-Trip Verification Tests
    # =========================================================================
    @testset "US3: Round-Trip Verification" begin
        @giac_var t s a

        # ilaplace(laplace(exp(-a*t), t, s), s, t) → exp(-a*t)
        @testset "Round-trip: exp(-a*t) → L → IL → exp(-a*t)" begin
            original = exp(-a * t)
            transformed = laplace(original, t, s)
            recovered = ilaplace(transformed, s, t)
            diff_result = simplify(recovered - original)
            @test string(diff_result) == "0"
        end

        # laplace(ilaplace(1/(s+a), s, t), t, s) → 1/(s+a)
        @testset "Round-trip: S-domain → IL → L → S-domain" begin
            one = giac_eval("1")
            original = one / (s + a)
            time_domain = ilaplace(original, s, t)
            recovered = laplace(time_domain, t, s)
            diff_result = simplify(recovered - original)
            @test string(diff_result) == "0"
        end
    end
end
