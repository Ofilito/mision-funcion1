-- Misión Función · Esquema D1 (SQLite) · Centro Educativo Dos Bocas
-- Ejecutar UNA vez en: Cloudflare > Storage & Databases > D1 > (tu base) > Console

CREATE TABLE IF NOT EXISTS students (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT    NOT NULL,                 -- nombre tal como lo escribió el estudiante
  name_key   TEXT    NOT NULL UNIQUE,          -- nombre normalizado (minúsculas, sin tildes) = identidad
  device     TEXT,                             -- último dispositivo
  unlocked   INTEGER NOT NULL DEFAULT 1,       -- siguiente nivel disponible (1..6)
  total      INTEGER NOT NULL DEFAULT 0,       -- suma de los 5 niveles (solo si terminó el nivel 5)
  grade      REAL    NOT NULL DEFAULT 0,       -- nota final MEDUCA
  last_date  TEXT    NOT NULL DEFAULT '',
  completed  INTEGER NOT NULL DEFAULT 0,
  created_at TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Resultado vigente por estudiante y nivel (igual que el juego: el último intento reemplaza)
CREATE TABLE IF NOT EXISTS level_results (
  student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  level      INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
  score      INTEGER NOT NULL,
  grade      REAL    NOT NULL,
  date_text  TEXT    NOT NULL DEFAULT '',
  ts         INTEGER NOT NULL DEFAULT 0,       -- marca de tiempo del cliente (evita que un dispositivo viejo pise datos nuevos)
  updated_at TEXT    NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (student_id, level)
);

-- Historial de TODOS los intentos (auditoría)
CREATE TABLE IF NOT EXISTS attempts (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  level      INTEGER NOT NULL,
  score      INTEGER NOT NULL,
  grade      REAL    NOT NULL,
  device     TEXT,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_attempts_student ON attempts(student_id, level);
CREATE INDEX IF NOT EXISTS idx_results_student  ON level_results(student_id);
