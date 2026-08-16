-- Analise complementar (nao e uma questao numerada do desafio) - Rentabilidade
-- Motivo: o enunciado sugere "ranking de prejuizos por produto" e "clientes
-- com maior lucro acumulado" como visuais do dashboard, sem premissas
-- formais pra isso. Criei essas 3 views pra sustentar o Power BI com numero
-- validado e com definicao clara do que cada metrica representa de fato.
--
-- Nomenclatura: evitei os termos "prejuizo" e "lucro" sem qualificar,
-- porque nenhum dos dois e exato:
--   - "valor reembolsado" != prejuizo real (o item devolvido pode voltar
--     pro estoque e ser revendido; nao estou descontando isso)
--   - "margem estimada" != lucro (nao desconta imposto, frete, custo
--     operacional, so a diferenca entre preco de venda e custo cadastrado)
--
-- Arquitetura: essas views ficam persistidas no Postgres (nao consulta
-- solta) pra o Power BI consumir como se fossem tabela normal, mantendo a
-- camada de regra de negocio no banco em vez de espalhada em consulta
-- nativa dentro do relatorio.
--
-- Definicao de "valor reembolsado por devolucoes": soma de
-- unit_refund_amount * quantity em return_items, agrupado por produto. So
-- contei devolucoes com:
--   - returns.status = 'completed' (open/cancelled nao geraram reembolso de fato)
--   - return_items.action = 'refund' (troca/exchange nao devolve dinheiro,
--     confirmei que unit_refund_amount = 0 em 100% das linhas de troca)
-- Validei que SUM(unit_refund_amount * quantity) por return bate exatamente
-- com returns.total_refund_amount (diferenca so de arredondamento float).
--
-- Definicao de "margem estimada": product_variants ja tem sale_price e
-- cost_price por variante -- margem = sale_price - cost_price. Usei essa
-- coluna direto em vez de puxar custo de purchase_order_items, que varia
-- por fornecedor e por pedido de compra (informacao de custo mais instavel).
--
-- Definicao de "margem acumulada estimada por cliente": soma, por cliente,
-- de quantity * (sale_price - cost_price) de todos os itens comprados em
-- pedidos paid/confirmed (mesmo filtro de status usado nas Questoes 6 e 7,
-- por consistencia -- pedido cancelado/draft nao gerou margem real).

-- ---------- View 1: valor reembolsado por produto ----------
CREATE OR REPLACE VIEW valor_reembolsado_por_produto AS
WITH devolucoes_validas AS (
    SELECT ri.order_item_id, ri.quantity, ri.unit_refund_amount
    FROM return_items ri
    JOIN returns r ON r.id = ri.return_id
    WHERE r.status = 'completed' AND ri.action = 'refund'
)
SELECT
    p.name AS produto,
    ROUND(SUM(dv.unit_refund_amount * dv.quantity), 2) AS valor_reembolsado
FROM devolucoes_validas dv
JOIN order_items oi      ON oi.id = dv.order_item_id
JOIN product_variants pv ON pv.id = oi.product_variant_id
JOIN products p          ON p.id = pv.product_id
GROUP BY p.name;

SELECT * FROM valor_reembolsado_por_produto ORDER BY valor_reembolsado DESC LIMIT 10;

-- ---------- View 2: margem estimada por produto ----------
CREATE OR REPLACE VIEW margem_estimada_por_produto AS
SELECT
    p.name AS produto,
    ROUND(AVG(pv.sale_price - pv.cost_price), 2)                   AS margem_estimada_unit,
    ROUND(AVG((pv.sale_price - pv.cost_price) / pv.sale_price), 4) AS margem_estimada_pct
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
GROUP BY p.name;

SELECT * FROM margem_estimada_por_produto ORDER BY margem_estimada_pct ASC LIMIT 10;

-- ---------- View 3: margem acumulada estimada por cliente ----------
CREATE OR REPLACE VIEW margem_acumulada_por_cliente AS
WITH pedidos_validos AS (
    SELECT id, customer_id FROM orders WHERE status IN ('paid', 'confirmed')
)
SELECT
    p.customer_id,
    ROUND(SUM(oi.quantity * (pv.sale_price - pv.cost_price)), 2) AS margem_acumulada_estimada
FROM order_items oi
JOIN product_variants pv ON pv.id = oi.product_variant_id
JOIN pedidos_validos p   ON p.id = oi.order_id
GROUP BY p.customer_id;

SELECT * FROM margem_acumulada_por_cliente ORDER BY margem_acumulada_estimada DESC LIMIT 10;
