# Tests for Tables.jl compatibility (025-tables-compatibility)
using Test
using Giac
using Tables

@testset "Tables.jl Compatibility" begin

    # Helper to check if GIAC library is available
    giac_available = !Giac.is_stub_mode()

    # ========================================================================
    # US1: GiacMatrix to DataFrame (Core Interface)
    # ========================================================================
    @testset "US1: GiacMatrix Tables.jl Interface" begin
        @testset "Tables.istable" begin
            @test Tables.istable(GiacMatrix) == true
        end

        @testset "Tables.rowaccess and columnaccess" begin
            @test Tables.rowaccess(GiacMatrix) == true
            @test Tables.columnaccess(GiacMatrix) == true
        end

        if giac_available
            @testset "Tables.schema" begin
                # Create a 2x3 matrix
                expr = giac_eval("[[1,2,3],[4,5,6]]")
                m = GiacMatrix(expr)

                schema = Tables.schema(m)
                @test schema !== nothing
                @test schema.names == (:col1, :col2, :col3)
            end

            @testset "GiacMatrix numeric values" begin
                expr = giac_eval("[[1,2],[3,4]]")
                m = GiacMatrix(expr)

                # Test rows access
                rows = Tables.rows(m)
                @test Tables.rowaccess(typeof(rows)) == true || length(collect(rows)) == 2

                # Test that we can iterate
                row_count = 0
                for row in Tables.rows(m)
                    row_count += 1
                    @test Tables.getcolumn(row, :col1) !== nothing
                end
                @test row_count == 2
            end

            @testset "GiacMatrix symbolic values" begin
                @giac_var x y
                expr = giac_eval("[[x,y],[x+1,y+1]]")
                m = GiacMatrix(expr)

                rows = collect(Tables.rows(m))
                @test length(rows) == 2

                # Values should be strings
                val = Tables.getcolumn(rows[1], :col1)
                @test val isa String
                @test val == "x"
            end
        else
            @test_broken false  # Skip these tests in stub mode
        end
    end

    # ========================================================================
    # US2: Row Iteration
    # ========================================================================
    @testset "US2: GiacMatrix Row Iteration" begin
        if giac_available
            @testset "Tables.rows returns iterable" begin
                expr = giac_eval("[[1,2,3],[4,5,6],[7,8,9]]")
                m = GiacMatrix(expr)

                rows = Tables.rows(m)
                @test length(rows) == 3
            end

            @testset "Row iteration yields correct count" begin
                expr = giac_eval("[[1,2],[3,4],[5,6]]")
                m = GiacMatrix(expr)

                count = 0
                for _ in Tables.rows(m)
                    count += 1
                end
                @test count == 3
            end

            @testset "Tables.getcolumn by index and name" begin
                expr = giac_eval("[[10,20,30]]")
                m = GiacMatrix(expr)

                rows = collect(Tables.rows(m))
                @test length(rows) == 1

                row = rows[1]
                @test Tables.getcolumn(row, 1) == "10"
                @test Tables.getcolumn(row, 2) == "20"
                @test Tables.getcolumn(row, :col1) == "10"
                @test Tables.getcolumn(row, :col3) == "30"
            end

            @testset "Tables.columnnames on row" begin
                expr = giac_eval("[[1,2]]")
                m = GiacMatrix(expr)

                rows = collect(Tables.rows(m))
                row = rows[1]
                names = Tables.columnnames(row)
                @test names == (:col1, :col2)
            end
        else
            @test_broken false  # Skip in stub mode
        end
    end

    # ========================================================================
    # US3: Column Access
    # ========================================================================
    @testset "US3: GiacMatrix Column Access" begin
        if giac_available
            @testset "Tables.columns returns accessor" begin
                expr = giac_eval("[[1,2],[3,4],[5,6]]")
                m = GiacMatrix(expr)

                cols = Tables.columns(m)
                @test cols !== nothing
            end

            @testset "Tables.getcolumn by index returns vector" begin
                expr = giac_eval("[[1,2],[3,4],[5,6]]")
                m = GiacMatrix(expr)

                cols = Tables.columns(m)
                col1 = Tables.getcolumn(cols, 1)
                @test col1 isa Vector
                @test length(col1) == 3
                @test col1 == ["1", "3", "5"]
            end

            @testset "Tables.getcolumn by name returns vector" begin
                expr = giac_eval("[[10,20],[30,40]]")
                m = GiacMatrix(expr)

                cols = Tables.columns(m)
                col2 = Tables.getcolumn(cols, :col2)
                @test col2 isa Vector
                @test col2 == ["20", "40"]
            end

            @testset "Tables.columnnames on columns" begin
                expr = giac_eval("[[1,2,3]]")
                m = GiacMatrix(expr)

                cols = Tables.columns(m)
                names = Tables.columnnames(cols)
                @test names == (:col1, :col2, :col3)
            end
        else
            @test_broken false  # Skip in stub mode
        end
    end

    # ========================================================================
    # US6: HelpResult to Table Row
    # ========================================================================
    @testset "US6: HelpResult Tables.jl Interface" begin
        @testset "Tables.istable" begin
            @test Tables.istable(HelpResult) == true
        end

        @testset "Tables.rowaccess" begin
            @test Tables.rowaccess(HelpResult) == true
        end

        @testset "Tables.schema returns 5-column schema" begin
            hr = HelpResult("test", "desc", String[], String[])
            schema = Tables.schema(hr)
            @test schema.names == (:command, :category, :description, :related, :examples)
        end

        @testset "Tables.rows yields single row" begin
            hr = HelpResult("test", "desc", String[], String[])
            rows = collect(Tables.rows(hr))
            @test length(rows) == 1
        end

        @testset "Column values" begin
            hr = HelpResult("factor", "Factorizes", ["ifactor", "partfrac"], ["factor(x^2-1)"])
            rows = collect(Tables.rows(hr))
            row = rows[1]

            @test Tables.getcolumn(row, :command) == "factor"
            @test Tables.getcolumn(row, :category) isa String
            @test Tables.getcolumn(row, :description) == "Factorizes"
            @test Tables.getcolumn(row, :related) isa String
            @test Tables.getcolumn(row, :examples) isa String
        end

        @testset "Related serialization (comma-separated)" begin
            hr = HelpResult("test", "desc", ["cmd1", "cmd2", "cmd3"], String[])
            rows = collect(Tables.rows(hr))
            row = rows[1]

            related = Tables.getcolumn(row, :related)
            @test related == "cmd1, cmd2, cmd3"
        end

        @testset "Examples serialization (semicolon-separated)" begin
            hr = HelpResult("test", "desc", String[], ["ex1", "ex2"])
            rows = collect(Tables.rows(hr))
            row = rows[1]

            examples = Tables.getcolumn(row, :examples)
            @test examples == "ex1; ex2"
        end

        @testset "Category from CATEGORY_LOOKUP" begin
            # :factor should be in :algebra category
            hr = HelpResult("factor", "Factorizes", String[], String[])
            rows = collect(Tables.rows(hr))
            row = rows[1]

            category = Tables.getcolumn(row, :category)
            @test category == "algebra"
        end
    end

    # ========================================================================
    # US5: CommandsTable
    # ========================================================================
    @testset "US5: CommandsTable" begin
        @testset "commands_table returns CommandsTable" begin
            # Clear cache first to ensure fresh collection
            clear_commands_cache!()

            ct = commands_table()
            @test ct isa CommandsTable
        end

        @testset "Tables.istable(CommandsTable)" begin
            @test Tables.istable(CommandsTable) == true
        end

        @testset "Tables.rowaccess(CommandsTable)" begin
            @test Tables.rowaccess(CommandsTable) == true
        end

        @testset "commands_table caching" begin
            clear_commands_cache!()

            ct1 = commands_table()
            ct2 = commands_table()

            # Same object should be returned
            @test ct1 === ct2
        end

        @testset "clear_commands_cache! invalidates cache" begin
            ct1 = commands_table()
            clear_commands_cache!()
            ct2 = commands_table()

            # Different objects after cache clear
            @test ct1 !== ct2
        end

        @testset "CommandsTable has 5 columns" begin
            ct = commands_table()
            schema = Tables.schema(ct)
            @test schema.names == (:command, :category, :description, :related, :examples)
        end

        if giac_available
            @testset "CommandsTable rows have correct structure" begin
                ct = commands_table()
                rows = Tables.rows(ct)
                @test length(rows) > 0

                # Check first row has all expected fields
                first_row = first(rows)
                @test haskey(first_row, :command)
                @test haskey(first_row, :category)
                @test haskey(first_row, :description)
                @test haskey(first_row, :related)
                @test haskey(first_row, :examples)
            end
        else
            @test_broken false  # Skip in stub mode (no commands available)
        end
    end

end
