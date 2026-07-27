#!/bin/bash
# I wont remember to configure it (again).
set -euo pipefail

#TODO: allow to do git-config.sh -v
VERSION='0.0.0'

function echo_error() {
  local message="$1"
  echo -e "\e[31mError: ${message}\e[0m" >&2 # Red
}

function echo_ok() {
  local message="$1"
  echo -e "\e[1;32m${message}\e[0m" # Bold Green  
}

function echo_step() {
  local message="$1"
  local ARROW="\e[34m==>\e[0m" # Blue
  echo -e "${ARROW} \e[1m${message}\e[0m" # Bold 
}

# User Details
echo_step "Configure user identity"
echo -n "Current Git global " && echo_ok "user.name: $(git config --global user.name)" 
echo -n "Enter your Full Name for Git (e.g., John Doe, Leave empty for no changes): "
read -r git_name
if [[ -n "$git_name" ]]; then
  git config --global user.name "$git_name"
fi
echo ''

echo -n "Current Git global " && echo_ok "user.email: $(git config --global user.email)"
echo -n "Enter your Email for Git (e.g., john@example.com, Leave empty for no changes): "
read -r git_email
if [[ -n "$git_email" ]]; then
  git config --global user.email "$git_email"
fi
echo ''

echo_ok "User identity set"
echo "Global user.name: $(git config --global user.name)"
echo "Global user.email: $(git config --global user.email)"
echo ''

# default init branch
echo_step "Configure default init branch"
echo -n "Current Git global " && echo_ok "init.defaultBranch: $(git config --global init.defaultBranch)"
echo -n "Enter preffered initial default branch name (e.g., main, Leave empty for no changes): "
read -r git_defaultbranch
if [[ -n "$git_defaultbranch" ]]; then
  git config --global init.defaultBranch "$git_defaultbranch"
fi
echo_ok "Default branch set to \"$(git config --global init.defaultBranch)\"."
echo ''

# Commit signing configuration
echo_step "Configure commit signing"
echo -n "Current Git global " && echo_ok "user.signingkey: $(git config --global user.signingkey)"
echo -n "Do you want to enable GPG commit signing? [y/N]: "
read -r enable_signing
echo ''
if [[ "$enable_signing" == [yY] ]]; then
  # TODO: cleanup this mess
  echo "List of available GPG keys:"
  gpg --list-secret-keys 2>/dev/null

  declare -A valid_gpg_keys=()
  declare -A key_fingerprints=()
  gpg_keys=()
  sec_seen=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^sec[[:space:]] ]]; then
      sec_seen=true
      continue
    fi

    if [[ "$sec_seen" == true ]]; then
      if [[ "$line" =~ ^[[:space:]]+([0-9A-Fa-f]{16,40})[[:space:]]*$ ]]; then
        fingerprint="${BASH_REMATCH[1]}"
        short_key="${fingerprint: -16}"
        gpg_keys+=("$short_key")
        key_fingerprints["${short_key,,}"]="$fingerprint"
        key_fingerprints["${fingerprint,,}"]="$fingerprint"
        valid_gpg_keys["${short_key,,}"]=1
        valid_gpg_keys["${fingerprint,,}"]=1
        sec_seen=false
      fi
    fi
  done < <(gpg --list-secret-keys 2>/dev/null)

  if [[ ${#gpg_keys[@]} -eq 0 ]]; then
    echo "No GPG secret keys found. Please generate one with 'gpg --full-generate-key' and rerun this script."
    exit 1
  fi

  for i in "${!gpg_keys[@]}"; do
    printf "%d) %s\n" $((i + 1)) "${gpg_keys[i]}"
  done

  while true; do
  echo -n "Enter the number of the key to use, or paste a key ID directly: "
  read -r gpg_key_id
  if [[ -z "$gpg_key_id" ]]; then
    echo_error "No key selected. Please enter a valid selection."
    continue
  fi

  normalized_key="${gpg_key_id,,}"

  if [[ "$gpg_key_id" =~ ^[0-9]+$ ]]; then
    if (( gpg_key_id >= 1 && gpg_key_id <= ${#gpg_keys[@]} )); then
      selected_short_key="${gpg_keys[gpg_key_id-1]}"
      gpg_key_id="${key_fingerprints[${selected_short_key,,}]}"
      break
    fi
    echo_error "Selection out of range. Please choose a valid number."
    continue
  fi

  if [[ -n "${valid_gpg_keys[$normalized_key]+x}" ]]; then
    gpg_key_id="${key_fingerprints[$normalized_key]}"
    break
  fi

  echo_error "Invalid key selection. Please enter a number from the list or one of the available short IDs/fingerprints."
  done

  git config --global user.signingkey "${gpg_key_id}!"
  git config --global commit.gpgsign true
  echo_ok "GPG commit signing enabled with key ID: $gpg_key_id"
else
  git config --global commit.gpgsign false
  echo_ok "GPG commit signing disabled."
fi
echo ''

# OS-Specific Line Ending Configuration (autocrlf)
echo_step "Configuring autocrlf"
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
  # Linux / macOS
  git config --global core.autocrlf input
  echo "Line endings (autocrlf) configured for Unix (input)."
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
  # Windows (Git Bash)
  git config --global core.autocrlf true
  echo "Line endings (autocrlf) configured for Windows (true)."
else
  echo "OS not definitively recognized. Skipping autocrlf configuration."
fi
echo ''

echo_step "Turning off default pager"
git config --global core.pager ''
echo ''

# Set simple push/pull behavior
echo_step "Configuring simple Push/Pull behaviors"
git config --global push.default simple
git config --global pull.rebase false
echo ''

echo_ok "Git current global config:"
echo "----------------------------------------"
git --no-pager config --global --list
echo "----------------------------------------"