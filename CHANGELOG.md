# Changelog

All notable changes to `systemverilog-lsp` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.4] - 2026-04-25

### Fixed
- **SessionStart hook JSON schema violation.**
  `hooks/slang-server-check.sh` emitted
  `{"hookSpecificOutput":{"additionalContext":"..."}}` without the
  required `hookEventName` field. Claude Code v2.1.x's hook validator
  rejects this with
  `Hook JSON output validation failed — hookSpecificOutput is missing
  required field "hookEventName"`, blocking session startup whenever
  slang-server is missing or off-PATH (the exact case the hook is
  designed to advise on). Both stdout paths (LOCAL_BIN-on-disk advice
  and missing-binary advice) now include
  `"hookEventName":"SessionStart"`. Pre-v2.1.x clients accepted the
  old schema-loose output, which is why this slipped through earlier
  releases.

## [1.1.3] - 2026-04-17

### Added
- `README.md` documenting installation, capabilities, and slang-server prerequisite.
- `CHANGELOG.md` (this file) tracking standalone-repo releases.
- `.gitignore` for Python build artifacts and editor noise.

### Fixed
- `plugin.json` `repository` field corrected to
  `https://github.com/babyworm/systemverilog-lsp` (was incorrectly
  pointing at the parent `babyworm/rtl-agent-team` monorepo, a leftover
  from the v1.1.2 split point).

## [1.1.2] - 2026-03-13

### Changed
- **Cache-invalidation manifest bump.** The `.lsp.json` fix from
  `a2c7687` ("remove unrecognized `name` key from .lsp.json files")
  was already present in v1.1.1 source, but stale Claude Code caches
  did not invalidate without a manifest version change. Bumping to
  v1.1.2 forced cache eviction so all stale v1.1.1 installs picked up
  the corrected `.lsp.json` on next plugin reload. **No file contents
  changed in this release** — only the manifest version.
- This is the last release that shipped from the `rtl-agent-team`
  monorepo at `plugins/systemverilog-lsp/`. Subsequent releases come
  from this standalone repository.

## [1.1.1] - 2026-03-13 (rtl-agent-team monorepo era)

### Fixed
- Removed unrecognized `"name"` key from `.lsp.json` (`a2c7687`).
  Claude Code's LSP config validator was emitting
  `Invalid LSP server config for ".lsp.json": Unrecognized key: "name"`
  on every `/reload-plugins`. The fix shipped silently inside a
  version-bump commit and only became visible to stale-cached users
  after the v1.1.2 cache-invalidation release.

## [1.1.0] and earlier — rtl-agent-team monorepo era

Earlier history (`0.6.x` through `1.1.0`) is documented in the parent
monorepo: see <https://github.com/babyworm/rtl-agent-team/blob/main/CHANGELOG.md>.

The history was preserved in this repo via `git filter-repo
--subdirectory-filter plugins/systemverilog-lsp`, so `git log` from
the v1.1.2 tag back shows the original commits with the original
authors and timestamps (commit hashes were rewritten by filter-repo).
