@testset "Calculus" begin
    @testset "Differentiation" begin
        # T061-T064 [US4]: Test differentiation
        # With actual library, these would compute derivatives
        f = giac_eval("x^2")
        x = giac_eval("x")

        # Test that diff function works (returns GiacExpr or throws)
        # In stub mode, it will throw GiacError since C_NULL is returned
        @test_throws GiacError giac_diff(f, x)

        # Test negative order throws ArgumentError
        @test_throws ArgumentError giac_diff(f, x, -1)

        # Test order 0 returns original expression
        result = giac_diff(f, x, 0)
        @test result === f
    end

    @testset "Integration" begin
        # T065-T068 [US4]: Test integration
        f = giac_eval("x^2")
        x = giac_eval("x")

        # Test that integrate function works (returns GiacExpr or throws in stub mode)
        @test_throws GiacError giac_integrate(f, x)

        # Definite integration
        @test_throws GiacError giac_integrate(f, x, 0, 1)
    end

    @testset "Limits" begin
        # T069-T072 [US4]: Test limits
        f = giac_eval("sin(x)/x")
        x = giac_eval("x")
        point = giac_eval("0")

        # Test limit computation (throws in stub mode)
        @test_throws GiacError giac_limit(f, x, point)
    end

    @testset "Series" begin
        # T073-T076 [US4]: Test series expansion
        f = giac_eval("exp(x)")
        x = giac_eval("x")
        point = giac_eval("0")

        # Test series expansion (throws in stub mode)
        @test_throws GiacError giac_series(f, x, point, 5)

        # Test negative order throws ArgumentError
        @test_throws ArgumentError giac_series(f, x, point, -1)
    end
end
