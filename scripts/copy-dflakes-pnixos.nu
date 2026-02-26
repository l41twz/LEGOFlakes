#!/usr/bin/env nu

def main [] {
    let source = "/home/nixos/LEGOFlakes/flakes/"
    let target = "/mnt/etc/nixos/"

    # Garante que o diretório de destino existe
    if not ($target | path exists) {
        mkdir $target
    }

    print $"Copiando conteúdo de ($source) para ($target)..."
    
    # No Nushell, usamos 'ls' para pegar os itens e 'cp' neles
    # Ou passamos o caminho do diretório sem o asterisco se quisermos o conteúdo
    ls $source | each { |it| 
        cp -r $it.name $target 
    }

    print "Arquivos copiados com sucesso!"
}
