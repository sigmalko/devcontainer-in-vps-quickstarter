# See: https://github.com/sigmalko/devcontainer-in-vps - it is pushed to GitHub Container Registry
FROM ghcr.io/sigmalko/devcontainer-in-vps:latest

# sshd runs as the container's foreground process; only vscode may log in by key.
RUN mkdir -p /run/sshd \
    && printf '%s\n' \
        'PasswordAuthentication no' \
        'KbdInteractiveAuthentication no' \
        'PubkeyAuthentication yes' \
        'AuthenticationMethods publickey' \
        'PermitRootLogin no' \
        'AllowUsers vscode' \
        'HostKey /etc/ssh/ssh_host_ed25519_key' \
        > /etc/ssh/sshd_config.d/00-devcontainer.conf

# Prepare directories before copying files.
RUN mkdir -p /workspaces /home/vscode/.m2 /home/vscode/.ssh && \
    chmod 700 /home/vscode/.ssh && \
    chown vscode:vscode /workspaces

# Allow inbound SSH authentication with the public key staged by up.sh.
# The .ssh directory is excluded from the build context, so private keys
# cannot be copied into the image.
COPY --chown=vscode:vscode .devcontainer/authorized_keys /home/vscode/.ssh/authorized_keys

# SSH permissions.
RUN chown -R vscode:vscode /home/vscode/.ssh && \
    chmod 700 /home/vscode/.ssh && \
    chmod 600 /home/vscode/.ssh/authorized_keys

# Load the interactive Bash configuration for SSH login shells and start in the
# mounted workspace directory.
RUN printf '%s\n' \
        '' \
        '[ -f ~/.bashrc ] && . ~/.bashrc' \
        '# Start interactive SSH sessions in the workspace directory.' \
        'if [[ -n "${SSH_CONNECTION:-}" && -d /workspaces ]]; then' \
        '    cd /workspaces' \
        'fi' \
        >> /home/vscode/.bash_profile && \
    chown vscode:vscode /home/vscode/.bash_profile

RUN mkdir -p /home/vscode/.bashrc.d && chown vscode:vscode /home/vscode/.bashrc.d
COPY --chown=vscode:vscode .devcontainer/bashrc-truecolor.sh /home/vscode/.bashrc.d/truecolor.sh
RUN printf '%s\n' \
        '' \
        '[ -f ~/.bashrc.d/truecolor.sh ] && . ~/.bashrc.d/truecolor.sh' \
        >> /home/vscode/.bashrc && \
    chown vscode:vscode /home/vscode/.bashrc /home/vscode/.bashrc.d/truecolor.sh

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
