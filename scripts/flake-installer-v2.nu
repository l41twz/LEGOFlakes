#!/usr/bin/env nu

def main [] {
    let source = "/home/nixos/LEGOFlakes/flakes/"
    let target = "/mnt/etc/nixos/"

    # 1. Cópia com privilégios de root
    print "Copiando arquivos para /mnt/etc/nixos..."
    sudo mkdir -p $target
    sudo bash -c $"cp -r ($source)* ($target)"

    # 2. Identificar o nome do host pelo timestamp
    # Procuramos arquivos que terminam com o formato: -YYYYMMDD-HHMMSS.nix
    let pattern = '-\d{8}-\d{6}\.nix$'
    
    let flake_path = (ls $target | where name =~ $pattern | first | get name)
    
    if ($flake_path | is-empty) {
        print "Erro: Nenhum arquivo com timestamp encontrado em /mnt/etc/nixos/"
        return
    }

    # Extrai apenas o nome (stem) sem o caminho e sem a extensão .nix
    let flake_name = ($flake_path | path parse | get stem)

    print $"Configuração dinâmica detectada: ($flake_name)"

    # 3. Executar a instalação
    cd $target
    
    # Se houver um repo git, o Nix exige o 'add' para enxergar novos arquivos
    if (".git" | path exists) {
        sudo git add .
    }

    print $"Iniciando nixos-install --flake .#($flake_name)..."
    sudo nixos-install --flake $".#($flake_name)"
}
