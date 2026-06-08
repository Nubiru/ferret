// =====================================================================
// redisClient.js — Conexion a Redis con MANEJO DE FALLBACK
// =====================================================================
// Parte 3 · Seccion 2.C (Setup):
//   "Si Redis se cae, la aplicacion registra el error pero SIGUE
//    funcionando, consultando directamente la base de datos principal."
//
// Por eso la conexion nunca tira la app: si falla, marcamos `disponible`
// en false y cache.js cae a la DB de forma transparente.
// =====================================================================
import { createClient } from 'redis';

let client = null;
let disponible = false;

export async function initRedis() {
  const url = process.env.REDIS_URL || 'redis://localhost:6379';
  client = createClient({ url });

  // Si Redis se cae EN CALIENTE, no rompemos: solo bajamos la bandera.
  client.on('error', (err) => {
    if (disponible) console.error('[redis] se perdio la conexion:', err.message);
    disponible = false;
  });
  client.on('ready', () => { disponible = true; });

  try {
    await client.connect();
    disponible = true;
    console.log('[redis] conectado a', url);
  } catch (e) {
    disponible = false;
    console.error('[redis] no se pudo conectar; la app sigue SIN cache:', e.message);
  }
  return client;
}

export function getRedis() { return client; }
export function redisDisponible() { return disponible; }
