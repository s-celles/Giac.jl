# Tests for @giac_var macro (011-giac-symbol-macro)

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
        # T021: @giac_var variable with giac_diff
        @testset "with giac_diff" begin
            @giac_var x
            expr = giac_eval("x^2")
            if !is_stub_mode()
                result = giac_diff(expr, x)
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
end
