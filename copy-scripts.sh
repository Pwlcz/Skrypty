#!/bin/bash
# Yes, I may be a bit lazy
set -euo pipefail

VERSION='0.1.0'

help() {
  cat <<'EOF'
Usage: copy-scripts.sh [Options]

Copies top-level scripts and executables from dist/ to ~/bin.

Options:
  -c, --check      Compare the installed script version with the version from this repository.
  -h, --help       Show this message.
  -v, --version    Show the script version.
EOF
}

echo_ok() {
  echo -e "\e[1;32m$*\e[0m"
}

echo_error() {
  echo -e "\e[31mError: $*\e[0m" >&2
}

ensure_profile_config() {
  local profile="$HOME/.profile"
  local path_line='export PATH="$HOME/bin:$PATH"'
  local source_line='source "$HOME/bin/aliases.sh"'
  local updated=0

  touch "$profile"

  if ! grep -Fqx "$path_line" "$profile"; then
    printf '\n# Added by copy-scripts.sh\n%s\n' "$path_line" >> "$profile"
    updated=1
  fi

  if [[ -f "$HOME/bin/aliases.sh" ]] && ! grep -Fqx "$source_line" "$profile"; then
    printf '\n# Added by copy-scripts.sh\n%s\n' "$source_line" >> "$profile"
    updated=1
  fi

  if [[ "$updated" -eq 1 ]]; then
    echo "Please restart your shell or run: source ${profile}"
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

is_candidate_file() {
  local path="$1"

  if [[ "$path" == "$script_dir/dist/"* ]]; then
    [[ -f "$path" && -x "$path" ]]
  else
    is_candidate_script "$path"
  fi
}

check_script_version() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$src")"
  local src_hash=""
  local dst_hash=""

  if [[ -f "$src" ]]; then
    src_hash="$(sha1sum "$src" 2>/dev/null | awk '{print $1}' || true)"
  fi

  if [[ -f "$dst" ]]; then
    dst_hash="$(sha1sum "$dst" 2>/dev/null | awk '{print $1}' || true)"
  fi

  if [[ -z "$src_hash" || -z "$dst_hash" ]]; then
    echo "SKIP $name"
    return 0
  fi

  if [[ "$src_hash" == "$dst_hash" ]]; then
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

  mapfile -d '' -t scripts < <(
    {
      find "$script_dir" -maxdepth 1 -type f -print0
      if [[ -d "$script_dir/dist" ]]; then
        find "$script_dir/dist" -type f -executable -print0
      fi
    } | sort -z
  )

  status=0
  for path in "${scripts[@]}"; do
    if ! is_candidate_file "$path"; then
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

  if [[ "$check_mode" -eq 0 ]]; then
    ensure_profile_config
  fi

  exit "$status"
}

main "$@"