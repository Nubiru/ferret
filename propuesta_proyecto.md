Proyecto Integrador - Parte 1
Unidad Curricular: Base de Datos III
Eje I: Optimización y SQL Avanzado

Objetivo: Construir una base sólida y optimizada bajo el paradigma relacional, aplicando técnicas de indexación avanzada y análisis de performance.

Consigna General
El proyecto debe implementarse en PostgreSQL. En esta fase, el foco está en el diseño del esquema, la carga masiva y la optimización de consultas complejas.
Deberán realizar grupos de hasta 5 personas.

1. Definición del Producto
Podrán elegir un tema propio, a elección, y deberá cumplir con los criterios detallados a continuación.
Entregables Técnicos (Requisitos)
A. Modelado y Estructura
Documentación del Concepto: Breve descripción de la problemática que resuelve la app.
Diagrama Entidad-Relación (DER): Exportado en imagen o PDF. Debe estar normalizado (3NF).

B. Carga Masiva de Datos
Poblado de Datos: Crear un script para insertar al menos 1.000.000 registros totales (ej: envíos 200.000, transacciones 200.000 o clientes 100.000, etc).
Objetivo: Sentir el peso de una consulta lenta para valorar el índice.

C. Estrategias de Indexación
Deben demostrar el uso y la justificación de:
B-Tree: Para búsquedas por rangos o igualdad (ej: id, fecha).
Hash: Para comparaciones de igualdad exacta en columnas de texto largo.
Y al menos uno de estos índices especializados:
GIN (Generalized Inverted Index): Aplicado sobre una columna tipo JSONB (ej: etiquetas de productos).
GiST: Aplicado sobre una columna de tipo rango (tsrange) o geometría (ej: coordenadas de entrega).

D. Análisis de Performance
Query Planner: Presentar el EXPLAIN ANALYZE de una consulta antes y después de aplicar los índices.
Visualización en Dalibo: Generar y adjuntar 2 diagramas usando el Postgres Explain Visualizer (PEV2) para identificar los "nodos" más costosos (Sequential Scans vs Index Scans).
Métricas con pg_stat_statements: Mostrar las 5 consultas más frecuentes o lentas del sistema.

E. SQL Avanzado (Lógica de Negocio)
Window Functions: Implementar al menos una métrica analítica (ej: Ranking de mejores vendedores o promedio de ventas)
CTE y Recursividad: Implementar una Consulta Recursiva para manejar una estructura jerárquica (ej: Organigrama de la empresa o categorías de productos anidadas).

Sugerencias de Temas 
Sugerencia 1: "GreenTrack Logistics" (Logística de Envíos)
El Desafío: Gestionar el movimiento de paquetes a través de una red de depósitos.
Componente Recursivo: Los Centros de Distribución están organizados jerárquicamente (Nodo Nacional -> Nodos Regionales -> Nodos Locales).
Uso de GIN: Búsqueda por palabras clave en una columna observaciones_destino (ej: "frágil", "refrigerado", "puerta 4") usando Full Text Search.
Uso de GiST: Gestión de la ventana_horaria de entrega del paquete mediante el tipo de dato Range (tsrange), para detectar solapamientos de horarios.
Sugerencia 2: "SkillTree Academy" (Plataforma Educativa)
El Desafío: Un sistema de cursos, categorías y seguimiento de alumnos.
Componente Recursivo: El Árbol de Categorías de los cursos (ej: Tecnología -> Programación -> Bases de Datos -> PostgreSQL).
Uso de GIN: Búsqueda de términos en el temario_detallado de cada curso para encontrar contenido específico rápidamente.
Uso de GiST: Control de la vigencia_matricula (fecha inicio y fin) de los alumnos usando Ranges (daterange), para validar accesos activos.


┌───────────────────────────┬─────────────┬───────────────────────────────────────────────────────────────────────────────────────────────┐   
  │            Rol            │ Responsable │                                          Entregables                                          │
  ├───────────────────────────┼─────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 🧱 Modelado & DER         │   Frederick1824  │ DER 3NF, DDL (schema.sql), documentación conceptual                                           │
  ├───────────────────────────┼─────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 📦 Carga masiva           │  LautaroAi │ Scripts de seed (seed.sql / Python con Faker), llegar al 1M, verificar integridad               │   
  ├───────────────────────────┼─────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ ⚡ Indexación &           │  marianof87  │ Índices (B-Tree, Hash, GIN, GiST), EXPLAIN ANALYZE antes/después, 2 Dalibo/PEV2,              │   
  │ Performance               │             │ pg_stat_statements                                                                            │   
  ├───────────────────────────┼─────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 🧠 SQL Avanzado           │ Nubiru   │ Window functions, CTEs recursivas, queries de negocio, validación con datos cargados          │   
  └───────────────────────────┴─────────────┴───────────────────────────────────────────────────────────────────────────────────────────────┘  