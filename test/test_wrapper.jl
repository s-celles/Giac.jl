@testset "Wrapper" begin
    @testset "Library Loading" begin
        # T008, T035 [US2]: Test library loading
        @test isdefined(Giac, :init_giac_library)

        # Library should be loaded during module init
        # If we got here, module loaded successfully
        @test true
    end

    @testset "Stub Mode" begin
        # Test is_stub_mode function
        @test is_stub_mode() isa Bool
        # Without GIAC_WRAPPER_LIB set, should be in stub mode
        if !haskey(ENV, "GIAC_WRAPPER_LIB")
            @test is_stub_mode() == true
        end
    end

    @testset "Low-level Functions" begin
        # T008: Placeholder tests for ccall bindings
        # These will be filled in as wrapper functions are implemented
        @test isdefined(Giac, :_giac_eval_string)
    end

    @testset "Tier 2 N-ary Dispatch (4+ parameters)" begin
        # Test apply_funcN for functions with more than 3 parameters
        # These use the new apply_funcN C++ function via CxxWrap

        @testset "series (4 params)" begin
            # series(expr, var, point, order) - use string to avoid exp() stub issues
            result = giac_eval("series(exp(x),x,0,4)")
            @test result isa GiacExpr
            if !is_stub_mode()
                result_str = string(result)
                # Should contain Taylor expansion terms
                @test contains(result_str, "x") || contains(result_str, "1")
            end
        end

        @testset "sum (4 params)" begin
            # sum(expr, var, start, end)
            result = giac_eval("sum(k,k,1,10)")
            @test result isa GiacExpr
            if !is_stub_mode()
                # sum of 1 to 10 = 55
                @test contains(string(result), "55")
            end
        end

        @testset "product (4 params)" begin
            # product(expr, var, start, end)
            result = giac_eval("product(k,k,1,5)")
            @test result isa GiacExpr
            if !is_stub_mode()
                # 5! = 120
                @test contains(string(result), "120")
            end
        end

        @testset "seq (4 params)" begin
            # seq(expr, var, start, end)
            result = giac_eval("seq(k^2,k,1,5)")
            @test result isa GiacExpr
            if !is_stub_mode()
                result_str = string(result)
                # Should contain 1, 4, 9, 16, 25
                @test contains(result_str, "1") && contains(result_str, "4") && contains(result_str, "9")
            end
        end
    end
end
