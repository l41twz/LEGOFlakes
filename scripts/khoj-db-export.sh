#!/usr/bin/env bash

# Exporta o banco de dados do Khoj rodando via docker (oci-containers) no NixOS
# O banco padrão configurado no módulo é: db=khoj, user=postgres

CONTAINER_NAME="khoj-database"
BACKUP_FILE="khoj_db_backup_$(date +%Y%m%d_%H%M%S).sql"

echo "Iniciando exportação do banco de dados do Khoj..."

# Verifica se o container está rodando
if ! docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null | grep -q 'true'; then
    echo "❌ Erro: O container '$CONTAINER_NAME' não está rodando."
    echo "Verifique o status do serviço com: systemctl status docker-$CONTAINER_NAME.service"
    exit 1
fi

# Executa o pg_dump dentro do container gerando o arquivo localmente
# Usamos -c (--clean) e --if-exists para que o script de importação apague
# os dados antigos antes de restaurar, evitando duplicação.
docker exec -t "$CONTAINER_NAME" pg_dump -U postgres -d khoj -c --if-exists > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Exportação concluída com sucesso!"
    echo "Arquivo salvo em: $(pwd)/$BACKUP_FILE"
else
    echo "❌ Ocorreu um erro durante a exportação."
    rm -f "$BACKUP_FILE" # Limpa o arquivo vazio/corrigido gerado
    exit 1
fi
