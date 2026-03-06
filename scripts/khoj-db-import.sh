#!/usr/bin/env bash

# Importa um backup do banco de dados do Khoj rodando via docker (oci-containers) no NixOS
# O banco padrão configurado no módulo é: db=khoj, user=postgres

CONTAINER_NAME="khoj-database"

# Exige que o arquivo de backup seja passado como primeiro argumento
if [ -z "$1" ]; then
    echo "Uso: $0 <arquivo_de_backup.sql>"
    exit 1
fi

BKP_FILE="$1"

if [ ! -f "$BKP_FILE" ]; then
    echo "❌ Erro: O arquivo '$BKP_FILE' não foi encontrado localmente."
    exit 1
fi

echo "Iniciando importação do arquivo '$BKP_FILE' para o banco 'khoj'..."

# Verifica se o container está rodando
if ! docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null | grep -q 'true'; then
    echo "❌ Erro: O container '$CONTAINER_NAME' não está rodando."
    echo "Verifique o status do serviço com: systemctl status docker-$CONTAINER_NAME.service"
    exit 1
fi

echo "⚠️  AVISO: Importar este arquivo pode sobrescrever/deletar dados atuais do seu Khoj!"
read -p "Deseja continuar com a importação? (s/N) " resp
if [[ "$resp" != "s" && "$resp" != "S" ]]; then
    echo "Importação cancelada pelo usuário."
    exit 0
fi

# Passa o conteúdo do arquivo via stdin (cat) para o psql sendo executado no container
cat "$BKP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U postgres -d khoj

if [ $? -eq 0 ]; then
    echo "✅ Importação concluída com sucesso!"
    echo "🔄 Recomenda-se reiniciar o servidor do Khoj para aplicar qualquer mudança:"
    echo "  sudo systemctl restart docker-khoj-server.service"
else
    echo "❌ Ocorreu um erro durante a importação. Verifique os logs do Postgres."
    exit 1
fi
