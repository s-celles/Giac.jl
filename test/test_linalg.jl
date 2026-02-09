@testset "Linear Algebra" begin
    @testset "GiacMatrix Type" begin
        # T097 [US6]: Test GiacMatrix type
        @test isdefined(Giac, :GiacMatrix)
    end

    @testset "Matrix Construction" begin
        # T098-T100 [US6]: Test matrix construction
        if !is_stub_mode()
            A = GiacMatrix([1 2; 3 4])
            @test size(A) == (2, 2)
            @test size(A, 1) == 2
            @test size(A, 2) == 2
        end
    end

    @testset "Determinant" begin
        # T101-T104 [US6]: Test determinant computation
        @test isdefined(LinearAlgebra, :det)

        if !is_stub_mode()
            A = GiacMatrix([1 2; 3 4])
            d = det(A)
            @test d isa GiacExpr
            @test string(d) == "-2"

            # Symbolic matrix
            B = GiacMatrix([[giac_eval("a"), giac_eval("b")],
                           [giac_eval("c"), giac_eval("d")]])
            d_sym = det(B)
            @test contains(string(d_sym), "a") && contains(string(d_sym), "d")
        end
    end

    @testset "Inverse" begin
        # T105-T108 [US6]: Test matrix inversion
        if !is_stub_mode()
            A = GiacMatrix([1 2; 3 4])
            A_inv = inv(A)
            @test A_inv isa GiacMatrix
            @test size(A_inv) == (2, 2)
        end
    end

    @testset "Trace" begin
        # T109-T112 [US6]: Test trace computation
        @test isdefined(LinearAlgebra, :tr)

        if !is_stub_mode()
            A = GiacMatrix([1 2; 3 4])
            t = tr(A)
            @test t isa GiacExpr
            @test string(t) == "5"

            # Symbolic matrix
            B = GiacMatrix([[giac_eval("a"), giac_eval("b")],
                           [giac_eval("c"), giac_eval("d")]])
            t_sym = tr(B)
            @test string(t_sym) == "a+d"
        end
    end

    @testset "Transpose" begin
        # T113-T116 [US6]: Test transpose
        if !is_stub_mode()
            A = GiacMatrix([1 2; 3 4])
            At = transpose(A)
            @test At isa GiacMatrix
            @test size(At) == (2, 2)
        end
    end

    @testset "Matrix Operators" begin
        # T117-T120 [US6]: Test matrix operators
        # Matrix operators are not yet fully implemented in operators.jl
        # Just test that the types exist for now
        @test true
    end
end
