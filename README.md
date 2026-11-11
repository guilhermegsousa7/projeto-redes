# Projeto (Rede De Computadores) - Infraestrutura de Redes e Servidores Linux

Infraestrutura corporativa segmentada em tres zonas (DMZ, LAN e DB Zone), com firewall,
DNS/DHCP, servidor web com HTTPS, banco PostgreSQL, servidor de arquivos Samba com quotas
e backup automatizado. Laboratorio em VirtualBox com Ubuntu Server 26.04.1 LTS.

## Topologia

```
              [ Internet / Cliente externo ]
                           |
                  WAN (NAT) enp0s3
                    [ fw (Firewall) ]
          enp0s8 /        | enp0s9        \ enp0s10
   DMZ 10.0.1.0/24   LAN 10.0.2.0/24   DB Zone 10.0.3.0/24
     [ web ]          [ arquivos ]         [ db ]
```

| Maquina  | Funcao                         | IP                                   |
|----------|--------------------------------|--------------------------------------|
| fw       | Firewall, roteador, NAT, DNS, DHCP | 10.0.1.1 / 10.0.2.1 / 10.0.3.1 + WAN |
| web      | Nginx (HTTPS) + aplicacao FastAPI  | 10.0.1.10                        |
| arquivos | Samba + quotas + destino de backup | 10.0.2.10                        |
| db       | PostgreSQL 18                  | 10.0.3.10                            |

Dominio interno: `empresa.local` (DNS direto e reverso no `fw`).
DHCP somente na LAN (faixa 10.0.2.100 a 10.0.2.200, reserva estatica para `arquivos`).

## Matriz de firewall (implementada em `fw/nftables.conf`)

| Origem        | Destino             | Porta       | Acao      |
|---------------|---------------------|-------------|-----------|
| WAN           | Servidor web (DMZ)  | 80, 443/TCP | Permitir (DNAT) |
| Servidor web  | Banco (DB Zone)     | 5432/TCP    | Permitir  |
| DMZ / WAN     | DB Zone (demais)    | qualquer    | Bloquear, com log (`FW-DROP-DB`) |
| LAN (admin)   | Todas as zonas      | 22/TCP      | Permitir  |
| LAN           | Servidor de arquivos| 139, 445/TCP| Permitir (mesma sub-rede) |
| db            | arquivos            | 22/TCP      | Permitir (regra adicional, usada pelo backup) |

Politica padrao de INPUT e FORWARD: DROP.

## Estrutura do repositorio

```
fw/         nftables, dnsmasq (DNS+DHCP), roteamento, netplan do firewall
web/        netplan, Nginx (TLS, rate limit, erros), aplicacao FastAPI, servico systemd
db/         netplan, PostgreSQL (listen, pg_hba restrito, esquema), script de backup
arquivos/   netplan, Samba (smb.conf), volume ext4 com quotas, grupos e usuarios
docs/       SOP (restaurar backup, adicionar usuarios) e roteiro de testes
```

## Ordem de implantacao

1. Criar a VM modelo (Ubuntu Server) e clonar `fw`, `web`, `db`, `arquivos`; ligar as placas
   em redes internas `dmz`, `lan` e `dbzone` (fw: adaptador 1 NAT, 2 dmz, 3 lan, 4 dbzone).
2. Aplicar os `netplan-*.yaml` e ativar o roteamento (`fw/99-forward.conf`).
3. Firewall (`fw/nftables.conf`) e DNS/DHCP (`fw/dnsmasq-projeto.conf`).
4. PostgreSQL (`db/`), depois a aplicacao e o Nginx (`web/`).
5. Samba, volume com quotas e usuarios (`arquivos/`).
6. Backup (`db/backup_banco.sh`) com chave SSH e cron.

## Decisoes e observacoes

- A faixa NAT do VirtualBox no `fw` foi alterada para 192.168.100.0/24, porque a faixa padrao
  (10.0.2.0/24) conflita com a LAN do projeto.
- O backup trafega por SSH com chave (porta 22), e nao por Samba, para nao abrir 445 entre
  a DB Zone e a LAN. Isso exigiu uma regra adicional no firewall, indicada acima.
- As quotas ficam em um volume ext4 dedicado (arquivo de disco de 4 GB montado em
  `/compartilhado` com `usrquota,grpquota`), sem alterar o disco do sistema.
- O `appuser` do banco nao e superusuario e so tem SELECT/INSERT na tabela `mensagens`.
- Certificado TLS autoassinado (laboratorio); TLS 1.2 e 1.3.
- Senhas de laboratorio nao sao versionadas: use `web/app.env.example` e a variavel
  `SENHA_SAMBA`. As senhas usadas na demonstracao constam do relatorio entregue.
