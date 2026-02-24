def main [] {
    let secret_dir = "secrets"
    if not ($secret_dir | path exists) { mkdir $secret_dir }

    let target_file = ($secret_dir | path join "gemini.key")
    let content = "{\n  # --> \n  gemini_api_key = \"SUA_APIKEY_AQUI\";\n}"

    $content | save --force $target_file
    print $"Arquivo criado: ($target_file)"
}
