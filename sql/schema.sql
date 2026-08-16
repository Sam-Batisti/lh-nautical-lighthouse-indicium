-- Tabela: addresses
-- Registros analisados: 3998
DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    address_type TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    street TEXT NOT NULL,
    number INTEGER NOT NULL,
    complement TEXT,
    district TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL
);
-- Tabela: attributes
-- Registros analisados: 8
DROP TABLE IF EXISTS attributes;
CREATE TABLE attributes (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    data_type TEXT NOT NULL
);
-- Tabela: brands
-- Registros analisados: 12
DROP TABLE IF EXISTS brands;
CREATE TABLE brands (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: categories
-- Registros analisados: 14
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    parent_category_id BIGINT,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: customers
-- Registros analisados: 2000
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    id BIGINT PRIMARY KEY,
    person_type TEXT NOT NULL,
    legal_name TEXT NOT NULL,
    trade_name TEXT,
    tax_id TEXT NOT NULL,
    state_registration TEXT,
    email TEXT,
    phone TEXT,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: employees
-- Registros analisados: 15
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    id BIGINT PRIMARY KEY,
    full_name TEXT NOT NULL,
    cpf TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL,
    primary_location_id BIGINT NOT NULL,
    hire_date DATE NOT NULL,
    termination_date DATE,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: fiscal_invoices
-- Registros analisados: 34365
DROP TABLE IF EXISTS fiscal_invoices;
CREATE TABLE fiscal_invoices (
    id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    nfe_number TEXT NOT NULL,
    nfe_access_key TEXT NOT NULL,
    series INTEGER NOT NULL,
    issued_at TIMESTAMP NOT NULL,
    status TEXT NOT NULL,
    total_amount NUMERIC NOT NULL,
    xml_storage_uri TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: goods_receipt_items
-- Registros analisados: 4733
DROP TABLE IF EXISTS goods_receipt_items;
CREATE TABLE goods_receipt_items (
    id BIGINT PRIMARY KEY,
    goods_receipt_id BIGINT NOT NULL,
    purchase_order_item_id BIGINT NOT NULL,
    quantity_received NUMERIC NOT NULL
);
-- Tabela: goods_receipts
-- Registros analisados: 1548
DROP TABLE IF EXISTS goods_receipts;
CREATE TABLE goods_receipts (
    id BIGINT PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL,
    received_by_employee_id BIGINT NOT NULL,
    received_at TIMESTAMP NOT NULL,
    notes TEXT,
    created_at TIMESTAMP NOT NULL
);
-- Tabela: locations
-- Registros analisados: 6
DROP TABLE IF EXISTS locations;
CREATE TABLE locations (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    location_type TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    street TEXT NOT NULL,
    number INTEGER NOT NULL,
    complement TEXT,
    district TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country TEXT NOT NULL,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: order_items
-- Registros analisados: 147320
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_variant_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC NOT NULL,
    icms_rate NUMERIC NOT NULL,
    ipi_rate NUMERIC NOT NULL,
    line_total NUMERIC NOT NULL
);
-- Tabela: orders
-- Registros analisados: 48998
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,
    order_number TEXT NOT NULL,
    channel TEXT NOT NULL,
    customer_id BIGINT NOT NULL,
    salesperson_id BIGINT,
    location_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    subtotal NUMERIC NOT NULL,
    discount_amount NUMERIC NOT NULL,
    total NUMERIC NOT NULL,
    placed_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: payments
-- Registros analisados: 53546
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    method TEXT NOT NULL,
    installments INTEGER NOT NULL,
    amount NUMERIC NOT NULL,
    status TEXT NOT NULL,
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: product_suppliers
-- Registros analisados: 1520
DROP TABLE IF EXISTS product_suppliers;
CREATE TABLE product_suppliers (
    product_variant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    supplier_sku TEXT,
    last_quoted_cost NUMERIC NOT NULL,
    lead_time_days INTEGER NOT NULL,
    is_preferred BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: product_variants
-- Registros analisados: 1009
DROP TABLE IF EXISTS product_variants;
CREATE TABLE product_variants (
    id BIGINT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    sku TEXT NOT NULL,
    barcode_ean TEXT,
    sale_price NUMERIC NOT NULL,
    cost_price NUMERIC NOT NULL,
    weight_kg NUMERIC NOT NULL,
    icms_rate NUMERIC NOT NULL,
    ipi_rate NUMERIC NOT NULL,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: products
-- Registros analisados: 500
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    brand_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    ncm_code TEXT NOT NULL,
    unit_of_measure TEXT NOT NULL,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: purchase_order_items
-- Registros analisados: 6059
DROP TABLE IF EXISTS purchase_order_items;
CREATE TABLE purchase_order_items (
    id BIGINT PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL,
    product_variant_id BIGINT NOT NULL,
    quantity_ordered INTEGER NOT NULL,
    unit_cost NUMERIC NOT NULL,
    line_total NUMERIC NOT NULL
);
-- Tabela: purchase_orders
-- Registros analisados: 2000
DROP TABLE IF EXISTS purchase_orders;
CREATE TABLE purchase_orders (
    id BIGINT PRIMARY KEY,
    po_number TEXT NOT NULL,
    supplier_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    destination_location_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    currency TEXT NOT NULL,
    subtotal NUMERIC NOT NULL,
    total NUMERIC NOT NULL,
    placed_at TIMESTAMP NOT NULL,
    expected_delivery_at DATE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: return_items
-- Registros analisados: 1384
DROP TABLE IF EXISTS return_items;
CREATE TABLE return_items (
    id BIGINT PRIMARY KEY,
    return_id BIGINT NOT NULL,
    order_item_id BIGINT NOT NULL,
    quantity NUMERIC NOT NULL,
    action TEXT NOT NULL,
    exchange_variant_id BIGINT,
    unit_refund_amount NUMERIC NOT NULL
);
-- Tabela: returns
-- Registros analisados: 980
DROP TABLE IF EXISTS returns;
CREATE TABLE returns (
    id BIGINT PRIMARY KEY,
    return_number TEXT NOT NULL,
    order_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    received_at_location_id BIGINT NOT NULL,
    status TEXT NOT NULL,
    reason TEXT,
    total_refund_amount NUMERIC NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: stock_levels
-- Registros analisados: 6054
DROP TABLE IF EXISTS stock_levels;
CREATE TABLE stock_levels (
    product_variant_id BIGINT NOT NULL,
    location_id BIGINT NOT NULL,
    quantity_on_hand NUMERIC NOT NULL,
    reorder_point INTEGER,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: stock_movements
-- Registros analisados: 115312
DROP TABLE IF EXISTS stock_movements;
CREATE TABLE stock_movements (
    id BIGINT PRIMARY KEY,
    product_variant_id BIGINT NOT NULL,
    location_id BIGINT NOT NULL,
    movement_type TEXT NOT NULL,
    quantity NUMERIC NOT NULL,
    reference_table TEXT,
    reference_id BIGINT,
    employee_id BIGINT,
    notes TEXT,
    occurred_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL
);
-- Tabela: suppliers
-- Registros analisados: 25
DROP TABLE IF EXISTS suppliers;
CREATE TABLE suppliers (
    id BIGINT PRIMARY KEY,
    legal_name TEXT NOT NULL,
    trade_name TEXT,
    country TEXT NOT NULL,
    tax_id TEXT NOT NULL,
    tax_id_type TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
-- Tabela: variant_attribute_values
-- Registros analisados: 2018
DROP TABLE IF EXISTS variant_attribute_values;
CREATE TABLE variant_attribute_values (
    product_variant_id BIGINT NOT NULL,
    attribute_id BIGINT NOT NULL,
    value TEXT NOT NULL
);