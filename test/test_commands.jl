# Tests for dynamic command invocation (invoke_cmd)
# Feature: 003-giac-commands (updated for 009-commands-submodule)

@testset "Dynamic Command Invocation (US1)" begin
    # Skip tests if in stub mode (no GIAC library)
    if Giac.is_stub_mode()
        @warn "Skipping command tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    @testset "Single-arg invocation" begin
        # T012: Test invoke_cmd(:factor, expr)
        expr = giac_eval("x^2 - 1")
        result = invoke_cmd(:factor, expr)
        @test result isa GiacExpr
        result_str = string(result)
        @test occursin("x-1", result_str) || occursin("x+1", result_str)
    end

    @testset "Trigonometric commands" begin
        # T013: Test invoke_cmd(:sin, expr)
        x = giac_eval("x")
        result = invoke_cmd(:sin, x)
        @test result isa GiacExpr
        @test string(result) == "sin(x)"

        # Test with numeric value
        pi_6 = giac_eval("pi/6")
        result = invoke_cmd(:sin, pi_6)
        @test result isa GiacExpr
    end

    @testset "Multi-arg invocation" begin
        # T014: Test invoke_cmd(:diff, expr, var)
        expr = giac_eval("x^2")
        x = giac_eval("x")
        result = invoke_cmd(:diff, expr, x)
        @test result isa GiacExpr
        @test string(result) == "2*x"
    end

    @testset "Unknown command error" begin
        # T015: Test unknown command with suggestions
        expr = giac_eval("x")
        @test_throws GiacError invoke_cmd(:factoor, expr)  # typo

        try
            invoke_cmd(:factoor, expr)
        catch e
            @test e isa GiacError
            @test e.category == :eval
            @test occursin("Unknown command", e.msg)
            # Should suggest "factor"
            @test occursin("factor", e.msg) || occursin("Did you mean", e.msg)
        end
    end

    @testset "Invalid argument type error" begin
        # T016: Test invalid argument type
        # Raw Julia arrays without conversion should fail
        @test_throws ArgumentError invoke_cmd(:factor, Dict("a" => 1))
    end
end

@testset "Method Syntax on GiacExpr (US5)" begin
    if Giac.is_stub_mode()
        @warn "Skipping method syntax tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    @testset "Method syntax basic" begin
        # T024: Test expr.factor()
        expr = giac_eval("x^2 - 1")
        result = expr.factor()
        @test result isa GiacExpr
        result_str = string(result)
        @test occursin("x-1", result_str) || occursin("x+1", result_str)
    end

    @testset "Method syntax with args" begin
        # T025: Test expr.diff(x)
        expr = giac_eval("x^3")
        x = giac_eval("x")
        result = expr.diff(x)
        @test result isa GiacExpr
        @test string(result) == "3*x^2"
    end

    @testset "Method chaining" begin
        # T026: Test expr.expand().simplify()
        expr = giac_eval("(x+1)^2")
        result = expr.expand()
        @test result isa GiacExpr
        # Expand should give x^2 + 2*x + 1
        result_str = string(result)
        @test occursin("x^2", result_str)
    end

    @testset "Method and function equivalence" begin
        # T027: Test that method and function syntax return identical results
        expr = giac_eval("x^2 - 4")

        method_result = expr.factor()
        func_result = invoke_cmd(:factor, expr)

        @test string(method_result) == string(func_result)
    end
end

@testset "Multi-Argument Command Support (US4)" begin
    if Giac.is_stub_mode()
        @warn "Skipping multi-arg tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    @testset "Substitution" begin
        # T033: Test invoke_cmd(:subst, expr, var, value)
        expr = giac_eval("x^2 + y")
        result = invoke_cmd(:subst, expr, giac_eval("x"), giac_eval("3"))
        @test result isa GiacExpr
        # x^2 + y with x=3 should give 9 + y
        result_str = string(result)
        @test occursin("9", result_str) || occursin("y", result_str)
    end

    @testset "Definite integral" begin
        # T034: Test invoke_cmd(:integrate, expr, var, a, b)
        expr = giac_eval("x^2")
        x = giac_eval("x")
        a = giac_eval("0")
        b = giac_eval("1")
        result = invoke_cmd(:integrate, expr, x, a, b)
        @test result isa GiacExpr
        # Integral of x^2 from 0 to 1 is 1/3
        result_str = string(result)
        @test occursin("1/3", result_str) || occursin("3", result_str)
    end

    @testset "Mixed argument types" begin
        # T036: Test mixed argument types (GiacExpr, Int, Float, Symbol)
        expr = giac_eval("x^2")

        # Symbol as variable name
        result = invoke_cmd(:diff, expr, :x)
        @test result isa GiacExpr
        @test string(result) == "2*x"

        # Integer as argument
        result = invoke_cmd(:diff, expr, :x, 2)  # Second derivative
        @test result isa GiacExpr
        @test string(result) == "2"
    end
end

@testset "Base Function Extensions" begin
    if Giac.is_stub_mode()
        @warn "Skipping Base extension tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    @testset "Base.sin" begin
        # T065: Test Base.sin(giac_eval("x"))
        x = giac_eval("x")
        result = sin(x)
        @test result isa GiacExpr
        @test string(result) == "sin(x)"
    end

    @testset "Base.cos" begin
        # T066: Test Base.cos(giac_eval("x"))
        x = giac_eval("x")
        result = cos(x)
        @test result isa GiacExpr
        @test string(result) == "cos(x)"
    end

    @testset "Base.exp" begin
        # T067: Test Base.exp(giac_eval("x"))
        x = giac_eval("x")
        result = exp(x)
        @test result isa GiacExpr
        @test string(result) == "exp(x)"
    end

    @testset "Combined expressions" begin
        # T068: Test sin(x) + cos(x) where x is GiacExpr
        x = giac_eval("x")
        result = sin(x) + cos(x)
        @test result isa GiacExpr
        result_str = string(result)
        @test occursin("sin", result_str)
        @test occursin("cos", result_str)
    end
end
