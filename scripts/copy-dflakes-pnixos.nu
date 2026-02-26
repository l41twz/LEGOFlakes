#!/usr/bin/env nu

def main [] {
    let source = "/home/nixos/LEGOFlakes/flakes/"
    let target = "/mnt/etc/nixos/"

    # Cria o diretório de destino se não existir
    mkdir $target

    print $"Copiando configurações de ($source) para ($target)..."
    
    # Copia recursivamente os arquivos
    cp -r $"($source)*" $target

    print "Arquivos copiados com sucesso!"
}