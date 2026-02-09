@testset "Algebra" begin
    @testset "Factorization" begin
        # T077-T080 [US5]: Test polynomial factorization
        p = giac_eval("x^2 - 1")

        if is_stub_mode()
            # Test factor function (throws in stub mode)
            @test_throws GiacError giac_factor(p)
            @test_throws GiacError giac_factor("x^2 - 1")
        else
            # With real GIAC, factorization works
            @test string(giac_factor(p)) == "(x-1)*(x+1)"
            @test string(giac_factor("x^2 - 1")) == "(x-1)*(x+1)"
        end
    end

    @testset "Expansion" begin
        # T081-T084 [US5]: Test polynomial expansion
        p = giac_eval("(x+1)^2")

        if is_stub_mode()
            # Test expand function (throws in stub mode)
            @test_throws GiacError giac_expand(p)
            @test_throws GiacError giac_expand("(x+1)^2")
        else
            # With real GIAC, expansion works
            @test string(giac_expand(p)) == "x^2+2*x+1"
            @test string(giac_expand("(x+1)^2")) == "x^2+2*x+1"
        end
    end

    @testset "Simplification" begin
        # T085-T088 [US5]: Test simplification
        e = giac_eval("(x^2-1)/(x-1)")

        if is_stub_mode()
            # Test simplify function (throws in stub mode)
            @test_throws GiacError giac_simplify(e)
            @test_throws GiacError giac_simplify("(x^2-1)/(x-1)")
        else
            # With real GIAC, simplification works
            @test string(giac_simplify(e)) == "x+1"
            @test string(giac_simplify("(x^2-1)/(x-1)")) == "x+1"
        end
    end

    @testset "Solving" begin
        # T089-T092 [US5]: Test equation solving
        eq = giac_eval("x^2 - 4")
        x = giac_eval("x")

        if is_stub_mode()
            # Test solve function (throws in stub mode)
            @test_throws GiacError giac_solve(eq, x)
            @test_throws GiacError giac_solve("x^2 - 4", "x")
        else
            # With real GIAC, solving works
            result = string(giac_solve(eq, x))
            @test contains(result, "-2") && contains(result, "2")
            result2 = string(giac_solve("x^2 - 4", "x"))
            @test contains(result2, "-2") && contains(result2, "2")
        end
    end

    @testset "GCD" begin
        # T093-T096 [US5]: Test GCD computation
        a = giac_eval("x^2 - 1")
        b = giac_eval("x - 1")

        if is_stub_mode()
            # Test gcd function (throws in stub mode)
            @test_throws GiacError giac_gcd(a, b)
            @test_throws GiacError giac_gcd("x^2 - 1", "x - 1")
        else
            # With real GIAC, gcd works
            @test string(giac_gcd(a, b)) == "x-1"
            @test string(giac_gcd("x^2 - 1", "x - 1")) == "x-1"
        end
    end
end
