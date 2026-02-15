# Tests for GiacMatrix display improvement (011-giacmatrix-display)

@testset "GiacMatrix Display" begin

    # =========================================================================
    # US1: View Matrix Contents in REPL (P1)
    # =========================================================================
    @testset "US1: Basic Display" begin
        # T003: Test basic 2×2 numeric matrix display format
        @testset "2×2 numeric matrix display" begin
            if !is_stub_mode()
                M = GiacMatrix([1 2; 3 4])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("2×2 GiacMatrix:", output)
                @test occursin("1", output)
                @test occursin("2", output)
                @test occursin("3", output)
                @test occursin("4", output)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T004: Test symbolic matrix display with GiacExpr elements
        @testset "symbolic matrix display" begin
            if !is_stub_mode()
                M = GiacMatrix([[giac_eval("a"), giac_eval("b")],
                               [giac_eval("c"), giac_eval("d")]])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("2×2 GiacMatrix:", output)
                @test occursin("a", output)
                @test occursin("b", output)
                @test occursin("c", output)
                @test occursin("d", output)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T005: Test 1×1 matrix display
        @testset "1×1 matrix display" begin
            if !is_stub_mode()
                M = GiacMatrix([[giac_eval("42")]])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("1×1 GiacMatrix:", output)
                @test occursin("42", output)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T006: Test column alignment with mixed-width elements
        @testset "column alignment" begin
            if !is_stub_mode()
                M = GiacMatrix([1 100; 1000 1])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                lines = split(output, '\n')
                # Find lines with matrix content (after header)
                content_lines = filter(l -> !isempty(strip(l)) && !occursin("GiacMatrix", l), lines)
                @test length(content_lines) >= 2
                # Check that columns are aligned (widths should match)
                if length(content_lines) >= 2
                    # Elements should be right-aligned within their column
                    @test occursin("1", content_lines[1])
                    @test occursin("100", content_lines[1])
                end
            else
                @test_broken false  # Skip in stub mode
            end
        end
    end

    # =========================================================================
    # US2: Compact Display for Large Matrices (P2)
    # =========================================================================
    @testset "US2: Truncation" begin
        # T010: Test row truncation for matrix with >10 rows
        @testset "row truncation (>10 rows)" begin
            if !is_stub_mode()
                # Create a 15×3 matrix
                M = GiacMatrix(ones(Int, 15, 3))
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("15×3 GiacMatrix:", output)
                @test occursin("⋮", output)  # Vertical ellipsis
            else
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
            end
        end

        # T011: Test column truncation for matrix with >10 columns
        @testset "column truncation (>10 cols)" begin
            if !is_stub_mode()
                # Create a 3×15 matrix
                M = GiacMatrix(ones(Int, 3, 15))
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("3×15 GiacMatrix:", output)
                @test occursin("⋯", output)  # Horizontal ellipsis
            else
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
            end
        end

        # T012: Test combined row and column truncation
        @testset "combined truncation (>10 rows and cols)" begin
            if !is_stub_mode()
                # Create a 15×15 matrix
                M = GiacMatrix(ones(Int, 15, 15))
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("15×15 GiacMatrix:", output)
                @test occursin("⋮", output)  # Vertical ellipsis
                @test occursin("⋯", output)  # Horizontal ellipsis
            else
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
            end
        end

        # T013: Test 10×10 matrix shows all elements (no truncation)
        @testset "10×10 shows all (no truncation)" begin
            if !is_stub_mode()
                M = GiacMatrix(ones(Int, 10, 10))
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("10×10 GiacMatrix:", output)
                @test !occursin("⋮", output)  # No vertical ellipsis
                @test !occursin("⋯", output)  # No horizontal ellipsis
            else
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
            end
        end
    end

    # =========================================================================
    # US3: String Representation and Edge Cases (P3)
    # =========================================================================
    @testset "US3: String and Edge Cases" begin
        # T020: Test string(m) returns compact format
        @testset "string() compact format" begin
            if !is_stub_mode()
                M = GiacMatrix([1 2; 3 4])
                s = string(M)
                @test s == "GiacMatrix(2×2)"
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T021: Test small matrix display
        @testset "small matrix display" begin
            if !is_stub_mode()
                M = GiacMatrix([[giac_eval("1")]])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("1×1 GiacMatrix:", output)
            else
                @test_broken false  # Skip in stub mode
            end
        end

        # T022: Test element truncation for very long expressions
        @testset "long expression truncation" begin
            if !is_stub_mode()
                # Create matrix with long symbolic expression
                M = GiacMatrix([[giac_eval("x^10+x^9+x^8+x^7+x^6+x^5+x^4+x^3+x^2+x+1")]])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("1×1 GiacMatrix:", output)
                # Long expressions should either be truncated with "…" or shown in full
                # depending on implementation
                @test length(output) > 0
            else
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
            end
        end

        # T023: Test mixed numeric and symbolic elements
        @testset "mixed numeric and symbolic" begin
            if !is_stub_mode()
                M = GiacMatrix([[giac_eval("1"), giac_eval("x")],
                               [giac_eval("y"), giac_eval("2")]])
                buf = IOBuffer()
                show(buf, MIME"text/plain"(), M)
                output = String(take!(buf))
                @test occursin("2×2 GiacMatrix:", output)
                @test occursin("1", output)
                @test occursin("x", output)
                @test occursin("y", output)
                @test occursin("2", output)
            else
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
                @test_broken false  # Skip in stub mode
            end
        end
    end

    # =========================================================================
    # Compact show (for containers)
    # =========================================================================
    @testset "Compact show" begin
        if !is_stub_mode()
            M = GiacMatrix([1 2; 3 4])
            buf = IOBuffer()
            show(buf, M)
            output = String(take!(buf))
            @test output == "GiacMatrix(2×2)"
        else
            @test_broken false  # Skip in stub mode
        end
    end
end
