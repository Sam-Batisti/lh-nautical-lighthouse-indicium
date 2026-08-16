# Questão 3 — Carregamento no PostgreSQL

Arquivo: `scripts/03_load_data.py`.

## Como funciona

1. Conecta no PostgreSQL local (`psycopg2`).
2. Roda o `sql/schema.sql` (Questão 2) pra (re)criar as 24 tabelas do zero.
3. Para cada CSV, usa o comando `COPY ... FROM STDIN` do próprio PostgreSQL pra carregar o arquivo inteiro direto na tabela de mesmo nome — é a forma nativa e mais rápida do Postgres importar CSV, e carrega o valor exatamente como está no arquivo (campo vazio vira `NULL`, sem remover nada nem mexer em caractere especial).

## Como rodar

1. Abre o script e troca `DB_PASSWORD` pela senha criada na instalação do PostgreSQL.
2. No terminal: `python scripts\03_load_data.py`

Ele imprime a contagem de linhas carregada por tabela — dá pra conferir na hora se bateu com o total de linhas do CSV original.
