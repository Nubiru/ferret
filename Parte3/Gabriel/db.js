// =====================================================================
// db.js — Conexion a PostgreSQL (ferret_db, la base PRINCIPAL del proyecto)
// =====================================================================
// Esta es la base relacional de los Ejes I y II (NO MongoDB: ese es el TP
// aparte). Eje III la cachea y Eje IV escribe sobre ella.
//
// PRIVILEGIO MINIMO POR DEFECTO (Eje II.D, end-to-end): la API se conecta
// como el rol restringido `ferret_api` (definido en rol_api.sql) SIN que haga
// falta exportar ninguna variable. Ese rol SOLO puede leer el catalogo,
// escribir en `producto` y ejecutar el procedure de venta; NO puede tocar
// venta/stock/cliente directamente ni borrar fisico. Es TCP local con
// password (peer auth no sirve para un rol que no coincide con el usuario OS).
//
// REQUISITO (una sola vez por maquina): crear el rol antes de arrancar:
//   psql -d ferret_db -f rol_api.sql
//
// Todo se puede sobreescribir por entorno (PGHOST, PGPORT, PGDATABASE,
// PGUSER, PGPASSWORD) para correr en otro host o como otro usuario.
// =====================================================================
import pg from 'pg';
const { Pool } = pg;

export const pool = new Pool({
  host:     process.env.PGHOST     || 'localhost',   // TCP (ferret_api usa password)
  port:     process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
  database: process.env.PGDATABASE || 'ferret_db',
  user:     process.env.PGUSER     || 'ferret_api',  // <- privilegio minimo por defecto
  password: process.env.PGPASSWORD || 'api_demo',
});

pool.on('error', (err) => {
  console.error('[pg] error inesperado en el pool:', err.message);
});
