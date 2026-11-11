-- Uso: sudo -u postgres psql -v app_senha='SENHA_DO_APP' -f init.sql
-- Privilegio minimo: appuser nao e superusuario e so le/insere em mensagens.
CREATE ROLE appuser LOGIN PASSWORD :'app_senha' NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE DATABASE appdb;
\c appdb
CREATE TABLE mensagens (id serial PRIMARY KEY, texto text NOT NULL, criado_em timestamptz DEFAULT now());
GRANT SELECT, INSERT ON mensagens TO appuser;
GRANT USAGE, SELECT ON SEQUENCE mensagens_id_seq TO appuser;
