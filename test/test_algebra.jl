@testset "Algebra" begin
    @testset "Factorization" begin
        # T077-T080 [US5]: Test polynomial factorization
        p = giac_eval("x^2 - 1")

        # Test factor function (throws in stub mode)
        @test_throws GiacError giac_factor(p)

        # String input
        @test_throws GiacError giac_factor("x^2 - 1")
    end

    @testset "Expansion" begin
        # T081-T084 [US5]: Test polynomial expansion
        p = giac_eval("(x+1)^2")

        # Test expand function (throws in stub mode)
        @test_throws GiacError giac_expand(p)

        # String input
        @test_throws GiacError giac_expand("(x+1)^2")
    end

    @testset "Simplification" begin
        # T085-T088 [US5]: Test simplification
        e = giac_eval("(x^2-1)/(x-1)")

        # Test simplify function (throws in stub mode)
        @test_throws GiacError giac_simplify(e)

        # String input
        @test_throws GiacError giac_simplify("(x^2-1)/(x-1)")
    end

    @testset "Solving" begin
        # T089-T092 [US5]: Test equation solving
        eq = giac_eval("x^2 - 4")
        x = giac_eval("x")

        # Test solve function (throws in stub mode)
        @test_throws GiacError giac_solve(eq, x)

        # String input
        @test_throws GiacError giac_solve("x^2 - 4", "x")
    end

    @testset "GCD" begin
        # T093-T096 [US5]: Test GCD computation
        a = giac_eval("x^2 - 1")
        b = giac_eval("x - 1")

        # Test gcd function (throws in stub mode)
        @test_throws GiacError giac_gcd(a, b)

        # String input
        @test_throws GiacError giac_gcd("x^2 - 1", "x - 1")
    end
end
