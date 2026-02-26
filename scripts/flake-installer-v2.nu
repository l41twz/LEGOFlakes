#!/usr/bin/env nu

def main [host_name: string] {
    let install_path = "/mnt/etc/nixos"

    # Muda para o diretório de instalação
    cd $install_path

    # Se você usa Git no seu flake, é necessário dar 'add' 
    # para o Nix reconhecer os arquivos novos/modificados
    if (".git" | path exists) {
        git add .
    }

    print $"Iniciando instalação do NixOS para o host: ($host_name)..."

    # Executa a instalação apontando para o diretório atual (.) e o host
    # O comando final será: nixos-install --flake .#nome-do-host
    nixos-install --flake $".#($host_name)"
}