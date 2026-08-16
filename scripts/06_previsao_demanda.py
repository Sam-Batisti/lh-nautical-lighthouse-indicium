# Questão 6 | Previsão de demanda | Bússola de Bordo 702

# Premissas obrigatórias:

# Treino: dados até 31/12/2025
# Teste: janeiro, fevereiro e março de 2026
# Granularidade: mensal
# Produto: Bússola de Bordo 702
# Baseline: média móvel dos últimos 3 meses, usando apenas dados
# anteriores à data de cada previsão.


# Observação sobre a qualidade dos dados:

# Encontrei dois cadastros diferentes para o produto "Bússola de Bordo 702".
# Ao analisar os pedidos, percebi que os dois cadastros possuem variantes
# com histórico de vendas.

# Por isso, considerei as três variantes encontradas nos dois cadastros.
# Assim, evito exclusão de vendas que podem ser reais por causa de uma
# inconsistência no cadastro do produto.


# Como foi definida a demanda:

# Considerei apenas pedidos com status "paid" e "confirmed", pois entendo
# que esses status representam vendas efetivamente realizadas.

# Pedidos "draft" ainda não representam uma venda concluída e pedidos
# "cancelled" não geraram uma venda. Por isso, não considerei esses registros
# na série de demanda.


import pandas as pd
from pathlib import Path

DATA_DIR = Path(r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv")

PRODUCT_NAME = "Bússola de Bordo 702"


# Tarefa 1: criei um dataset unificado a partir das tabelas necessárias

products = pd.read_csv(DATA_DIR / "products.csv")
variants = pd.read_csv(DATA_DIR / "product_variants.csv")
items = pd.read_csv(DATA_DIR / "order_items.csv")
orders = pd.read_csv(DATA_DIR / "orders.csv")

# Converti a coluna de data para o formato de data do Python
orders["created_at"] = pd.to_datetime(orders["created_at"])

# Primeiro, localizei os dois cadastros do produto pelo nome
product_ids = products.loc[
    products["name"] == PRODUCT_NAME,
    "id"
]

# Depois, localizei todas as variantes relacionadas a esses produtos
variant_ids = variants.loc[
    variants["product_id"].isin(product_ids),
    "id"
]

# Filtrei os itens de pedido que pertencem a essas variantes
produto_items = items[
    items["product_variant_id"].isin(variant_ids)
]

# Agora juntei os itens aos pedidos para trazer a data e o status da venda
dataset = produto_items.merge(
    orders[["id", "status", "created_at"]],
    left_on="order_id",
    right_on="id",
    suffixes=("", "_pedido")
)

# Considerei somente as vendas que realmente doram realizadas
dataset = dataset[
    dataset["status"].isin(["paid", "confirmed"])
]

# Criei uma coluna com o mês da venda
dataset["mes"] = dataset["created_at"].dt.to_period("M")

# Tarefa 1: transformei os dados em uma série mensal de vendas

# Soma das quantidade de unidades vendidas em cada mês
vendas_mes = dataset.groupby("mes")["quantity"].sum()


# Incluí todos os meses da série, inclusive os meses sem venda.
# Quando não houve venda, considerei a quantidade como zero.
#
# Isso é importante para a média móvel, porque um mês sem venda
# continua sendo um mês da série e não deve apenas desaparecer.

calendario_mensal = pd.period_range(
    "2020-01",
    "2026-03",
    freq="M"
)

vendas_mes = vendas_mes.reindex(
    calendario_mensal,
    fill_value=0
)

# Período de treino e  período de teste

CORTE_TREINO = pd.Period("2025-12", "M")

treino = vendas_mes[
    vendas_mes.index <= CORTE_TREINO
]

teste = vendas_mes[
    vendas_mes.index > CORTE_TREINO
]


# Tarefas 2 e 3: criei o baseline e fiz as previsões para o primeiro
# trimestre de 2026

# Para cada mês que quero prever, usei os três meses reais anteriores.
#
# Janeiro/2026 usa outubro, novembro e dezembro de 2025.
# Fevereiro/2026 usa novembro, dezembro de 2025 e janeiro de 2026.
# Março/2026 usa dezembro de 2025, janeiro e fevereiro de 2026.
#
# Dessa forma, cada previsão usa somente informações que já estariam
# disponíveis no momento em que aquela previsão fosse realizada.

previsoes = {}

for mes in teste.index:

    ultimos_3 = vendas_mes[
        vendas_mes.index < mes
    ].iloc[-3:]

    previsoes[mes] = ultimos_3.mean()


# Tarefa 4: calculei o MAE para comparar a previsão com o valor real

erros_abs = {
    mes: abs(previsoes[mes] - teste[mes])
    for mes in teste.index
}

mae = sum(erros_abs.values()) / len(erros_abs)


# Mostrei a série mensal completa para acompanhar os dados utilizados

print("Vendas mensais da Bússola de Bordo 702, de janeiro de 2020 a março de 2026:")
print(vendas_mes.to_string())


# Mostrei a previsão, o valor real e o erro de cada mês do período de teste

print("\nPrevisão x Real | Primeiro trimestre de 2026:")

for mes in teste.index:

    print(
        f"  {mes}: "
        f"previsto={previsoes[mes]:.2f} | "
        f"real={teste[mes]} | "
        f"erro_abs={erros_abs[mes]:.2f}"
    )

print(f"\nMAE: {mae:.2f} unidades")


# Tarefa 5: interpretação dos resultados

# a. Avaliação do baseline
#
# Eu considero a média móvel de 3 meses uma boa referência inicial,
# porque é simples e fácil de interpretar.
# Porém, não considero esse método suficiente para ser o modelo definitivo
# de planejamento de estoque.
# O principal problema apareceu em janeiro: o modelo previu 32,67 unidades,
# mas foram vendidas 76 unidades. O erro foi de 43,33 unidades.
# Em fevereiro e março, o resultado melhorou porque o modelo já conseguiu
# incorporar o aumento real das vendas de janeiro e fevereiro.
# O MAE geral foi de 16,56 unidades, mas é importante olhar também os erros
# de cada mês, porque a média sozinha pode esconder uma diferença grande.


# b. Limitação do método
#
# A principal limitação da média móvel é que ela reage ao que já aconteceu.
# Ela não consegue antecipar uma mudança brusca na demanda.
# Isso ficou claro em janeiro de 2026: as vendas aumentaram bastante,
# mas o modelo ainda estava olhando para os meses anteriores e previu
# somente 32,67 unidades.
# O método também não considera fatores como tendência, sazonalidade,
# promoções ou outros eventos que possam alterar a demanda.
# No contexto da LH Nautical, essa limitação pode ser importante porque
# uma previsão abaixo da demanda real pode levar à falta de estoque.