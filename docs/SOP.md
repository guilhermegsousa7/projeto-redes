# SOP - Procedimentos operacionais

## 1. Restaurar um backup do banco (VM db)

Os backups ficam em `/compartilhado/backups` no servidor `arquivos`, como
`db_app_AAAA-MM-DD_HH-MM-SS.tar.gz` (os 7 mais recentes sao mantidos).

```bash
# 1. Buscar o mais recente
ULTIMO=$(sudo ssh -i /root/.ssh/id_backup bkp@10.0.2.10 'ls -1t /compartilhado/backups/db_app_*.tar.gz | head -n 1')
sudo scp -i /root/.ssh/id_backup bkp@10.0.2.10:$ULTIMO /tmp/restore.tar.gz
sudo tar -xzf /tmp/restore.tar.gz -C /tmp

# 2. Testar primeiro em um banco temporario
sudo -u postgres createdb appdb_teste
sudo -u postgres psql -q -d appdb_teste -f /tmp/db_app_*.sql
sudo -u postgres psql -d appdb_teste -c "SELECT count(*) FROM mensagens;"
sudo -u postgres dropdb appdb_teste

# 3. Restaurar de fato (na VM web: sudo systemctl stop app)
sudo -u postgres dropdb appdb
sudo -u postgres createdb appdb
sudo -u postgres psql -q -d appdb -f /tmp/db_app_*.sql
# (na VM web: sudo systemctl start app)

# 4. Limpar
sudo rm -f /tmp/restore.tar.gz /tmp/db_app_*.sql
```

## 2. Adicionar um usuario ao Samba (VM arquivos)

```bash
sudo groupadd -f NOME_DO_GRUPO                         # se o grupo for novo
sudo useradd -m -s /usr/sbin/nologin -G todos,GRUPO NOVO_USUARIO
sudo smbpasswd -a NOVO_USUARIO                         # define a senha do Samba
sudo setquota -u NOVO_USUARIO 204800 256000 0 0 /compartilhado   # quota em KB (soft hard)
sudo repquota -v -ug /compartilhado                    # conferir
```

Grupos e acesso: `todos` (publico), `devs` (escrevem em projetos), `diretoria` (leitura em
projetos e backups), `mkt` (so publico), `backup_mgr` (escrevem em backups).

## 3. Adicionar um usuario de aplicacao ao banco (VM db)

```bash
sudo -u postgres psql -c "CREATE ROLE novo LOGIN PASSWORD 'SENHA' NOSUPERUSER NOCREATEDB NOCREATEROLE;"
sudo -u postgres psql -d appdb -c "GRANT SELECT, INSERT ON mensagens TO novo;"
echo 'host  appdb  novo  10.0.1.10/32  scram-sha-256' | sudo tee -a /etc/postgresql/18/main/pg_hba.conf
sudo systemctl reload postgresql
```

## 4. Conferir e recarregar o firewall (VM fw)

```bash
sudo nft -c -f /etc/nftables.conf     # valida a sintaxe sem aplicar
sudo nft -f /etc/nftables.conf        # aplica
sudo dmesg | grep FW-DROP-DB | tail   # tentativas bloqueadas para a DB Zone
```
