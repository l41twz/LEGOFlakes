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

    # ── Expansão de Memória / Bypass de Limite RAM (Swap no Disco) ────────────
    print "Aumentando a capacidade do LiveCD via Swap em Disco (Evitando Core Dump e No Space)..."
    sudo bash -c "
        if [ ! -f /mnt/iso_swap ]; then
            echo 'Criando 8GB de swap no /mnt/iso_swap...'
            dd if=/dev/zero of /mnt/iso_swap bs=1M count=8192 status=none
            chmod 600 /mnt/iso_swap
            mkswap /mnt/iso_swap
            swapon /mnt/iso_swap
        else
            swapon /mnt/iso_swap 2>/dev/null || true
        fi
        
        # Aumentar os limites teóricos dos tmpfs do LiveCD para aproveitar o Swap
        mount -o remount,size=20G /nix/.rw-store 2>/dev/null || true
        mount -o remount,size=20G / 2>/dev/null || true
    "

    print "Preparando diretórios temporários e de cache no disco..."
    sudo mkdir -p /mnt/.nix-tmp /mnt/.nix-cache /root/.cache
    sudo chmod 777 /mnt/.nix-tmp /mnt/.nix-cache

    print "Montando /tmp e /root/.cache para o disco..."
    sudo mount --bind /mnt/.nix-tmp /tmp
    sudo mount --bind /mnt/.nix-cache /root/.cache

    # ── Instala ───────────────────────────────────────────────────────────────
    print $"Instalando NixOS para o host: ($hostname)..."
    sudo nixos-install --flake $".#($hostname)" --option eval-cache false --no-write-lock-file
    
    # ── Limpeza ───────────────────────────────────────────────────────────────
    print "Desmontando diretórios temporários e limpando..."
    sudo umount -l /tmp
    sudo umount -l /root/.cache
    sudo rm -rf /mnt/.nix-tmp /mnt/.nix-cache
}
