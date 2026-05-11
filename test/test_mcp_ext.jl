using Test
using Giac
using ModelContextProtocol

# Helper: locate a tool by name from the server's tool list.
function _find_tool(server, tool_name::AbstractString)
    idx = findfirst(t -> t.name == tool_name, server.tools)
    idx === nothing && error("tool \"$tool_name\" not found on server")
    return server.tools[idx]
end

@testset "GiacMCPExt" begin

    # ------------------------------------------------------------------
    # 1. Extension activation (FR-002, FR-009)
    # ------------------------------------------------------------------
    @testset "Extension activation" begin
        @test isdefined(Giac, :giac_mcp_server)
        @test isa(Giac.giac_mcp_server, Function)
        # Once ModelContextProtocol is loaded, the zero-arg method exists.
        @test hasmethod(Giac.giac_mcp_server, Tuple{})
    end

    # ------------------------------------------------------------------
    # 2. Server shape (FR-003)
    # ------------------------------------------------------------------
    @testset "Server shape" begin
        server = giac_mcp_server()
        @test length(server.tools) == 2
        tool_names = Set(t.name for t in server.tools)
        @test tool_names == Set(["giac_eval", "giac_search"])
    end

    # ------------------------------------------------------------------
    # 3. Eval handler — happy paths (FR-003, FR-004, SC-005)
    # ------------------------------------------------------------------
    @testset "Eval handler — happy paths" begin
        server = giac_mcp_server()
        eval_tool = _find_tool(server, "giac_eval")

        # Arithmetic
        result = eval_tool.handler(Dict("expr" => "2+3"))
        @test isa(result, TextContent)
        @test occursin("5", result.text)

        # Algebra — factorization
        result = eval_tool.handler(Dict("expr" => "factor(x^2-1)"))
        @test isa(result, TextContent)
        @test occursin("x-1", result.text) || occursin("x - 1", result.text)
        @test occursin("x+1", result.text) || occursin("x + 1", result.text)

        # Calculus — differentiation
        result = eval_tool.handler(Dict("expr" => "diff(sin(x^2),x)"))
        @test isa(result, TextContent)
        @test occursin("cos", result.text)
        @test occursin("x^2", result.text) || occursin("x*x", result.text)

        # Laplace transform
        result = eval_tool.handler(Dict("expr" => "laplace(exp(-t),t,s)"))
        @test isa(result, TextContent)
        @test occursin("s+1", result.text) || occursin("s + 1", result.text)
    end

    # ------------------------------------------------------------------
    # 4. Eval handler — error path (FR-006, SC-004)
    # ------------------------------------------------------------------
    @testset "Eval handler — error path" begin
        server = giac_mcp_server()
        eval_tool = _find_tool(server, "giac_eval")

        # Invalid Giac input must NOT throw (the MCP session must stay alive).
        # Giac itself is forgiving and reports parse errors as a textual "undef"
        # result via stderr warnings, so the handler returns a TextContent in
        # that path. When Giac DOES raise a Julia exception (e.g. wrapper-level
        # failures), our try/catch wraps it as CallToolResult(isError=true).
        # Either shape satisfies FR-006; both keep the session alive.
        local result
        threw = false
        try
            result = eval_tool.handler(Dict("expr" => "invalid_syntax(("))
        catch
            threw = true
        end
        @test !threw
        @test (isa(result, TextContent) && !isempty(result.text)) ||
              (isa(result, CallToolResult) && result.isError == true && !isempty(result.content))
    end

    # ------------------------------------------------------------------
    # 5. Search handler — basic (FR-005)
    # ------------------------------------------------------------------
    @testset "Search handler — basic" begin
        server = giac_mcp_server()
        search_tool = _find_tool(server, "giac_search")

        # Keyword match
        result = search_tool.handler(Dict("query" => "laplace"))
        @test isa(result, TextContent)
        @test occursin("laplace", result.text)

        # Explicit empty-match contract
        result = search_tool.handler(Dict("query" => "xxxxxxxx-no-such"))
        @test isa(result, TextContent)
        @test result.text == "No commands matched."
    end

    # ------------------------------------------------------------------
    # 6. Re-creation safety (FR-010)
    # ------------------------------------------------------------------
    @testset "Re-creation safety" begin
        s1 = giac_mcp_server()
        s2 = giac_mcp_server()
        @test s1 !== s2
        @test length(s1.tools) == 2
        @test length(s2.tools) == 2
    end

    # ------------------------------------------------------------------
    # 7. Kwarg forwarding (FR-011)
    # ------------------------------------------------------------------
    @testset "Kwarg forwarding" begin
        server = giac_mcp_server(name = "custom-giac")
        # `Server` stores configuration in `.config`; the server name lives there.
        @test server.config.name == "custom-giac"
    end

    @testset "Server version tracks Giac.jl version" begin
        # serverInfo.version (visible to MCP clients in the initialize handshake)
        # MUST default to the running Giac.jl version, not the framework's hardcoded
        # "1.0.0".
        server = giac_mcp_server()
        @test server.config.version == string(pkgversion(Giac))

        # User override still wins.
        server = giac_mcp_server(version = "9.9.9-test")
        @test server.config.version == "9.9.9-test"
    end

    # ------------------------------------------------------------------
    # US2 — stub-export visible (data-model.md Entity 5)
    # ------------------------------------------------------------------
    @testset "US2 — public surface" begin
        @test :giac_mcp_server in names(Giac)
        @test isa(Giac.giac_mcp_server, Function)
    end

    # ------------------------------------------------------------------
    # US3 — search quality across SC-005 keywords
    # ------------------------------------------------------------------
    @testset "Search quality — SC-005 keywords" begin
        server = giac_mcp_server()
        search_tool = _find_tool(server, "giac_search")

        function _text_for(query::AbstractString)
            result = search_tool.handler(Dict("query" => query))
            @test isa(result, TextContent)
            return result.text
        end

        # laplace → at least `laplace`
        text = _text_for("laplace")
        @test text != "No commands matched."
        @test occursin("laplace", text)

        # matrix → at least one matrix-related command
        text = _text_for("matrix")
        @test text != "No commands matched."

        # prime → at least one prime-related command
        text = _text_for("prime")
        @test text != "No commands matched."
        @test occursin("prime", text)

        # factor → at least `factor`
        text = _text_for("factor")
        @test text != "No commands matched."
        @test occursin("factor", text)

        # integrate → at least `integrate`
        text = _text_for("integrate")
        @test text != "No commands matched."
        @test occursin("integrate", text)
    end

    @testset "Search quality — explicit empty match" begin
        server = giac_mcp_server()
        search_tool = _find_tool(server, "giac_search")
        result = search_tool.handler(Dict("query" => "xxxxxxxxxxx-no-such-command"))
        @test result.text == "No commands matched."
    end

end
