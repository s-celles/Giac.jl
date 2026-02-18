@testset "Types" begin
    @testset "GiacInput type alias (032-vector-input-solve)" begin
        # T002: Test that AbstractVector is part of GiacInput union
        @test AbstractVector <: GiacInput
        @test Vector{GiacExpr} <: GiacInput
        @test Vector{Int} <: GiacInput
        @test Vector{Any} <: GiacInput
        # Verify existing types still work
        @test GiacExpr <: GiacInput
        @test Number <: GiacInput
        @test String <: GiacInput
        @test Symbol <: GiacInput
    end

    @testset "GiacError" begin
        # T007: Test GiacError exception type
        err = GiacError("test error", :parse)
        @test err isa Exception
        @test err.msg == "test error"
        @test err.category == :parse

        # Test error categories
        @test GiacError("", :eval).category == :eval
        @test GiacError("", :type).category == :type
        @test GiacError("", :memory).category == :memory
    end

    @testset "GiacExpr" begin
        # T007: Test GiacExpr type exists
        @test isdefined(Giac, :GiacExpr)

        # Test GiacExpr has required fields
        # Note: Actual construction requires wrapper to be working
    end

    @testset "GiacContext" begin
        # T007: Test GiacContext type exists
        @test isdefined(Giac, :GiacContext)

        # T034 [US2]: Test DEFAULT_CONTEXT is initialized
        @test isdefined(Giac, :DEFAULT_CONTEXT)
    end

    @testset "to_julia conversion" begin
        # T022 [US1]: Test to_julia numeric conversion
        # These tests will be expanded when giac_eval is working
    end

    # Callable GiacExpr Tests (034-callable-giacexpr)
    @testset "Callable GiacExpr - Helper Function" begin
        # T002: Test _arg_to_giac_string with GiacExpr argument
        @testset "_arg_to_giac_string with GiacExpr" begin
            if !is_stub_mode()
                x = giac_eval("x")
                @test Giac._arg_to_giac_string(x) == "x"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T003: Test _arg_to_giac_string with Int argument
        @testset "_arg_to_giac_string with Int" begin
            @test Giac._arg_to_giac_string(42) == "42"
            @test Giac._arg_to_giac_string(0) == "0"
            @test Giac._arg_to_giac_string(-5) == "-5"
        end

        # T004: Test _arg_to_giac_string with Float64 argument
        @testset "_arg_to_giac_string with Float64" begin
            @test Giac._arg_to_giac_string(3.14) == "3.14"
            @test Giac._arg_to_giac_string(0.0) == "0.0"
        end

        # T005: Test _arg_to_giac_string with Symbol argument
        @testset "_arg_to_giac_string with Symbol" begin
            @test Giac._arg_to_giac_string(:x) == "x"
            @test Giac._arg_to_giac_string(:abc) == "abc"
        end

        # Test _extract_function_name helper
        @testset "_extract_function_name" begin
            # Simple function calls should extract the name
            @test Giac._extract_function_name("u(t)") == "u"
            @test Giac._extract_function_name("f(x,y)") == "f"
            @test Giac._extract_function_name("func(a,b,c)") == "func"

            # Simple identifiers should return nothing
            @test Giac._extract_function_name("x") === nothing
            @test Giac._extract_function_name("abc") === nothing

            # Expressions with operators should return nothing
            @test Giac._extract_function_name("a+b") === nothing
            @test Giac._extract_function_name("x^2") === nothing

            # GIAC operations should NOT be extracted (they are operations, not user functions)
            @test Giac._extract_function_name("diff(u,t)") === nothing
            @test Giac._extract_function_name("sin(x)") === nothing
            @test Giac._extract_function_name("integrate(f,x)") === nothing
        end
    end

    @testset "Callable GiacExpr - US1: Basic Function Evaluation" begin
        # T007: Test calling GiacExpr with single numeric argument
        @testset "u(0) with numeric argument" begin
            if !is_stub_mode()
                @giac_var u(t)
                result = u(0)
                @test result isa GiacExpr
                @test string(result) == "u(0)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T008: Test calling GiacExpr with GiacExpr argument
        @testset "f(x) with GiacExpr argument" begin
            if !is_stub_mode()
                @giac_var f(t) x
                result = f(x)
                @test result isa GiacExpr
                @test string(result) == "f(x)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T009: Test calling GiacExpr created by giac_eval
        @testset "callable on giac_eval result" begin
            if !is_stub_mode()
                u = giac_eval("u")
                result = u(0)
                @test result isa GiacExpr
                @test string(result) == "u(0)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T010: Test calling GiacExpr with zero arguments
        @testset "u() with zero arguments" begin
            if !is_stub_mode()
                @giac_var u(t)
                result = u()
                @test result isa GiacExpr
                @test string(result) == "u()"
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

    @testset "Callable GiacExpr - US2: ODE Initial Conditions" begin
        # T014: Test u(0) ~ 1 creating valid equation
        @testset "u(0) ~ 1 creates equation" begin
            if !is_stub_mode()
                @giac_var u(t)
                eq = u(0) ~ 1
                @test eq isa GiacExpr
                # The equation should contain "u(0)=1" or equivalent
                eq_str = string(eq)
                @test occursin("u(0)", eq_str)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T015: Test diff(u, t)(0) ~ 1 derivative condition
        @testset "diff(u, t)(0) ~ 1 derivative condition" begin
            if !is_stub_mode()
                @giac_var t u(t)
                du = invoke_cmd(:diff, u, t)
                du_at_0 = du(0)
                @test du_at_0 isa GiacExpr
                eq = du_at_0 ~ 1
                @test eq isa GiacExpr
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T016: Test diff(u, t, 2)(0) ~ 0 n-th derivative condition
        @testset "diff(u, t, 2)(0) n-th derivative" begin
            if !is_stub_mode()
                @giac_var t u(t)
                d2u = invoke_cmd(:diff, u, t, 2)
                d2u_at_0 = d2u(0)
                @test d2u_at_0 isa GiacExpr
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T017: Integration test with desolve
        @testset "desolve integration" begin
            if !is_stub_mode()
                @giac_var t u(t)
                # Simple ODE: u' = 0 with u(0) = 1 should give u = 1
                du = invoke_cmd(:diff, u, t)
                ode = du ~ 0
                initial = u(0) ~ 1
                # Just verify we can construct the problem
                @test ode isa GiacExpr
                @test initial isa GiacExpr
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

    @testset "Callable GiacExpr - US3: Multiple Arguments" begin
        # T020: Test f(0, 0) with two numeric arguments
        @testset "f(0, 0) with two numeric args" begin
            if !is_stub_mode()
                @giac_var f(x, y)
                result = f(0, 0)
                @test result isa GiacExpr
                @test string(result) == "f(0,0)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T021: Test f(a, b) with two GiacExpr arguments
        @testset "f(a, b) with two GiacExpr args" begin
            if !is_stub_mode()
                @giac_var f(x, y) a b
                result = f(a, b)
                @test result isa GiacExpr
                @test string(result) == "f(a,b)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T022: Test f(x, 1) with mixed argument types
        @testset "f(x, 1) mixed argument types" begin
            if !is_stub_mode()
                @giac_var f(x, y) x
                result = f(x, 1)
                @test result isa GiacExpr
                @test string(result) == "f(x,1)"
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

    @testset "Callable GiacExpr - Edge Cases" begin
        # T025: Test nested calls f(g(x))
        @testset "nested calls f(g(x))" begin
            if !is_stub_mode()
                @giac_var f(t) g(t) x
                g_of_x = g(x)
                f_of_g_of_x = f(g_of_x)
                @test f_of_g_of_x isa GiacExpr
                @test string(f_of_g_of_x) == "f(g(x))"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T026: Test Rational argument u(1//2)
        @testset "Rational argument u(1//2)" begin
            if !is_stub_mode()
                @giac_var u(t)
                result = u(1//2)
                @test result isa GiacExpr
                # GIAC should interpret 1//2 appropriately
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T027: Test Float64 argument u(0.5)
        @testset "Float64 argument u(0.5)" begin
            if !is_stub_mode()
                @giac_var u(t)
                result = u(0.5)
                @test result isa GiacExpr
                @test string(result) == "u(0.5)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T028: Test invalid argument type raises ArgumentError
        @testset "invalid argument type raises error" begin
            if !is_stub_mode()
                @giac_var u(t)
                # Passing a Dict or other invalid type should raise ArgumentError
                @test_throws ArgumentError u(Dict())
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T029: Test null GiacExpr raises GiacError
        @testset "null GiacExpr raises error" begin
            # Create a null GiacExpr (for testing only)
            null_expr = GiacExpr(C_NULL)
            @test_throws GiacError null_expr(0)
        end
    end

    @testset "LaTeX display (014-pluto-latex-notebook)" begin
        # Test that MIME"text/latex" show method is defined for GiacExpr
        @test hasmethod(Base.show, Tuple{IO, MIME"text/latex", GiacExpr})

        # Test that MIME"text/latex" show method is defined for GiacMatrix
        @test hasmethod(Base.show, Tuple{IO, MIME"text/latex", GiacMatrix})

        if !is_stub_mode()
            # Test actual LaTeX output for GiacExpr
            expr = giac_eval("2/(1-x)")
            io = IOBuffer()
            show(io, MIME"text/latex"(), expr)
            latex_output = String(take!(io))
            @test startswith(latex_output, "\$\$")
            @test endswith(latex_output, "\$\$")
            @test length(latex_output) > 4  # More than just "$$$$"

            # Test actual LaTeX output for GiacMatrix
            M = GiacMatrix([1 2; 3 4])
            io = IOBuffer()
            show(io, MIME"text/latex"(), M)
            latex_output = String(take!(io))
            @test startswith(latex_output, "\$\$")
            @test endswith(latex_output, "\$\$")
        else
            @test_broken false  # Skipping LaTeX output tests in stub mode
        end
    end
end
