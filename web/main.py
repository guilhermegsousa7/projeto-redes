# /opt/app/main.py - aplicacao FastAPI (atras do Nginx), grava no PostgreSQL da DB Zone
import os
import html
import psycopg2
from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse, RedirectResponse

app = FastAPI()

def conectar():
    return psycopg2.connect(host="10.0.3.10", dbname="appdb", user="appuser",
                            password=os.environ["DB_PASS"], connect_timeout=3)

@app.get("/", response_class=HTMLResponse)
def inicio():
    con = conectar()
    cur = con.cursor()
    cur.execute("SELECT texto, criado_em FROM mensagens ORDER BY id DESC LIMIT 10")
    linhas = cur.fetchall()
    con.close()
    itens = "".join(f"<li>{html.escape(t)} <small>({c:%d/%m/%Y %H:%M:%S})</small></li>" for t, c in linhas)
    return f"""<html><body><h1>Projeto Redes - Web na DMZ</h1>
    <form method="post" action="/add"><input name="texto" required>
    <button>Enviar</button></form><ul>{itens}</ul></body></html>"""

@app.post("/add")
def adicionar(texto: str = Form(...)):
    con = conectar()
    cur = con.cursor()
    cur.execute("INSERT INTO mensagens (texto) VALUES (%s)", (texto,))
    con.commit()
    con.close()
    return RedirectResponse("/", status_code=303)

@app.get("/health")
def saude():
    con = conectar()
    con.close()
    return {"status": "ok", "banco": "conectado"}
