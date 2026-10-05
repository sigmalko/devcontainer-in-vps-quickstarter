# Dev Container on a VPS

This project runs a development container with an SSH server. Login uses only
an Ed25519 key generated locally in the project directory.

## Requirements

- Docker Engine and Docker Compose v2,
- the `ssh-keygen` tool (OpenSSH package),
- the `@devcontainers/cli` CLI (`devcontainer` command) when using either
  startup script,
- the `SSH_PORT` port open on the host/VPS and in its firewall.

## Windows: Docker Desktop and PowerShell

Use this route for a project stored on a Windows drive such as `C:\dev\...`.
It is designed for Docker Desktop running Linux containers; it does not require
WSL or Git Bash.

Before the first run, install and start:

- Docker Desktop, configured for Linux containers;
- the Windows **OpenSSH Client** (`ssh` and `ssh-keygen`);
- Node.js and the Dev Containers CLI:

  ```powershell
  npm install --global @devcontainers/cli
  ```

From a regular PowerShell window in the repository root, run:

```powershell
.\up.ps1
```

If your execution policy blocks project scripts, use this one-off invocation;
it does not change the machine-wide execution policy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\up.ps1
```

`up.ps1` verifies that Docker Desktop, Docker Compose v2, OpenSSH and the Dev
Containers CLI are available. It creates `.devcontainer/.env` from the
template when absent, creates the client and host key pairs in `.ssh`, applies
the restrictive ACL required by Windows OpenSSH to private keys, stages the
client public key, and recreates the Dev Container.

The port comes from `SSH_PORT` in `.devcontainer/.env`; the template defaults
to `2222`. After a successful start, connect from PowerShell with:

```powershell
ssh -i .\.ssh\id_ed25519 -p 2222 vscode@localhost
```

Replace `2222` if you changed `SSH_PORT`. If Docker reports that the port is
already allocated, choose a free host port in `.devcontainer/.env`, then run
`up.ps1` again. The container always listens on port `22` internally.

## First-time setup

For Linux, macOS, WSL, or Git Bash, run the following commands from the
project root directory. For native Windows PowerShell, use the section above.

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

3. Generate the SSH key and start the container:

   ```bash
   ./up.sh
   ```

   The script creates two key pairs if they do not already exist:

   - `.ssh/id_ed25519` and `.ssh/id_ed25519.pub` authenticate the SSH client;
   - `.ssh/ssh_host_ed25519_key` and `.ssh/ssh_host_ed25519_key.pub` identify
     the SSH server.

   The script stages the client public key in `.devcontainer/authorized_keys`
   for the image build, where it becomes the `authorized_keys` file for the
   `vscode` user. The staged file and both private keys remain untracked. The
   script then removes an existing Dev Container, builds a new one, and starts
   it.

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

   The project directory is mounted in the container at `/workspaces`.

## Connecting over SSH

From Windows PowerShell on the host running Docker, connect with:

```powershell
ssh -i .\.ssh\id_ed25519 -p 2222 vscode@localhost
```

From Linux, macOS, WSL, or Git Bash, use:

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

## SSH host-key storage

The SSH client key and the SSH host key have different purposes. `up.sh` stages
the client public key (`.ssh/id_ed25519.pub`) at
`.devcontainer/authorized_keys`, which is copied into the image as
`authorized_keys`; it is public and only authorizes a client to log in.

The SSH host private key (`.ssh/ssh_host_ed25519_key`) is not copied into the
image. Docker Compose bind-mounts it, together with its public key, as a
read-only runtime source. Before `sshd` starts, the container copies the keys
to `/run/ssh-host-key` and applies `root:root` ownership and mode `0600` to
the private key. This is necessary for Windows bind mounts, which otherwise
appear as mode `0777` and are rejected by `sshd`. The copy exists only for the
life of the container; the stable source key remains in `.ssh`. Only the
staged client public key is included in the image. The `.ssh` directory and
the staged file are excluded from Git.

Keep these host-key files to preserve the server identity. If you intentionally
rotate them, verify the new fingerprint before updating each client's
`known_hosts` entry.

## Terminal colors

Interactive Bash sessions use a Catppuccin Mocha-inspired truecolor prompt,
chosen for readability in VS Code dark themes. The prompt exports
`COLORTERM=truecolor` and preserves the terminal-provided `TERM` value. It
shows the user and host in blue, the current directory in green, the Git branch
in peach, and a failed command status in red.

## Scheduled CLI updates

The base image provides a daily update job for Claude and Codex at `04:00`.
It is a system cron definition in `/etc/cron.d/devcontainer-cli-updates`, not a
per-user crontab, so `crontab -l` for `vscode` correctly shows no entries.

The Dev Container starts `cron` alongside `sshd`, so the job is active after
startup. Inspect its definition and log with:

```bash
cat /etc/cron.d/devcontainer-cli-updates
tail -f /var/log/devcontainer-cli-updates.log
```

GitHub CLI (`gh`) is installed through the Dev Container GitHub CLI feature.

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
removed. The SSH host key remains available because it is stored in the
project's `.ssh` directory and bind-mounted into the container at runtime.

To also rebuild the image without using Docker's build cache, add
`--build-no-cache`:

```bash
devcontainer up \
  --remove-existing-container \
  --build-no-cache \
  --workspace-folder "$PWD" \
  --config "$PWD/.devcontainer/devcontainer.json"
```
