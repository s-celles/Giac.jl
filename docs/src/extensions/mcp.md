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

## Example prompts

Once the server is wired into your MCP client, you can address it in plain
natural language. The LLM routes the request to `giac_eval` (or
`giac_search`) and returns Giac's exact symbolic result. A few prompts to
get started, grouped by domain:

### French — direct style

- `factorise avec giac x²-1`
- `développe avec giac (a+b)²`
- `résous avec giac x² - 5x + 6 = 0`
- `dérive avec giac sin(x²)`
- `intègre avec giac x·exp(x)`
- `calcule avec giac la limite de sin(x)/x en 0`
- `décompose avec giac 1/(x³-1) en éléments simples`

### English — direct style

- `with giac, factor x^4 - 1`
- `with giac, expand (x+y+z)^3`
- `with giac, solve x^3 - 6x^2 + 11x - 6 = 0`
- `with giac, integrate 1/(x^2 + 2x + 5) dx`
- `with giac, compute the Laplace transform of t^2 * exp(-t) * sin(t)`
- `with giac, compute the Z-transform of n^2`

### English — natural, story-style

These read like questions a human would actually ask. The LLM still routes
them through `giac_eval`, but the framing exercises its judgement about
which Giac construct to invoke.

- `with giac, I'm stuck on x^4 - 5x^2 + 4 — can you break it into factors?`
- `with giac, between which two integers does the real root of x^3 + x - 1 = 0 lie?`
- `with giac, what's the slope of tan(x^2) at x = 1?`
- `with giac, give me the area under the bell curve exp(-x^2) over the whole real line`
- `with giac, does the sequence (1 + 1/n)^n converge, and to what?`
- `with giac, a mass on a spring satisfies y'' + 4y = cos(2t) — find the motion`
- `with giac, a population grows logistically with y' = y(1-y) and starts at 1/2; what's y(t)?`
- `with giac, is the matrix [[1,2,3],[4,5,6],[7,8,10]] invertible? Prove it`
- `with giac, the matrix [[2,1,0],[0,2,1],[0,0,2]] isn't diagonalizable — what's its Jordan structure?`
- `with giac, what polynomial of degree 3 passes through (0,1), (1,2), (2,5), (3,10)?`
- `with giac, do x^2 + x + 1 and x^3 - 1 share a common root?`
- `with giac, my password is the prime just after one billion — what is it?`
- `with giac, is the Mersenne number 2^31 - 1 actually prime?`
- `with giac, find integers u and v such that 1071·u + 462·v = gcd(1071, 462)`
- `with giac, an engineer needs the Laplace transform of t² e^(-t) sin(t) — deliver it`
- `with giac, recover the time-domain signal whose Laplace transform is (s+1)/((s²+1)(s+2))`
- `with giac, rewrite sin(5x) using only sin(x) and cos(x)`
- `with giac, fuse sin(x) + cos(x) into a single sinusoid`
- `with giac, how many 5-card poker hands are there from a standard deck?`
- `with giac, give me the 50th Fibonacci number`
- `with giac, fit a line through (1,2), (2,5), (3,7), (4,10) and tell me the slope`
- `with giac, Euler famously summed 1/k² — confirm his answer`
- `with giac, give me a closed-form expression for 1³ + 2³ + … + n³`
- `with giac, does the alternating sum (-1)^k / k converge, and to what value?`

### Catalogue search

Use the `giac_search` tool when you don't remember the exact command name:

- `with giac, which commands deal with matrices?`
- `with giac, what's available for prime numbers?`
- `with giac, list the Laplace-related commands`

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
