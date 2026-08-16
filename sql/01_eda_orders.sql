-- Questao 1.1 - EDA da tabela orders (SQL)
-- Premissa: sem tratamento/limpeza
-- Motor: DuckDB, direto no editor do DBeaver.


-- 1) Cria a tabela orders lendo o CSV bruto diretamente (DuckDB). 

CREATE OR REPLACE TABLE orders AS
SELECT *
FROM read_csv_auto('C:/Users/lenovo/OneDrive/Desktop/Lighthouse/1-lh_nautical_csv/orders.csv');

-- 2) Consulta da Questao 1.1
SELECT
    COUNT(*)                    AS qtd_linhas,
    MIN(created_at)             AS data_min,
    MAX(created_at)             AS data_max,
    MIN(total)                  AS total_min,
    MAX(total)                  AS total_max,
    ROUND(AVG(total), 2)        AS total_medio
FROM orders;

