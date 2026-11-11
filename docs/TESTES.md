# Roteiro de testes (demonstracao)

## 1. Fluxo Web HTTPS -> Aplicacao -> PostgreSQL
- Navegador: `https://localhost:8443` (porta encaminhada do host para o `fw`, depois DNAT para a `web`).
- Enviar uma mensagem no formulario e ver que ela aparece na lista.
- Na `web`: `curl -s http://127.0.0.1:8000/health` deve retornar `{"status":"ok","banco":"conectado"}`.
- Na `db`: `sudo -u postgres psql -d appdb -c "SELECT * FROM mensagens;"`.

## 2. Firewall e segmentacao
Na `web`:
```bash
timeout 3 bash -c '</dev/tcp/10.0.3.10/5432' && echo ABERTA || echo BLOQUEADA   # ABERTA
timeout 3 bash -c '</dev/tcp/10.0.3.10/22'   && echo ABERTA || echo BLOQUEADA   # BLOQUEADA
timeout 3 bash -c '</dev/tcp/10.0.2.10/445'  && echo ABERTA || echo BLOQUEADA   # BLOQUEADA
```
Na `arquivos`:
```bash
timeout 3 bash -c '</dev/tcp/10.0.3.10/5432' && echo ABERTA || echo BLOQUEADA   # BLOQUEADA
```
No `fw`: `sudo dmesg | grep FW-DROP-DB | tail -n 3` mostra os bloqueios registrados.

## 3. Samba, restricao de escrita e quotas (a partir do `fw`, na LAN)
```bash
echo teste > /tmp/teste.txt
smbclient //10.0.2.10/projetos -U 'ana%SENHA'   -c 'put /tmp/teste.txt ana.txt; ls'   # devs escrevem
smbclient //10.0.2.10/projetos -U 'carla%SENHA' -c 'ls; put /tmp/teste.txt carla.txt' # diretoria: le, nao escreve
smbclient //10.0.2.10/projetos -U 'bruno%SENHA' -c 'ls'                               # mkt: acesso negado
head -c 70M /dev/zero > /tmp/grande.bin
smbclient //10.0.2.10/publico -U 'bruno%SENHA' -c 'put /tmp/grande.bin grande.bin'    # estoura a quota
```
Quotas: `sudo repquota -v -ug /compartilhado` (na `arquivos`).

## 4. Backup automatizado
Na `db`:
```bash
sudo /usr/local/bin/backup_banco.sh
sudo ssh -i /root/.ssh/id_backup bkp@10.0.2.10 'ls -lh /compartilhado/backups'
sudo crontab -l            # 0 2 * * * /usr/local/bin/backup_banco.sh
cat /var/log/backup_banco.log
```
Restauracao: ver `docs/SOP.md`.

## 5. Nginx
Na `web`:
```bash
curl -sk -o /dev/null -w "%{http_code}\n" https://127.0.0.1/      # 200
curl -sI http://127.0.0.1/ | head -n 1                              # 301 (redireciona para HTTPS)
curl -sk https://127.0.0.1/naoexiste                                # pagina 404 personalizada
for i in $(seq 1 30); do curl -sk -o /dev/null -w "%{http_code} " https://127.0.0.1/; done; echo   # aparecem 429
```

## 6. Rede, DNS e DHCP
No `fw`:
```bash
ping -c 2 10.0.1.10; ping -c 2 10.0.2.10; ping -c 2 10.0.3.10
dig @10.0.1.1 web.empresa.local +short       # 10.0.1.10
dig @10.0.1.1 -x 10.0.3.10 +short            # db.empresa.local.
```
