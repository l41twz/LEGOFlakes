#!/usr/bin/env nu

# ============================================================
# NixOS LEGO — Editor Setup
# Configura Micro com plugins e settings para o projeto
# ============================================================

def lego-root [] { $env.FILE_PWD | path dirname }

export def main [] {
  print (gum style --foreground 82 --bold "🔧 Configurando Editor Micro para NixOS LEGO")
  print ""

  # Verificar Micro
  if (which micro | is-empty) {
    print (gum style --foreground 208 "⚠ Micro não encontrado.")
    let choice = (
      gum choose --header "Como deseja instalar o Micro?" [
        "Instalar temporariamente (nix-shell -p micro)"
        "Adicionar ao sistema (environment.systemPackages)"
        "Cancelar"
      ]
    )

    match $choice {
      "Instalar temporariamente (nix-shell -p micro)" => {
        print "Execute: nix-shell -p micro"
        print "Depois rode este script novamente."
      }
      "Adicionar ao sistema (environment.systemPackages)" => {
        print "Adicione 'micro' ao seu environment.systemPackages"
        print "Depois rode este script novamente."
      }
      _ => { print "Setup cancelado." }
    }
    return
  }

  print (gum style --foreground 82 "✓ Micro encontrado")

  # Diretório de config
  let micro_config = $"($env.HOME)/.config/micro"
  mkdir $micro_config

  # Copiar settings
  let settings_src = $"((lego-root))/config/micro/settings.json"
  let settings_dst = $"($micro_config)/settings.json"

  if ($settings_src | path exists) {
    cp $settings_src $settings_dst
    print (gum style --foreground 82 "✓ Settings aplicados")
  } else {
    print (gum style --foreground 208 "⚠ Settings source não encontrado, pulando...")
  }

  # Instalar plugins
  let plug_dir = $"($micro_config)/plug"
  mkdir $plug_dir

  install-plugin $plug_dir "filemanager" "https://github.com/micro-editor/updated-plugins/tree/master/filemanager-plugin"
  install-plugin $plug_dir "manipulator" "https://github.com/micro-editor/updated-plugins/tree/master/manipulator-plugin"
  
  # Gemini plugin (local)
  let gemini_src = $"((lego-root))/config/micro/gemini.lua"
  let gemini_dst_dir = $"($plug_dir)/gemini"
  mkdir $gemini_dst_dir
  let gemini_dst = $"($gemini_dst_dir)/gemini.lua"
  if ($gemini_src | path exists) {
    cp $gemini_src $gemini_dst
    print (gum style --foreground 82 "  ✓ Gemini plugin instalado")
  } else {
    print (gum style --foreground 208 "  ⚠ Gemini plugin não encontrado")
  }
  # Configurar bindings
  let bindings_file = $"($micro_config)/bindings.json"
  if not ($bindings_file | path exists) {
    echo "{\n    \"Ctrl-1\": \"lua:gemini.geminiCommand\"\n}" | save $bindings_file
    print (gum style --foreground 82 "  ✓ Bindings configurados (Ctrl-1)")
  } else {
    # TODO: Merge json intelligently? For now, just warn if missing.
    let content = (open $bindings_file)
    if ($content | get -i "Ctrl-1" | is-empty) {
       print (gum style --foreground 208 "  ⚠ Adicione manualment ao bindings.json: \"Ctrl-1\": \"lua:gemini.geminiCommand\"")
    }
  }


  print ""
  print (gum style --foreground 82 --bold "✅ Setup do Micro concluído!")
  print ""
  print "Atalhos úteis:"
  print "  Ctrl+S: Salvar      Ctrl+Q: Sair"
  print "  Ctrl+F: Buscar      Tab: Alternar painéis"
  print "  Ctrl+1: Gemini AI   Ctrl+E: Comandos"
  print "  Ctrl+E → 'vsplit <arq>': Split vertical"
  print "  Ctrl+E → 'hsplit <arq>': Split horizontal"
}

def install-plugin [plug_dir: string, name: string, repo: string] {
  let target = $"($plug_dir)/($name)"
  if ($target | path exists) {
    print (gum style --foreground 240 $"  • ($name) já instalado")

    let update = (do { gum confirm $"Atualizar ($name)?" } | complete)
    if $update.exit_code == 0 {
      if ($target | path join ".git" | path exists) {
        cd $target
        git pull
        cd -
        print (gum style --foreground 82 $"  ✓ ($name) atualizado")
      } else {
        print (gum style --foreground 240 $"  ℹ ($name) não é um repositório git, pulando update.")
      }
    }
  } else {
    print $"  • Instalando ($name)..."
    git clone $repo $target
    print (gum style --foreground 82 $"  ✓ ($name) instalado")
  }
}
