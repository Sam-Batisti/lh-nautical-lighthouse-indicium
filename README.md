# LH Nautical | From Data to Decisions

An end-to-end analytics case covering data quality, SQL, analytics engineering, forecasting and recommendation.

## Sobre o projeto

Este repositório documenta a resolução de um case técnico de dados para a LH Nautical, empresa fictícia de varejo náutico com lojas físicas, armazéns e e-commerce. O case cobre o ciclo completo de trabalho com dados: exploração e qualidade dos dados brutos, modelagem e carga em banco relacional, análise de clientes, dimensão de calendário, previsão de demanda e sistema de recomendação.

O critério orientador do projeto não foi só chegar ao número certo, mas documentar a decisão por trás de cada escolha metodológica — filtros aplicados, tratamento de ambiguidade nos dados e trade-offs de cada abordagem.

## Stack

`SQL` · `PostgreSQL` · `DuckDB` · `Python` · `pandas` · `NumPy` · `Power BI`

## Pipeline

```
CSV bruto (24 tabelas)
    -> EDA sem tratamento (Python + SQL)
    -> Geração de schema e carga em PostgreSQL
    -> Modelagem analítica em SQL (clientes, calendário)
    -> Previsão de demanda (Python)
    -> Sistema de recomendação (Python)
    -> Power BI
```

## Estrutura do repositório

```
LH-Nautical-Data-Challenge/
├── README.md
├── scripts/          scripts Python, um por questão
├── sql/              consultas SQL, um arquivo por questão
├── dashboard/         arquivo .pbix do Power BI
└── requirements.txt
```

## Questões obrigatórias e principais achados

### Questão 1 — EDA (`scripts/01_eda_orders.py`, `sql/01_eda_orders.sql`)

Análise exploratória da tabela `orders`, sem qualquer tratamento, para diagnosticar se os dados são confiáveis para decisão.

- 48.998 linhas, 13 colunas, período de 2020-01-01 a 2026-12-31
- Coluna `total`: mínimo 32,62, máximo 127.262,02, média 28.704,99
- 452 outliers pela regra de IQR (0,92% das linhas), 8,82% das linhas com data futura em relação à referência da análise, e 49,25% de nulos em `salesperson_id`
- Diagnóstico: a base é utilizável, mas não está pronta para decisão sem tratamento prévio — datas futuras e o volume de nulos em `salesperson_id` precisam ser investigados antes de qualquer análise operacional.

### Questão 2 — Schema (`scripts/02_generate_schema.py`, `sql/schema.sql`)

Gerador de DDL PostgreSQL em Python 3 puro (só biblioteca padrão), com inferência de tipo por coluna a partir dos 24 CSVs. Trata casos de borda como identificadores com zero à esquerda (CPF, telefone) e chaves de acesso de NF-e com 44 dígitos que estourariam `BIGINT`.

### Questão 3 — Carregamento (`scripts/03_load_data.py`)

Carga bruta dos 24 CSVs no PostgreSQL via `COPY ... FROM STDIN`, sem transformação — cada valor entra exatamente como está no arquivo original.

### Questão 4 — Análise de clientes (`sql/04_clientes_fieis.sql`)

Ranking dos 10 clientes fiéis com maior ticket médio, entre os que compraram de 13 ou mais categorias distintas, e a categoria mais comprada por esse grupo.

- Todos os 10 clientes fiéis compraram das 14 categorias existentes no catálogo
- Categoria mais comprada pelo grupo: Hélices (492 unidades), à frente de Coletes Salva-Vidas (393) e Eletrônica Náutica (392)

### Questão 5 — Dimensão de calendário (`sql/05_dimensao_calendario.sql`)

Construção de uma tabela de datas via `generate_series` para calcular a venda média diária por dia da semana no canal físico (pos), incluindo dias sem nenhuma venda registrada como zero.

- Sem a dimensão de calendário, dias sem venda somem do cálculo em vez de contar como zero, o que infla artificialmente a média.
- Com o tratamento correto, quinta-feira é o pior dia de vendas (R$ 157.154,32 de média diária), não domingo como a leitura ingênua sugeria.

### Questão 6 — Previsão de demanda (`scripts/06_previsao_demanda.py`)

Baseline de média móvel de 3 meses (walk-forward) para prever as vendas mensais de "Bússola de Bordo 702" no primeiro trimestre de 2026, considerando pedidos com status `paid` e `confirmed`.

- Achado de qualidade de dados: existem 2 linhas de produto cadastradas com o mesmo nome ("Bússola de Bordo 702", ids 74 e 240) — nome não é chave única no catálogo. As 3 variantes das 2 linhas foram usadas em conjunto após confirmar que ambas têm histórico de venda real.
- MAE de 16,56 unidades no trimestre de teste. O erro concentra-se em janeiro (43,33 unidades) — o modelo não antecipa mudança brusca de patamar de demanda, o que na prática geraria ruptura de estoque.

### Questão 7 — Sistema de recomendação (`scripts/07_recomendacao.py`)

Matriz binária cliente x produto (presença de compra, pedidos `paid`/`confirmed`) e similaridade de cosseno entre produtos, para recomendar itens complementares ao "Motor de Popa 1949".

- Produto mais similar: Vela Mestra 1913 (similaridade 0,2452)
- Nenhuma "Defensa Náutica" aparece no top 5, apesar da hipótese de negócio inicial — o catálogo tem cerca de 44 SKUs distintos de defensa, o que dilui a similaridade calculada por produto individual.

## Análise complementar (`sql/08_prejuizo_margem.sql`)

O enunciado sugere "ranking de prejuízos por produto" e "clientes com maior lucro acumulado" como visuais do dashboard, sem premissas formais para essa análise — por isso ela não é uma questão numerada do desafio, e sim um insumo complementar construído especificamente para sustentar o Power BI com números validados.

Evitei os termos "prejuízo" e "lucro" sem qualificar, porque nenhum dos dois é exato com os dados disponíveis: o valor devolvido não é necessariamente prejuízo líquido (o item pode voltar ao estoque e ser revendido), e a diferença entre preço de venda e custo cadastrado não é lucro contábil (não desconta imposto, frete ou custo operacional). A lógica está documentada e validada em três views no PostgreSQL:

- `valor_reembolsado_por_produto`: soma do valor efetivamente reembolsado ao cliente, só em devoluções concluídas (`completed`) e de ação `refund` (troca não devolve dinheiro). Top: Bússola de Bordo 8282, R$ 58.380,75.
- `margem_estimada_por_produto`: `sale_price - cost_price` por variante, média por produto. Margem média geral de 41,3%.
- `margem_acumulada_por_cliente`: soma da margem estimada de todos os itens comprados por cliente, mesmo filtro `paid`/`confirmed` usado nas Questões 6 e 7. Cliente 740 lidera com R$ 529.657,42.

## Análise complementar (`sql/09_dashboard_clientes.sql`)

Suporte à página "Clientes" do dashboard. "Cliente elite" segue a definição literal da Questão 4 — diversidade de categorias compradas ≥ 13. Como o catálogo tem só 14 categorias no total, esse corte sozinho classifica 96% da base como elite, então o gráfico de categoria mais consumida restringe ao Top 10 desses clientes elite ordenados por ticket médio, mantendo a definição do enunciado e ainda assim segmentando algo relevante.

- `ticket_medio_por_cliente`: ticket médio e quantidade de pedidos por cliente, filtro `paid`/`confirmed`.
- `diversidade_categorias_por_cliente`: quantidade de categorias distintas compradas por cliente e flag `cliente_elite` (≥ 13).
- `consumo_categorias_clientes_elite`: quantidade de itens comprados por categoria, entre o Top 10 clientes elite por ticket médio. Categoria líder: Pesca (344 itens).

## Análise complementar (`sql/10_dashboard_produtos.sql`)

Suporte à página "Produtos e Rentabilidade" do dashboard. Ao montar essa página, encontrei um problema de qualidade de dado: o catálogo tem produtos com nome duplicado/placeholder — `"asdf"` aparece em dois `product_id` diferentes (187 e 342, categorias diferentes), e `"TBD"` também existe como nome de produto (id 66). As views da análise 08 agrupam por `p.name`, então esses dois "asdf" ficam somados numa linha só — não distorceu a Questão 4, mas nas análises por produto do dashboard isso juntaria dois produtos reais e diferentes numa barra só (cheguei a ver "asdf" aparecer em #1 no ranking de faturamento, R$ 8,28 Mi, antes da correção).

Decisão: não excluí `"asdf"`/`"TBD"` do catálogo — são dados brutos e não há premissa que justifique remover. Em vez disso, as views abaixo sempre agrupam por `product_id` (nunca por nome), e uma coluna `nome_produto` no formato `<nome> | ID <id>` deixa visível quando dois produtos compartilham nome, em vez de esconder o problema.

- `ranking_valor_reembolsado_produto`: valor reembolsado por produto, agrupado por `product_id`. Líder: Bússola de Bordo 8282 (ID 449), R$ 58.380,75 — mesmo número da view 08, confirma que essa categoria específica não tinha colisão de nome.
- `margem_estimada_por_categoria`: margem estimada média por categoria (`product_variants` → `products` → `categories`). Categoria com menor margem: Pesca (39,2%).
- `faturamento_margem_por_produto`: faturamento total e margem estimada por produto, mesma chave `product_id`, usada tanto no gráfico de dispersão (faturamento × margem) quanto no ranking de faturamento. Após corrigir o agrupamento, os dois produtos "asdf" aparecem separados (R$ 4,85 Mi e R$ 3,44 Mi) e o líder real passa a ser Bateria Náutica 5523 (ID 258), R$ 7,10 Mi.

## Análise complementar (`sql/11_dashboard_demanda.sql`)

Suporte à página "Demanda e Operação" do dashboard. As duas views abaixo não criam regra nova — empacotam como view a mesma lógica já validada na Questão 6 (`sql/05_dimensao_calendario.sql` e `scripts/06_previsao_demanda.py`), que antes eram só consulta solta / script Python, não consultáveis pelo Power BI.

- `vendas_dia_semana`: mesma lógica exata do `05_dimensao_calendario.sql` (canal POS, dias sem venda entram como zero na média). Pior dia: Quinta-feira.
- `previsao_bussola_702`: série mensal completa (2020-01 a 2026-03) da Bússola de Bordo 702, com `qtd_prevista` e `erro_absoluto` preenchidos só no período de teste oficial (jan-mar/2026) — não inventei previsão pra meses que o script original não avaliou. Validei em SQL (DuckDB) contra a saída do script: bate exatamente (jan 32,67/76, fev 49,67/55, mar 50,00/51, MAE 16,55).

## Dashboard

O painel complementar em Power BI está em `dashboard/Dashboard.pbix`, conectado direto no PostgreSQL. Tem 5 páginas: uma Capa e 4 páginas de dados, cada uma com uma cor de destaque própria pra facilitar a orientação visual.

- **Capa** — abertura do painel, com atalho direto pra cada uma das 4 páginas.
- **Visão Executiva** (azul-aço) — faturamento, vendas e KPIs gerais. Filtros: Ano, Canal, Categoria.
- **Visão de Clientes** (verde-água) — ticket médio, diversidade de categorias e "clientes elite" (Questão 4). Sem filtro de categoria: os 3 gráficos dessa página trabalham no grão cliente (histórico de todos os pedidos), então um recorte por categoria não se aplicaria de forma consistente entre eles.
- **Visão de Produtos** (âmbar) — rentabilidade, ranking de reembolso e faturamento × margem (`sql/10_dashboard_produtos.sql`). Filtro: Categoria.
- **Visão de Demanda** (lilás) — vendas médias por dia da semana (Questão 6) e previsão × real da Bússola de Bordo 702 (`sql/11_dashboard_demanda.sql`). Filtro: Ano — afeta a série de previsão; o gráfico de dia da semana é uma média fixa do período completo e não tem coluna de data, então não responde ao filtro por desenho.

Navegação: barra lateral fixa em todas as páginas, com atalho para a Capa, para cada uma das 4 páginas, botões Anterior/Próxima (seguindo a sequência Capa → Executiva → Clientes → Produtos → Demanda, sem "Próxima" na última página) e um botão de reset visual por página.

## Como rodar

1. Instalar as dependências: `pip install -r requirements.txt`
2. Ajustar os caminhos dos CSVs e as credenciais do PostgreSQL no início de cada script/arquivo SQL
3. Rodar os scripts na ordem numérica (`scripts/01_...` até `scripts/07_...`)
4. Rodar `sql/08_prejuizo_margem.sql`, `sql/09_dashboard_clientes.sql`, `sql/10_dashboard_produtos.sql` e `sql/11_dashboard_demanda.sql` para criar as views de apoio ao dashboard
5. No Power BI, conectar direto no PostgreSQL (banco `lh_nautical`) e selecionar as tabelas/views no Navigator — inclusive as 11 views das análises complementares, que aparecem como tabela normal

## Nota sobre os dados

Os dados utilizados neste projeto foram fornecidos exclusivamente para o desafio técnico da LH Nautical e não estão publicados neste repositório.
