import express from 'express';
import cors from 'cors';
import { MongoClient } from 'mongodb';

const app = express();
app.use(cors());
app.use(express.json());

// ToDo 1: URI de conexión local por defecto de MongoDB
const uri = "mongodb://localhost:27017";
const client = new MongoClient(uri);

app.get('/api/reporte-ventas', async (req, res) => {
  try {
    await client.connect();

    // ToDo 2: base de datos y colección correctas
    const database = client.db("ferret_hardware"); // Nombre de la DB
    const ventas = database.collection("ventas");  // Nombre de la colección

    // ToDo 3: Pipeline exportado desde Compass (los 5 stages)
    const pipeline = [
      // Stage 1 ($match): solo ventas con precio > 0
      { $match: { precio: { $gt: 0 } } },

      // Stage 2 ($project): categoría, cantidad y recaudacionVenta = precio * cantidad
      {
        $project: {
          categoria: 1,
          cantidad: 1,
          recaudacionVenta: { $multiply: ["$precio", "$cantidad"] }
        }
      },

      // Stage 3 ($group): agrupar por categoría; total, items y promedio (ticketPromedio)
      {
        $group: {
          _id: "$categoria",
          totalRecaudado: { $sum: "$recaudacionVenta" },
          cantidadItems: { $sum: "$cantidad" },
          ticketPromedio: { $avg: "$recaudacionVenta" }
        }
      },

      // Stage 4 ($match): doble filtrado — el campo ya se llama totalRecaudado en este punto
      { $match: { totalRecaudado: { $gt: 315 } } },

      // Stage 5 ($sort): de mayor a menor recaudación
      { $sort: { totalRecaudado: -1 } }
    ];

    const reporte = await ventas.aggregate(pipeline).toArray();
    res.status(200).json(reporte);
  } catch (error) {
    console.error("Error en la base de datos:", error);
    res.status(500).json({ error: "Error interno del servidor" });
  } finally {
    await client.close();
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Servidor de Datos activo en http://localhost:${PORT}`);
});
