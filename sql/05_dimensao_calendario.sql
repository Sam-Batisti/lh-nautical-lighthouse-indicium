-- Tarefa 1: dimensao de datas --
WITH calendario AS (
    SELECT generate_series(
        (SELECT MIN(created_at::date) FROM orders),
        (SELECT MAX(created_at::date) FROM orders),
        interval '1 day'
    )::date AS dia
),
-- vendas diarias,lojas fisicas (channel = 'pos'): soma de "total" por dia
vendas_pos AS (
    SELECT created_at::date AS dia, SUM(total) AS venda_dia
    FROM orders
    WHERE channel = 'pos'
    GROUP BY created_at::date
)
-- Tarefa 2: Cruzar o calendario com as vendas (LEFT JOIN) -- 
-- Dia sem venda fica sem correspondencia e o COALESCE transforma isso em 0.--
SELECT
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
ORDER BY media_venda_diaria ASC;
-- RESULTADO:
-- Quinta-feira   | 157154.32   <- pior dia --

