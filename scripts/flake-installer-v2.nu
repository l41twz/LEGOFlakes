#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    print "Expandindo os limites da RAM da ISO com Swap..."
    
    # 1. Magia do Swap e expansão do tmpfs via bash (garante estabilidade do sistema)
    sudo bash -c "
        if [ ! -f /mnt/iso_swap ]; then
            echo 'Alocando 8GB no disco para suportar o nixpkgs-master...'
            touch /mnt/iso_swap
            # Previne erros no BTRFS, se for o caso
            chattr +C /mnt/iso_swap 2>/dev/null || true
            dd if=/dev/zero of=/mnt/iso_swap bs=1M count=8192 status=none
            chmod 600 /mnt/iso_swap
            mkswap /mnt/iso_swap
            swapon /mnt/iso_swap
        fi
        echo 'Remontando partições na RAM para 12GB de limite virtual...'
        mount -o remount,size=12G /nix/.rw-store
        mount -o remount,size=12G /
    "

    # 2. Preparar configuração
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp -f $dynamic_file $"($target)flake.nix"

    cd $target

    # Limpar possível lock file corrompido das tentativas anteriores
    if ($"($target)flake.lock" | path exists) { sudo rm -f $"($target)flake.lock" }

    # 3. Executar instalação limpa
    print $"Iniciando instalação definitiva de: ($clean_hostname)..."
    sudo nixos-install --flake $".#($clean_hostname)" --option eval-cache false
}
