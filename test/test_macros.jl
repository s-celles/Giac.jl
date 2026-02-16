# Tests for @giac_var macro (011-giac-symbol-macro)
# Tests for @giac_several_vars macro (012-giac-several-var)

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
