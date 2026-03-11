# NIXOS-LEGO-MODULE: ssh-agent-git-ry5
# PURPOSE: SSH agent configuration for git USER
# CATEGORY: system
# ---
programs.ssh.startAgent = true;
programs.ssh.extraConfig = ''
Host github.com
  HostName github.com
  User git
  IdentityFile /home/ry5/.ssh/l41twz
  IdentitiesOnly yes
'';