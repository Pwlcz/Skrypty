#!/bin/bash
# Yes, I may be a bit lazy
set -euo pipefail

VERSION='0.0.1'

help() {
  cat <<'EOF'
Usage: copy-scripts.sh [Options]

Copies top-level scripts from this directory to ~/bin.

Options:
  --check      Compare the installed script version with the version from this repository.
  --help       Show this message.
  --version    Show the script version.
EOF
}

echo_ok() {
  echo -e "\e[1;32m$*\e[0m"
}

echo_error() {
  echo -e "\e[31mError: $*\e[0m" >&2
}

ensure_path_entry() {
  local shellrc=""
  local shell_name=""

  if [[ -n "${SHELL:-}" ]]; then
    shell_name="$(basename "$SHELL")"
  fi

  case "$shell_name" in
    zsh)
      shellrc="$HOME/.zshrc"
      ;;
    bash)
      shellrc="$HOME/.bashrc"
      ;;
    fish)
      shellrc="$HOME/.config/fish/config.fish"
      ;;
    *)
      if [[ -f "$HOME/.zshrc" ]]; then
        shellrc="$HOME/.zshrc"
      else
        shellrc="$HOME/.bashrc"
      fi
      ;;
  esac

  mkdir -p "$(dirname "$shellrc")"
  touch "$shellrc"

  if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    cat >> "$shellrc" <<'EOF'

# Added by copy-scripts.sh
export PATH="$HOME/bin:$PATH"
EOF
echo "Please restart your shell or run: source ${shellrc}"
  fi
}

is_candidate_script() {
  local path="$1"
  local name
  name="$(basename "$path")"

  [[ -f "$path" ]] || return 1
  [[ "$name" != "copy-scripts.sh" ]] || return 1
  [[ "$name" != "README"* ]] || return 1
  [[ "$name" != *.md ]] || return 1
  [[ "$name" != *.txt ]] || return 1
  [[ -x "$path" || "$name" == *.sh ]] || return 1
  return 0
}

check_script_version() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$src")"
  local src_version=""
  local dst_version=""

  if "$src" -v >/dev/null 2>&1; then
    src_version="$($src -v 2>/dev/null || true)"
  fi

  if [[ -x "$dst" ]] && "$dst" -v >/dev/null 2>&1; then
    dst_version="$($dst -v 2>/dev/null || true)"
  fi

  if [[ -z "$src_version" || -z "$dst_version" ]]; then
    echo "SKIP $name"
    return 0
  fi

  if [[ "$src_version" == "$dst_version" ]]; then
    echo "OK   $name"
    return 0
  fi

  echo "DIFF $name"
  return 1
}

function main() {
  check_mode=0
  if ! PARSED_ARGS=$(getopt --name copy-scripts.sh --options hvc \
        --longoptions help,version,check -- "$@"); then
    help >&2
    exit 1
  fi
  eval set -- "${PARSED_ARGS}"
  
  while true; do
    case "$1" in 
      --check|-c)
        check_mode=1
        break
        ;;
      --help|-h)
        help
        exit 0
        ;;
      --version|-v)
        echo "$VERSION"
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        echo_error "Unrecognized option: $1"
        help >&2
        exit 1
        ;;
    esac
  done

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  target_dir="$HOME/bin"
  mkdir -p "$target_dir"
  ensure_path_entry

  mapfile -t scripts < <(find "$script_dir" -maxdepth 1 -type f | sort)

  status=0
  for path in "${scripts[@]}"; do
    if ! is_candidate_script "$path"; then
      continue
    fi

    name="$(basename "$path")"
    dest="$target_dir/$name"

    if [[ "$check_mode" -eq 1 ]]; then
      if ! check_script_version "$path" "$dest"; then
        status=1
      fi
      continue
    fi

    install -m 0755 "$path" "$dest"
    echo_ok "Installed $name -> $dest"
  done
  exit "$status"
}

main "$@"