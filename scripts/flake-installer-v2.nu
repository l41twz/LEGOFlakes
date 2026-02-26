#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    print "🚀 INICIANDO V15: RESOLVENDO ESPAÇO E SINTAXE"
    
    # 1. RESOLVENDO O ESPAÇO (Bind Mount)
    # Isso move o 'rascunho' da ISO para o SSD de 35GB
    print "Redirecionando armazenamento temporário para o SSD..."
    sudo mkdir -p /mnt/nix_storage_fix
    sudo mount --bind /mnt/nix_storage_fix /nix/.rw-store

    # 2. SWAP (Segurança extra contra o erro 134/Core Dump)
    sudo bash -c "
        if [ ! -f /mnt/iso_swap ]; then
            dd if=/dev/zero of=/mnt/iso_swap bs=1M count=4096 status=none
            chmod 600 /mnt/iso_swap
            mkswap /mnt/iso_swap
            swapon /mnt/iso_swap
        fi
    "

    # 3. LOCALIZANDO E PREPARANDO O FLAKE
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    
    sudo cp -f $dynamic_file $"($target)/flake.nix"
    cd $target

    # 4. FIX DA SINTAXE (USANDO 'NOT' EM VEZ DE '!') E GIT
    print "Configurando Git para evitar o erro 'dirty tree'..."
    # Corrigido o erro de sintaxe da imagem image_5474be.png
    if not ($"($target)/.git" | path exists) { 
        sudo git init 
    }
    
    sudo git config --global user.email "installer@nixos.org"
    sudo git config --global user.name "NixOS"
    sudo git add .
    # O commit é vital para o Nix não reclamar de 'dirty tree' (image_54803e.png)
    sudo git commit -m "install" --allow-empty

    # 5. EXECUÇÃO
    print $"Instalando: ($clean_hostname)..."
    sudo nixos-install --flake $".#($clean_hostname)" --option eval-cache false
}
