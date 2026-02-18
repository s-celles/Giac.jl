# Documentation Examples Tests: Electromagnetism (036-domain-docs-tests)
# Verifies all code examples in docs/src/physics/electromagnetism.md work correctly

@testset "Documentation Examples: Electromagnetism" begin
    using Giac.Commands: diff, integrate, solve, simplify, desolve

    @testset "Electrostatics - Coulomb's Law" begin
        @giac_var q1 q2 r k F

        if is_stub_mode()
            @test solve(F ~ k * q1 * q2 / r^2, r) isa GiacExpr
        else
            # Coulomb's law: F = k*q1*q2/r²
            result = string(solve(F ~ k * q1 * q2 / r^2, r))
            @test contains(result, "q1") && contains(result, "q2")
        end
    end

    @testset "Electric Potential" begin
        @giac_var q r k V

        if is_stub_mode()
            @test solve(V ~ k * q / r, q) isa GiacExpr
        else
            # Electric potential: V = k*q/r
            result = string(solve(V ~ k * q / r, q))
            @test contains(result, "V") && contains(result, "r")
        end
    end

    @testset "RC Circuit" begin
        @giac_var t R C V(t)

        if is_stub_mode()
            @test desolve([D(V) + V/(R*C) ~ 0], t, :V) isa GiacExpr
        else
            # RC circuit: dV/dt + V/(RC) = 0 using D operator
            ode = D(V) + V/(R*C) ~ 0
            result = string(desolve([ode], t, :V))
            @test contains(result, "exp")
        end
    end

    @testset "RL Circuit" begin
        @giac_var t R L I(t)

        if is_stub_mode()
            @test desolve([D(I) + R/L*I ~ 0], t, :I) isa GiacExpr
        else
            # RL circuit: dI/dt + (R/L)*I = 0 using D operator
            ode = D(I) + R/L*I ~ 0
            result = string(desolve([ode], t, :I))
            @test contains(result, "exp")
        end
    end

    @testset "Capacitor Energy" begin
        @giac_var C V E

        if is_stub_mode()
            @test solve(E ~ C * V^2 / 2, C) isa GiacExpr
        else
            # Energy stored in capacitor: E = (1/2)CV²
            result = string(solve(E ~ C * V^2 / 2, V))
            @test contains(result, "E") && contains(result, "C")
        end
    end

    @testset "Ohm's Law" begin
        @giac_var V I R

        if is_stub_mode()
            @test solve(V ~ I * R, I) isa GiacExpr
        else
            # Ohm's law: V = IR
            result = string(solve(V ~ I * R, I))
            @test contains(result, "V") && contains(result, "R")
        end
    end

    @testset "Wave Equation" begin
        @giac_var x t k omega

        if is_stub_mode()
            @test diff(sin(k * x - omega * t), t) isa GiacExpr
        else
            # Wave: E = E0*sin(kx - ωt)
            # Derivative with respect to time
            E = sin(k * x - omega * t)
            dE_dt = diff(E, t)
            result = string(dE_dt)
            @test contains(result, "omega") && contains(result, "cos")
        end
    end
end
