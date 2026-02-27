#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos"

    # ── Encontra o flake gerado (ex: vm-20260226-173236.nix) ──────────────────
    let config_file = (
        ls $target
        | where name =~ '-\d{8}-\d{6}\.nix$'
        | sort-by modified --reverse
        | first
        | get name
    )

    let hostname = (
        $config_file
        | path parse
        | get stem
        | str replace -r '-\d{8}-\d{6}$' ''
    )

    print $"Configuração encontrada: ($config_file)"
    print $"Hostname: ($hostname)"

    # ── Prepara o flake.nix ───────────────────────────────────────────────────
    sudo cp -f $config_file $"($target)/flake.nix"
    sudo rm -f $"($target)/flake.lock"

    # ── Git: necessário para o Nix resolver path: corretamente ───────────────
    cd $target
    sudo git config --global --add safe.directory $target
    if not ($"($target)/.git" | path exists) {
        sudo git init
    }
    sudo git add -A

    # ── Limpa cache de avaliações anteriores ─────────────────────────────────
    sudo rm -rf /root/.cache/nix

    # ── Redireciona só o store para o disco ───────────────────────────────────
    # Monta /mnt/nix/store sobre /nix/store — preserva o restante de /nix
    # (incluindo os binários da ISO como sudo, nixos-install, etc.)
    let is_mounted = (sudo mountpoint -q /nix/store | complete | get exit_code) == 0
    if not $is_mounted {
        print "Redirecionando /nix/store para o disco..."
        sudo mount --bind /mnt/nix/store /nix/store
    }

    # ── Instala ───────────────────────────────────────────────────────────────
    print "Preparando diretórios temporários e de cache no disco alvo..."
    sudo mkdir -p /mnt/.nix-tmp /mnt/.nix-cache
    print $"Instalando NixOS para o host: ($hostname)..."
    sudo env TMPDIR=/mnt/.nix-tmp XDG_CACHE_HOME=/mnt/.nix-cache nixos-install --flake $".#($hostname)" --option eval-cache false
    sudo rm -rf /mnt/.nix-tmp /mnt/.nix-cache
}
