@testset "Calculus" begin
    @testset "Differentiation" begin
        # T061-T064 [US4]: Test differentiation
        f = giac_eval("x^2")
        x = giac_eval("x")

        if is_stub_mode()
            # In stub mode, it will throw GiacError since C_NULL is returned
            @test_throws GiacError giac_diff(f, x)
        else
            # With real GIAC, differentiation works
            @test string(giac_diff(f, x)) == "2*x"
            @test string(giac_diff(giac_eval("x^3"), x)) == "3*x^2"
            @test string(giac_diff(giac_eval("x^3"), x, 2)) == "6*x"
        end

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

        if is_stub_mode()
            # In stub mode, throws GiacError
            @test_throws GiacError giac_integrate(f, x)
            @test_throws GiacError giac_integrate(f, x, 0, 1)
        else
            # With real GIAC, integration works
            @test contains(string(giac_integrate(f, x)), "x^3")
            @test string(giac_integrate(f, x, 0, 1)) == "1/3"
        end
    end

    @testset "Limits" begin
        # T069-T072 [US4]: Test limits
        f = giac_eval("sin(x)/x")
        x = giac_eval("x")
        point = giac_eval("0")

        if is_stub_mode()
            # In stub mode, throws GiacError
            @test_throws GiacError giac_limit(f, x, point)
        else
            # With real GIAC, limits work
            @test string(giac_limit(f, x, point)) == "1"
        end
    end

    @testset "Series" begin
        # T073-T076 [US4]: Test series expansion
        f = giac_eval("exp(x)")
        x = giac_eval("x")
        point = giac_eval("0")

        if is_stub_mode()
            # In stub mode, throws GiacError
            @test_throws GiacError giac_series(f, x, point, 5)
        else
            # With real GIAC, series expansion works
            result = string(giac_series(f, x, point, 4))
            @test contains(result, "1")
            @test contains(result, "x")
        end

        # Test negative order throws ArgumentError
        @test_throws ArgumentError giac_series(f, x, point, -1)
    end
end
