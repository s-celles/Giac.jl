# Giac.jl

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/s-celles/Giac.jl)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18685533.svg)](https://doi.org/10.5281/zenodo.18685533)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://s-celles.github.io/Giac.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://s-celles.github.io/Giac.jl/dev)
[![CI](https://github.com/s-celles/Giac.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/s-celles/Giac.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/github/s-celles/Giac.jl/graph/badge.svg)](https://codecov.io/github/s-celles/Giac.jl)

A Julia wrapper for the [Giac](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html) computer algebra system.

## MCP Server (LLM Integration)

Giac.jl can expose its CAS engine to MCP-aware LLM clients (Claude Desktop,
Claude Code, Cursor, …) via the
[Model Context Protocol](https://modelcontextprotocol.io). The integration
is a weak-dependency package extension on
[`ModelContextProtocol.jl`](https://github.com/JuliaSMLM/ModelContextProtocol.jl),
so users who do not need MCP pay no cost.

```julia
using Pkg; Pkg.add("ModelContextProtocol")   # one-time setup
using Giac, ModelContextProtocol
start!(giac_mcp_server())                    # blocks on STDIO transport
```

### Claude Desktop

Add to `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "giac-cas": {
      "command": "julia",
      "args": [
        "--project=/path/to/env",
        "-e",
        "using Giac, ModelContextProtocol; start!(giac_mcp_server())"
      ]
    }
  }
}
```

### Claude Code

```bash
claude mcp add-json "giac-cas" '{"command":"julia","args":["--project=/path/to/env","-e","using Giac, ModelContextProtocol; start!(giac_mcp_server())"]}'
```

See [`docs/src/extensions/mcp.md`](docs/src/extensions/mcp.md) for the full
setup guide, manual JSON-RPC test, and the list of advertised tools.

## Contributors

See [CONTRIBUTORS.md](CONTRIBUTORS.md) for the people who built, reviewed,
and inspired this package.
