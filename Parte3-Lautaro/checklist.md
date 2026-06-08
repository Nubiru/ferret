## Checklist: Integración de Caché con Redis (Proyecto Integrador - Parte 3)

Esta sección detalla el progreso de la implementación de la capa de persistencia políglota utilizando Redis como almacén clave-valor en memoria.

>[!IMPORTANT]
> Antes que nada, instalar los paquetes de Node.js requeridos con `npm install express pg cors redis@5` (la versión de paquete de redis 5.12.1 es compatible con la de servidor 5.0.14.1)

### 1. Fase de Diseño y Selección
- [x] Identificamos 1 o 2 endpoints estratégicos para cachear (alta frecuencia de lectura, baja de escritura).
- [x] Listado de endpoints cacheados:
  - *Endpoint 1:* `http://localhost:3000/api/catalogo`
  - *Endpoint 2:* `http://localhost:3000/api/catalogo/producto/:id`
- [x] Asegurar que el caso de uso soporta **consistencia eventual** (tolera desactualización de 1 o 2 minutos sin romper el sistema).
>[!IMPORTANT]
>Se creó una función `catalogo_productos()` para que la consulta de los endpoints fuese menos verbosa y se pudiese centralizar la lógica en el backend. La misma se encuentra adjunta en el s `funcion_catalogo.sql`

### 2. Configuración (Setup)
- [x] Instalamos el cliente de Redis en nuestro proyecto.
- [x] Establecemos conexión exitosa con el servidor de Redis (Local o Cloud).
- [x] Implementamos **Manejo de Errores (Fallback)**: Si Redis se cae, la aplicación registra el error pero sigue funcionando, consultando directamente la base de datos principal.

### 3. Implementación del Patrón Cache-Aside
- [x] **Consulta a la Caché:** El endpoint verifica primero si la clave existe en Redis.
- [x] **Cache HIT:** Si el dato existe, se retorna inmediatamente al cliente (se evita ir a la DB).
- [x] **Cache MISS (Consulta a la DB):** Si el dato NO existe, el sistema realiza la consulta a la base de datos principal (PostgreSQL, MongoDB, etc.).
- [x] **Población de la Caché:** Guardamos el resultado obtenido de la base de datos en Redis.
- [x] Devolver la respuesta final al cliente en todos los flujos.

### 4. Buenas Prácticas Técnicas
- [x] **Nomenclatura (Namespacing):** Utilizamos el estándar de separación con dos puntos (`:`) para las claves. *(Ejemplo: `users:123` o `products:list:active`)*.
- [x] **Asignación de TTL:** Toda clave guardada en Redis tiene un tiempo de vida (Time-To-Live) configurado.