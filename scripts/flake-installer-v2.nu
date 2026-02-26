#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let disk_cache = "/mnt/.cache-nix"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    # 1. Resolver o problema de espaço na RAM (Bind Mount)
    print "Redirecionando cache da RAM para o disco real..."
    sudo mkdir -p $disk_cache
    sudo mkdir -p /root/.cache/nix
    
    # Monta a pasta do disco por cima da pasta de cache da RAM
    # Isso faz com que os downloads pesados usem os 35GB do disco
    sudo mount --bind $disk_cache /root/.cache/nix

    # 2. Configurar variáveis de ambiente
    $env.TMPDIR = "/mnt/tmp"
    sudo mkdir -p /mnt/tmp

    # 3. Localizar e preparar o flake.nix (mesma lógica anterior)
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    
    if ($dynamic_file | is-empty) {
        print "Erro: Arquivo com timestamp não encontrado."
        return
    }

    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp $dynamic_file $"($target)flake.nix"

    # 4. Executar a instalação
    cd $target
    print $"Instalando host: ($clean_hostname) com cache em disco..."
    
    # O --no-write-lock-file ajuda se o diretório estiver estranho, 
    # mas o principal é o sudo -E para manter o TMPDIR
    sudo -E nixos-install --flake $".#($clean_hostname)"
}
