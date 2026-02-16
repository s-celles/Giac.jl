@testset "Calculus" begin
    @testset "Differentiation" begin
        # T061-T064 [US4]: Test differentiation via invoke_cmd
        f = giac_eval("x^2")
        x = giac_eval("x")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:diff, f, x)
            @test result isa GiacExpr
        else
            # With real GIAC, differentiation works
            @test string(invoke_cmd(:diff, f, x)) == "2*x"
            @test string(invoke_cmd(:diff, giac_eval("x^3"), x)) == "3*x^2"
            @test string(invoke_cmd(:diff, giac_eval("x^3"), x, 2)) == "6*x"
        end
    end

    @testset "Integration" begin
        # T065-T068 [US4]: Test integration via invoke_cmd
        f = giac_eval("x^2")
        x = giac_eval("x")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:integrate, f, x)
            @test result isa GiacExpr
        else
            # With real GIAC, integration works
            @test contains(string(invoke_cmd(:integrate, f, x)), "x^3")
        end
    end

    @testset "Limits" begin
        # T069-T072 [US4]: Test limits via invoke_cmd
        f = giac_eval("sin(x)/x")
        x = giac_eval("x")
        point = giac_eval("0")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:limit, f, x, point)
            @test result isa GiacExpr
        else
            # With real GIAC, limits work
            @test string(invoke_cmd(:limit, f, x, point)) == "1"
        end
    end

    @testset "Series" begin
        # T073-T076 [US4]: Test series expansion via invoke_cmd
        f = giac_eval("exp(x)")
        x = giac_eval("x")
        point = giac_eval("0")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:series, f, x, point, 5)
            @test result isa GiacExpr
        else
            # With real GIAC, series expansion works
            result = string(invoke_cmd(:series, f, x, point, 4))
            @test contains(result, "1")
            @test contains(result, "x")
        end
    end
end
