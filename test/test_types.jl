@testset "Types" begin
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
