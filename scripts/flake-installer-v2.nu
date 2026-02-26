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
    if not ($"($target)/.git" | path exists) {
        sudo git init
    }
    sudo git add -A

    # ── Limpa cache de avaliações anteriores ─────────────────────────────────
    sudo rm -rf /root/.cache/nix

    # ── Instala ───────────────────────────────────────────────────────────────
    print $"Instalando NixOS para o host: ($hostname)..."
    sudo nixos-install --flake $".#($hostname)" --store /mnt --option eval-cache false
}
