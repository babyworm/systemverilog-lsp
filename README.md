# systemverilog-lsp

> SystemVerilog/Verilog language server for Claude Code, powered by [slang-server](https://github.com/hudson-trading/slang-server)

A Claude Code plugin that wires the [slang-server](https://github.com/hudson-trading/slang-server) LSP into Claude Code's editor surface, providing semantic awareness for `.sv`, `.svh`, `.v`, `.vh` files.

## Capabilities (via slang-server)

- Diagnostics (lint, syntax, elaboration errors)
- Hover (type info, bit widths, constant values, documentation)
- Go to definition / Find references, including class scopes, virtual
  interfaces, and implicit function return variables
- Document and workspace symbols
- Call hierarchy
- Completion (identifiers, hierarchical references, struct members, named
  ports, parameters, and call arguments)
- Rename symbol
- Inlay hints (parameter names, types)

Which of these Claude Code actually uses depends on its LSP tool; completion,
rename, and inlay hints are mainly useful to interactive editors. The list
tracks slang-server `main`; see the upstream
[feature docs](https://hudson-trading.github.io/slang-server/) for details.

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

Build requirements (from the slang-server build docs): `git`, Python 3.9 or
later, CMake 3.28 or later, and a C++20 compiler (GCC 11+, clang 17+, or Xcode 16+).

### Updating slang-server

The SessionStart hook only checks that a `slang-server` binary exists, so an
existing install is never refreshed automatically. slang-server moves quickly;
update it from time to time:

```bash
# Fetch the latest source and rebuild only if it changed
bash scripts/install-slang-server.sh update

# Show the installed version and the source commit it was built from
bash scripts/install-slang-server.sh check
```

Restart the session (or run `/reload-plugins`) afterwards so the new binary
is picked up.

To build a specific release, branch, or fork:

```bash
# Pin to a tag, branch, or commit
bash scripts/install-slang-server.sh install --ref <tag-or-branch>

# Build from a fork
SLANG_SERVER_REPO=https://github.com/<you>/slang-server.git \
  bash scripts/install-slang-server.sh install
```

### Option B — install yourself

See [hudson-trading/slang-server](https://github.com/hudson-trading/slang-server) build instructions, then place the `slang-server` binary anywhere on your `PATH`.

## File-type bindings

| Extension          | Language ID     |
| :----------------- | :-------------- |
| `.sv`, `.svh`      | `systemverilog` |
| `.v`, `.vh`, `.vl` | `verilog`       |

## Project configuration (optional)

slang-server works without configuration, but large or UVM-based projects
benefit from a `.slang/server.json` in the workspace root:

```json
{
  "env": { "UVM_HOME": "/tools/uvm" },
  "index": [{ "dirs": ["rtl", "tb", "${UVM_HOME}/src"], "excludeDirs": ["build"] }],
  "incdirs": ["${UVM_HOME}/src"],
  "flags": "-f slang.f"
}
```

- `index` limits which directories are indexed (default: whole workspace).
- `incdirs` adds include search paths; `flags` passes slang command-line flags.
- `env` defines variables for `$VAR` / `${VAR}` expansion in the other fields.

Machine-specific settings go in `.slang/local/server.json` (keep it out of
source control) or `~/.slang/server.json`. See the upstream
[configuration reference](https://hudson-trading.github.io/slang-server/start/config/)
for all options.

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
