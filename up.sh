#!/bin/bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ssh_dir="$project_dir/.ssh"
client_private_key="$ssh_dir/id_ed25519"
host_private_key="$ssh_dir/ssh_host_ed25519_key"

ensure_ssh_key_pair() {
  local private_key="$1"
  local public_key="$private_key.pub"
  local key_comment="$2"

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ ! -e "$private_key" ]]; then
    if [[ -e "$public_key" ]]; then
      echo "Cannot generate $private_key: $public_key already exists." >&2
      exit 1
    fi

    ssh-keygen -t ed25519 -f "$private_key" -N "" -C "$key_comment"
  elif [[ ! -f "$public_key" ]]; then
    ssh-keygen -y -f "$private_key" > "$public_key"
  fi

  chmod 600 "$private_key"
  chmod 644 "$public_key"
}

ensure_ssh_key_pair "$client_private_key" "devcontainer-in-vps-client"
ensure_ssh_key_pair "$host_private_key" "devcontainer-in-vps-host"

devcontainer up \
  --remove-existing-container \
  --workspace-folder "$project_dir" \
  --config "$project_dir/.devcontainer/devcontainer.json"
