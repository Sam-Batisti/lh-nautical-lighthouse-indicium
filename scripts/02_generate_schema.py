# Questão 2 | Geração do schema PostgreSQL
# LH Nautical

# Objetivo:
# Ler todos os arquivos CSV do diretório e gerar um único schema.sql.
# O script usa somente bibliotecas padrão do Python.

import csv
from datetime import datetime
from pathlib import Path

DATA_DIR = Path(r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv")
OUTPUT_FILE = Path(r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\lh_nautical_challenge\sql\schema.sql")

DATETIME_FORMATS = ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S")
DATE_FORMATS = ("%Y-%m-%d",)

# Tratei esses campos como texto porque são identificadores,
# mesmo quando seus valores são formados apenas por números.
TEXT_FIELDS = {
    "cpf",
    "tax_id",
    "phone",
    "barcode_ean",
    "ncm_code",
    "nfe_access_key"
}

# Esses campos representam quantidades inteiras.
INTEGER_FIELDS = {
    "reorder_point"
}

def classify(value):
    try:
        int(value)
        return "integer"
    except ValueError:
        pass
    try:
        float(value)
        return "numeric"
    except ValueError:
        pass
    if value.lower() in {"true", "false", "t", "f", "yes", "no"}:
        return "boolean"
    for fmt in DATETIME_FORMATS:
        try:
            datetime.strptime(value, fmt)
            return "timestamp"
        except ValueError:
            pass
    for fmt in DATE_FORMATS:
        try:
            datetime.strptime(value, fmt)
            return "date"
        except ValueError:
            pass
    return "text"

def postgres_type(types):
    if not types:
        return "TEXT"
    if types <= {"integer"}:
        return "INTEGER"
    if types <= {"integer", "numeric"}:
        return "NUMERIC"
    if types <= {"boolean"}:
        return "BOOLEAN"
    if types <= {"timestamp"}:
        return "TIMESTAMP"
    if types <= {"date"}:
        return "DATE"
    return "TEXT"

def clean_name(name):
    name = name.strip().lower().replace(" ", "_")
    return "".join(
        c if c.isalnum() or c == "_" else "_"
        for c in name
    )

def generate_schema(csv_file):
    table_name = clean_name(csv_file.stem)

    with csv_file.open("r", encoding="utf8", newline="") as file:
        reader = csv.reader(file)
        header = [clean_name(column) for column in next(reader)]
        types = [set() for _ in header]
        nulls = [False] * len(header)
        rows = 0

        for row in reader:
            rows += 1
            for i in range(len(header)):
                value = row[i].strip() if i < len(row) else ""
                if not value:
                    nulls[i] = True
                else:
                    types[i].add(classify(value))

    columns = []

    for column, column_types, has_null in zip(header, types, nulls):
        if column in TEXT_FIELDS:
            data_type = "TEXT"
        elif column in INTEGER_FIELDS:
            data_type = "INTEGER"
        elif column == "id" or column.endswith("_id"):
            data_type = "BIGINT"
        else:
            data_type = postgres_type(column_types)

        if column == "id":
            constraint = " PRIMARY KEY"
        elif has_null:
            constraint = ""
        else:
            constraint = " NOT NULL"

        columns.append(
            f"    {column} {data_type}{constraint}"
        )

    return (
        f"-- Tabela: {table_name}\n"
        f"-- Registros analisados: {rows}\n"
        f"DROP TABLE IF EXISTS {table_name};\n"
        f"CREATE TABLE {table_name} (\n"
        + ",\n".join(columns)
        + "\n);"
    )

def main():
    csv_files = sorted(DATA_DIR.glob("*.csv"))

    if not csv_files:
        raise FileNotFoundError(
            f"Nenhum CSV encontrado em: {DATA_DIR}"
        )

    schemas = []

    for csv_file in csv_files:
        print(f"Analisando: {csv_file.name}")
        schemas.append(generate_schema(csv_file))

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(
        "\n\n".join(schemas),
        encoding="utf8"
    )

    print(f"\n{len(csv_files)} tabelas processadas.")
    print(f"Schema salvo em: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()