-- Analise complementar (nao e uma questao numerada do desafio) - Pagina 2 do dashboard (Clientes)
-- Definicao de "cliente elite" veio do proprio enunciado da Questao 4:
-- diversidade de categorias compradas >= 13. Usei exatamente esse corte,
-- sem reinterpretar.
--
-- Observacao: o catalogo tem so 14 categorias no total, entao >= 13
-- sozinho classifica 1919 dos 2000 clientes (96%) como elite -- corte
-- pouco seletivo se usado isolado. Por isso, no grafico "categoria mais
-- consumida pelos clientes elite" (view 3), restringi aos Top 10 clientes
-- elite ordenados por ticket medio, em vez de somar os 1919. Mantem a
-- definicao literal da Questao 4 (elite = diversidade >= 13) e ainda
-- assim produz um grafico que segmenta algo de fato.
--
-- Mesmo filtro de status usado nas Questoes 6, 7 e na view 08
-- (paid/confirmed = pedido concluido de fato).
--
-- nome_cliente = COALESCE(trade_name, legal_name): trade_name so existe
-- pra clientes PJ (782 de 2000) e ainda assim nulo em boa parte; legal_name
-- e preenchido em 100% das linhas, entao serve de fallback seguro.

-- ---------- View 1: ticket medio por cliente ----------
CREATE OR REPLACE VIEW ticket_medio_por_cliente AS
SELECT
    c.id AS customer_id,
    COALESCE(c.trade_name, c.legal_name) AS nome_cliente,
    COUNT(o.id)                          AS qtd_pedidos,
    ROUND(AVG(o.total), 2)               AS ticket_medio
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.status IN ('paid', 'confirmed')
GROUP BY c.id, COALESCE(c.trade_name, c.legal_name);

SELECT * FROM ticket_medio_por_cliente ORDER BY ticket_medio DESC LIMIT 10;

-- ---------- View 2: diversidade de categorias por cliente ----------
CREATE OR REPLACE VIEW diversidade_categorias_por_cliente AS
WITH pedidos_validos AS (
    SELECT id, customer_id FROM orders WHERE status IN ('paid', 'confirmed')
)
SELECT
    c.id AS customer_id,
    COALESCE(c.trade_name, c.legal_name) AS nome_cliente,
    COUNT(DISTINCT p.category_id)        AS qtd_categorias,
    CASE WHEN COUNT(DISTINCT p.category_id) >= 13 THEN 1 ELSE 0 END AS cliente_elite
FROM order_items oi
JOIN product_variants pv ON pv.id = oi.product_variant_id
JOIN products p          ON p.id = pv.product_id
JOIN pedidos_validos pd  ON pd.id = oi.order_id
JOIN customers c         ON c.id = pd.customer_id
GROUP BY c.id, COALESCE(c.trade_name, c.legal_name);

SELECT * FROM diversidade_categorias_por_cliente ORDER BY qtd_categorias DESC LIMIT 10;

-- ---------- View 3: consumo por categoria entre o Top 10 clientes elite ----------
-- Elite = diversidade >= 13 (Questao 4). Dentro da elite, ranqueado por
-- ticket medio e pego so o Top 10 -- grafico segmenta de fato, sem
-- contradizer a definicao literal de elite do enunciado.
-- Grao = categoria. Power BI so precisa ordenar por qtd_itens desc.
CREATE OR REPLACE VIEW consumo_categorias_clientes_elite AS
WITH elite_top10 AS (
    SELECT d.customer_id
    FROM diversidade_categorias_por_cliente d
    JOIN ticket_medio_por_cliente t ON t.customer_id = d.customer_id
    WHERE d.cliente_elite = 1
    ORDER BY t.ticket_medio DESC
    LIMIT 10
),
pedidos_validos AS (
    SELECT id, customer_id FROM orders WHERE status IN ('paid', 'confirmed')
)
SELECT
    cat.name         AS categoria,
    SUM(oi.quantity)  AS qtd_itens_comprados
FROM order_items oi
JOIN product_variants pv ON pv.id = oi.product_variant_id
JOIN products p          ON p.id = pv.product_id
JOIN categories cat      ON cat.id = p.category_id
JOIN pedidos_validos pd  ON pd.id = oi.order_id
JOIN elite_top10 e       ON e.customer_id = pd.customer_id
GROUP BY cat.name;

SELECT * FROM consumo_categorias_clientes_elite ORDER BY qtd_itens_comprados DESC;
