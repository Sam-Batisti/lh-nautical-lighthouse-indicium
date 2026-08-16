# Questão 2 — Geração de schema (Python puro → PostgreSQL)

Arquivo: `scripts/02_generate_schema.py`. Saída: `sql/schema.sql`.

## Como funciona

Só biblioteca padrão do Python 3 (`csv`, `datetime`, `pathlib`, `argparse`), sem pandas. Para cada CSV da pasta:

1. Lê o cabeçalho e percorre **todas** as linhas em streaming (uma por vez, sem carregar o arquivo inteiro na memória).
2. Para cada coluna, classifica cada valor não-vazio numa categoria (`int`, `float`, `bool`, `timestamp`, `date`, `text`) e no final escolhe o tipo PostgreSQL mais específico que serve para **todos** os valores observados.
3. Coluna com pelo menos um valor vazio no CSV vira `NULL`able; sem nenhum vazio, vira `NOT NULL`.
4. Coluna chamada `id` vira `PRIMARY KEY`.
5. Escreve um `CREATE TABLE` por CSV (com `DROP TABLE IF EXISTS` na frente, pra poder rodar de novo sem erro) em um único `schema.sql`.

## Como rodar

```
python scripts\02_generate_schema.py --csv-dir "C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv" --out "C:\Users\lenovo\OneDrive\Desktop\Lighthouse\lh_nautical_challenge\sql\schema.sql"
```

(os dois caminhos acima já são o padrão do script — dá pra rodar só `python scripts\02_generate_schema.py`, sem argumentos.)

## Decisões de modelagem (e por quê)

Rodei o script contra os 24 CSVs reais e ele achou três casos que quebrariam ou corromperiam dados se eu tivesse ido no caminho "óbvio" (tudo que parece número vira INTEGER/BIGINT):

**1. `customers.tax_id` (CPF/CNPJ) — virou `TEXT`, não `BIGINT`.** 223 dos 2.000 registros (11%) têm zero à esquerda (ex: `00429721404`). Guardar como número perde esse zero permanentemente. O script detecta valor numérico com zero à esquerda (e mais de um dígito) e classifica como identificador, não quantidade — então a coluna cai pra `TEXT` automaticamente.

**2. `fiscal_invoices.nfe_access_key` — virou `TEXT`, não `BIGINT`.** A chave de acesso da NF-e tem 44 dígitos; o `BIGINT` do PostgreSQL só aguenta até 19 (~9,2 × 10¹⁸). Se eu tivesse forçado número, a inserção quebraria por overflow. O script rejeita valores maiores que o limite do `BIGINT`, e como parte das chaves também começa com zero, a coluna inteira cai pra `TEXT` — o resultado certo pra um identificador que nunca vai ser somado ou comparado numericamente.

**3. `stock_levels.reorder_point` — virou `TEXT` por falta de dado, não por decisão.** Os 6.054 registros da coluna estão 100% vazios no CSV. Sem nenhum valor pra observar, o script não tem base pra inferir o tipo real (provavelmente seria `INTEGER`) e cai no padrão seguro `TEXT`. Registro isso como limitação conhecida, não como bug: qualquer inferência automática de schema é só tão boa quanto os dados que ela consegue observar.

**Regra geral aplicada:** `suppliers.phone` teve o mesmo tratamento do `tax_id` (zero à esquerda → `TEXT`), enquanto `employees.cpf` ficou `BIGINT` mesmo — conferi os 15 registros e nenhum tem zero à esquerda, então não é o mesmo problema.

## Observação sobre o próximo passo

Esse schema define os tipos de cada tabela isoladamente, mas ainda não declara `FOREIGN KEY` entre elas (ex: `orders.customer_id → customers.id`). Não coloquei isso aqui porque a tarefa pede especificamente "detectar as colunas... e criar uma instrução de criação de cada tabela" — sem mencionar relacionamentos. Se a próxima etapa pedir integridade referencial, é um passo natural de evolução deste mesmo script.
