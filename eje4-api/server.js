// =====================================================================
// server.js — API Express del Proyecto Integrador (Ejes III + IV)
// =====================================================================
// Stack: Express + PostgreSQL (ferret_db) + Redis.
//
//   GET    /api/productos       -> Eje III: lectura con Cache-Aside
//   POST   /api/productos       -> Eje IV : CREATE  (201) + invalida cache
//   PUT    /api/productos/:id   -> Eje IV : UPDATE  + invalida cache
//   DELETE /api/productos/:id   -> Eje IV : baja LOGICA (activo=false) + invalida
//
// El catalogo de productos es el caso de uso ideal de cache: mucha
// lectura, poca escritura, tolera consistencia eventual (3.1).
//
// Reparto: cache.js (cache-aside + invalidacion) = Gabriel. Este scaffold
// + el CRUD plano = companero de equipo.
// =====================================================================
import express from 'express';
import cors from 'cors';
import { pool } from './db.js';
import { initRedis } from './redisClient.js';
import { cacheAside, invalidarNamespace } from './cache.js';

const app = express();
app.use(cors());
app.use(express.json());

// Namespacing (3.4.A): claves separadas con ":" para simular "tablas".
const CLAVE_CATALOGO  = 'productos:catalogo';
const PATRON_PRODUCTOS = 'productos:*';

// ---------------------------------------------------------------------
// EJE III — Lectura con Cache-Aside
// ---------------------------------------------------------------------
// Query con JOINs + agregacion => candidata ideal a cachear (es "cara").
app.get('/api/productos', async (req, res) => {
  try {
    const { origen, dato } = await cacheAside(CLAVE_CATALOGO, async () => {
      const { rows } = await pool.query(`
        SELECT p.id, p.nombre,
               c.nombre AS categoria,
               m.nombre AS marca,
               MIN(s.precio_unitario) AS precio_desde,
               COUNT(s.id)            AS variantes
        FROM producto p
        JOIN categoria c ON c.id = p.categoria_id
        LEFT JOIN marca m ON m.id = p.marca_id
        LEFT JOIN sku   s ON s.producto_id = p.id AND s.activo
        WHERE p.activo
        GROUP BY p.id, c.nombre, m.nombre
        ORDER BY p.id
        LIMIT 100;
      `);
      return rows;
    });
    res.set('X-Cache', origen);                  // visible en Postman: cache | db
    res.json({ origen, total: dato.length, productos: dato });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------------------------------------------------------------------
// EJE IV — CREATE (POST)  -> 201 Created
// ---------------------------------------------------------------------
app.post('/api/productos', async (req, res) => {
  const { nombre, categoria_id, marca_id, atributos } = req.body;
  if (!nombre || !categoria_id) {
    return res.status(400).json({ error: 'nombre y categoria_id son obligatorios' });
  }
  try {
    const { rows } = await pool.query(
      `INSERT INTO producto (nombre, categoria_id, marca_id, atributos)
       VALUES ($1, $2, $3, COALESCE($4::jsonb, '{}'::jsonb))
       RETURNING *`,
      [nombre, categoria_id, marca_id ?? null, atributos ? JSON.stringify(atributos) : null]
    );
    const invalidadas = await invalidarNamespace(PATRON_PRODUCTOS); // Eje IV.4
    res.status(201).json({ producto: rows[0], cache_invalidada: invalidadas });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ---------------------------------------------------------------------
// EJE IV — UPDATE (PUT)  -> id en la URL, valor en el body
// ---------------------------------------------------------------------
app.put('/api/productos/:id', async (req, res) => {
  const { id } = req.params;
  const { nombre } = req.body;
  if (!nombre) return res.status(400).json({ error: 'nombre es obligatorio' });
  try {
    const { rows } = await pool.query(
      `UPDATE producto SET nombre = $1 WHERE id = $2 RETURNING *`,
      [nombre, id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'producto no encontrado' });
    const invalidadas = await invalidarNamespace(PATRON_PRODUCTOS);
    res.json({ producto: rows[0], cache_invalidada: invalidadas });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ---------------------------------------------------------------------
// EJE IV — DELETE (baja LOGICA, nunca DELETE FROM)
// ---------------------------------------------------------------------
app.delete('/api/productos/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const { rows } = await pool.query(
      `UPDATE producto SET activo = false
       WHERE id = $1 AND activo = true
       RETURNING id, nombre, activo`,
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'producto no encontrado o ya inactivo' });
    }
    const invalidadas = await invalidarNamespace(PATRON_PRODUCTOS);
    res.json({ baja_logica: rows[0], cache_invalidada: invalidadas });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ---------------------------------------------------------------------
const PORT = process.env.PORT || 3000;
await initRedis();                               // intenta Redis; si falla, sigue sin cache
app.listen(PORT, () => console.log(`[api] escuchando en http://localhost:${PORT}`));

export { app };
