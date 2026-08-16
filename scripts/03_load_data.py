# Questão 3 | Carregamento dos CSVs no PostgreSQL

# Carrego todos os CSVs nas tabelas criadas na Questão 2.
# Sem limpeza ou tratamento dos dados.
# Para a carga, utilizo o comando COPY do PostgreSQL.

import psycopg2
from pathlib import Path

DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "lh_nautical"
DB_USER = "postgres"
DB_PASSWORD = "postgres"

CSV_DIR = Path(r"C:\Users\lenovo\OneDrive\Desktop\Lighthouse\1-lh_nautical_csv")

def main():
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    conn.set_client_encoding("UTF8")
    cur = conn.cursor()
    csv_files = sorted(CSV_DIR.glob("*.csv"))

    if not csv_files:
        raise FileNotFoundError(f"Nenhum CSV encontrado em: {CSV_DIR}")

    try:
        for csv_path in csv_files:
            table_name = csv_path.stem
            print(f"Carregando: {table_name}")

            with csv_path.open("rb") as file:
                cur.copy_expert(
                    f"COPY {table_name} FROM STDIN WITH (FORMAT csv, HEADER true)",
                    file
                )

            cur.execute(f"SELECT COUNT(*) FROM {table_name}")
            total = cur.fetchone()[0]
            print(f"{table_name}: {total} linhas carregadas")

        conn.commit()
        print(f"\nCarga concluída. {len(csv_files)} tabelas processadas.")

    except Exception:
        conn.rollback()
        print("\nErro durante a carga. Nenhuma alteração foi confirmada.")
        raise

    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()