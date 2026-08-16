# EDA - Etapa 1: Visão geral do schema das 24 tabelas da LH Nautical.

# Objetivo: para cada tabela, levantar:
# - shape (linhas x colunas)
# - dtypes brutos (como o pandas interpreta sem parsing)
# - % de nulos por coluna
# - # de duplicatas (linha inteira e por chave primária, quando aplicável)
# - cardinalidade (nunique) de cada coluna
# - range de colunas de data (min/max) para detectar datas futuras/inválidas
# - range de colunas numéricas (min/max) para detectar negativos/outliers óbvios

# Saída: outputs/01_schema_overview.md (relatório legível) e
# outputs/01_schema_overview.csv (uma linha por coluna, para consulta rápida).

import pandas as pd
import numpy as np
from pathlib import Path

DATA_DIR = Path(r"c:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv")
OUT_DIR = Path(r"c:\Users\lenovo\OneDrive\Desktop\Lighthouse\lh_nautical_challenge\outputs")
OUT_DIR.mkdir(parents=True, exist_ok=True)

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", 50)

csv_files = sorted(DATA_DIR.glob("*.csv"))

DATE_HINTS = ("_at", "date", "created", "updated", "issued", "placed", "received", "hire", "termination")

rows_summary = []
report_lines = ["# EDA — Visão geral do schema (LH Nautical)\n"]
report_lines.append(f"Total de tabelas: {len(csv_files)}\n")

tables = {}

for f in csv_files:
    name = f.stem
    df = pd.read_csv(f, low_memory=False)
    tables[name] = df

    n_rows, n_cols = df.shape
    dup_full = df.duplicated().sum()

    # heurística de chave primária: coluna 'id' isolada (não *_id)
    pk_col = "id" if "id" in df.columns else None
    dup_pk = df[pk_col].duplicated().sum() if pk_col else np.nan
    null_pk = df[pk_col].isna().sum() if pk_col else np.nan

    report_lines.append(f"\n## {name}\n")
    report_lines.append(f"- Linhas: {n_rows:,} | Colunas: {n_cols}")
    report_lines.append(f"- Linhas duplicadas (todas colunas): {dup_full}")
    if pk_col:
        report_lines.append(f"- PK `{pk_col}`: nulos={null_pk}, duplicados={dup_pk}")

    col_lines = []
    for col in df.columns:
        s = df[col]
        dtype = str(s.dtype)
        n_null = s.isna().sum()
        pct_null = 100 * n_null / n_rows if n_rows else 0
        n_unique = s.nunique(dropna=True)

        min_v = max_v = ""
        is_date_like = any(h in col.lower() for h in DATE_HINTS)
        if is_date_like and dtype == "object":
            parsed = pd.to_datetime(s, errors="coerce")
            n_unparsed = parsed.isna().sum() - n_null
            if parsed.notna().any():
                min_v, max_v = parsed.min(), parsed.max()
            extra = f" | não-parseáveis={n_unparsed}" if n_unparsed > 0 else ""
            col_lines.append(
                f"  - `{col}` ({dtype}, candidata a data): nulos={n_null} ({pct_null:.1f}%), "
                f"únicos={n_unique}, min={min_v}, max={max_v}{extra}"
            )
        elif pd.api.types.is_numeric_dtype(s):
            min_v, max_v = s.min(), s.max()
            n_negative = (s < 0).sum()
            n_zero = (s == 0).sum()
            col_lines.append(
                f"  - `{col}` ({dtype}): nulos={n_null} ({pct_null:.1f}%), únicos={n_unique}, "
                f"min={min_v}, max={max_v}, negativos={n_negative}, zeros={n_zero}"
            )
        else:
            sample_vals = s.dropna().unique()[:5]
            col_lines.append(
                f"  - `{col}` ({dtype}): nulos={n_null} ({pct_null:.1f}%), únicos={n_unique}, "
                f"exemplos={list(sample_vals)}"
            )

        rows_summary.append({
            "table": name, "column": col, "dtype": dtype,
            "n_rows": n_rows, "n_null": n_null, "pct_null": round(pct_null, 2),
            "n_unique": n_unique, "min": str(min_v), "max": str(max_v),
        })

    report_lines.append("\n".join(col_lines))

report_path = OUT_DIR / "01_schema_overview.md"
report_path.write_text("\n".join(report_lines), encoding="utf-8")

summary_df = pd.DataFrame(rows_summary)
summary_df.to_csv(OUT_DIR / "01_schema_overview.csv", index=False, encoding="utf-8-sig")

print(f"Relatório salvo em: {report_path}")
print(f"Resumo tabular salvo em: {OUT_DIR / '01_schema_overview.csv'}")
print(f"\nTabelas carregadas: {list(tables.keys())}")
