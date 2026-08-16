# Questão 1 — EDA da tabela `orders`

*Metodologia: leitura da tabela `orders.csv` sem qualquer limpeza ou tratamento, conforme solicitado. Para os calculos abaixo usei Python (`scripts/01_eda_orders.py`) e conferi em SQL puro contra um banco DuckDB (`sql/01_eda_orders.sql`, no DBeaver).

## Parte 1 — Visão geral `orders`

| Métrica | Valor |
|---|---|
| Quantidade total de linhas | 48.998 |
| Quantidade total de colunas | 13 |
| Data mínima (`created_at`) | 2020-01-01 |
| Data máxima (`created_at`) | 2026-12-31 |

Colunas: `id, order_number, channel, customer_id, salesperson_id, location_id, status, subtotal, discount_amount, total, placed_at, created_at, updated_at`.

## Parte 2 — Análise numérica da coluna `total`

| Métrica | Valor (R$) |
|---|---|
| Mínimo | 32,62 |
| Máximo | 127.262,02 |
| Médio | 28.704,99 |

*(Mediana 25.917,84 e desvio padrão 19.425,64 calculados como apoio à interpretação abaixo.)*

## Parte 3 / Questão 1.3 — Interpretação

**Resposta direta ao Sr. Almir: os dados dão uma base útil, mas ainda não são confiáveis o suficiente para decisões sem tratamento prévio e sem cruzar `orders` com outras tabelas.** Seguem 4 pontos de análise pra essa conclusão:

**1. Datas futuras em `created_at`.** O intervalo vai até 31/12/2026, mas a data de referência desta análise é 11/08/2026 — ou seja, **4.322 pedidos (8,8% da base) têm data de criação no futuro**. Isso não é sazonalidade nem erro de fuso: é um sinal de erro de geração/carga dos dados (provável timestamp sintético), e qualquer relatório de vendas por período vai distorcer enquanto isso não for investigado.

**2. Outliers em `total` são prováveis, mas não claramente erros.** Pela regra clássica do IQR (1,5×), 452 pedidos (0,92%) ficam acima de R$ 82.597,85. Como a LH Nautical vende itens de alto valor (embarcações, motores), pedidos de R$ 100 mil+ podem ser legítimos, não acho que devam ser tratados como erro por padrão, mas merecem checagem pontual (contra `order_items`, por exemplo) antes de entrarem em qualquer análise de ticket médio. Não há valores negativos ou zerados em `total`, o que é um bom sinal.

**3. Qualidade geral: sem nulos/duplicatas graves, mas com uma coluna a investigar.** Não há linhas duplicadas nem `id` duplicado. A única coluna com nulos relevantes é `salesperson_id` (49,25%), o que faz sentido em parte. Pedidos do canal `ecommerce` naturalmente não têm vendedor, mas mesmo dentro do `ecommerce` há uma mescla de nulos e preenchidos, o que sugere inconsistência de captura e não uma regra de negócio limpa. Também vale registrar que a tabela mistura pedidos com `status` = `paid`, `confirmed`, `cancelled` e `draft` todos com `total` preenchido, então entendo quequalquer leitura de "faturamento" precisa necessariamente filtrar por status, senão superestima receita.

**4. `orders` sozinha não sustenta decisão de negócio — precisa de relacionamento com outras tabelas.** A tabela responde "quanto" mas não confirma "se de fato aconteceu": não dá pra saber, só com `orders`, se o `total` bate com a soma dos itens do pedido (precisa de `order_items`), se todo pedido `paid` tem um pagamento correspondente (precisa de `payments`), ou se os 49,25% de `salesperson_id` nulo têm explicação de negócio (precisa de `employees`/`channel`). Sem esse cruzamento, qualquer número tirado só de `orders` é uma estimativa, não um fato validado.

**Conclusão:** a tabela `orders` está pronta para *exploração*, mas não para *decisão* isolada. Antes de virar relatório pra diretoria, precisa de: (1) tratamento prévio — investigar/corrigir as datas futuras e decidir como tratar `status` ao somar `total`; e (2) relacionamento com `order_items`, `payments` e `customers` para validar que os valores registrados batem com a operação real.

---

## Questão 1.1 — SQL

Ferramenta: DBeaver conectado a um banco DuckDB (`db/lh_nautical.duckdb`). Arquivo: `sql/01_eda_orders.sql`. A tabela `orders` é materializada lendo o CSV bruto direto (`read_csv_auto`, nativo do DuckDB), e a query roda em cima dela:

```sql
CREATE OR REPLACE TABLE orders AS
SELECT *
FROM read_csv_auto('C:/Users/lenovo/OneDrive/Desktop/Lighthouse/1-lh_nautical_csv/orders.csv');

SELECT
    COUNT(*)                    AS qtd_linhas,
    MIN(created_at)             AS data_min,
    MAX(created_at)             AS data_max,
    MIN(total)                  AS total_min,
    MAX(total)                  AS total_max,
    ROUND(AVG(total), 2)        AS total_medio
FROM orders;
```

**Resultado:**

| qtd_linhas | data_min | data_max | total_min | total_max | total_medio |
|---|---|---|---|---|---|
| 48998 | 2020-01-01 01:19:28 | 2026-12-31 23:43:09 | 32.62 | 127262.02 | 28704.99 |

