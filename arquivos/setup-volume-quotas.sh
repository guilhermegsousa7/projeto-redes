#!/bin/bash
# Volume ext4 dedicado com quotas, grupos, usuarios, pastas e ACLs.
# Uso: SENHA_SAMBA='defina-uma-senha' sudo -E bash setup-volume-quotas.sh
set -euo pipefail
: "${SENHA_SAMBA:?defina SENHA_SAMBA no ambiente}"

apt install -y acl quota samba
mkdir -p /compartilhado
truncate -s 4G /srv/compartilhado.img
mkfs.ext4 -q -F /srv/compartilhado.img
tune2fs -O quota -Q usrquota,grpquota /srv/compartilhado.img
echo '/srv/compartilhado.img /compartilhado ext4 defaults,loop,usrquota,grpquota 0 0' >> /etc/fstab
systemctl daemon-reload
mount /compartilhado

for g in todos devs mkt diretoria backup_mgr; do groupadd -f "$g"; done
useradd -m -s /usr/sbin/nologin -G todos,devs ana
useradd -m -s /usr/sbin/nologin -G todos,mkt bruno
useradd -m -s /usr/sbin/nologin -G todos,diretoria carla
useradd -m -s /bin/bash -G todos,backup_mgr bkp
for u in ana bruno carla bkp; do printf '%s\n%s\n' "$SENHA_SAMBA" "$SENHA_SAMBA" | smbpasswd -s -a "$u"; done

mkdir -p /compartilhado/publico /compartilhado/projetos /compartilhado/backups
chown root:todos /compartilhado/publico
chown root:devs /compartilhado/projetos
chown root:backup_mgr /compartilhado/backups
chmod 2770 /compartilhado/publico /compartilhado/projetos /compartilhado/backups
setfacl -m g:diretoria:rx /compartilhado/projetos /compartilhado/backups
setfacl -d -m g:diretoria:rx /compartilhado/projetos /compartilhado/backups

# Quotas em KB: usuario (soft hard) e grupo (soft hard)
setquota -u ana 204800 256000 0 0 /compartilhado
setquota -u bruno 51200 61440 0 0 /compartilhado
setquota -u carla 204800 256000 0 0 /compartilhado
setquota -u bkp 1048576 1228800 0 0 /compartilhado
setquota -g devs 1048576 1228800 0 0 /compartilhado
setquota -g mkt 524288 614400 0 0 /compartilhado
setquota -g diretoria 1048576 1228800 0 0 /compartilhado
setquota -g backup_mgr 2097152 2457600 0 0 /compartilhado
