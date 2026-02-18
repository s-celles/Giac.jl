# Tests for Z-transform and inverse Z-transform (ztrans/invztrans)
# Feature: 039-z-transform
# Tests GIAC's native ztrans and invztrans commands

using Giac.Commands: ztrans, invztrans, simplify

@testset "Z-Transform Functions (ztrans/invztrans)" begin

    # =========================================================================
    # User Story 1: Forward Z-Transform Tests (ztrans)
    # =========================================================================
    @testset "US1: ztrans - Forward Z-Transform" begin
        @giac_var n z a

        # Z-transform of constant 1 (unit step) → z/(z-1)
        @testset "ztrans(1, n, z) → z/(z-1)" begin
            result = ztrans(giac_eval("1"), n, z)
            expected = z / (z - giac_eval("1"))
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Z-transform of geometric sequence a^n → -z/(a-z) or z/(z-a)
        @testset "ztrans(a^n, n, z) → z/(z-a) equivalent" begin
            result = ztrans(a^n, n, z)
            # GIAC returns -z/(a-z) which equals z/(z-a)
            expected = -z / (a - z)
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Z-transform of ramp sequence n → z/(z-1)^2
        @testset "ztrans(n, n, z) → z/(z-1)^2 equivalent" begin
            result = ztrans(n, n, z)
            one = giac_eval("1")
            expected = z / (z - one)^2
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end
    end

    # =========================================================================
    # User Story 2: Inverse Z-Transform Tests (invztrans)
    # =========================================================================
    @testset "US2: invztrans - Inverse Z-Transform" begin
        @giac_var n z a

        # Inverse z-transform of z/(z-1) → 1 (unit step)
        @testset "invztrans(z/(z-1), z, n) → 1" begin
            one = giac_eval("1")
            expr = z / (z - one)
            result = invztrans(expr, z, n)
            @test string(result) == "1"
        end

        # Inverse z-transform of z/(z-a) → a^n
        @testset "invztrans(z/(z-a), z, n) → a^n" begin
            expr = z / (z - a)
            result = invztrans(expr, z, n)
            expected = a^n
            diff_result = simplify(result - expected)
            @test string(diff_result) == "0"
        end

        # Inverse z-transform of z/(z-1)^2 → n
        @testset "invztrans(z/(z-1)^2, z, n) → n" begin
            one = giac_eval("1")
            expr = z / (z - one)^2
            result = invztrans(expr, z, n)
            diff_result = simplify(result - n)
            @test string(diff_result) == "0"
        end
    end

    # =========================================================================
    # User Story 3: Round-Trip Verification Tests
    # =========================================================================
    @testset "US3: Round-Trip Verification" begin
        @giac_var n z a

        # invztrans(ztrans(a^n, n, z), z, n) → a^n
        @testset "Round-trip: a^n → Z → IZ → a^n" begin
            original = a^n
            transformed = ztrans(original, n, z)
            recovered = invztrans(transformed, z, n)
            diff_result = simplify(recovered - original)
            @test string(diff_result) == "0"
        end

        # ztrans(invztrans(z/(z-a), z, n), n, z) → z/(z-a)
        @testset "Round-trip: Z-domain → IZ → Z → Z-domain" begin
            original = z / (z - a)
            time_domain = invztrans(original, z, n)
            recovered = ztrans(time_domain, n, z)
            diff_result = simplify(recovered - original)
            @test string(diff_result) == "0"
        end
    end
end
