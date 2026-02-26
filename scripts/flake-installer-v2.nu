#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"

    # 1. Identificar o nome do host pelo timestamp
    # Busca arquivos que terminam com o padrão: -YYYYMMDD-HHMMSS.nix
    let pattern = '-\d{8}-\d{6}\.nix$'
    
    # Lista os arquivos no destino e filtra pelo padrão
    let found_files = (ls $target | where name =~ $pattern)

    if ($found_files | is-empty) {
        print $"Erro: Nenhum arquivo com timestamp encontrado em ($target)"
        return
    }

    # Pega o primeiro arquivo encontrado e extrai o 'stem' (nome sem extensão)
    let flake_name = ($found_files | first | get name | path parse | get stem)

    print $"Configuração dinâmica detectada: ($flake_name)"

    # 2. Executar a instalação
    # Entra no diretório para que o Nix reconheça o flake local (.)
    cd $target
    
    # O Nix exige que arquivos novos em um repo Git sejam 'staged'
    if (".git" | path exists) {
        print "Repositório Git detectado, adicionando arquivos..."
        sudo git add .
    }

    print $"Iniciando instalação: nixos-install --flake .#($flake_name)"
    
    # Executa o comando final como root
    sudo nixos-install --flake $".#($flake_name)"
}
