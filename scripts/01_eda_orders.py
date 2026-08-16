# Questão 1 - EDA da tabela orders (LH Nautical)

# Premissas obrigatórias do desafio:
# Usar apenas a tabela orders
# Não fazer limpeza nem tratamento
# Apenas observar, agregar e descrever

import pandas as pd
from pathlib import Path


# Defini o local onde está o arquivo orders.csv
DATA_DIR = Path(
    r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv"
)

# Leitura do CSV
df = pd.read_csv(DATA_DIR / "orders.csv")

# Parte 1: visão geral

n_rows, n_cols = df.shape

print("Questão 1 | EDA da tabela orders")
print("=" * 50)

print("\nParte 1 | Visão geral")
print(f"Quantidade total de linhas: {n_rows:,}".replace(",", "."))
print(f"Quantidade total de colunas: {n_cols}")
print(f"Data mínima: {pd.to_datetime(df['created_at']).min()}")
print(f"Data máxima: {pd.to_datetime(df['created_at']).max()}")


# Verifiquei os valores nulos de created_at
n_null_created = df["created_at"].isna().sum()

print(f"Nulos em created_at: {n_null_created}")


# Parte 2: análise da coluna total

total = df["total"]

n_null_total = total.isna().sum()

print("\nParte 2 | Análise da coluna total")
print("=" * 50)

print(f"Nulos em total: {n_null_total}")
print(f"Valor mínimo: R$ {total.min():,.2f}")
print(f"Valor máximo: R$ {total.max():,.2f}")
print(f"Valor médio: R$ {total.mean():,.2f}")


# Calculei também a mediana e o desvio padrão para ajudar
# na interpretação da distribuição dos valores
print(f"Mediana: R$ {total.median():,.2f}")
print(f"Desvio padrão: R$ {total.std():,.2f}")


# Parte 3: diagnóstico auxiliar

print("\nParte 3 | Diagnóstico da qualidade dos dados")
print("=" * 50)


# Verifiquei os valores nulos em todas as colunas
null_by_col = df.isna().sum()
null_by_col = null_by_col[null_by_col > 0]

print("\nNulos por coluna:")

if null_by_col.empty:
    print("Nenhuma coluna possui valores nulos.")
else:
    for col, n in null_by_col.items():
        percentual = 100 * n / n_rows
        print(f"{col}: {n} ({percentual:.2f}%)")


# Verifiquei possíveis duplicidades
dup_full = df.duplicated().sum()

if "id" in df.columns:
    dup_id = df["id"].duplicated().sum()
else:
    dup_id = "N/A"

print("\nDuplicidades:")
print(f"Linhas inteiramente duplicadas: {dup_full}")
print(f"IDs duplicados: {dup_id}")


# Verifiquei valores negativos e iguais a zero
# sem alterar os dados

for col in ["subtotal", "discount_amount", "total"]:

    if col in df.columns:

        s = df[col]

        n_neg = (s < 0).sum()
        n_zero = (s == 0).sum()

        print(f"\n{col}:")
        print(f"Valores negativos: {n_neg}")
        print(f"Valores iguais a zero: {n_zero}")


# Analisei possíveis valores extremos usando a regra do IQR
q1 = total.quantile(0.25)
q3 = total.quantile(0.75)

iqr = q3 - q1

upper_fence = q3 + 1.5 * iqr
lower_fence = q1 - 1.5 * iqr

n_outliers_iqr = (
    (total > upper_fence) |
    (total < lower_fence)
).sum()

print("\nPossíveis outliers em total:")
print(f"Quantidade: {n_outliers_iqr}")
print(f"Percentual: {100 * n_outliers_iqr / n_rows:.2f}%")
print(f"Limite inferior: R$ {lower_fence:,.2f}")
print(f"Limite superior: R$ {upper_fence:,.2f}")


# Verifiquei se existem datas posteriores à data da análise
# sem alterar os registros

DATA_REFERENCIA = pd.Timestamp("2026-08-11")

created_parsed = pd.to_datetime(
    df["created_at"],
    errors="coerce"
)

n_futuras = (
    created_parsed > DATA_REFERENCIA
).sum()

print("\nDatas posteriores à data da análise:")
print(
    f"{n_futuras} registros "
    f"({100 * n_futuras / n_rows:.2f}%)"
)


# Verifiquei os status existentes na tabela

if "status" in df.columns:

    print("\nStatus encontrados:")
    print(
        df["status"]
        .value_counts()
        .to_string()
    )


# Verifiquei os canais existentes

if "channel" in df.columns:

    print("\nCanais encontrados:")
    print(
        df["channel"]
        .value_counts()
        .to_string()
    )
