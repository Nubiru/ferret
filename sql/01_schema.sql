-- =====================================================================
-- FeRReT — Schema (Parte 1, Eje I)
-- Base de Datos III — Proyecto Integrador
-- =====================================================================

-- EXTENSIONES
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 1. SUCURSAL
CREATE TABLE sucursal (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    direccion VARCHAR(200) NOT NULL,
    ciudad VARCHAR(80) NOT NULL,
    provincia VARCHAR(80) NOT NULL,
    telefono VARCHAR(30),
    es_deposito_central BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_apertura DATE NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

-- CAMION
CREATE TABLE camion (
    id SERIAL PRIMARY KEY,
    patente VARCHAR(10) NOT NULL UNIQUE,
    modelo VARCHAR(80) NOT NULL,
    capacidad_kg INTEGER NOT NULL CHECK (capacidad_kg > 0),
    ano_fabricacion SMALLINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- CARGO
CREATE TABLE cargo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    familia VARCHAR(30) NOT NULL,
    salario_base NUMERIC(12,2) NOT NULL CHECK (salario_base >= 0)
);

-- EMPLEADO
CREATE TABLE empleado (
    id SERIAL PRIMARY KEY,
    dni VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    apellido VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    fecha_ingreso DATE NOT NULL,
    fecha_baja DATE,
    cargo_id INTEGER NOT NULL REFERENCES cargo(id),
    sucursal_id INTEGER REFERENCES sucursal(id),
    supervisor_id INTEGER REFERENCES empleado(id),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT empleado_no_es_su_propio_jefe CHECK (supervisor_id <> id)
);

-- CATEGORIA
CREATE TABLE categoria (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    padre_id INTEGER REFERENCES categoria(id),
    UNIQUE (padre_id, nombre)
);

-- MARCA
CREATE TABLE marca (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
);

-- PRODUCTO
CREATE TABLE producto (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categoria(id),
    marca_id INTEGER REFERENCES marca(id),
    descripcion_larga TEXT,
    atributos JSONB NOT NULL DEFAULT '{}'::jsonb,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta TIMESTAMP NOT NULL DEFAULT NOW()
);

-- SKU
CREATE TABLE sku (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES producto(id) ON DELETE CASCADE,
    codigo_barras VARCHAR(20) NOT NULL UNIQUE,
    descripcion_variante VARCHAR(200) NOT NULL,
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    unidad_medida VARCHAR(20) NOT NULL,
    peso_gramos INTEGER,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- STOCK
CREATE TABLE stock (
    sku_id INTEGER NOT NULL REFERENCES sku(id) ON DELETE CASCADE,
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    cantidad INTEGER NOT NULL DEFAULT 0,
    stock_minimo INTEGER NOT NULL DEFAULT 0,
    ultima_actualizacion TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sku_id, sucursal_id)
);

-- CLIENTE
CREATE TABLE cliente (
    id SERIAL PRIMARY KEY,
    tipo_cliente VARCHAR(10) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    fecha_alta TIMESTAMP NOT NULL DEFAULT NOW(),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- VENTA
CREATE TABLE venta (
    id BIGSERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES cliente(id),
    empleado_vendedor_id INTEGER NOT NULL REFERENCES empleado(id),
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    fecha_venta TIMESTAMP NOT NULL,
    tipo_venta VARCHAR(10) NOT NULL,
    total NUMERIC(14,2) NOT NULL,
    medio_pago VARCHAR(30) NOT NULL
);

-- VENTA_LINEA
CREATE TABLE venta_linea (
    id BIGSERIAL PRIMARY KEY,
    venta_id BIGINT NOT NULL REFERENCES venta(id) ON DELETE CASCADE,
    sku_id INTEGER NOT NULL REFERENCES sku(id),
    cantidad INTEGER NOT NULL,
    precio_unitario NUMERIC(12,2) NOT NULL,
    subtotal NUMERIC(14,2) NOT NULL
);

-- MOVIMIENTO STOCK
CREATE TABLE movimiento_stock (
    id BIGSERIAL PRIMARY KEY,
    sku_id INTEGER NOT NULL REFERENCES sku(id),
    sucursal_id INTEGER NOT NULL REFERENCES sucursal(id),
    tipo VARCHAR(30) NOT NULL,
    cantidad INTEGER NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT NOW()
);


-- =========================================================
-- FIN
-- =========================================================