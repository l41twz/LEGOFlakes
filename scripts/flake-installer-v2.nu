#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    print "🚀 INICIANDO V14: OPERAÇÃO SSD TOTAL"
    
    # 1. O PULO DO GATO: Usar o SSD para o Nix Store da ISO
    print "Redirecionando o armazenamento temporário para o SSD (35GB disponíveis)..."
    sudo mkdir -p /mnt/nix_temp_overlay
    
    # Vincula o diretório do disco ao store da ISO. 
    # Agora o Nix tem espaço infinito para descompactar o master.
    sudo mount --bind /mnt/nix_temp_overlay /nix/.rw-store

    # 2. Ativar Swap (Segurança extra contra OOM)
    sudo bash -c "
        if [ ! -f /mnt/iso_swap ]; then
            dd if=/dev/zero of=/mnt/iso_swap bs=1M count=4096 status=none
            chmod 600 /mnt/iso_swap
            mkswap /mnt/iso_swap
            swapon /mnt/iso_swap
        fi
    "

    # 3. Preparar o arquivo de configuração
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    
    sudo cp -f $dynamic_file $"($target)/flake.nix"
    cd $target

    # 4. Configurar Git corretamente para evitar o Bug 134 e o aviso de 'Dirty'
    print "Configurando Git para a instalação..."
    if ! ($"($target)/.git" | path exists) { sudo git init }
    
    # Nix exige que os arquivos estejam 'comitados' ou 'staged' em repositórios Git
    sudo git config --global user.email "installer@nixos.org"
    sudo git config --global user.name "NixOS Installer"
    sudo git add .
    sudo git commit -m "Instalação estável" --allow-empty

    # 5. Execução Definitiva
    print $"Iniciando instalação de: ($clean_hostname)..."
    # Sem cache de avaliação para garantir que o novo espaço seja usado
    sudo nixos-install --flake $".#($clean_hostname)" --option eval-cache false
}
