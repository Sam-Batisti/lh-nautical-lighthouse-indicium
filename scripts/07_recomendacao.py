# Questão 7 | Sistema de recomendação

# Objetivo:

# Identificar os produtos que apresentam maior similaridade de compra
# com o produto "Motor de Popa 1949".

# A recomendação será baseada no comportamento dos clientes.

# 1. Criei uma matriz cliente x produto.
# 2. Considerei 1 quando o cliente comprou o produto pelo menos uma vez.
# 3. Considerei 0 quando não houve compra.
# 4. Ignorei a quantidade comprada.
# 5. Calculei a similaridade de cosseno entre os produtos.
# 6. Criei um ranking com os 5 produtos mais similares ao Motor de Popa 1949.


# Definição de compra:

# Considerei somente pedidos com status "paid" ou "confirmed".
# Pedidos "draft" e "cancelled" não representam uma compra concluída,
# por isso não foram considerados no comportamento dos clientes.

import pandas as pd
import numpy as np
from pathlib import Path

DATA_DIR = Path(r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv")
PRODUTO_REFERENCIA = "Motor de Popa 1949"
TOP_N = 5

products = pd.read_csv(DATA_DIR / "products.csv")
variants = pd.read_csv(DATA_DIR / "product_variants.csv")
items = pd.read_csv(DATA_DIR / "order_items.csv")
orders = pd.read_csv(DATA_DIR / "orders.csv")

pedidos_validos = orders.loc[orders["status"].isin(["paid", "confirmed"]), ["id", "customer_id"]]

# item -> pedido (so paid/confirmed) -> variante -> produto
dataset = items.merge(pedidos_validos, left_on="order_id", right_on="id")
dataset = dataset.merge(variants[["id", "product_id"]], left_on="product_variant_id", right_on="id", suffixes=("", "_var"))

# ---------- Tarefa 1: matriz usuario x produto (binaria) ----------
pares = dataset[["customer_id", "product_id"]].drop_duplicates()  # ignora quantidade, so presenca
matriz = pd.crosstab(pares["customer_id"], pares["product_id"])
matriz = (matriz > 0).astype(int)
print(f"Matriz usuario x produto: {matriz.shape[0]} clientes x {matriz.shape[1]} produtos")

# ---------- Tarefa 2: similaridade de cosseno produto x produto ----------
# cosseno entre colunas (produtos): dot(i,j) / (norma_i * norma_j)

M = matriz.values.astype(float)
normas = np.linalg.norm(M, axis=0)
similaridade = (M.T @ M) / np.outer(normas, normas)
similaridade = np.nan_to_num(similaridade)  # produto sem nenhum comprador -> divisao por 0

produto_ids = matriz.columns.tolist()

# ---------- Tarefa 3: ranking dos 5 mais similares ao produto de referencia ----------
id_referencia = products.loc[products["name"] == PRODUTO_REFERENCIA, "id"].iloc[0]
idx_referencia = produto_ids.index(id_referencia)

scores = pd.Series(similaridade[idx_referencia], index=produto_ids)
scores = scores.drop(id_referencia).sort_values(ascending=False)  # desconsidera o proprio produto
top5 = scores.head(TOP_N)

nomes = products.set_index("id")["name"]
print(f"\nTop {TOP_N} produtos mais similares a '{PRODUTO_REFERENCIA}':")
for pid, score in top5.items():
    print(f"  {nomes.get(pid, '?')} (id={pid}) -- similaridade={score:.4f}")

# Observação de negócio

# A Marina levantou a hipótese de que clientes que compram um
# Motor de Popa também costumam comprar uma Defensa Náutica.
# Se a Defensa Náutica não aparecer entre os cinco primeiros resultados,
# isso não significa necessariamente que a hipótese esteja errada.
# Podemos investigar se existem vários produtos diferentes de Defensa
# Náutica no catálogo. Nesse caso, a questõa de compra pode estar
# dividida entre vários product_id, reduzindo a similaridade de cada item.
# Essa é uma hipótese para uma próxima análise e não uma conclusão
# desse modelo apresentado.
