const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
// Importamos el cliente de Redis
const { createClient } = require('redis');

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
    user: 'postgres',        // Tu usuario de Postgres
    host: 'localhost',
    database: 'ferret_pruebas',    // El nombre de tu DB
    password: '-byGalos-21',    // Tu clave secreta
    port: 5432,
});

// Creamos y conectamos el cliente de Redis
const redisClient = createClient({
    url: 'redis://127.0.0.1:6379'
});

// Escuchamos errores y confirmamos la conexión exitosa
redisClient.on('error', (err) => console.log('Error en Redis Client', err));
redisClient.connect().then(() => console.log('Conectado exitosamente a Redis'));

// GET: Obtener el catálogo de productos con paginación
app.get('/api/catalogo', async (req, res) => {
    try {
        // 1. Petición del cliente: La App necesita un página con 10 productos
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const offset = (page - 1) * limit;

        // Instrucciones Técnicas y Buenas Prácticas: A. Nomenclatura de Claves (Keyspace Namespacing)
        const cacheKey = `catalogo:page:${page}:limit:${limit}`;
        
        // 2. Consulta a la Caché
        const cachedData = await redisClient.get(cacheKey);
        
        // Cache HIT
        if (cachedData) {
            console.log(`Sirviendo página ${page} desde Redis`);
            return res.json(JSON.parse(cachedData)); 
        }
        // Cache MISS:  Si el dato NO existe, se avanza al paso 3.
        
        // 3. Consulta a la Base de Datos
        console.log(`Sirviendo página ${page} desde PostgreSQL (Disco)`);
        const result = await pool.query(
            'SELECT * FROM catalogo_productos() LIMIT $1 OFFSET $2', 
            [limit, offset]
        );

        // 4. Población de la Caché - Instrucciones Técnicas y Buenas Prácticas: B. Estrategia de Expiración
        await redisClient.setEx(cacheKey, 120, JSON.stringify(result.rows));

        // 5. Respuesta
        res.json(result.rows);

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error interno en el servidor' });
    }
});

app.listen(3000, () => console.log('Backend corriendo en http://localhost:3000/api/catalogo?page=10&limit=10 modifica los parámetros para probar la paginación'));

// GET: Obtener un producto específico
app.get('/api/catalogo/producto/:id', async (req, res) => {
    try {
        const id_producto = req.params.id;
        // Instrucciones Técnicas y Buenas Prácticas: A. Nomenclatura de Claves (Keyspace Namespacing)
        const cacheKey = `catalogo:producto:${id_producto}`;
        
        // 2. Consulta a la Caché
        const cachedData = await redisClient.get(cacheKey);
        
        // Cache HIT
        if (cachedData) {
            console.log(`Sirviendo producto ${id_producto} desde Redis`);
            return res.json(JSON.parse(cachedData)); 
        }
        // Cache MISS:  Si el dato NO existe, se avanza al paso 3.
        
        // 3. Consulta a la Base de Datos
        console.log(`Sirviendo producto ${id_producto} desde PostgreSQL (Disco)`);
        const result = await pool.query(
            'SELECT * FROM catalogo_productos() WHERE id_producto = $1', 
            [id_producto]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Producto no encontrado' });
        }

        // 4. Población de la Caché - Instrucciones Técnicas y Buenas Prácticas: B. Estrategia de Expiración
        await redisClient.setEx(cacheKey, 120, JSON.stringify(result.rows));

        // 5. Respuesta
        res.json({
            mensaje: 'Producto encontrado',
            producto: result.rows[0]
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error interno en el servidor' });
    } 
});

app.listen(3000, () => console.log('Backend corriendo en http://localhost:3000/api/catalogo/producto agrega el /id del producto al final de la URL'));