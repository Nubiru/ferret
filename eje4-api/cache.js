// =====================================================================
// cache.js — Logica de cache (la parte "inteligente" del backend)
// =====================================================================
// Responsable: Gabriel (@Nubiru)
//
//   Eje III  -> patron Cache-Aside (Lazy Loading)        [cacheAside]
//   Eje IV   -> Invalidacion Selectiva (keys + del)      [invalidarNamespace]
//
// El resto del backend (scaffold Express, conexiones, CRUD plano) es de
// un companero; este archivo es el nucleo evaluado de los Ejes III y IV.
// =====================================================================
import { getRedis, redisDisponible } from './redisClient.js';

// Parte 3 · Seccion 4.B: "Un cache sin vencimiento es un bug de memoria
// esperando a ocurrir." Todo dato cacheado lleva TTL.
export const TTL_SEGUNDOS = 60;

// ---------------------------------------------------------------------
// EJE III — Patron Cache-Aside (Lazy Loading)
// ---------------------------------------------------------------------
// Recibe la clave Redis y una funcion `cargarDesdeDB` que hace la query
// lenta. Implementa el algoritmo exacto de la consigna:
//   1. Consulta a la cache
//   2. HIT  -> devuelve de Redis (no toca la DB)
//   3. MISS -> consulta la DB
//   4. Pobla la cache con TTL
//   5. Devuelve el dato
// Devuelve { origen, dato } para que el endpoint pueda mostrar HIT/MISS.
export async function cacheAside(clave, cargarDesdeDB, ttl = TTL_SEGUNDOS) {
  const redis = getRedis();

  // Fallback (3.2.C): sin Redis, vamos derecho a la DB. La app no se cae.
  if (!redis || !redisDisponible()) {
    return { origen: 'db (redis-caido)', dato: await cargarDesdeDB() };
  }

  // 2. Consulta a la cache
  try {
    const cacheado = await redis.get(clave);
    if (cacheado !== null) {
      return { origen: 'cache', dato: JSON.parse(cacheado) }; // CACHE HIT
    }
  } catch (e) {
    console.error('[cache] error leyendo Redis; caigo a DB:', e.message);
    return { origen: 'db (error-redis)', dato: await cargarDesdeDB() };
  }

  // 3. CACHE MISS -> consulta a la DB principal
  const dato = await cargarDesdeDB();

  // 4. Poblacion de la cache con TTL
  try {
    await redis.set(clave, JSON.stringify(dato), { EX: ttl });
  } catch (e) {
    console.error('[cache] no pude poblar Redis (sigo igual):', e.message);
  }

  // 5. Respuesta
  return { origen: 'db', dato };
}

// ---------------------------------------------------------------------
// EJE IV — Invalidacion Selectiva
// ---------------------------------------------------------------------
// Parte 4 · Seccion 4: "Queda absolutamente PROHIBIDO el uso de
// redisClient.flushDb()". Solo borramos las claves del namespace afectado
// (ej. 'productos:*'), protegiendo sesiones y otros datos en memoria.
//
// Usa keys() + del() como pide la consigna textualmente.
// (Nota prod: en datasets grandes conviene SCAN/scanIterator en vez de
//  KEYS para no bloquear el hilo de Redis; para este TP, KEYS cumple.)
export async function invalidarNamespace(patron) {
  const redis = getRedis();
  if (!redis || !redisDisponible()) return 0;
  try {
    const claves = await redis.keys(patron); // ej: 'productos:*'
    if (claves.length === 0) return 0;
    await redis.del(claves);
    return claves.length;
  } catch (e) {
    console.error('[cache] error invalidando', patron, '->', e.message);
    return 0;
  }
}
