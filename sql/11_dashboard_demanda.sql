-- Analise complementar (nao e uma questao numerada do desafio) - Pagina 4 do dashboard (Demanda e Operacao)
--
-- As duas views abaixo empacotam, como view, a MESMA logica ja usada e
-- validada nas Questoes 6 (sql/05_dimensao_calendario.sql) e no script
-- scripts/06_previsao_demanda.py. Nao mudei nenhuma regra de negocio --
-- so tornei o resultado consultavel direto pelo Power BI (as questoes
-- originais eram consultas soltas / script Python, nao views).

-- ---------- View 1: vendas medias por dia da semana (Questao 6) ----------
-- Mesma logica exata do sql/05_dimensao_calendario.sql: canal POS (lojas
-- fisicas), calendario completo cruzado via LEFT JOIN + COALESCE pra 0,
-- entao dia sem venda entra na media como zero (nao e ignorado).
CREATE OR REPLACE VIEW vendas_dia_semana AS
WITH calendario AS (
    SELECT generate_series(
        (SELECT MIN(created_at::date) FROM orders),
        (SELECT MAX(created_at::date) FROM orders),
        interval '1 day'
    )::date AS dia
),
vendas_pos AS (
    SELECT created_at::date AS dia, SUM(total) AS venda_dia
    FROM orders
    WHERE channel = 'pos'
    GROUP BY created_at::date
)
SELECT
    EXTRACT(DOW FROM cal.dia)::int AS dia_semana_num,
    CASE EXTRACT(DOW FROM cal.dia)::int
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
    END AS dia_semana,
    ROUND(AVG(COALESCE(vp.venda_dia, 0)), 2) AS media_venda_diaria
FROM calendario cal
LEFT JOIN vendas_pos vp ON vp.dia = cal.dia
GROUP BY EXTRACT(DOW FROM cal.dia)
ORDER BY dia_semana_num;

SELECT * FROM vendas_dia_semana ORDER BY media_venda_diaria ASC;

-- ---------- View 2: previsao x real -- Bussola de Bordo 702 (Questao 6 / script 06) ----------
-- Mesmas premissas do script: produto identificado pelo nome (cobre os
-- dois cadastros duplicados encontrados), status paid/confirmed, serie
-- mensal com zero-fill, media movel de 3 meses usando so dados reais
-- anteriores a cada previsao (ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING).
-- qtd_prevista e erro_absoluto so vem preenchidos no periodo de teste
-- oficial (jan-mar/2026) -- meses antes disso nao foram avaliados no
-- script original, entao nao invento um "previsto" pra eles aqui tambem.
-- Validado em SQL (DuckDB) contra a saida do script: bate exatamente
-- (jan 32.67/76, fev 49.67/55, mar 50.00/51, MAE 16.55).
CREATE OR REPLACE VIEW previsao_bussola_702 AS
WITH produto_ids AS (
    SELECT id FROM products WHERE name = 'Bússola de Bordo 702'
),
variante_ids AS (
    SELECT id FROM product_variants WHERE product_id IN (SELECT id FROM produto_ids)
),
pedidos_validos AS (
    SELECT id, created_at FROM orders WHERE status IN ('paid', 'confirmed')
),
calendario_mensal AS (
    SELECT generate_series(
        '2020-01-01'::date, '2026-03-01'::date, interval '1 month'
    )::date AS mes_ini
),
vendas_mes AS (
    SELECT date_trunc('month', o.created_at)::date AS mes_ini, SUM(oi.quantity) AS qtd_vendida
    FROM order_items oi
    JOIN pedidos_validos o ON o.id = oi.order_id
    WHERE oi.product_variant_id IN (SELECT id FROM variante_ids)
    GROUP BY date_trunc('month', o.created_at)
),
serie AS (
    SELECT
        cal.mes_ini,
        COALESCE(vm.qtd_vendida, 0) AS qtd_real
    FROM calendario_mensal cal
    LEFT JOIN vendas_mes vm ON vm.mes_ini = cal.mes_ini
),
com_previsto AS (
    SELECT
        mes_ini,
        qtd_real,
        ROUND(AVG(qtd_real) OVER (
            ORDER BY mes_ini
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ), 2) AS qtd_prevista
    FROM serie
)
SELECT
    to_char(mes_ini, 'YYYY-MM')                                            AS mes,
    mes_ini,
    qtd_real,
    CASE WHEN mes_ini >= '2026-01-01' THEN qtd_prevista ELSE NULL END      AS qtd_prevista,
    CASE WHEN mes_ini >= '2026-01-01' THEN ROUND(ABS(qtd_real - qtd_prevista), 2) ELSE NULL END AS erro_absoluto
FROM com_previsto
ORDER BY mes_ini;

SELECT * FROM previsao_bussola_702 WHERE mes_ini >= '2026-01-01';
