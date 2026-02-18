# Documentation Examples Tests: Algebra (036-domain-docs-tests)
# Verifies all code examples in docs/src/mathematics/algebra.md work correctly

@testset "Documentation Examples: Algebra" begin
    using Giac.Commands: factor, expand, simplify, solve, gcd, lcm, quo, rem

    @testset "Polynomial Factorization" begin
        @giac_var x

        if is_stub_mode()
            @test factor(x^2 - 1) isa GiacExpr
        else
            @test string(factor(x^2 - 1)) == "(x-1)*(x+1)"
            @test string(factor(x^2 - 4)) == "(x-2)*(x+2)"
            @test string(factor(x^2 + 2*x + 1)) == "(x+1)^2"
        end
    end

    @testset "Polynomial Expansion" begin
        @giac_var x

        if is_stub_mode()
            @test expand((x + 1)^2) isa GiacExpr
        else
            @test string(expand((x + 1)^2)) == "x^2+2*x+1"
            @test string(expand((x + 1)^3)) == "x^3+3*x^2+3*x+1"
            @test string(expand((x - 1) * (x + 1))) == "x^2-1"
        end
    end

    @testset "Simplification" begin
        @giac_var x

        if is_stub_mode()
            @test simplify((x^2-1)/(x-1)) isa GiacExpr
        else
            @test string(simplify((x^2-1)/(x-1))) == "x+1"
            @test string(simplify((x^3-x)/(x^2-1))) == "x"
        end
    end

    @testset "Equation Solving" begin
        @giac_var x

        if is_stub_mode()
            @test solve(x^2 - 4, x) isa GiacExpr
        else
            result = string(solve(x^2 - 4, x))
            @test contains(result, "-2") && contains(result, "2")

            result = string(solve(x^2 - 1, x))
            @test contains(result, "-1") && contains(result, "1")
        end
    end

    @testset "GCD and LCM" begin
        @giac_var x

        if is_stub_mode()
            @test gcd(x^2 - 1, x - 1) isa GiacExpr
        else
            @test string(gcd(x^2 - 1, x - 1)) == "x-1"
            result = string(lcm(x - 1, x + 1))
            @test contains(result, "x-1") && contains(result, "x+1")
        end
    end

    @testset "Polynomial Division" begin
        @giac_var x

        if is_stub_mode()
            @test quo(x^3 - 1, x - 1) isa GiacExpr
        else
            @test string(quo(x^3 - 1, x - 1)) == "x^2+x+1"
            @test string(rem(x^3, x - 1)) == "1"
        end
    end

    @testset "Systems of Equations" begin
        @giac_var x y

        if is_stub_mode()
            @test solve([x + y ~ 1, x - y ~ 0], [x, y]) isa GiacExpr
        else
            result = string(solve([x + y ~ 1, x - y ~ 0], [x, y]))
            @test contains(result, "1/2")
        end
    end
end
