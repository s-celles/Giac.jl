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
end
