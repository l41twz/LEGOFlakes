#!/usr/bin/env nu

def main [] {
    let target = "/mnt/etc/nixos/"
    let disk_workdir = "/mnt/nix-workspace"
    let timestamp_pattern = '-\d{8}-\d{6}\.nix$'

    print "Limpando lock files e caches corrompidos..."
    if ($"($target)flake.lock" | path exists) { sudo rm -f $"($target)flake.lock" }
    sudo rm -rf /root/.cache/nix
    sudo rm -rf /home/nixos/.cache/nix

    sudo mkdir -p $"($disk_workdir)/cache"
    sudo mkdir -p $"($disk_workdir)/tmp"

    let dynamic_file = (ls $target | where name =~ $timestamp_pattern | first | get name)
    if ($dynamic_file | is-empty) { print "Erro: Configuração não encontrada."; return }
    
    let clean_hostname = ($dynamic_file | path parse | get stem | str replace -r '-\d{8}-\d{6}$' '')
    sudo cp -f $dynamic_file $"($target)flake.nix"

    cd $target

    print "Gerando novo flake.lock limpo..."
    sudo -E env TMPDIR=$"($disk_workdir)/tmp" XDG_CACHE_HOME=$"($disk_workdir)/cache" nix flake update

    print $"Instalando host: ($clean_hostname)..."
    
    # CORREÇÃO: Comando em uma única linha, sem a barra invertida (\)
    sudo -E env TMPDIR=$"($disk_workdir)/tmp" XDG_CACHE_HOME=$"($disk_workdir)/cache" nixos-install --flake $".#($clean_hostname)" --option eval-cache false
}
