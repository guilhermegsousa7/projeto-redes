#!/bin/bash
# /usr/local/bin/backup_banco.sh - backup diario do PostgreSQL -> servidor de arquivos (SSH com chave)
# Cron (root): 0 2 * * * /usr/local/bin/backup_banco.sh
set -euo pipefail
DATA=$(date +%Y-%m-%d_%H-%M-%S)
DUMP=/tmp/db_app_${DATA}.sql
ARQ=/tmp/db_app_${DATA}.tar.gz
DEST=bkp@10.0.2.10
PASTA=/compartilhado/backups
RETENCAO=7
CHAVE=/root/.ssh/id_backup

runuser -u postgres -- pg_dump appdb > "$DUMP"
tar -czf "$ARQ" -C /tmp "$(basename "$DUMP")"
scp -q -i "$CHAVE" -o StrictHostKeyChecking=accept-new "$ARQ" "$DEST:$PASTA/"
ssh -i "$CHAVE" "$DEST" "ls -1t $PASTA/db_app_*.tar.gz | tail -n +$((RETENCAO+1)) | xargs -r rm --"
rm -f "$DUMP" "$ARQ"
echo "$(date '+%F %T') backup ok: db_app_${DATA}.tar.gz" >> /var/log/backup_banco.log
