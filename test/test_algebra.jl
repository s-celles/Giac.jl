@testset "Algebra" begin
    @testset "Factorization" begin
        # T077-T080 [US5]: Test polynomial factorization via invoke_cmd
        p = giac_eval("x^2 - 1")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:factor, p)
            @test result isa GiacExpr
        else
            # With real GIAC, factorization works
            @test string(invoke_cmd(:factor, p)) == "(x-1)*(x+1)"
        end
    end

    @testset "Expansion" begin
        # T081-T084 [US5]: Test polynomial expansion via invoke_cmd
        p = giac_eval("(x+1)^2")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:expand, p)
            @test result isa GiacExpr
        else
            # With real GIAC, expansion works
            @test string(invoke_cmd(:expand, p)) == "x^2+2*x+1"
        end
    end

    @testset "Simplification" begin
        # T085-T088 [US5]: Test simplification via invoke_cmd
        e = giac_eval("(x^2-1)/(x-1)")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:simplify, e)
            @test result isa GiacExpr
        else
            # With real GIAC, simplification works
            @test string(invoke_cmd(:simplify, e)) == "x+1"
        end
    end

    @testset "Solving" begin
        # T089-T092 [US5]: Test equation solving via invoke_cmd
        eq = giac_eval("x^2 - 4")
        x = giac_eval("x")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:solve, eq, x)
            @test result isa GiacExpr
        else
            # With real GIAC, solving works
            result = string(invoke_cmd(:solve, eq, x))
            @test contains(result, "-2") && contains(result, "2")
        end
    end

    @testset "GCD" begin
        # T093-T096 [US5]: Test GCD computation via invoke_cmd
        a = giac_eval("x^2 - 1")
        b = giac_eval("x - 1")

        if is_stub_mode()
            # In stub mode, invoke_cmd returns a stub GiacExpr (no error)
            result = invoke_cmd(:gcd, a, b)
            @test result isa GiacExpr
        else
            # With real GIAC, gcd works
            @test string(invoke_cmd(:gcd, a, b)) == "x-1"
        end
    end
end
