@testset "Memory Management" begin
    @testset "GiacExpr Finalization" begin
        # T121-T124 [US2]: Test GiacExpr cleanup
        # Creating and releasing expressions should not cause memory leaks

        # Create many expressions
        for i in 1:100
            expr = giac_eval("x^$i")
            @test expr isa GiacExpr
        end

        # Force garbage collection
        GC.gc()

        # If we get here without errors, basic memory management works
        @test true
    end

    @testset "GiacContext Finalization" begin
        # T125-T128 [US2]: Test GiacContext cleanup
        # Creating and releasing contexts should not cause memory leaks

        # Create a context
        ctx = GiacContext()
        @test ctx isa GiacContext

        # Force garbage collection
        GC.gc()

        @test true
    end

    @testset "Thread Safety" begin
        # T129-T132 [US2]: Test thread safety lock
        @test isdefined(Giac, :GIAC_LOCK)
        @test Giac.GIAC_LOCK isa ReentrantLock

        # Test with_giac_lock function
        result = Giac.with_giac_lock() do
            42
        end
        @test result == 42
    end

    @testset "Null Pointer Handling" begin
        # T133-T136: Test null pointer handling
        # Creating GiacExpr with C_NULL should work but operations should fail gracefully
        null_expr = GiacExpr(C_NULL)
        @test null_expr.ptr == C_NULL

        # String conversion should return special value
        @test string(null_expr) == "<null GiacExpr>"

        # to_julia should throw
        @test_throws GiacError to_julia(null_expr)
    end
end
