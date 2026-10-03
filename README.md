# Dev Container on a VPS

This project runs a development container with an SSH server. Login uses only
an Ed25519 key generated locally in the project directory.

## Requirements

- Docker Engine and Docker Compose v2,
- the `ssh-keygen` tool (OpenSSH package),
- optionally, VS Code with the **Dev Containers** extension or the
  `@devcontainers/cli` CLI,
- the `SSH_PORT` port open on the host/VPS and in its firewall.

## First-time setup

Run the commands from the project root directory.

1. Create the local Compose configuration file:

   ```bash
   cp .devcontainer/.env.example .devcontainer/.env
   ```

2. Change values in `.devcontainer/.env` if needed:

   ```dotenv
   COMPOSE_PROJECT_NAME=sample
   SSH_PORT=2222
   DOCKER_API_VERSION=1.48
   ```

   `SSH_PORT` is the port exposed on the host; the container port always
   remains `22`.

3. Generate the SSH key:

   ```bash
   ./up.sh
   ```

   The script creates `.ssh/id_ed25519` and `.ssh/id_ed25519.pub`. It does not
   overwrite an existing key. The public key is copied into the image as the
   `authorized_keys` file for the `vscode` user; the private key remains on the
   host only. It then removes an existing Dev Container, builds a new one, and
   starts it.

4. Alternatively, build and start the Dev Container manually.

   In VS Code, open the project directory and run
   **Dev Containers: Reopen in Container**.

   Alternatively, use the CLI:

   ```bash
   devcontainer up \
     --workspace-folder "$PWD" \
     --config "$PWD/.devcontainer/devcontainer.json"
   ```

   Add `--remove-existing-container` to recreate an existing Dev Container.

## Connecting over SSH

From the host running Docker, connect with:

```bash
ssh -i .ssh/id_ed25519 -p 2222 vscode@localhost
```

If `SSH_PORT` has a different value, replace `2222` with that value. From
another computer, use the VPS public address instead of `localhost`:

```bash
ssh -i .ssh/id_ed25519 -p 2222 vscode@ADRES_VPS
```

At the first connection, SSH asks you to confirm the container host-key
fingerprint. Password login and `root` login are disabled; only public-key
login for the `vscode` user is allowed. An interactive SSH session starts in
`/workspaces`.

## Changing the key or port

- After changing `SSH_PORT`, restart the container.
- After generating a new key, run **Rebuild Container** in VS Code or rebuild
  the container with `devcontainer up`, because the public key is added to the
  image during its build.
- Do not add `.ssh/id_ed25519` or `.devcontainer/.env` to the repository.

## Recreating the Dev Container

Running `devcontainer up` alone can reuse an existing container. To remove the
current Dev Container and create a new one, run:

```bash
devcontainer up \
  --remove-existing-container \
  --workspace-folder "$PWD" \
  --config "$PWD/.devcontainer/devcontainer.json"
```

Files in the project directory remain available because the workspace is
mounted into the container. Data stored only in the old container filesystem is
removed.

To also rebuild the image without using Docker's build cache, add
`--build-no-cache`:

```bash
devcontainer up \
  --remove-existing-container \
  --build-no-cache \
  --workspace-folder "$PWD" \
  --config "$PWD/.devcontainer/devcontainer.json"
```
