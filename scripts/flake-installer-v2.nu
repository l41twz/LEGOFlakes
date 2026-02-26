#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let disk_storage = "/mnt/.nix-cache-fix"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    # 1. Liberar o pouco espaço que resta na RAM
    print "Limpando lixo da RAM da ISO..."
    sudo nix-collect-garbage

    # 2. Criar estrutura de cache no DISCO REAL (vda3)
    print "Redirecionando caches de root e nixos para o disco real..."
    sudo mkdir -p $disk_storage
    sudo mkdir -p /root/.cache
    sudo mkdir -p /home/nixos/.cache

    # Monta o disco por cima das pastas que estão enchendo a RAM
    sudo mount --bind $disk_storage /root/.cache
    sudo mount --bind $disk_storage /home/nixos/.cache

    # 3. Preparar o flake.nix (mesma lógica)
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { 
        print "Erro: Arquivo de config não encontrado."; return 
    }

    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp $dynamic_file $"($target)flake.nix"

    # 4. Instalação com variáveis de ambiente forçadas
    cd $target
    print $"Iniciando instalação de ($clean_hostname)..."
    
    # HOME=/mnt/temp garante que o Nix procure as chaves e caches no disco
    sudo mkdir -p /mnt/temp-home
    sudo -E env HOME=/mnt/temp-home TMPDIR=/mnt/temp-home nixos-install --flake $".#($clean_hostname)"
}
