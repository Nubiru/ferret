-- =====================================================================
-- FeRReT — Schema (Parte 1, Eje I)
-- Base de Datos III — Proyecto Integrador
-- =====================================================================
-- Este es un BORRADOR INICIAL. El stream "A. Modelado & DER" debe
-- revisarlo, ajustarlo y mantenerlo. Buscar "REVISAR" para puntos
-- abiertos de decisión.
-- =====================================================================

-- Extensiones necesarias.
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- para EXCLUDE combinado (scalar = + range &&)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- habilitar si se decide sumar FTS
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- debe estar cargada también en shared_preload_libraries

-- =====================================================================
-- 1. UBICACIONES Y FLOTA
-- =====================================================================

CREATE TABLE sucursal (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL UNIQUE,
    direccion         VARCHAR(200) NOT NULL,
    ciudad            VARCHAR(80)  NOT NULL,
    provincia         VARCHAR(80)  NOT NULL,
    telefono          VARCHAR(30),
    es_deposito_central BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_apertura    DATE NOT NULL,
    activa            BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE camion (
    id                SERIAL PRIMARY KEY,
    patente           VARCHAR(10) NOT NULL UNIQUE,
    modelo            VARCHAR(80) NOT NULL,
    capacidad_kg      INTEGER NOT NULL CHECK (capacidad_kg > 0),
    ano_fabricacion   SMALLINT,
    activo            BOOLEAN NOT NULL DEFAULT TRUE
);

-- =====================================================================
-- 2. ORGANIGRAMA DE EMPLEADOS (recursivo por supervisor_id)
-- =====================================================================

CREATE TABLE cargo (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(60) NOT NULL UNIQUE,
    -- ejecutivo, administrativo, caja, venta, transporte, adquisicion, guardia
    familia           VARCHAR(30) NOT NULL,
    salario_base      NUMERIC(12,2) NOT NULL CHECK (salario_base >= 0)
);

CREATE TABLE empleado (
    id                SERIAL PRIMARY KEY,
    dni               VARCHAR(15) NOT NULL UNIQUE,
    nombre            VARCHAR(80) NOT NULL,
    apellido          VARCHAR(80) NOT NULL,
    email             VARCHAR(120) NOT NULL UNIQUE,   -- candidato a índice Hash
    fecha_ingreso     DATE NOT NULL,
    fecha_baja        DATE,
    cargo_id          INTEGER NOT NULL REFERENCES cargo(id),
    -- Los ejecutivos de casa central pueden tener sucursal_id NULL.
    sucursal_id       INTEGER REFERENCES sucursal(id),
    -- Auto-referencia: el CEO tiene supervisor_id NULL.
    supervisor_id     INTEGER REFERENCES empleado(id),
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT empleado_no_es_su_propio_jefe CHECK (supervisor_id <> id)
);

-- =====================================================================
-- 3. CATÁLOGO: CATEGORÍAS (recursivo) → PRODUCTO → SKU (variante)
-- =====================================================================

CREATE TABLE categoria (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    -- Auto-referencia para jerarquía. Las raíces tienen padre_id NULL.
    padre_id          INTEGER REFERENCES categoria(id) ON DELETE RESTRICT,
    UNIQUE (padre_id, nombre)  -- no repetir nombre bajo el mismo padre
);

CREATE TABLE marca (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(80) NOT NULL UNIQUE
);

-- Un "producto" es el concepto abstracto (ej. "Tornillo autoperforante").
-- Un "SKU" es una variante concreta con código de barras y precio.
CREATE TABLE producto (
    id                SERIAL PRIMARY KEY,
    nombre            VARCHAR(150) NOT NULL,
    categoria_id      INTEGER NOT NULL REFERENCES categoria(id),
    marca_id          INTEGER REFERENCES marca(id),
    descripcion_larga TEXT,  -- base para FTS si en Parte 2 se amplía
    -- Atributos variables del producto: material, medida, rosca, color, etc.
    -- Acá vive el índice GIN.
    atributos         JSONB NOT NULL DEFAULT '{}'::jsonb,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta        TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE sku (
    id                SERIAL PRIMARY KEY,
    producto_id       INTEGER NOT NULL REFERENCES producto(id) ON DELETE CASCADE,
    codigo_barras     VARCHAR(20) NOT NULL UNIQUE,   -- candidato a índice Hash
    descripcion_variante VARCHAR(200) NOT NULL,      -- ej. "caja x100, 6x1 pulgada"
    precio_unitario   NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    precio_alquiler_dia NUMERIC(12,2),               -- NULL si no es alquilable
    unidad_medida     VARCHAR(20) NOT NULL,          -- unidad, kg, m, caja, etc.
    peso_gramos       INTEGER,
    es_alquilable     BOOLEAN NOT NULL DEFAULT FALSE,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT sku_alquilable_precio CHECK (
        (es_alquilable = FALSE AND precio_alquiler_dia IS NULL)
        OR (es_alquilable = TRUE AND precio_alquiler_dia IS NOT NULL)
    )
);

-- =====================================================================
-- 4. STOCK POR SUCURSAL (N:M con atributos)
-- =====================================================================

CREATE TABLE stock (
    sku_id            INTEGER NOT NULL REFERENCES sku(id)      ON DELETE CASCADE,
    sucursal_id       INTEGER NOT NULL REFERENCES sucursal(id) ON DELETE RESTRICT,
    cantidad          INTEGER NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
    stock_minimo      INTEGER NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    ultima_actualizacion TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sku_id, sucursal_id)
);

-- =====================================================================
-- 5. CLIENTES (mayorista / minorista)
-- =====================================================================

CREATE TABLE cliente (
    id                SERIAL PRIMARY KEY,
    tipo_cliente      VARCHAR(10) NOT NULL CHECK (tipo_cliente IN ('minorista','mayorista')),
    nombre            VARCHAR(150) NOT NULL,
    email             VARCHAR(120) NOT NULL UNIQUE,  -- candidato a índice Hash
    telefono          VARCHAR(30),
    direccion         VARCHAR(200),
    ciudad            VARCHAR(80),
    -- Solo mayoristas:
    cuit              VARCHAR(15),
    razon_social      VARCHAR(150),
    limite_credito    NUMERIC(14,2),
    fecha_alta        TIMESTAMP NOT NULL DEFAULT NOW(),
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT cliente_mayorista_campos CHECK (
        (tipo_cliente = 'minorista')
        OR (tipo_cliente = 'mayorista' AND cuit IS NOT NULL)
    )
);

-- =====================================================================
-- 6. VENTAS
-- =====================================================================

CREATE TABLE venta (
    id                BIGSERIAL PRIMARY KEY,
    cliente_id        INTEGER NOT NULL REFERENCES cliente(id),
    empleado_vendedor_id INTEGER NOT NULL REFERENCES empleado(id),
    sucursal_id       INTEGER NOT NULL REFERENCES sucursal(id),
    fecha_venta       TIMESTAMP NOT NULL,   -- candidato a B-Tree
    tipo_venta        VARCHAR(10) NOT NULL CHECK (tipo_venta IN ('minorista','mayorista')),
    total             NUMERIC(14,2) NOT NULL CHECK (total >= 0),
    medio_pago        VARCHAR(30) NOT NULL
);

CREATE TABLE venta_linea (
    id                BIGSERIAL PRIMARY KEY,
    venta_id          BIGINT NOT NULL REFERENCES venta(id) ON DELETE CASCADE,
    sku_id            INTEGER NOT NULL REFERENCES sku(id),
    cantidad          INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario   NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    descuento_pct     NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (descuento_pct BETWEEN 0 AND 100),
    subtotal          NUMERIC(14,2) NOT NULL
);

-- =====================================================================
-- 7. COMPRAS A PROVEEDORES
-- =====================================================================

CREATE TABLE proveedor (
    id                SERIAL PRIMARY KEY,
    razon_social      VARCHAR(150) NOT NULL,
    cuit              VARCHAR(15)  NOT NULL UNIQUE,
    email             VARCHAR(120) NOT NULL,
    telefono          VARCHAR(30),
    direccion         VARCHAR(200),
    activo            BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orden_compra (
    id                BIGSERIAL PRIMARY KEY,
    proveedor_id      INTEGER NOT NULL REFERENCES proveedor(id),
    empleado_comprador_id INTEGER NOT NULL REFERENCES empleado(id),
    sucursal_destino_id INTEGER NOT NULL REFERENCES sucursal(id),
    fecha_orden       TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_recepcion   TIMESTAMP,
    estado            VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente','recibida','cancelada')),
    total             NUMERIC(14,2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE orden_compra_linea (
    id                BIGSERIAL PRIMARY KEY,
    orden_compra_id   BIGINT NOT NULL REFERENCES orden_compra(id) ON DELETE CASCADE,
    sku_id            INTEGER NOT NULL REFERENCES sku(id),
    cantidad          INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario   NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0)
);

-- =====================================================================
-- 8. VIAJES DE TRANSPORTE (logística interna entre sucursales)
-- =====================================================================

CREATE TABLE viaje (
    id                BIGSERIAL PRIMARY KEY,
    camion_id         INTEGER NOT NULL REFERENCES camion(id),
    chofer_id         INTEGER NOT NULL REFERENCES empleado(id),
    sucursal_origen_id INTEGER NOT NULL REFERENCES sucursal(id),
    sucursal_destino_id INTEGER NOT NULL REFERENCES sucursal(id),
    fecha_salida      TIMESTAMP NOT NULL,
    fecha_llegada     TIMESTAMP,
    estado            VARCHAR(20) NOT NULL CHECK (estado IN ('planificado','en_ruta','completado','cancelado')),
    CONSTRAINT viaje_origen_destino_distintos CHECK (sucursal_origen_id <> sucursal_destino_id)
);

-- =====================================================================
-- 9. MOVIMIENTOS DE STOCK (historial)
-- =====================================================================
-- Tabla "fact" que registra toda variación de stock.
-- Referencias opcionales a venta / orden / viaje según el origen.

CREATE TABLE movimiento_stock (
    id                BIGSERIAL PRIMARY KEY,
    sku_id            INTEGER NOT NULL REFERENCES sku(id),
    sucursal_id       INTEGER NOT NULL REFERENCES sucursal(id),
    tipo              VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada_compra','salida_venta','transferencia_entrada','transferencia_salida','ajuste')),
    cantidad          INTEGER NOT NULL,  -- puede ser negativo en ajustes
    fecha             TIMESTAMP NOT NULL DEFAULT NOW(),  -- candidato a B-Tree
    venta_id          BIGINT REFERENCES venta(id),
    orden_compra_id   BIGINT REFERENCES orden_compra(id),
    viaje_id          BIGINT REFERENCES viaje(id)
);

-- =====================================================================
-- 10. ALQUILER DE HERRAMIENTAS (GiST con EXCLUDE)
-- =====================================================================

CREATE TABLE alquiler (
    id                BIGSERIAL PRIMARY KEY,
    sku_id            INTEGER NOT NULL REFERENCES sku(id),
    cliente_id        INTEGER NOT NULL REFERENCES cliente(id),
    sucursal_id       INTEGER NOT NULL REFERENCES sucursal(id),
    empleado_id       INTEGER NOT NULL REFERENCES empleado(id),
    ventana           TSRANGE NOT NULL,          -- índice GiST + EXCLUDE
    precio_total      NUMERIC(12,2) NOT NULL CHECK (precio_total >= 0),
    estado            VARCHAR(20) NOT NULL CHECK (estado IN ('reservado','entregado','devuelto','cancelado')),
    -- El mismo SKU no puede estar alquilado a dos clientes en ventanas que se solapen.
    -- (btree_gist permite combinar = escalar con && de rango).
    EXCLUDE USING GIST (sku_id WITH =, ventana WITH &&)
);

-- =====================================================================
-- 11. PROMOCIONES (GiST con EXCLUDE sobre daterange)
-- =====================================================================

CREATE TABLE promocion (
    id                SERIAL PRIMARY KEY,
    producto_id       INTEGER NOT NULL REFERENCES producto(id) ON DELETE CASCADE,
    descripcion       VARCHAR(200) NOT NULL,
    descuento_pct     NUMERIC(5,2) NOT NULL CHECK (descuento_pct BETWEEN 0 AND 100),
    vigencia          DATERANGE NOT NULL,        -- índice GiST + EXCLUDE
    -- Un mismo producto no puede tener dos promos activas que se pisen.
    EXCLUDE USING GIST (producto_id WITH =, vigencia WITH &&)
);

-- =====================================================================
-- FIN DEL BORRADOR
-- =====================================================================
-- Puntos abiertos a revisar entre los 4:
--  1. ¿Precio del producto a nivel `sku` (como está) o con historial
--     de precios en tabla aparte (`precio_historia`)?
--  2. ¿Sumamos cuenta corriente para mayoristas (pagos parciales)?
--  3. ¿Auditoría/historial de cambios de stock más fina que `movimiento_stock`?
--  4. ¿`cliente_mayorista` como subtabla en vez de campos nullable?
--  5. Definir bien cuándo un SKU puede venderse y alquilarse a la vez.
-- =====================================================================
