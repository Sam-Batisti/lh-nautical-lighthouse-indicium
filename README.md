# LH Nautical — Desafio de Dados

Case técnico feito pra o Lighthouse da empresa Indicium AI,o desafio foi receber os dados brutos de uma loja náutica fictícia (a LH Nautical) e ir do zero até um dashboard, passando por SQL, Python e Power BI.

## Sobre o projeto

A LH Nautical vende produto náutico em loja física, e-commerce e armazém. Os dados vêm em 24 CSVs soltos — pedidos, clientes, estoque, nota fiscal, devolução, etc. O desafio pedia pra eu ir do dado cru até uma análise que faça sentido pra decisão de negócio: entender a qualidade dos dados, montar um banco relacional, responder perguntas de vendas e clientes, fazer uma previsão simples de demanda, montar uma recomendação de produto e fechar tudo num painel.

Tentei documentar não só o resultado, mas o porquê de cada decisão — que filtro usei, o que fazer quando o dado tava ambíguo, e por que escolhi um jeito e não outro. Isso importa mais do que só "bater o número certo".

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

## As questões do desafio e o que encontrei

### Questão 1 — EDA (`scripts/01_eda_orders.py`, `sql/01_eda_orders.sql`)

Primeiro passo: olhar a tabela `orders` sem mexer em nada, só pra ver se dá pra confiar nesse dado.

- 48.998 linhas, 13 colunas, período de 2020-01-01 a 2026-12-31
- Coluna `total`: mínimo 32,62, máximo 127.262,02, média 28.704,99
- 452 outliers pela regra do IQR (0,92% das linhas), 8,82% das linhas com data no futuro, e quase metade (49,25%) de `salesperson_id` vazio
- Conclusão: dá pra usar, mas não tá pronto pra decisão sem tratar antes — as datas futuras e o tanto de `salesperson_id` vazio precisam ser investigados primeiro.

### Questão 2 — Schema (`scripts/02_generate_schema.py`, `sql/schema.sql`)

Fiz um script em Python puro (sem biblioteca externa) que lê os 24 CSVs e gera o DDL do PostgreSQL sozinho, adivinhando o tipo de cada coluna. Precisei tratar dois casos que dariam problema: CPF e telefone que começam com zero (se virar número, perde o zero) e a chave de acesso da nota fiscal, que tem 44 dígitos e não cabe num `BIGINT`.

### Questão 3 — Carregamento (`scripts/03_load_data.py`)

Carga bruta dos 24 CSVs pro PostgreSQL, usando `COPY ... FROM STDIN` — sem tratar nada, cada valor entra exatamente como tá no arquivo original.

### Questão 4 — Análise de clientes (`sql/04_clientes_fieis.sql`)

Rankear os 10 clientes fiéis com maior ticket médio, considerando fiel quem comprou de 13 categorias diferentes ou mais, e ver qual categoria esse grupo mais compra.

- Os 10 clientes fiéis compraram das 14 categorias que existem no catálogo — todas elas
- Categoria mais comprada pelo grupo: Hélices (492 unidades), na frente de Coletes Salva-Vidas (393) e Eletrônica Náutica (392)

### Questão 5 — Dimensão de calendário (`sql/05_dimensao_calendario.sql`)

Montei uma tabela de datas com `generate_series` pra calcular a venda média diária por dia da semana, só do canal de loja física (pos), contando os dias sem venda nenhuma como zero.

- Sem essa tabela de calendário, dia sem venda simplesmente some do cálculo em vez de entrar como zero — e isso infla a média sem eu perceber.
- Corrigindo isso, quinta-feira é o pior dia de vendas (R$ 157.154,32 de média), não domingo como parecia numa primeira olhada.

### Questão 6 — Previsão de demanda (`scripts/06_previsao_demanda.py`)

Usei uma média móvel de 3 meses (olhando só pro passado, sem trapacear com dado futuro) pra prever a venda mensal da "Bússola de Bordo 702" no primeiro trimestre de 2026, considerando só pedido com status `paid` ou `confirmed`.

- Achado no caminho: existem 2 cadastros de produto com o mesmo nome "Bússola de Bordo 702" (ids 74 e 240) — ou seja, nome não é uma chave única no catálogo. Usei as 3 variantes dos dois cadastros juntas, depois de confirmar que as duas têm venda de verdade.
- O erro médio (MAE) ficou em 16,56 unidades no trimestre de teste, mas concentrado em janeiro (43,33 unidades) — o modelo não pega mudança brusca de demanda, o que na prática significaria faltar produto no estoque.

### Questão 7 — Sistema de recomendação (`scripts/07_recomendacao.py`)

Montei uma matriz simples de cliente x produto (1 se o cliente comprou, 0 se não comprou) e calculei a similaridade de cosseno entre produtos, pra sugerir o que costuma ser comprado junto com o "Motor de Popa 1949".

- Produto mais parecido: Vela Mestra 1913, com similaridade de 0,2452
- A "Defensa Náutica" não apareceu entre os 5 primeiros, mesmo com a expectativa inicial de que apareceria — mas isso pode ser porque o catálogo tem uns 44 SKUs diferentes de defensa, o que espalha (dilui) a similaridade entre vários produtos em vez de concentrar num só.

## Extras que criei pra sustentar o dashboard

Essas análises não são questão numerada do desafio — o enunciado só sugeria alguns gráficos pro painel ("ranking de prejuízo", "clientes com mais lucro") sem dar uma regra exata de como calcular. Então criei essa lógica eu mesma e documentei em SQL, pra não jogar um número no dashboard sem saber de onde ele veio.

### `sql/08_prejuizo_margem.sql`

Evitei falar "prejuízo" e "lucro" sem qualificar, porque nenhum dos dois é exato com o que eu tenho: o valor devolvido não é prejuízo líquido de verdade (o produto pode voltar pro estoque e ser vendido de novo), e a diferença entre preço de venda e custo não é lucro contábil (não desconta imposto, frete, etc). Por isso uso os termos "valor reembolsado" e "margem estimada".

- `valor_reembolsado_por_produto`: soma do valor devolvido de fato, só em devolução concluída (`completed`) e do tipo `refund` (troca não devolve dinheiro). O topo é Bússola de Bordo 8282, com R$ 58.380,75.
- `margem_estimada_por_produto`: preço de venda menos custo, por variante, com a média por produto. A margem média geral deu 41,3%.
- `margem_acumulada_por_cliente`: soma da margem de tudo que cada cliente comprou, com o mesmo filtro de pedido válido das questões 6 e 7. O cliente 740 lidera com R$ 529.657,42.

### `sql/09_dashboard_clientes.sql`

Dá suporte à página de Clientes do dashboard. Usei a mesma definição de "cliente elite" da Questão 4 (diversidade de categoria ≥ 13). Só que como o catálogo tem só 14 categorias no total, esse corte sozinho já pega 96% dos clientes — então o gráfico de categoria mais consumida restringe pro Top 10 desses clientes elite por ticket médio, pra ainda sobrar algo útil de olhar.

- `ticket_medio_por_cliente`: ticket médio e número de pedidos por cliente.
- `diversidade_categorias_por_cliente`: quantas categorias diferentes cada cliente comprou, e uma flag `cliente_elite`.
- `consumo_categorias_clientes_elite`: quantidade comprada por categoria, olhando só o Top 10 elite. Categoria que mais aparece: Pesca (344 itens).

### `sql/10_dashboard_produtos.sql`

Dá suporte à página de Produtos. Enquanto montava essa página encontrei um problema: tem produto com nome repetido ou tipo "rascunho" no catálogo — "asdf" aparece em dois `product_id` diferentes (187 e 342, de categorias diferentes), e "TBD" também é nome de produto (id 66). As views da Questão 8 agrupam por nome, então esses dois "asdf" ficam somados numa linha só. Isso não bagunçou a Questão 4, mas nessa página do dashboard chegou a aparecer "asdf" em #1 do ranking de faturamento (R$ 8,28 Mi) antes de eu corrigir.

Decidi não apagar "asdf"/"TBD" do catálogo — é dado bruto e não tinha motivo pra remover. Em vez disso, essas views sempre agrupam por `product_id` (nunca por nome), e criei uma coluna `nome_produto` no formato "nome | ID x" pra deixar visível quando dois produtos dividem o mesmo nome, em vez de esconder isso.

- `ranking_valor_reembolsado_produto`: valor reembolsado por produto, agora por id. O líder é o mesmo da Questão 8 (Bússola de Bordo 8282), confirmando que esse produto não tinha o problema de nome repetido.
- `margem_estimada_por_categoria`: margem média por categoria. A categoria com menor margem é Pesca (39,2%).
- `faturamento_margem_por_produto`: faturamento e margem por produto, usada tanto no gráfico de faturamento x margem quanto no ranking. Depois de corrigir o agrupamento, os dois "asdf" aparecem separados (R$ 4,85 Mi e R$ 3,44 Mi), e o líder de verdade passa a ser Bateria Náutica 5523, com R$ 7,10 Mi.

### `sql/11_dashboard_demanda.sql`

Dá suporte à página de Demanda. Essas duas views não inventam regra nova — só pegam a mesma lógica da Questão 5 e da Questão 6 e transformam em view, pra dar pra consultar direto do Power BI (antes era só script Python / consulta solta).

- `vendas_dia_semana`: mesma lógica da Questão 5. Pior dia continua sendo quinta-feira.
- `previsao_bussola_702`: série mensal completa (jan/2020 a mar/2026) da Bússola de Bordo 702, com previsão e erro preenchidos só no período de teste oficial (jan-mar/2026) — não inventei previsão pra mês que o script original não avaliou. Conferi em SQL contra a saída do script Python e bateu certinho (jan 32,67/76, fev 49,67/55, mar 50,00/51, MAE 16,55).

## Dashboard

🔗 **[Ver o dashboard ao vivo](https://app.powerbi.com/view?r=eyJrIjoiNzZmZWZmNGUtOWQ2YS00NGZlLWE4NTUtMTJkNjM5ZGU0OGFhIiwidCI6IjY1MDZiNzgwLTU4NTEtNGY0Ny04NTI5LWExMTEwN2VkYTdlMSJ9)**

O painel em Power BI está em `dashboard/Dashboard.pbix`, conectado direto no PostgreSQL. Tem 5 páginas: uma Capa e 4 páginas de dado, cada uma com uma cor pra ajudar na localização.

- **Capa** — atalho pra cada uma das 4 páginas.
- **Visão Executiva** (azul) — faturamento, vendas e KPIs gerais. Filtros de Ano, Canal e Categoria.
- **Visão de Clientes** (verde) — ticket médio, diversidade de categoria e clientes elite (Questão 4). Sem filtro de categoria de propósito: os 3 gráficos dessa página olham o histórico completo do cliente, então filtrar por categoria não faria sentido igual nos três.
- **Visão de Produtos** (âmbar) — rentabilidade, reembolso e faturamento x margem. Filtro de Categoria.
- **Visão de Demanda** (lilás) — venda média por dia da semana e previsão x real da Bússola de Bordo 702. Filtro de Ano, que só afeta a previsão — o gráfico de dia da semana é uma média fixa do período todo e não tem coluna de data pra filtrar.

## Como rodar

1. Instalar as dependências: `pip install -r requirements.txt`
2. Ajustar os caminhos dos CSVs e as credenciais do PostgreSQL no início de cada script/arquivo SQL
3. Rodar os scripts na ordem numérica (`scripts/01_...` até `scripts/07_...`)
4. Rodar `sql/08_prejuizo_margem.sql`, `sql/09_dashboard_clientes.sql`, `sql/10_dashboard_produtos.sql` e `sql/11_dashboard_demanda.sql` pra criar as views que sustentam o dashboard
5. No Power BI, conectar direto no PostgreSQL (banco `lh_nautical`) e selecionar as tabelas/views no Navigator — as 11 views das análises extras aparecem lá como tabela normal

## Sobre os dados

Os dados desse projeto foram fornecidos só pra esse desafio técnico da LH Nautical e não estão publicados neste repositório.
