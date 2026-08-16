"""
Questão 7 | Sistema de recomendação

Objetivo:

Identificar os produtos que apresentam maior similaridade de compra
com o produto "Motor de Popa 1949".

A recomendação será baseada no comportamento dos clientes.

Para isso:

1. Criei uma matriz cliente x produto.
2. Considerei 1 quando o cliente comprou o produto pelo menos uma vez.
3. Considerei 0 quando não houve compra.
4. Ignorei a quantidade comprada.
5. Calculei a similaridade de cosseno entre os produtos.
6. Criei um ranking com os 5 produtos mais similares ao Motor de Popa 1949.


Definição de compra:

Considerei somente pedidos com status "paid" ou "confirmed".
Pedidos "draft" e "cancelled" não representam uma compra concluída,
por isso não foram considerados no comportamento dos clientes.
"""

import pandas as pd
import numpy as np
from pathlib import Path


# Defini o local onde estão os arquivos do desafio
DATA_DIR = Path(
    r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv"
)

PRODUTO_REFERENCIA = "Motor de Popa 1949"
TOP_N = 5


# Carreguei as tabelas necessárias
products = pd.read_csv(DATA_DIR / "products.csv")
variants = pd.read_csv(DATA_DIR / "product_variants.csv")
items = pd.read_csv(DATA_DIR / "order_items.csv")
orders = pd.read_csv(DATA_DIR / "orders.csv")


# Mantive somente os pedidos que representam compras realizadas
pedidos_validos = orders.loc[
    orders["status"].isin(["paid", "confirmed"]),
    ["id", "customer_id"]
]


# Relacionei os itens aos pedidos para descobrir quem comprou cada item
dataset = items.merge(
    pedidos_validos,
    left_on="order_id",
    right_on="id"
)


# Relacionei cada variante ao seu respectivo produto
dataset = dataset.merge(
    variants[["id", "product_id"]],
    left_on="product_variant_id",
    right_on="id",
    suffixes=("", "_variante")
)


# Tarefa 1: criei a matriz cliente x produto

# Aqui não importa quantas unidades o cliente comprou.
# Se ele comprou o produto pelo menos uma vez, considero 1.
pares = dataset[
    ["customer_id", "product_id"]
].drop_duplicates()


# Transformei os pares cliente/produto em uma matriz.
# As linhas representam clientes e as colunas representam produtos.
matriz = pd.crosstab(
    pares["customer_id"],
    pares["product_id"]
)


# Garanti que a matriz tenha somente 0 e 1
matriz = (matriz > 0).astype(int)


print(
    f"Matriz criada: {matriz.shape[0]} clientes x "
    f"{matriz.shape[1]} produtos"
)


# Tarefa 2: calculei a similaridade entre os produtos

# Cada coluna da matriz representa o comportamento de compra
# de um produto entre os clientes.
M = matriz.values.astype(float)


# Calculei o tamanho do vetor de cada produto
normas = np.linalg.norm(M, axis=0)


# Calculei a similaridade de cosseno entre todos os produtos.
# Quanto mais próximo de 1, mais parecido é o comportamento de compra.
similaridade = (
    M.T @ M
) / np.outer(normas, normas)


# Caso algum produto não tenha compradores, evito erro de divisão por zero
similaridade = np.nan_to_num(similaridade)


# Guardei os IDs dos produtos na mesma ordem das colunas da matriz
produto_ids = matriz.columns.tolist()


# Tarefa 3: encontrei o produto de referência

# Primeiro, verifiquei se existe apenas um cadastro para o produto.
ids_referencia = products.loc[
    products["name"] == PRODUTO_REFERENCIA,
    "id"
].tolist()


if len(ids_referencia) == 0:
    raise ValueError(
        f"O produto '{PRODUTO_REFERENCIA}' não foi encontrado no catálogo."
    )


if len(ids_referencia) > 1:
    raise ValueError(
        f"Foram encontrados {len(ids_referencia)} cadastros para "
        f"'{PRODUTO_REFERENCIA}'. É necessário definir qual produto utilizar."
    )


id_referencia = ids_referencia[0]


# Verifiquei se o produto possui histórico de compras
if id_referencia not in produto_ids:
    raise ValueError(
        f"O produto '{PRODUTO_REFERENCIA}' não possui compras válidas "
        f"na base utilizada para a recomendação."
    )


# Localizei a posição do produto na matriz
idx_referencia = produto_ids.index(id_referencia)


# Peguei a similaridade do Motor de Popa 1949 com todos os outros produtos
scores = pd.Series(
    similaridade[idx_referencia],
    index=produto_ids
)


# Retirei o próprio Motor de Popa do ranking
scores = scores.drop(
    id_referencia
)


# Ordenei do produto mais similar para o menos similar
scores = scores.sort_values(
    ascending=False
)


# Selecionei os cinco produtos mais similares
top5 = scores.head(TOP_N)


# Relacionei os IDs aos nomes dos produtos
nomes = products.set_index("id")["name"]


print(
    f"\nTop {TOP_N} produtos mais similares a "
    f"'{PRODUTO_REFERENCIA}':"
)


for product_id, score in top5.items():

    print(
        f"  {nomes.get(product_id, '?')} "
        f"(id={product_id}) "
        f"similaridade={score:.4f}"
    )


# Observação de negócio

# A Marina levantou a hipótese de que clientes que compram um
# Motor de Popa também costumam comprar uma Defensa Náutica.
#
# Se a Defensa Náutica não aparecer entre os cinco primeiros resultados,
# isso não significa necessariamente que a hipótese esteja errada.
#
# Podemos investigar se existem vários produtos diferentes de Defensa
# Náutica no catálogo. Nesse caso, o comportamento de compra pode estar
# dividido entre vários product_id, reduzindo a similaridade de cada item.
#
# Essa é uma hipótese para uma análise posterior e não uma conclusão
# do modelo atual.