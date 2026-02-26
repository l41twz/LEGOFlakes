#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    print "🚀 INICIANDO V17: NOME CORRETO + PODER DO SSD"
    
    # 1. PREPARANDO O ESPAÇO (SSD + RAM VIRTUAL)
    # Redireciona o lixo temporário do Nix para os 35GB do SSD
    sudo mkdir -p /mnt/tmp
    sudo chmod 1777 /mnt/tmp
    sudo mount -o remount,size=20G /nix/.rw-store 2>/dev/null || true
    
    sudo bash -c "
        if [ ! -f /mnt/iso_swap ]; then
            dd if=/dev/zero of=/mnt/iso_swap bs=1M count=8192 status=none
            chmod 600 /mnt/iso_swap
            mkswap /mnt/iso_swap
            swapon /mnt/iso_swap
        fi
    "

    # 2. IDENTIFICANDO A CONFIGURAÇÃO (Voltando à função real)
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    
    # Extrai o hostname real (o que vem antes do timestamp)
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    
    print $"Hostname detectado: ($clean_hostname)"
    sudo cp -f $dynamic_file $"($target)/flake.nix"
    cd $target

    # 3. FIX DO GIT (Essencial para o Nix não dar 'Core Dump')
    if not ($"($target)/.git" | path exists) { sudo git init }
    sudo git config --global user.email "installer@nixos.org"
    sudo git config --global user.name "NixOS"
    sudo git add .
    sudo git commit -m "pre-install" --allow-empty

    # 4. EXECUÇÃO COM REDIRECIONAMENTO DE CACHE PARA O SSD
    print $"Instalando host: ($clean_hostname)..."
    
    with-env { 
        TMPDIR: "/mnt/tmp", 
        XDG_CACHE_HOME: "/mnt/tmp/.cache" 
    } {
        sudo -E nixos-install --flake $".#($clean_hostname)" --option eval-cache false
    }
}
