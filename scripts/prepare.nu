#!/usr/bin/env nu
# Script para gerar configuração base do NixOS em /mnt

def main [] {
    print "Gerando configuração do NixOS em /mnt..."
    sudo nixos-generate-config --root /mnt
    
    let target_dir = "/mnt/etc/nixos"
    if ($target_dir | path exists) {
        cd $target_dir
        print "Criando arquivos base..."
        sudo touch flake.nix home.nix
        ls | where name =~ "nix"
        print $"Arquivos flake.nix e home.nix criados em ($target_dir)"
    } else {
        print $"Erro: Diretório ($target_dir) não encontrado. Verifique se o disco está montado em /mnt."
    }
}
