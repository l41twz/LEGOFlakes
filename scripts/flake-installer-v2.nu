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
    sudo git config --global user.email "livecd@nixos.org"
    sudo git config --global user.name "LiveCD Installer"

    if not ($"($target)/.git" | path exists) {
        sudo git init
    }
    sudo git add -A
    try {
        sudo git commit -m "Autocommit for flake evaluation" | ignore
    }

    # ── Redireciona caches e temp para o disco alvo (bypass RAM) ──────────────
    print "Preparando diretórios temporários e de cache no disco..."
    sudo mkdir -p /mnt/.nix-tmp /mnt/.nix-cache /root/.cache
    sudo chmod 777 /mnt/.nix-tmp /mnt/.nix-cache

    print "Montando /tmp e /root/.cache para o disco (Evita RAM full)..."
    sudo mount --bind /mnt/.nix-tmp /tmp
    sudo mount --bind /mnt/.nix-cache /root/.cache

    # Monta /mnt/nix/store sobre /nix/store — preserva o restante de /nix
    let is_mounted = (sudo mountpoint -q /nix/store | complete | get exit_code) == 0
    if not $is_mounted {
        print "Redirecionando /nix/store para o disco..."
        sudo mount --bind /mnt/nix/store /nix/store
    }

    # ── Instala ───────────────────────────────────────────────────────────────
    print $"Instalando NixOS para o host: ($hostname)..."
    sudo nixos-install --flake $".#($hostname)" --option eval-cache false --no-write-lock-file
    
    # ── Limpeza ───────────────────────────────────────────────────────────────
    print "Desmontando diretórios temporários e limpando..."
    sudo umount -l /tmp
    sudo umount -l /root/.cache
    sudo rm -rf /mnt/.nix-tmp /mnt/.nix-cache
}
