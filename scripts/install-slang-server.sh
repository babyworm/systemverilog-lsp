#!/usr/bin/env bash
# systemverilog-lsp helper: install slang-server from upstream source.

set -euo pipefail

MODE="local"
CMD="install"
INSTALL_PREFIX_LOCAL="${HOME}/.local"
INSTALL_PREFIX_GLOBAL="/usr/local"
# Overridable via environment, e.g. to build from a fork or a pinned ref.
SRC_DIR="${SLANG_SERVER_SRC_DIR:-${HOME}/.local/src/slang-server}"
REPO_URL="${SLANG_SERVER_REPO:-https://github.com/hudson-trading/slang-server.git}"
REF="${SLANG_SERVER_REF:-main}"
# Toolchain minimums from slang-server docs/start/building.md.
MIN_CMAKE_VERSION="3.28"
MIN_GCC_MAJOR="11"
MIN_CLANG_MAJOR="17"

usage() {
  cat <<'EOF'
Usage:
  install-slang-server.sh install [--mode local|global|skip] [--ref REF]
  install-slang-server.sh update  [--mode local|global] [--ref REF]
  install-slang-server.sh check
  install-slang-server.sh help

Commands:
  install  Build slang-server from source and install it
  update   Fetch the latest source and rebuild only if it changed
  check    Show the installed binary, its version, and the source checkout

Modes:
  local   Build from source and install under ~/.local/bin (recommended)
  global  Build from source and install under /usr/local/bin (may require sudo)
  skip    Do nothing and exit successfully

Options:
  --ref REF  Branch, tag, or commit to build (default: main)

Environment:
  SLANG_SERVER_REPO     Git URL to build from (default: upstream repository)
  SLANG_SERVER_REF      Same as --ref
  SLANG_SERVER_SRC_DIR  Source checkout location (default: ~/.local/src/slang-server)
EOF
}

version_gte() {
  printf '%s\n%s' "$2" "$1" | sort -V -C
}

have() {
  command -v "$1" >/dev/null 2>&1
}

parse_args() {
  if [ $# -gt 0 ]; then
    CMD="$1"
    shift
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --mode)
        MODE="${2:-}"
        shift 2
        ;;
      --ref)
        REF="${2:-}"
        if [ -z "$REF" ]; then
          echo "--ref requires a value" >&2
          exit 1
        fi
        shift 2
        ;;
      -h|--help|help)
        CMD="help"
        shift
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

check_prereqs() {
  local ok=1

  for bin in git cmake python3; do
    if ! have "$bin"; then
      echo "Missing prerequisite: $bin" >&2
      ok=0
    fi
  done

  if have cmake; then
    local cmake_ver
    cmake_ver="$(cmake --version | awk 'NR==1{print $3}')"
    if ! version_gte "$cmake_ver" "$MIN_CMAKE_VERSION"; then
      echo "cmake $cmake_ver is too old (need >= $MIN_CMAKE_VERSION)" >&2
      ok=0
    fi
  fi

  if have g++; then
    local gcc_major
    gcc_major="$(g++ -dumpversion | cut -d. -f1)"
    if [ "${gcc_major:-0}" -lt "$MIN_GCC_MAJOR" ]; then
      echo "g++ $gcc_major is too old (need >= $MIN_GCC_MAJOR for C++20)" >&2
      ok=0
    fi
  elif have clang++; then
    local clang_major
    clang_major="$(clang++ -dumpversion | cut -d. -f1)"
    # Apple clang uses Xcode version numbers, so only check upstream clang.
    if ! clang++ --version | grep -q "Apple" &&
      [ "${clang_major:-0}" -lt "$MIN_CLANG_MAJOR" ]; then
      echo "clang++ $clang_major is too old (need >= $MIN_CLANG_MAJOR for C++20)" >&2
      ok=0
    fi
  else
    echo "Missing prerequisite: g++ >= $MIN_GCC_MAJOR or clang++ >= $MIN_CLANG_MAJOR" >&2
    ok=0
  fi

  if [ "$ok" -ne 1 ]; then
    cat <<'EOF' >&2
Install prerequisites first:
  Ubuntu/Debian: sudo apt install git cmake g++ ninja-build python3
  Fedora:        sudo dnf install git cmake gcc-c++ ninja-build python3
  macOS:         brew install cmake ninja python
If the distro cmake is older than required: pip install --user cmake
EOF
    exit 1
  fi
}

source_head() {
  git -C "$SRC_DIR" rev-parse HEAD 2>/dev/null || true
}

# Check out $REF. Branches follow the remote; tags and commits are detached.
clone_or_update() {
  mkdir -p "$(dirname "$SRC_DIR")"
  if [ -d "$SRC_DIR/.git" ]; then
    git -C "$SRC_DIR" remote set-url origin "$REPO_URL"
    git -C "$SRC_DIR" fetch --tags origin
  else
    git clone "$REPO_URL" "$SRC_DIR"
  fi

  if git -C "$SRC_DIR" rev-parse -q --verify "refs/remotes/origin/$REF" >/dev/null; then
    git -C "$SRC_DIR" checkout -q --detach "origin/$REF"
  else
    git -C "$SRC_DIR" checkout -q --detach "$REF"
  fi

  # Only direct submodules are needed (slang, reflect-cpp, ctre).
  # Shallow first; fall back for servers that refuse fetching a bare commit.
  git -C "$SRC_DIR" submodule update --init --depth 1 ||
    git -C "$SRC_DIR" submodule update --init
}

build_and_install() {
  local prefix="$1"
  local build_dir="$SRC_DIR/build"
  local generator_args=()

  if have ninja; then
    generator_args=(-G Ninja)
  fi

  cmake -S "$SRC_DIR" -B "$build_dir" "${generator_args[@]}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DSLANG_SERVER_INCLUDE_TESTS=OFF
  cmake --build "$build_dir" -j"$(nproc 2>/dev/null || echo 4)" --target slang_server

  # Copy the binary directly. `cmake --install` also runs the install rules of
  # bundled dependencies (e.g. mimalloc) that the slang_server target does not
  # build, and fails on their missing artifacts.
  local binary="$build_dir/bin/slang-server"
  if [ ! -x "$binary" ]; then
    echo "Build did not produce $binary" >&2
    exit 1
  fi

  if [ "$MODE" = "global" ]; then
    echo "Global install selected. You may be prompted for sudo."
    sudo install -d "$prefix/bin"
    sudo install -m 755 "$binary" "$prefix/bin/slang-server"
  else
    install -d "$prefix/bin"
    install -m 755 "$binary" "$prefix/bin/slang-server"
  fi
}

verify_install() {
  if have slang-server; then
    echo "slang-server ready: $(command -v slang-server)"
    slang-server --version 2>&1 | head -1 || true
    return 0
  fi

  if [ -x "${HOME}/.local/bin/slang-server" ]; then
    echo "slang-server installed at ${HOME}/.local/bin/slang-server"
    "${HOME}/.local/bin/slang-server" --version 2>&1 | head -1 || true
    echo 'Add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile if needed.'
    return 0
  fi

  echo "slang-server installation verification failed" >&2
  return 1
}

check_status() {
  if have slang-server; then
    echo "slang-server: $(command -v slang-server)"
    slang-server --version 2>&1 | head -1 || true
    if [ -d "$SRC_DIR/.git" ]; then
      echo "source: $SRC_DIR @ $(git -C "$SRC_DIR" log -1 --format='%h %cs %s')"
    fi
  elif [ -x "${HOME}/.local/bin/slang-server" ]; then
    echo "slang-server exists at ${HOME}/.local/bin/slang-server but PATH is missing ~/.local/bin"
  else
    echo "slang-server: not installed"
  fi
}

main() {
  parse_args "$@"

  case "$CMD" in
    install)
      case "$MODE" in
        skip)
          echo "Skipping slang-server installation."
          exit 0
          ;;
        local|global)
          ;;
        *)
          echo "Invalid mode: $MODE" >&2
          usage
          exit 1
          ;;
      esac
      check_prereqs
      clone_or_update
      if [ "$MODE" = "global" ]; then
        build_and_install "$INSTALL_PREFIX_GLOBAL"
      else
        mkdir -p "${INSTALL_PREFIX_LOCAL}/bin"
        build_and_install "$INSTALL_PREFIX_LOCAL"
      fi
      verify_install
      ;;
    update)
      case "$MODE" in
        local|global)
          ;;
        *)
          echo "Invalid mode for update: $MODE" >&2
          usage
          exit 1
          ;;
      esac
      check_prereqs
      local before
      before="$(source_head)"
      clone_or_update
      if [ -n "$before" ] && [ "$before" = "$(source_head)" ] &&
        { have slang-server || [ -x "${INSTALL_PREFIX_LOCAL}/bin/slang-server" ]; }; then
        echo "slang-server is already up to date ($(git -C "$SRC_DIR" log -1 --format='%h %cs'))."
        exit 0
      fi
      if [ "$MODE" = "global" ]; then
        build_and_install "$INSTALL_PREFIX_GLOBAL"
      else
        mkdir -p "${INSTALL_PREFIX_LOCAL}/bin"
        build_and_install "$INSTALL_PREFIX_LOCAL"
      fi
      verify_install
      echo "Restart the Claude Code session (or run /reload-plugins) to use the new server."
      ;;
    check)
      check_status
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "Unknown command: $CMD" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
