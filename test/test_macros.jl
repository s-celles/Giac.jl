# Tests for @giac_var macro (011-giac-symbol-macro)
# Tests for @giac_several_vars macro (012-giac-several-var)
# Tests for @giac_var function syntax (033-giac-var-function)

@testset "Macros" begin
    @testset "Single Variable Declaration (US1)" begin
        # T006: @giac_var x creates GiacExpr
        @testset "creates GiacExpr" begin
            @giac_var x
            @test x isa GiacExpr
        end

        # T007: string(x) == "x" after @giac_var x
        @testset "string representation matches symbol" begin
            @giac_var y
            @test string(y) == "y"
        end

        # T008: x isa GiacExpr after @giac_var x
        @testset "type is GiacExpr" begin
            @giac_var z
            @test z isa GiacExpr
            @test typeof(z) == GiacExpr
        end
    end

    @testset "Multiple Variable Declaration (US2)" begin
        # T013: @giac_var x y z creates three GiacExpr
        @testset "creates multiple GiacExpr" begin
            @giac_var x y z
            @test x isa GiacExpr
            @test y isa GiacExpr
            @test z isa GiacExpr
        end

        # T014: tuple return: x, y = @giac_var x y
        @testset "tuple return for destructuring" begin
            a, b = @giac_var a b
            @test a isa GiacExpr
            @test b isa GiacExpr
            @test string(a) == "a"
            @test string(b) == "b"
        end

        # T015: string values after @giac_var a b c
        @testset "string representation for multiple" begin
            @giac_var p q r
            @test string(p) == "p"
            @test string(q) == "q"
            @test string(r) == "r"
        end
    end

    @testset "Expression Interoperability (US3)" begin
        # T021: @giac_var variable with invoke_cmd(:diff, ...)
        @testset "with diff command" begin
            @giac_var x
            expr = giac_eval("x^2")
            if !is_stub_mode()
                result = invoke_cmd(:diff, expr, x)
                @test string(result) == "2*x"
            else
                # In stub mode, verify types work together
                @test x isa GiacExpr
                @test expr isa GiacExpr
            end
        end

        # T022: @giac_var variable + giac_eval arithmetic
        @testset "with giac_eval arithmetic" begin
            @giac_var x
            one = giac_eval("1")
            if !is_stub_mode()
                result = x + one
                @test result isa GiacExpr
                @test string(result) == "x+1"
            else
                # In stub mode, verify types
                @test x isa GiacExpr
                @test one isa GiacExpr
            end
        end

        # T023: @giac_var variable + manual giac_eval variable interop
        @testset "with manual giac_eval variable" begin
            @giac_var x
            y = giac_eval("y")
            if !is_stub_mode()
                result = x + y
                @test result isa GiacExpr
                @test string(result) == "x+y"
            else
                # In stub mode, verify types
                @test x isa GiacExpr
                @test y isa GiacExpr
            end
        end
    end

    @testset "Edge Cases" begin
        # T026: no-argument error
        @testset "no arguments throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_var
        end

        # T027: string argument error
        @testset "string argument throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_var "x"
        end

        # T028: numeric argument error
        @testset "numeric argument throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_var 1
        end
    end

    # Tests for @giac_var function syntax (033-giac-var-function)
    @testset "Function Syntax - US1: Single-Variable Functions" begin
        # T002: Backward compatibility - existing @giac_var x y z still works
        @testset "backward compatibility @giac_var x y z" begin
            @giac_var x_compat y_compat z_compat
            @test x_compat isa GiacExpr
            @test y_compat isa GiacExpr
            @test z_compat isa GiacExpr
            @test string(x_compat) == "x_compat"
            @test string(y_compat) == "y_compat"
            @test string(z_compat) == "z_compat"
        end

        # T005: @giac_var u(t) returns GiacExpr with string(u) == "u(t)"
        @testset "@giac_var u(t) creates function GiacExpr" begin
            @giac_var u(t)
            @test u isa GiacExpr
            @test string(u) == "u(t)"
        end

        # T006: @giac_var f(x) followed by diff(f, x)
        @testset "@giac_var f(x) with differentiation" begin
            @giac_var func_x(x_var)
            @test func_x isa GiacExpr
            @test string(func_x) == "func_x(x_var)"
            if !is_stub_mode()
                @giac_var x_var
                result = invoke_cmd(:diff, func_x, x_var)
                @test result isa GiacExpr
                # Result should be the derivative of func_x with respect to x_var
            end
        end

        # T007: Separate @giac_var u(t) and @giac_var t work together
        @testset "separate @giac_var u(t) and @giac_var t" begin
            @giac_var u_sep(t_sep)
            @giac_var t_sep
            @test u_sep isa GiacExpr
            @test t_sep isa GiacExpr
            @test string(u_sep) == "u_sep(t_sep)"
            @test string(t_sep) == "t_sep"
        end
    end

    @testset "Function Syntax - US2: Multi-Variable Functions" begin
        # T010: @giac_var f(x, y) returns GiacExpr with string(f) == "f(x,y)"
        @testset "@giac_var f(x, y) creates multi-var function" begin
            @giac_var f_xy(x_mv, y_mv)
            @test f_xy isa GiacExpr
            @test string(f_xy) == "f_xy(x_mv,y_mv)"
        end

        # T011: @giac_var g(x, y, z) with 3 arguments
        @testset "@giac_var g(x, y, z) with 3 arguments" begin
            @giac_var g_xyz(x_3, y_3, z_3)
            @test g_xyz isa GiacExpr
            @test string(g_xyz) == "g_xyz(x_3,y_3,z_3)"
        end
    end

    @testset "Function Syntax - US3: Mixed Declarations" begin
        # T014: @giac_var x y u(t) creates 2 variables and 1 function
        @testset "@giac_var x y u(t) mixed declaration" begin
            @giac_var x_mix y_mix u_mix(t_mix)
            @test x_mix isa GiacExpr
            @test y_mix isa GiacExpr
            @test u_mix isa GiacExpr
            @test string(x_mix) == "x_mix"
            @test string(y_mix) == "y_mix"
            @test string(u_mix) == "u_mix(t_mix)"
        end

        # T015: @giac_var t u(t) v(t) creates 1 variable and 2 functions
        @testset "@giac_var t u(t) v(t) one var two functions" begin
            @giac_var t_two u_two(t_two) v_two(t_two)
            @test t_two isa GiacExpr
            @test u_two isa GiacExpr
            @test v_two isa GiacExpr
            @test string(t_two) == "t_two"
            @test string(u_two) == "u_two(t_two)"
            @test string(v_two) == "v_two(t_two)"
        end
    end

    @testset "Function Syntax - Edge Cases" begin
        # T018: @giac_var u() raises ArgumentError (zero arguments)
        @testset "@giac_var u() throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_var u()
        end

        # T019: @giac_var u(1) raises ArgumentError (non-symbol argument)
        @testset "@giac_var u(1) throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_var u(1)
        end

        # T020: @giac_var u(t, 2) raises ArgumentError (mixed arguments)
        @testset "@giac_var u(t, 2) throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_var u(t, 2)
        end
    end

    # Tests for @giac_several_vars (012-giac-several-var)
    @testset "@giac_several_vars: US1 - 1D Variable Vector" begin
        # T004: Basic 1D variable creation
        @testset "basic 1D creation @giac_several_vars a 3" begin
            result = @giac_several_vars a 3
            @test a1 isa GiacExpr
            @test a2 isa GiacExpr
            @test a3 isa GiacExpr
            @test string(a1) == "a1"
            @test string(a2) == "a2"
            @test string(a3) == "a3"
            # Verify tuple return
            @test result isa Tuple
            @test length(result) == 3
            # Use === for identity comparison (GiacExpr == is symbolic comparison)
            @test result[1] === a1
            @test result[2] === a2
            @test result[3] === a3
        end

        # T005: 1D variables usable in expressions
        @testset "1D variables usable in expressions" begin
            @giac_several_vars b 3
            @test b1 isa GiacExpr
            @test b2 isa GiacExpr
            @test b3 isa GiacExpr
            if !is_stub_mode()
                result = b1 + b2 + b3
                @test result isa GiacExpr
                @test string(result) == "b1+b2+b3"
            end
        end

        # T006: Edge case - single variable
        @testset "edge case @giac_several_vars c 1" begin
            @giac_several_vars c 1
            @test c1 isa GiacExpr
            @test string(c1) == "c1"
        end

        # T007: Edge case - zero variables
        @testset "edge case @giac_several_vars d 0" begin
            # Should create no variables, return empty tuple
            result = @giac_several_vars d 0
            @test !@isdefined(d0)
            @test !@isdefined(d1)
            @test result == ()
            @test result isa Tuple
            @test length(result) == 0
        end
    end

    @testset "@giac_several_vars: US2 - 2D Variable Matrix" begin
        # T010: Basic 2D variable creation
        @testset "basic 2D creation @giac_several_vars m 2 3" begin
            result = @giac_several_vars m 2 3
            @test m11 isa GiacExpr
            @test m12 isa GiacExpr
            @test m13 isa GiacExpr
            @test m21 isa GiacExpr
            @test m22 isa GiacExpr
            @test m23 isa GiacExpr
            @test string(m11) == "m11"
            @test string(m23) == "m23"
            # Verify tuple return (2x3 = 6 variables)
            @test result isa Tuple
            @test length(result) == 6
            # Use === for identity comparison
            @test result[1] === m11
            @test result[6] === m23
        end

        # T011: 2D variables usable in matrix expressions
        @testset "2D variables usable in expressions" begin
            @giac_several_vars n 2 2
            @test n11 isa GiacExpr
            @test n22 isa GiacExpr
            if !is_stub_mode()
                # Determinant calculation
                det = n11 * n22 - n12 * n21
                @test det isa GiacExpr
            end
        end

        # T012: Square matrix
        @testset "square matrix @giac_several_vars s 3 3" begin
            @giac_several_vars s 3 3
            @test s11 isa GiacExpr
            @test s22 isa GiacExpr
            @test s33 isa GiacExpr
            @test string(s11) == "s11"
            @test string(s33) == "s33"
        end
    end

    @testset "@giac_several_vars: US3 - N-Dimensional Variables" begin
        # T015: 3D variable creation
        @testset "3D creation @giac_several_vars t 2 2 2" begin
            result = @giac_several_vars t 2 2 2
            @test t111 isa GiacExpr
            @test t112 isa GiacExpr
            @test t121 isa GiacExpr
            @test t122 isa GiacExpr
            @test t211 isa GiacExpr
            @test t212 isa GiacExpr
            @test t221 isa GiacExpr
            @test t222 isa GiacExpr
            @test string(t111) == "t111"
            @test string(t222) == "t222"
            # Verify tuple return (2x2x2 = 8 variables)
            @test result isa Tuple
            @test length(result) == 8
            # Use === for identity comparison
            @test result[1] === t111
            @test result[8] === t222
        end

        # T016: 4D variable creation
        @testset "4D creation @giac_several_vars x 2 2 2 2" begin
            @giac_several_vars x 2 2 2 2
            @test x1111 isa GiacExpr
            @test x2222 isa GiacExpr
            @test string(x1111) == "x1111"
            @test string(x2222) == "x2222"
        end

        # T017: Underscore separator when dimension > 9
        @testset "underscore separator when dim > 9" begin
            @giac_several_vars w 2 10 3
            # Should use underscore separator since 10 > 9
            @test w_1_1_1 isa GiacExpr
            @test w_1_10_1 isa GiacExpr
            @test w_2_10_3 isa GiacExpr
            @test string(w_1_1_1) == "w_1_1_1"
            @test string(w_1_10_1) == "w_1_10_1"
            @test string(w_2_10_3) == "w_2_10_3"
        end

        # T018: Lexicographic ordering
        @testset "lexicographic ordering" begin
            # Variables should be generated in row-major order
            # For @giac_several_vars v 2 3: v11, v12, v13, v21, v22, v23
            @giac_several_vars v 2 3
            @test string(v11) == "v11"
            @test string(v12) == "v12"
            @test string(v13) == "v13"
            @test string(v21) == "v21"
            @test string(v22) == "v22"
            @test string(v23) == "v23"
        end
    end

    @testset "@giac_several_vars: US4 - Variable Naming Flexibility" begin
        # T021: Longer base name
        @testset "longer base name @giac_several_vars coeff 3" begin
            @giac_several_vars coeff 3
            @test coeff1 isa GiacExpr
            @test coeff2 isa GiacExpr
            @test coeff3 isa GiacExpr
            @test string(coeff1) == "coeff1"
        end

        # T022: Unicode base name
        @testset "Unicode base name @giac_several_vars α 2" begin
            @giac_several_vars α 2
            @test α1 isa GiacExpr
            @test α2 isa GiacExpr
            @test string(α1) == "α1"
            @test string(α2) == "α2"
        end

        # T023: Underscore in base name
        @testset "underscore in base name @giac_several_vars x_vec 2" begin
            @giac_several_vars x_vec 2
            @test x_vec1 isa GiacExpr
            @test x_vec2 isa GiacExpr
            @test string(x_vec1) == "x_vec1"
        end
    end

    @testset "@giac_several_vars: Edge Cases and Error Handling" begin
        # T026: Negative dimension throws error
        @testset "negative dimension throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_several_vars a -1
        end

        # T027: Non-integer dimension throws error
        @testset "non-integer dimension throws error" begin
            @test_throws ArgumentError @macroexpand @giac_several_vars a 2.5
        end

        # T028: Missing dimensions throws error
        @testset "missing dimensions throws ArgumentError" begin
            @test_throws ArgumentError @macroexpand @giac_several_vars a
        end

        # T029: Invalid base name (string instead of symbol)
        @testset "invalid base name throws error" begin
            @test_throws ArgumentError @macroexpand @giac_several_vars "a" 3
        end
    end
end
