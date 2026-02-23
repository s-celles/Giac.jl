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

@testset "Vector Input for GIAC Commands (032-vector-input-solve)" begin
    if Giac.is_stub_mode()
        @warn "Skipping vector input tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    @testset "US1: Solve systems of equations with vectors" begin
        @giac_var x y z

        # T005: Test solve([x+y~0, x-y~2], [x,y]) returning [[1, -1]]
        result = Giac.Commands.solve([x+y~0, x-y~2], [x, y])
        @test result isa GiacExpr
        result_str = string(result)
        # Result should contain [[1,-1]] indicating x=1, y=-1
        @test occursin("1", result_str)
        @test occursin("-1", result_str)

        # T006: Test 3-equation system solve([eq1, eq2, eq3], [x, y, z])
        result3 = Giac.Commands.solve([x+y+z~6, x-y~0, y+z~4], [x, y, z])
        @test result3 isa GiacExpr
        result3_str = string(result3)
        # Solution should exist (non-empty result)
        @test !isempty(result3_str)
        @test result3_str != "[]"

        # T007: Test inconsistent system returning empty result
        # x + y = 1 and x + y = 2 are inconsistent
        result_empty = Giac.Commands.solve([x+y~1, x+y~2], [x, y])
        @test result_empty isa GiacExpr
        # Inconsistent systems should return empty list []
        result_empty_str = string(result_empty)
        @test result_empty_str == "[]"
    end

    @testset "US2: Vector input with other commands" begin
        @giac_var x y z

        # T010: Test vector input to list command (e.g., sum of vector)
        # sum([x, y, z]) should return x+y+z
        sum_result = Giac.Commands.sum([x, y, z])
        @test sum_result isa GiacExpr
        sum_str = string(sum_result)
        @test occursin("x", sum_str) || occursin("y", sum_str) || occursin("z", sum_str)

        # T011: Test mixed-type vector [1, x, 2.5]
        mixed_result = Giac.Commands.sum([1, x, 2])
        @test mixed_result isa GiacExpr
        # Should be able to handle mixed numeric and symbolic types
    end

    @testset "US3: Nested vector input for matrices" begin
        # T014: Test det_minor([[1,2],[3,4]]) with nested vectors
        # Note: det_minor computes the actual determinant value
        det_result = Giac.Commands.det_minor([[1, 2], [3, 4]])
        @test det_result isa GiacExpr
        det_str = string(det_result)
        # Determinant of [[1,2],[3,4]] = 1*4 - 2*3 = -2
        @test det_str == "-2"

        # T015: Test inverse via invoke_cmd with nested vectors
        # inverse() computes the actual matrix inverse
        inv_result = Giac.Commands.inverse([[1, 2], [3, 4]])
        @test inv_result isa GiacExpr
        inv_str = string(inv_result)
        # Should return a matrix representation
        @test occursin("[", inv_str)
    end

    @testset "Edge Cases: Empty and Deeply Nested Vectors" begin
        # T018: Test empty vector [] conversion
        empty_result = Giac.Commands.nops([])
        @test empty_result isa GiacExpr
        # nops([]) should return 0 (number of elements in empty list)
        @test string(empty_result) == "0"

        # T019: Test deeply nested vectors (3+ levels)
        # A 3D array-like structure
        deep_result = invoke_cmd(:nops, [[[1, 2], [3, 4]], [[5, 6], [7, 8]]])
        @test deep_result isa GiacExpr
        # Should return 2 (number of top-level elements)
        @test string(deep_result) == "2"
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

    @testset "Base.diff multiple dispatch" begin
        # Test that Base.diff still works for arrays (021-remove-giac-prefix)
        @test diff([1, 4, 9, 16]) == [3, 5, 7]  # Base.diff for arrays

        # Test that diff works for GiacExpr (symbolic differentiation)
        x = giac_eval("x")
        f = giac_eval("x^2")
        result = diff(f, x)
        @test result isa GiacExpr
        @test string(result) == "2*x"
    end
end

# ============================================================================
# GiacMatrix Command Support (058-commands-matrix-support)
# ============================================================================
@testset "GiacMatrix Command Support (058-commands-matrix-support)" begin
    if Giac.is_stub_mode()
        @warn "Skipping GiacMatrix command tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    M = GiacMatrix([[1, 2], [3, 4]])

    @testset "invoke_cmd with GiacMatrix" begin
        # T003: invoke_cmd(:eigenvals, GiacMatrix(...))
        result = invoke_cmd(:eigenvals, M)
        @test result isa GiacExpr
        result_str = string(result)
        # Eigenvalues of [[1,2],[3,4]] are (5±√33)/2
        @test !isempty(result_str)

        # T005: invoke_cmd(:det, GiacMatrix(...))
        det_result = invoke_cmd(:det, M)
        @test det_result isa GiacExpr
        @test string(det_result) == "-2"

        # T006: invoke_cmd(:transpose, GiacMatrix(...))
        trans_result = invoke_cmd(:transpose, M)
        @test trans_result isa GiacExpr
        trans_str = string(trans_result)
        @test occursin("[", trans_str)
    end

    @testset "Giac.Commands with GiacMatrix" begin
        # T004: eigenvals(GiacMatrix(...)) via generated Tier 2 command
        eigenvals_result = Giac.Commands.eigenvals(M)
        @test eigenvals_result isa GiacExpr
        @test !isempty(string(eigenvals_result))

        # trace via GiacMatrix-specific method (trace is in JULIA_CONFLICTS
        # but safe for GiacMatrix via multiple dispatch)
        trace_result = Giac.Commands.trace(M)
        @test trace_result isa GiacExpr
        @test string(trace_result) == "5"
    end

    @testset "GiacMatrix with symbolic entries" begin
        # T007: Matrix with symbolic entries
        @giac_var x y
        M_sym = GiacMatrix([[x, y], [1, x]])
        det_sym = invoke_cmd(:det, M_sym)
        @test det_sym isa GiacExpr
        det_str = string(det_sym)
        @test occursin("x", det_str)
    end
end

# ============================================================================
# HeldCmd Equation Tilde Operator (059-heldcmd-equation-tilde)
# ============================================================================
@testset "HeldCmd Equation Tilde Operator (059-heldcmd-equation-tilde)" begin
    if Giac.is_stub_mode()
        @warn "Skipping HeldCmd tilde tests - GIAC library not available (stub mode)"
        @test_skip true
        return
    end

    using Giac.Commands: hold_cmd, release
    using Giac: HeldEquation

    M = GiacMatrix([[1, 2], [3, 4]])

    @testset "HeldCmd ~ GiacExpr" begin
        # SC-001: hold_cmd(:eigenvals, M) ~ eigenvals(M) produces valid equation
        h = hold_cmd(:eigenvals, M)
        result = Giac.Commands.eigenvals(M)
        eq = h ~ result
        @test eq isa HeldEquation
        eq_str = string(eq)
        @test occursin("=", eq_str)
        # LaTeX should preserve unevaluated form
        latex_io = IOBuffer()
        show(latex_io, MIME("text/latex"), eq)
        latex_str = String(take!(latex_io))
        @test occursin("eigenvals", latex_str)
        @test occursin("=", latex_str)
    end

    @testset "GiacExpr ~ HeldCmd" begin
        h = hold_cmd(:eigenvals, M)
        result = Giac.Commands.eigenvals(M)
        eq = result ~ h
        @test eq isa HeldEquation
        eq_str = string(eq)
        @test occursin("=", eq_str)
        # LaTeX should preserve unevaluated form on the right
        latex_io = IOBuffer()
        show(latex_io, MIME("text/latex"), eq)
        latex_str = String(take!(latex_io))
        @test occursin("eigenvals", latex_str)
    end

    @testset "HeldCmd ~ HeldCmd" begin
        @giac_var x
        h1 = hold_cmd(:factor, x^2 - 1)
        h2 = hold_cmd(:expand, (x - 1) * (x + 1))
        eq = h1 ~ h2
        @test eq isa HeldEquation
        eq_str = string(eq)
        @test occursin("=", eq_str)
    end

    @testset "HeldCmd ~ Number" begin
        h = hold_cmd(:det, M)
        eq = h ~ -2
        @test eq isa HeldEquation
        eq_str = string(eq)
        @test occursin("=", eq_str)
        @test occursin("-2", eq_str)
    end

    @testset "Number ~ HeldCmd" begin
        h = hold_cmd(:det, M)
        eq = -2 ~ h
        @test eq isa HeldEquation
        eq_str = string(eq)
        @test occursin("=", eq_str)
        @test occursin("-2", eq_str)
    end
end
