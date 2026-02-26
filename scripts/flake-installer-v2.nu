#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let temp_dir = "/mnt/tmp"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    # 1. Preparar o espaço no DISCO REAL para temporários
    print "Configurando diretório temporário no disco para evitar erro de espaço..."
    sudo mkdir -p $temp_dir
    sudo chmod 1777 $temp_dir # Permissão padrão de pasta temp
    
    # Definir variáveis de ambiente para o processo atual
    $env.TMPDIR = $temp_dir
    $env.XDG_CACHE_HOME = $"($temp_dir)/cache"

    # 2. Localizar e preparar o flake.nix
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    
    if ($dynamic_file | is-empty) {
        print "Erro: Arquivo com timestamp não encontrado."
        return
    }

    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp $dynamic_file $"($target)flake.nix"

    # 3. Executar a instalação com redirecionamento de cache
    cd $target
    
    print $"Instalando host: ($clean_hostname) usando ($temp_dir) para cache..."

    # Executamos com sudo -E para preservar as variáveis TMPDIR que definimos
    sudo -E nixos-install --flake $".#($clean_hostname)" --option build-dir $temp_dir
}
