# Questão 1 — EDA da tabela `orders` (saída do script Python)

## Parte 1 — Visão geral

- Quantidade total de linhas: **48.998**
- Quantidade total de colunas: **13**
- Colunas: id, order_number, channel, customer_id, salesperson_id, location_id, status, subtotal, discount_amount, total, placed_at, created_at, updated_at
- `created_at` — nulos brutos: 0 | não-parseáveis como data: 0
- Intervalo de datas (created_at): **2020-01-01 01:19:28** até **2026-12-31 23:43:09**

## Parte 2 — Análise numérica da coluna `total`

- Nulos em `total`: 0 (0.00%)
- Valor mínimo: **32.62**
- Valor máximo: **127,262.02**
- Valor médio: **28,704.99**
- Mediana (apoio à Parte 3): 25,917.84
- Desvio padrão (apoio à Parte 3): 19,425.64

## Diagnóstico auxiliar (evidências para a Parte 3)

**Nulos por coluna (>0):**
- `salesperson_id`: 24131 (49.25%)

**Duplicatas:** linha inteira = 0 | `id` duplicado = 0
**subtotal**: negativos=0, zeros=0, min=36.65, max=127,262.02
**discount_amount**: negativos=0, zeros=36566, min=0.00, max=15,914.76
**total**: negativos=0, zeros=0, min=32.62, max=127,262.02

**Outliers (regra IQR clássica 1.5x)** em `total`: 452 linhas (0.92%) fora do intervalo [-28,484.74, 82,597.85]
Q1=13,171.24 | Q3=40,941.88 | IQR=27,770.65

**Datas futuras em `created_at`** (posteriores a 2026-08-11): 4322 linhas (8.82%)

**Valores únicos em `status`:** ['cancelled', 'confirmed', 'draft', 'paid']
**Contagem por status:**
status
paid         34365
confirmed     7335
cancelled     4847
draft         2451

**Valores únicos em `channel`:** ['ecommerce', 'pos']