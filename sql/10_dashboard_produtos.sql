-- Analise complementar (nao e uma questao numerada do desafio) - Pagina 3 do dashboard (Produtos e Rentabilidade)
--
-- Achado de qualidade de dado: encontrei produtos com nome duplicado/placeholder
-- no catalogo -- por exemplo "asdf" aparece em dois product_id diferentes (187 e
-- 342, categorias diferentes), e "TBD" tambem existe como nome de produto (id 66).
-- As views da view 08 (margem_estimada_por_produto, valor_reembolsado_por_produto)
-- agrupam por p.name, entao esses dois produtos "asdf" ficam somados numa linha
-- so -- pra Q4 aquilo nao chegou a distorcer o resultado, mas pra essas analises
-- por produto do dashboard, isso juntaria dois produtos reais e diferentes numa
-- unica barra, inflando o numero sem sentido de negocio (cheguei a ver "asdf"
-- aparecer em #1 no ranking de faturamento, R$ 8,28 Mi).
--
-- Decisao: nao excluir "asdf"/"TBD" do catalogo -- sao dados brutos e nao ha
-- premissa que justifique remove-los. Em vez disso, as 3 views abaixo sempre
-- agrupam por product_id (nunca por nome), pra nunca fundir produtos diferentes
-- so por coincidencia de nome. Pra leitura no Power BI, criei uma coluna de
-- exibicao "nome_produto" no formato "<nome> | ID <id>", que deixa visivel
-- quando dois produtos compartilham nome em vez de esconder o problema.
--
-- Mesmo filtro de status usado nas Questoes 6, 7 e nas views 08/09
-- (paid/confirmed = pedido concluido de fato).

-- ---------- View 1: ranking de valor reembolsado por produto (por id) ----------
CREATE OR REPLACE VIEW ranking_valor_reembolsado_produto AS
WITH devolucoes_validas AS (
    SELECT ri.order_item_id, ri.quantity, ri.unit_refund_amount
    FROM return_items ri
    JOIN returns r ON r.id = ri.return_id
    WHERE r.status = 'completed' AND ri.action = 'refund'
)
SELECT
    p.id                              AS product_id,
    p.name || ' | ID ' || p.id        AS nome_produto,
    ROUND(SUM(dv.unit_refund_amount * dv.quantity), 2) AS valor_reembolsado
FROM devolucoes_validas dv
JOIN order_items oi      ON oi.id = dv.order_item_id
JOIN product_variants pv ON pv.id = oi.product_variant_id
JOIN products p          ON p.id = pv.product_id
GROUP BY p.id, p.name;

SELECT * FROM ranking_valor_reembolsado_produto ORDER BY valor_reembolsado DESC LIMIT 10;

-- ---------- View 2: margem estimada media por categoria ----------
-- Categorias nao tem nome duplicado no catalogo (conferido: 14/14 nomes unicos),
-- mas agrupo por category_id mesmo assim, pra manter o mesmo principio em toda
-- a pagina 3.
CREATE OR REPLACE VIEW margem_estimada_por_categoria AS
SELECT
    cat.id                              AS category_id,
    cat.name                            AS categoria,
    ROUND(AVG(pv.sale_price - pv.cost_price), 2)                   AS margem_estimada_unit,
    ROUND(AVG((pv.sale_price - pv.cost_price) / pv.sale_price), 4) AS margem_estimada_pct
FROM product_variants pv
JOIN products p     ON p.id = pv.product_id
JOIN categories cat ON cat.id = p.category_id
GROUP BY cat.id, cat.name;

SELECT * FROM margem_estimada_por_categoria ORDER BY margem_estimada_pct ASC;

-- ---------- View 3: faturamento e margem por produto (por id) ----------
-- Serve tanto pro grafico de dispersao (faturamento x margem) quanto pro
-- ranking "Top Produtos por Faturamento" -- uma view so, mesma chave (product_id).
CREATE OR REPLACE VIEW faturamento_margem_por_produto AS
WITH faturamento AS (
    SELECT
        p.id   AS product_id,
        p.name AS produto,
        SUM(oi.line_total) AS faturamento_total
    FROM order_items oi
    JOIN product_variants pv ON pv.id = oi.product_variant_id
    JOIN products p          ON p.id = pv.product_id
    JOIN orders o             ON o.id = oi.order_id
    WHERE o.status IN ('paid', 'confirmed')
    GROUP BY p.id, p.name
),
margem AS (
    SELECT
        p.id AS product_id,
        ROUND(AVG(pv.sale_price - pv.cost_price), 2)                   AS margem_estimada_unit,
        ROUND(AVG((pv.sale_price - pv.cost_price) / pv.sale_price), 4) AS margem_estimada_pct
    FROM product_variants pv
    JOIN products p ON p.id = pv.product_id
    GROUP BY p.id
)
SELECT
    f.product_id,
    f.produto || ' | ID ' || f.product_id AS nome_produto,
    f.faturamento_total,
    m.margem_estimada_unit,
    m.margem_estimada_pct
FROM faturamento f
JOIN margem m ON m.product_id = f.product_id;

SELECT * FROM faturamento_margem_por_produto ORDER BY faturamento_total DESC LIMIT 10;
