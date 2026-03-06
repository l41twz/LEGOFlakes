#!/usr/bin/env nu

def main [] {
    let source = "/home/nixos/LEGOFlakes/flakes/"
    let target = "/mnt/etc/nixos/"

    print $"Solicitando permissões para gravar em ($target)..."

    # Garante que o diretório de destino existe com sudo
    sudo mkdir -p $target

    # No Nushell, para usar o wildcard (*) com sudo, 
    # é mais seguro disparar uma subshell do bash ou usar o cp direto
    sudo bash -c $"cp -r ($source)* ($target)"

    if ($env.LAST_EXIT_CODE == 0) {
        print "Arquivos copiados com sucesso como root!"
    } else {
        error make {msg: "Falha na cópia. Verifique a senha ou permissões."}
    }
}
