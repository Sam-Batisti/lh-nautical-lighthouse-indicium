# Questão 4 — Análise de Clientes (Fidelidade)

## Questão 4.1 — SQL

Arquivo: `sql/04_clientes_fieis.sql`. Motor: PostgreSQL (banco `lh_nautical`, DBeaver).

**Lógica:** Faturamento Total e Frequência vêm direto de `orders` (uma linha por pedido). Diversidade de Categorias precisa do caminho `order_items → product_variants → products → category_id`. Calculei os dois em CTEs separadas e só depois juntei — se eu tivesse feito um único `JOIN` de `orders` direto com `order_items`, o `total` e a contagem de pedidos teriam sido duplicados pra cada item do pedido (um pedido com 5 itens contaria o faturamento 5 vezes). Separar evita esse erro de dupla contagem.

**Resultado — Top 10 clientes fiéis** (Ticket Médio mais alto entre quem comprou de 13+ categorias):

| customer_id | Faturamento Total | Frequência | Ticket Médio | Diversidade de Categorias |
|---|---|---|---|---|
| 22 | 1.087.838,44 | 26 | 41.839,94 | 14 |
| 1477 | 916.262,58 | 22 | 41.648,30 | 14 |
| 929 | 1.082.775,89 | 26 | 41.645,23 | 14 |
| 1116 | 655.737,20 | 16 | 40.983,58 | 14 |
| 1691 | 815.471,30 | 20 | 40.773,56 | 14 |
| 774 | 726.127,99 | 18 | 40.340,44 | 14 |
| 1470 | 1.040.553,09 | 26 | 40.021,27 | 14 |
| 1599 | 997.616,46 | 25 | 39.904,66 | 14 |
| 965 | 677.297,78 | 17 | 39.841,05 | 14 |
| 1722 | 1.146.455,22 | 29 | 39.532,94 | 14 |

**Observação:** a loja tem só 14 categorias no total (`categories`, Questão 2) — e todos os 10 clientes fiéis compraram das 14. Ou seja, o "cliente de elite" da LH Nautical não é só quem gasta muito por transação: é quem literalmente já passou por toda a loja.

## Tarefa 3 — Categoria mais comprada pelos 10 clientes fiéis

Mesmo arquivo `sql/04_clientes_fieis.sql`, segunda query (reaproveita a lógica do Top 10 numa CTE e soma `quantity` por categoria, olhando só os pedidos desses 10 clientes).

**Resultado — ranking de categorias por quantidade total de itens:**

| Categoria | Total de Itens Comprados |
|---|---|
| **Hélices** | **492** |
| Coletes Salva-Vidas | 393 |
| Eletrônica Náutica | 392 |
| Âncoras | 387 |
| Iluminação | 333 |
| Manutenção | 330 |
| Segurança | 325 |
| Velas | 313 |
| Pintura Marítima | 307 |
| Acessórios de Convés | 305 |
| Motores | 279 |
| Pesca | 278 |
| Equipamentos | 255 |
| Cabos | 254 |

**Resposta:** a categoria que concentra a maior quantidade de itens comprados pelos 10 clientes fiéis é **Hélices**, com 492 unidades — à frente de Coletes Salva-Vidas (393) e Eletrônica Náutica (392). Para a diretoria: se a ideia é replicar o comportamento desse grupo de elite em outros segmentos, Hélices é o produto-âncora a reforçar em campanhas de cross-sell.

## Questão 4.2 — Explicação

**1. Como cheguei nas categorias mais vendidas (cadeia de chaves)?**
Nenhuma tabela liga item comprado direto a categoria — precisei atravessar 3 tabelas: `order_items.product_variant_id → product_variants.id` (acha o produto), `product_variants.product_id → products.id` (acha a categoria), `products.category_id → categories.id` (acha o nome da categoria). Com esse caminho fechado, agrupei por categoria e somei `quantity`.

**2. Que lógica usei pra filtrar diversidade mínima?**
Contei categorias distintas por cliente com `COUNT(DISTINCT category_id)`, percorrendo o mesmo caminho de chaves (`orders → order_items → product_variants → products`), agrupado por `customer_id`. O `DISTINCT` é o que garante contar cada categoria uma vez só, mesmo que o cliente tenha comprado dela em pedidos ou itens diferentes. Depois apliquei `WHERE diversidade_categorias >= 13` pra manter só quem bate o critério de elite.

**3. Como garanti que a contagem de itens refletisse só os Top 10?**
Montei uma CTE `top10` que roda a mesma lógica da Questão 4.1 (ticket médio + filtro de diversidade + `ORDER BY` + `LIMIT 10`) isolada, e depois fiz `JOIN` dela com `orders` por `customer_id`. Como é um `INNER JOIN`, só sobrevivem os pedidos de clientes que estão nessa CTE de 10 — qualquer pedido de outro cliente é descartado antes mesmo de chegar na soma de `quantity`. Isso evita ter que repetir o filtro de diversidade duas vezes ou arriscar inconsistência entre as duas contagens.
