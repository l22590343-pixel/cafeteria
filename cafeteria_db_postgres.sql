-- ================================================================
--  INSTRUCCIONES:
--  1. En pgAdmin, crea la base de datos "cafeteria_db" manualmente
--  2. Haz doble clic en cafeteria_db para conectarte a ella
--  3. Abre Query Tool (ícono de rayo) y ejecuta TODO este script
-- ================================================================

-- Eliminar tablas si ya existen (para empezar limpio)
DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS usuarios;

-- Eliminar tipos si ya existen
DROP TYPE IF EXISTS rol_tipo;
DROP TYPE IF EXISTS estado_tipo;
DROP TYPE IF EXISTS metodo_tipo;

-- Crear tipos ENUM
CREATE TYPE rol_tipo    AS ENUM ('admin', 'cliente');
CREATE TYPE estado_tipo AS ENUM ('preparacion', 'listo', 'entregado');
CREATE TYPE metodo_tipo AS ENUM ('efectivo', 'tarjeta');

-- Tabla usuarios
CREATE TABLE usuarios (
  id       SERIAL PRIMARY KEY,
  nombre   VARCHAR(100) NOT NULL,
  usuario  VARCHAR(50)  NOT NULL UNIQUE,
  pass     VARCHAR(255) NOT NULL,
  rol      rol_tipo     NOT NULL DEFAULT 'cliente',
  creado   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- Tabla productos
CREATE TABLE productos (
  id       SERIAL PRIMARY KEY,
  nombre   VARCHAR(100)   NOT NULL,
  cat      VARCHAR(50)    NOT NULL DEFAULT 'Bebida',
  precio   NUMERIC(10,2)  NOT NULL,
  stock    INTEGER        NOT NULL DEFAULT 0,
  img_url  TEXT,
  activo   BOOLEAN        NOT NULL DEFAULT TRUE
);

-- Tabla pedidos
CREATE TABLE pedidos (
  id          SERIAL PRIMARY KEY,
  usuario_id  INTEGER        NOT NULL REFERENCES usuarios(id),
  total       NUMERIC(10,2)  NOT NULL,
  estado      estado_tipo    NOT NULL DEFAULT 'preparacion',
  metodo_pago metodo_tipo    NOT NULL DEFAULT 'efectivo',
  fecha       TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

-- Tabla detalle_pedido
CREATE TABLE detalle_pedido (
  id          SERIAL PRIMARY KEY,
  pedido_id   INTEGER        NOT NULL REFERENCES pedidos(id),
  producto_id INTEGER        NOT NULL REFERENCES productos(id),
  nombre_prod VARCHAR(100)   NOT NULL,
  qty         INTEGER        NOT NULL,
  precio_unit NUMERIC(10,2)  NOT NULL,
  subtotal    NUMERIC(10,2)  NOT NULL
);

-- Índices
CREATE INDEX idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX idx_detalle_pedido  ON detalle_pedido(pedido_id);
CREATE INDEX idx_pedidos_estado  ON pedidos(estado);

-- Datos iniciales
INSERT INTO usuarios (nombre, usuario, pass, rol) VALUES
  ('Administrador', 'admin',   'admin123', 'admin'),
  ('Cliente Demo',  'cliente', '1234',     'cliente');

INSERT INTO productos (nombre, cat, precio, stock) VALUES
  ('Café Americano', 'Bebida',   30.00, 20),
  ('Latte',          'Bebida',   40.00, 15),
  ('Pan dulce',      'Alimento', 25.00, 30),
  ('Galleta',        'Alimento', 20.00, 12);

-- Verificar que todo quedó bien
SELECT 'USUARIOS:' AS resultado;
SELECT id, nombre, usuario, rol FROM usuarios;

SELECT 'PRODUCTOS:' AS resultado;
SELECT id, nombre, cat, precio, stock FROM productos;

SELECT 'TABLAS CREADAS:' AS resultado;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;