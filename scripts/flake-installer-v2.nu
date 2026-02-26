#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    # 1. Localizar o arquivo dinâmico (ex: vm1-20260226-004638.nix)
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    
    if ($dynamic_file | is-empty) {
        print "Erro: Arquivo com timestamp não encontrado."
        return
    }

    # 2. Extrair o Hostname limpo (ex: 'vm1')
    # Remove o timestamp e a extensão .nix
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')

    print $"Host detectado: ($clean_hostname)"
    print $"Preparando arquivo flake.nix..."

    # 3. Criar uma cópia chamada flake.nix
    # O NixOS precisa que o arquivo principal se chame exatamente flake.nix
    sudo cp $dynamic_file $"($target)flake.nix"

    # 4. Executar a instalação
    cd $target
    
    # Se houver Git, precisamos registrar o novo flake.nix
    if (".git" | path exists) {
        sudo git add flake.nix
    }

    print $"Iniciando: nixos-install --flake .#($clean_hostname)"
    sudo nixos-install --flake $".#($clean_hostname)"
}
