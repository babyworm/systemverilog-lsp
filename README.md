# systemverilog-lsp

> SystemVerilog/Verilog language server for Claude Code, powered by [slang-server](https://github.com/hudson-trading/slang-server)

A Claude Code plugin that wires the [slang-server](https://github.com/hudson-trading/slang-server) LSP into Claude Code's editor surface, providing semantic awareness for `.sv`, `.svh`, `.v`, `.vh` files.

## Capabilities (via slang-server)

- Diagnostics (lint, syntax, elaboration errors)
- Hover (type info, documentation)
- Completion (identifiers, keywords, symbols)
- Go to definition / Find references
- Rename symbol
- Inlay hints (parameter names, types)

## Install

This plugin is distributed via the [rtl-agent-marketplace](https://github.com/babyworm/rtl-agent-team):

```bash
/plugin marketplace add babyworm/rtl-agent-team
/plugin install systemverilog-lsp@rtl-agent-marketplace
```

After installation, run `/reload-plugins`.

## Prerequisite: slang-server binary

The plugin checks for `slang-server` on your `PATH` at SessionStart and prompts you if it is missing. You have two options:

### Option A — auto-install (recommended)

The plugin ships with an installer that builds `slang-server` from source. After install, the SessionStart hook offers to run it. Or run it manually:

```bash
# Build & install to ~/.local/bin (no sudo needed)
bash scripts/install-slang-server.sh install --mode local

# Build & install to /usr/local/bin (system-wide, requires sudo)
bash scripts/install-slang-server.sh install --mode global

# Skip installation (no-op, marker only)
bash scripts/install-slang-server.sh install --mode skip
```

### Option B — install yourself

See [hudson-trading/slang-server](https://github.com/hudson-trading/slang-server) build instructions, then place the `slang-server` binary anywhere on your `PATH`.

## File-type bindings

| Extension     | Language ID     |
| :------------ | :-------------- |
| `.sv`, `.svh` | `systemverilog` |
| `.v`, `.vh`   | `verilog`       |

## Repository layout

```
.
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin manifest
├── .lsp.json                    # LSP server registration (slang-server)
├── hooks/
│   ├── hooks.json               # SessionStart hook registration
│   └── slang-server-check.sh    # readiness check + install prompt
├── scripts/
│   └── install-slang-server.sh  # build-from-source installer
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## License

MIT — see [LICENSE](LICENSE).

`slang-server` itself is a separate project maintained by [hudson-trading](https://github.com/hudson-trading/slang-server) under its own license; check that repository for terms.

## History

This plugin originated as a sub-plugin of [rtl-agent-team](https://github.com/babyworm/rtl-agent-team) (`plugins/systemverilog-lsp/`). It was extracted to its own repository at the `v1.1.2` release point to give the plugin an independent release cadence and tag namespace. See [CHANGELOG.md](CHANGELOG.md) for full history.

## Contributing

Issues and pull requests welcome. For LSP behavior questions (completion, diagnostics, hover content), please report upstream at [hudson-trading/slang-server](https://github.com/hudson-trading/slang-server) — this plugin is a thin wrapper around that server.
