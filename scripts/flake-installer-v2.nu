#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let disk_workdir = "/mnt/nix-workspace"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    # 1. Limpeza rigorosa (Resolve o Erro 134 - Core Dump)
    print "Limpando lock files e caches corrompidos..."
    if ($"($target)flake.lock" | path exists) { sudo rm -f $"($target)flake.lock" }
    sudo rm -rf /root/.cache/nix
    sudo rm -rf /home/nixos/.cache/nix

    # 2. Preparar área no disco real (Evita falta de espaço na RAM)
    sudo mkdir -p $"($disk_workdir)/cache"
    sudo mkdir -p $"($disk_workdir)/tmp"

    # 3. Preparar o flake.nix
    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp -f $dynamic_file $"($target)flake.nix"

    cd $target

    # 4. Atualizar dependências do zero
    print "Gerando novo flake.lock limpo..."
    sudo -E env TMPDIR=$"($disk_workdir)/tmp" XDG_CACHE_HOME=$"($disk_workdir)/cache" nix flake update

    # 5. Instalar
    print $"Instalando host: ($clean_hostname)..."
    sudo -E env TMPDIR=$"($disk_workdir)/tmp" XDG_CACHE_HOME=$"($disk_workdir)/cache" \
    nixos-install --flake $".#($clean_hostname)" --option eval-cache false
}
