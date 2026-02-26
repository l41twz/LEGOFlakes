#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let fake_home = "/mnt/temp-home"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    # 1. Criar um "Home" falso no seu disco real (35GB livres)
    # Isso evita usar o /home/nixos da RAM
    print "Preparando espaço no disco real para cache e downloads..."
    sudo mkdir -p $fake_home
    sudo mkdir -p $"($fake_home)/cache"

    # 2. Localizar o arquivo e preparar o flake.nix
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    
    if ($dynamic_file | is-empty) {
        print "Erro: Arquivo com timestamp não encontrado."
        return
    }

    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp $dynamic_file $"($target)flake.nix"
    print $"Arquivo flake.nix criado para o host: ($clean_hostname)"

    # 3. Executar a instalação redirecionando TUDO para o disco real
    cd $target
    
    print "Iniciando instalação. O cache será gravado em /mnt/temp-home..."
    
    # O segredo está aqui: redirecionamos o HOME e o TMPDIR para o disco real
    # Usamos sudo -E para que o instalador herde essas variáveis
    sudo -E env HOME=$fake_home TMPDIR=$"($fake_home)/tmp" XDG_CACHE_HOME=$"($fake_home)/cache" nixos-install --flake $".#($clean_hostname)"
}
