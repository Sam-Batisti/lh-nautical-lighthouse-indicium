-- Questão 4 | Análise de clientes
-- Tarefas 1 e 2: cálculo do ticket médio, diversidade de categorias e Top 10

WITH pedidos AS (
    SELECT
        customer_id,
        COUNT(id) AS frequencia,
        SUM(total) AS faturamento_total
    FROM orders
    GROUP BY customer_id
),
categorias AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.category_id) AS diversidade_categorias
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN product_variants pv ON pv.id = oi.product_variant_id
    JOIN products p ON p.id = pv.product_id
    GROUP BY o.customer_id
),
clientes_elite AS (
    SELECT
        ped.customer_id,
        ped.faturamento_total,
        ped.frequencia,
        ped.faturamento_total / ped.frequencia AS ticket_medio,
        cat.diversidade_categorias
    FROM pedidos ped
    JOIN categorias cat ON cat.customer_id = ped.customer_id
    WHERE cat.diversidade_categorias >= 13
)
SELECT
    customer_id,
    ROUND(faturamento_total, 2) AS faturamento_total,
    frequencia,
    ROUND(ticket_medio, 2) AS ticket_medio,
    diversidade_categorias
FROM clientes_elite
ORDER BY ticket_medio DESC, customer_id ASC
LIMIT 10;


-- Tarefa 3: categoria com maior quantidade de itens comprados
-- considerando somente os 10 clientes selecionados acima

WITH pedidos AS (
    SELECT
        customer_id,
        COUNT(id) AS frequencia,
        SUM(total) AS faturamento_total
    FROM orders
    GROUP BY customer_id
),
categorias AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.category_id) AS diversidade_categorias
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN product_variants pv ON pv.id = oi.product_variant_id
    JOIN products p ON p.id = pv.product_id
    GROUP BY o.customer_id
),
top10 AS (
    SELECT
        ped.customer_id,
        ped.faturamento_total / ped.frequencia AS ticket_medio
    FROM pedidos ped
    JOIN categorias cat ON cat.customer_id = ped.customer_id
    WHERE cat.diversidade_categorias >= 13
    ORDER BY ticket_medio DESC, ped.customer_id ASC
    LIMIT 10
)
SELECT
    c.name AS categoria,
    SUM(oi.quantity) AS total_itens_comprados
FROM top10 t
JOIN orders o ON o.customer_id = t.customer_id
JOIN order_items oi ON oi.order_id = o.id
JOIN product_variants pv ON pv.id = oi.product_variant_id
JOIN products p ON p.id = pv.product_id
JOIN categories c ON c.id = p.category_id
GROUP BY c.name
ORDER BY total_itens_comprados DESC
LIMIT 1;