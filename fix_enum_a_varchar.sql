-- ================================================================
--  EJECUTA ESTE SCRIPT si ya tienes la base de datos creada
--  y te sale el error de "tipo metodo_tipo" o "tipo estado_tipo"
--
--  Esto convierte las columnas ENUM a VARCHAR (más compatible con JDBC)
--  Abre el Query Tool de cafeteria_db en pgAdmin y ejecuta todo esto
-- ================================================================

-- 1. Convertir columnas de pedidos
ALTER TABLE pedidos
  ALTER COLUMN estado TYPE VARCHAR(20) USING estado::text,
  ALTER COLUMN metodo_pago TYPE VARCHAR(20) USING metodo_pago::text;

-- 2. Convertir columna rol en usuarios
ALTER TABLE usuarios
  ALTER COLUMN rol TYPE VARCHAR(10) USING rol::text;

-- 3. Defaults
ALTER TABLE pedidos
  ALTER COLUMN estado SET DEFAULT 'preparacion',
  ALTER COLUMN metodo_pago SET DEFAULT 'efectivo';

ALTER TABLE usuarios
  ALTER COLUMN rol SET DEFAULT 'cliente';

-- 4. Ahora sí eliminar ENUMs
DROP TYPE IF EXISTS estado_tipo;
DROP TYPE IF EXISTS metodo_tipo;
DROP TYPE IF EXISTS rol_tipo;