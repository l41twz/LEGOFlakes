#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    print "Expandindo limites de RAM da ISO com Swap..."
    sudo bash -c "
        if [ ! -f /mnt/iso_swap ]; then
            touch /mnt/iso_swap
            chattr +C /mnt/iso_swap 2>/dev/null || true
            dd if=/dev/zero of=/mnt/iso_swap bs=1M count=8192 status=none
            chmod 600 /mnt/iso_swap
            mkswap /mnt/iso_swap
            swapon /mnt/iso_swap
        fi
        mount -o remount,size=12G /nix/.rw-store 2>/dev/null || true
        mount -o remount,size=12G / 2>/dev/null || true
    "

    # Prepara o flake.nix
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    
    sudo cp -f $dynamic_file $"($target)/flake.nix"

    cd $target

    # Limpeza de resquícios da falha anterior
    if ($"($target)/flake.lock" | path exists) { sudo rm -f $"($target)/flake.lock" }
    sudo rm -rf /root/.cache/nix

    # =========================================================
    # O SEGREDO: Transformar em repositório Git para evitar o Bug 134
    # =========================================================
    print "Inicializando repositório Git para evitar o bug 'path:'..."
    sudo git init
    sudo git add .

    print $"Iniciando instalação definitiva de: ($clean_hostname)..."
    # O Nix agora vai ler o flake como se fosse um Git tracker, ignorando o bug do 'path:'
    sudo nixos-install --flake $".#($clean_hostname)" --option eval-cache false
}
