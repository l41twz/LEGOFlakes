#!/usr/bin/env nu
def main [pergunta: string] {
  # Tenta encontrar a raiz do projeto subindo diretórios
  # Como FILE_PWD pode falhar, usamos PWD e subimos até achar secrets/gemini.key
  
  mut current_dir = ($env.PWD | path expand)
  mut found_secrets = ""
  
  loop {
    let check_path = ($current_dir | path join "secrets/gemini.key")
    if ($check_path | path exists) {
      $found_secrets = $check_path
      break
    }
    
    let parent = ($current_dir | path dirname)
    if $parent == $current_dir {
      break
    }
    $current_dir = $parent
  }

  mut secrets_file = ""
  if $found_secrets != "" {
    $secrets_file = $found_secrets
  } else {
    let home_path = ($env.HOME | path join "LEGOFlakes/secrets/gemini.key")
    if ($home_path | path exists) {
      $secrets_file = $home_path
    }
  }

  if $secrets_file == "" {
      print "Erro: Não foi possível encontrar secrets/gemini.key na árvore de diretórios."
      return
  }
  
  let file_content = (open --raw $secrets_file)
  let api_key = ($file_content | parse -r 'gemini_api_key\s*=\s*"([^"]+)"' | get capture0 | first)
  
  if ($api_key == "GEMINI_API_KEY_PLACEHOLDER") {
    print "Erro: GEMINI_API_KEY não configurada em ./secrets/gemini.key"
    return
  }

  # Lista atualizada de modelos (fevereiro 2026)
  # Prioriza modelos com quota ilimitada primeiro, depois os mais rápidos
  let modelos = [
    "gemini-3-pro-preview",        # Mais novo e poderoso (quota: 0/15 ilimitado)
    "gemini-3-flash-preview",      # Novo e balanceado (quota: 0/5, 0/250K)
    "gemini-2.5-pro",              # Estável, advanced thinking (quota: 0/15 ilimitado)
    "gemini-2.5-flash",            # Melhor custo-benefício (quota: 1/5, 80/250K)
    "gemini-2.5-flash-lite",       # Ultra rápido (quota: 1/10, 13/250K)
    "gemini-2.0-flash"             # Deprecado mas funcional até 31/03/2026
  ]
  
  let body = { contents: [{ parts: [{ text: $pergunta }] }] } | to json
  
  for modelo in $modelos {
    let url = $"https://generativelanguage.googleapis.com/v1beta/models/($modelo):generateContent?key=($api_key)"
    let response = (curl -s -X POST $url -H "Content-Type: application/json" -d $body | from json)
    
    let error_check = (try { $response.error } catch { null })
    
    if $error_check != null {
      let msg = ($error_check.message | str downcase)
      # Continua se for quota ou modelo não encontrado/suportado
      if ($msg =~ "quota" or $msg =~ "limit" or $msg =~ "exhausted" or $msg =~ "not found" or $msg =~ "not supported") {
        continue
      }
      print $"Erro: ($error_check.message)"
      return
    }
    
    print ($response.candidates.0.content.parts.0.text)
    return
  }
  print "Erro: Quota esgotada em todos os modelos."
}