# Documentation Examples Tests: Calculus (036-domain-docs-tests)
# Verifies all code examples in docs/src/mathematics/calculus.md work correctly

@testset "Documentation Examples: Calculus" begin
    using Giac.Commands: diff, integrate, limit, series

    @testset "Differentiation Examples" begin
        @giac_var x y

        if is_stub_mode()
            # Stub mode: verify commands return GiacExpr
            @test diff(x^2, x) isa GiacExpr
            @test diff(x^3, x) isa GiacExpr
        else
            # Real GIAC: verify exact outputs
            # Basic differentiation
            @test string(diff(x^2, x)) == "2*x"
            @test string(diff(x^3, x)) == "3*x^2"

            # Higher-order derivatives
            @test string(diff(x^4, x, 2)) == "12*x^2"
            @test string(diff(x^5, x, 3)) == "60*x^2"

            # Chain rule
            @test string(diff(sin(x^2), x)) == "2*x*cos(x^2)"

            # Product rule
            result = string(diff(x * sin(x), x))
            @test contains(result, "sin") && contains(result, "cos")

            # Multivariable: partial derivative
            @test string(diff(x^2 * y^3, x)) == "2*x*y^3"
            # Note: GIAC may return x^2*3*y^2 instead of 3*x^2*y^2
            result = string(diff(x^2 * y^3, y))
            @test contains(result, "3") && contains(result, "x^2") && contains(result, "y^2")
        end
    end

    @testset "Integration Examples" begin
        @giac_var x

        if is_stub_mode()
            @test integrate(x^2, x) isa GiacExpr
        else
            # Indefinite integrals
            result = string(integrate(x^2, x))
            @test contains(result, "x^3") && contains(result, "3")

            @test contains(string(integrate(sin(x), x)), "cos")

            # Exponential integration
            @test contains(string(integrate(exp(x), x)), "exp")
        end
    end

    @testset "Limit Examples" begin
        @giac_var x inf

        if is_stub_mode()
            @test limit(sin(x) / x, x, 0) isa GiacExpr
        else
            # Classic limit: sin(x)/x as x→0
            @test string(limit(sin(x) / x, x, 0)) == "1"

            # Limit at infinity: 1/x → 0
            @test string(limit(1/x, x, inf)) == "0"

            # L'Hôpital case: (exp(x)-1)/x as x→0
            result = string(limit((exp(x)-1)/x, x, 0))
            @test result == "1"
        end
    end

    @testset "Taylor Series Examples" begin
        @giac_var x

        if is_stub_mode()
            @test series(exp(x), x, 0, 4) isa GiacExpr
        else
            # exp(x) series around 0
            result = string(series(exp(x), x, 0, 4))
            @test contains(result, "1") && contains(result, "x")

            # sin(x) series
            result = string(series(sin(x), x, 0, 5))
            @test contains(result, "x")

            # cos(x) series
            result = string(series(cos(x), x, 0, 4))
            @test contains(result, "1")
        end
    end

    @testset "Definite Integrals" begin
        @giac_var x

        if is_stub_mode()
            @test integrate(x^2, x, 0, 1) isa GiacExpr
        else
            # ∫₀¹ x² dx = 1/3
            result = string(integrate(x^2, x, 0, 1))
            @test contains(result, "1") && contains(result, "3")

            # ∫₀^π sin(x) dx = 2 (use invoke_cmd(:pi) for pi constant)
            result = string(integrate(sin(x), x, 0, invoke_cmd(:pi)))
            @test result == "2"
        end
    end
end
