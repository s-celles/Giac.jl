# MCP Server (LLM Integration)

Giac.jl can expose its computer-algebra engine to MCP-aware LLM clients
(Claude Desktop, Claude Code, Cursor, and others) through the
[Model Context Protocol](https://modelcontextprotocol.io). The integration
is implemented as a **weak-dependency package extension**: users who do
not need MCP see no behavior change, no new dependency in their manifest,
and no precompilation cost.

## Installation

```julia
using Pkg
Pkg.add("ModelContextProtocol")
```

`Giac.jl` itself does NOT pull `ModelContextProtocol.jl` in transitively.
You install it explicitly when (and only when) you want the MCP server.

## Quickstart

```julia
using Giac, ModelContextProtocol

server = giac_mcp_server()   # construct the server (no I/O yet)
start!(server)                # blocks on STDIO transport
```

`start!` reads JSON-RPC requests from stdin, writes responses to stdout,
and logs to stderr. Press Ctrl-C to stop.

## What tools are exposed

The returned `Server` advertises two MCP tools:

- **`giac_eval`** — evaluate any Giac/Xcas expression. Input: `expr` (string).
  Output: the textual result of the expression.

  ```text
  expr = "factor(x^4-1)"   →   (x-1)*(x+1)*(x^2+1)
  expr = "laplace(exp(-t),t,s)"   →   1/(s+1)
  ```

  Multiple statements separated by `;` are allowed; the response is the
  value of the last statement. Each tool call is **independent** —
  variable bindings (`a := 5`) do NOT persist across calls.

- **`giac_search`** — search the Giac command catalogue by keyword. Input:
  `query` (string). Output: comma-separated list of matching command names,
  or the literal `"No commands matched."` when nothing matches.

  The search first tries prefix matching (the canonical Giac.jl behavior)
  and falls back to substring matching so LLM-style queries like
  `"matrix"` or `"prime"` find the relevant commands.

## Setup with Claude Desktop

Edit `~/.config/claude/claude_desktop_config.json` (or the platform
equivalent) and add a `mcpServers` entry:

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

Substitute `/path/to/env` with a Julia environment that has both `Giac` and
`ModelContextProtocol` installed. A dedicated environment (for example
`~/.julia/environments/mcp-giac/`) is recommended so the MCP server starts
as quickly as Julia allows. Restart Claude Desktop after editing the config.

## Setup with Claude Code

```bash
claude mcp add-json "giac-cas" '{"command":"julia","args":["--project=/path/to/env","-e","using Giac, ModelContextProtocol; start!(giac_mcp_server())"]}'
```

Confirm with `claude mcp list`. From any Claude Code session, ask:

> Use the Giac MCP server to factor `x^4 - 1`.

and Claude will call the `giac_eval` tool and return the Giac-computed
factorization.

## Setup with other MCP clients (Cursor, ...)

The command is the same — only the configuration UI differs. Most clients
accept a JSON object with a `command` and `args` array; copy the structure
from the Claude Desktop section.

## Manual JSON-RPC test

To verify the server end-to-end without an LLM client:

```bash
printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' \
  '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"giac_eval","arguments":{"expr":"factor(x^4-1)"}},"id":2}' \
| julia --project -e 'using Giac, ModelContextProtocol; start!(giac_mcp_server())' \
  2>/dev/null | jq .
```

The output is two JSON-RPC response objects: the `initialize` reply and the
`tools/call` reply whose `content[0].text` contains Giac's factored form
of `x^4 - 1`.

## API reference

```@docs
giac_mcp_server
```

## Limitations and future work

The first release is intentionally minimal. Deferred to later iterations:

- **MCP `Resource`s** that expose Giac documentation by domain so the LLM
  can fetch reference material on demand.
- **MCP `Prompt`s** offering pre-built templates such as
  "solve step by step, verify each step with `giac_eval`".
- A **structured invocation tool** accepting `{"command": "factor", "args": ["x^4-1"]}`
  for callers that want typed arguments instead of free-form expressions.
- **Session/context state** across tool calls (e.g., `a := 5` persisting).
  Each tool call is currently independent.
- A **`PackageCompiler.jl` sysimage** to reduce Julia's startup latency
  when an LLM client launches the server as a subprocess.
