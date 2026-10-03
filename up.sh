#!/bin/bash

set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ssh_dir="$project_dir/.ssh"
private_key="$ssh_dir/id_ed25519"
public_key="$private_key.pub"

ensure_ssh_key() {
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ ! -e "$private_key" ]]; then
    if [[ -e "$public_key" ]]; then
      echo "Cannot generate $private_key: $public_key already exists." >&2
      exit 1
    fi

    ssh-keygen -t ed25519 -f "$private_key" -N "" -C "devcontainer-in-vps"
  elif [[ ! -f "$public_key" ]]; then
    ssh-keygen -y -f "$private_key" > "$public_key"
  fi

  chmod 600 "$private_key"
  chmod 644 "$public_key"
}

ensure_ssh_key

devcontainer up \
  --workspace-folder "$PWD" \
  --config "$PWD/.devcontainer/devcontainer.json"
