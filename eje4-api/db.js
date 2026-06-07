// =====================================================================
// db.js — Conexion a PostgreSQL (ferret_db, la base PRINCIPAL del proyecto)
// =====================================================================
// Esta es la base relacional de los Ejes I y II (NO MongoDB: ese es el TP
// aparte). Eje III la cachea y Eje IV escribe sobre ella.
//
// Por defecto usa el socket unix local (autenticacion peer, sin password),
// igual que `psql -d ferret_db`. En otro host se puede sobreescribir todo
// por variables de entorno (PGHOST, PGPORT, PGUSER, PGPASSWORD).
// =====================================================================
import pg from 'pg';
const { Pool } = pg;

export const pool = new Pool({
  host:     process.env.PGHOST     || '/var/run/postgresql', // socket => peer auth
  port:     process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
  database: process.env.PGDATABASE || 'ferret_db',
  user:     process.env.PGUSER     || process.env.USER,
  password: process.env.PGPASSWORD,            // undefined en peer auth local
});

pool.on('error', (err) => {
  console.error('[pg] error inesperado en el pool:', err.message);
});
