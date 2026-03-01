# NIXOS-LEGO-MODULE: ssh-agent-git
# PURPOSE: SSH agent configuration for git USER
# CATEGORY: system
# ---
          programs.ssh.startAgent = true;
          programs.ssh.extraConfig = ''
            Host github.com
              HostName github.com
              User git
              IdentityFile /home/ry3/.ssh/ry3
              IdentitiesOnly yes
          '';