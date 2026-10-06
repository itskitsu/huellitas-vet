-- =====================================================================
-- Huellitas Vet · 01 · Tablas, datos de ejemplo y festivos
-- Requisitos: PostgreSQL 14+. (pgvector solo se necesita para el RAG
-- y lo usa el nodo PGVector Store; ver sql/00_extensiones.sql)
-- Es seguro ejecutarlo más de una vez (CREATE ... IF NOT EXISTS).
-- =====================================================================

CREATE TABLE IF NOT EXISTS clientes (
  id             serial PRIMARY KEY,
  canal          text NOT NULL,              -- 'telegram' | 'whatsapp'
  usuario_id     text NOT NULL,              -- chat id (Telegram) o número (WhatsApp)
  nombre         text,
  fecha_creacion timestamp NOT NULL DEFAULT now(),
  UNIQUE (canal, usuario_id)
);

CREATE TABLE IF NOT EXISTS mascotas (
  id         serial PRIMARY KEY,
  cliente_id integer NOT NULL REFERENCES clientes(id),
  nombre     text NOT NULL,
  especie    text,                           -- perro | gato
  tamano     text,                           -- pequeno | mediano | grande
  sexo       text,
  peso_kg    numeric,
  raza       text,
  edad       text
);

CREATE TABLE IF NOT EXISTS servicios (
  codigo        text PRIMARY KEY,
  nombre        text NOT NULL,
  tipo          text NOT NULL CHECK (tipo IN ('peluqueria','cirugia','vacunacion','consulta')),
  profesional   text NOT NULL,
  dias_semana   integer[] NOT NULL,          -- ISO: 1 = lunes ... 6 = sábado
  hora_inicio   time NOT NULL,
  hora_fin      time NOT NULL,
  dur_pequeno   integer NOT NULL,            -- minutos
  dur_mediano   integer NOT NULL,
  dur_grande    integer NOT NULL,
  cupos_dia     integer,                     -- NULL = sin límite diario
  instrucciones text
);

CREATE TABLE IF NOT EXISTS citas (
  id                        serial PRIMARY KEY,
  cliente_id                integer NOT NULL REFERENCES clientes(id),
  mascota_id                integer REFERENCES mascotas(id),
  tipo_servicio             text NOT NULL CHECK (tipo_servicio IN ('peluqueria','cirugia','vacunacion','consulta')),
  servicio                  text NOT NULL,
  profesional               text NOT NULL,
  fecha_hora_inicio         timestamp NOT NULL,
  fecha_hora_fin            timestamp NOT NULL,
  estado                    text NOT NULL DEFAULT 'agendada'
                            CHECK (estado IN ('agendada','completada','cancelada','no_asistio')),
  calendar_event_id         text,
  instrucciones_enviadas    boolean NOT NULL DEFAULT false,
  recordatorio_24h_enviado  boolean NOT NULL DEFAULT false,
  recordatorio_2h_enviado   boolean NOT NULL DEFAULT false,
  recordatorio_ayuno_enviado boolean NOT NULL DEFAULT false,
  fecha_creacion            timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS citas_inicio_idx ON citas (fecha_hora_inicio) WHERE estado = 'agendada';

CREATE TABLE IF NOT EXISTS turnos (
  id             serial PRIMARY KEY,
  fecha          date NOT NULL,
  numero         integer NOT NULL,
  cliente_id     integer NOT NULL REFERENCES clientes(id),
  mascota_id     integer REFERENCES mascotas(id),
  motivo         text,
  estado         text NOT NULL DEFAULT 'en_espera'
                 CHECK (estado IN ('en_espera','llamado','atendido','no_asistio','expirado')),
  aviso_enviado  boolean NOT NULL DEFAULT false,
  hora_solicitud timestamp NOT NULL DEFAULT now(),
  hora_llamado   timestamp,
  hora_atencion  timestamp,
  UNIQUE (fecha, numero)
);

CREATE TABLE IF NOT EXISTS vacunas (
  id                 serial PRIMARY KEY,
  mascota_id         integer NOT NULL REFERENCES mascotas(id),
  tipo               text,
  nombre             text NOT NULL,
  fecha_aplicacion   date NOT NULL,
  fecha_proxima      date,
  recordatorio_enviado boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS festivos (
  fecha  date PRIMARY KEY,
  nombre text NOT NULL
);

-- ---------------------------------------------------------------------
-- Catálogo de ejemplo (datos ficticios)
-- ---------------------------------------------------------------------
INSERT INTO servicios (codigo, nombre, tipo, profesional, dias_semana, hora_inicio, hora_fin,
                       dur_pequeno, dur_mediano, dur_grande, cupos_dia, instrucciones) VALUES
 ('bano_completo','Baño completo','peluqueria','Camila (peluquera)','{1,2,3,4,5,6}','08:00','17:00',60,90,120,NULL,
  'Trae a tu mascota con collar o arnés y su carné de vacunas al día.'),
 ('bano_corte','Baño y corte','peluqueria','Camila (peluquera)','{1,2,3,4,5,6}','08:00','17:00',90,120,150,NULL,
  'Indica el tipo de corte que prefieres al llegar.'),
 ('bano_gato','Baño de gato','peluqueria','Camila (peluquera)','{2,4,6}','08:00','12:00',60,60,60,NULL,
  'Los gatos deben llegar en transportadora.'),
 ('vacuna','Vacunación','vacunacion','Dr. Andrés (veterinario)','{1,2,3,4,5,6}','08:00','17:00',30,30,30,NULL,
  'La mascota debe estar sana. Trae el carné de vacunas.'),
 ('desparasitacion','Desparasitación','vacunacion','Dr. Andrés (veterinario)','{1,2,3,4,5,6}','08:00','17:00',30,30,30,NULL,
  'Indica el peso aproximado de tu mascota.'),
 ('esterilizacion','Esterilización','cirugia','Dra. Valentina (cirujana)','{2,4}','07:30','12:00',90,120,150,2,
  'Ayuno de sólidos 8 horas y de agua 4 horas antes de la cirugía. Llega a las 7:30 am.'),
 ('profilaxis','Profilaxis dental','cirugia','Dra. Valentina (cirujana)','{3,5}','07:30','12:00',60,90,120,2,
  'Ayuno de sólidos 8 horas antes del procedimiento.')
ON CONFLICT (codigo) DO NOTHING;

-- ---------------------------------------------------------------------
-- Festivos de Colombia (revisa y completa cada año con el calendario oficial)
-- ---------------------------------------------------------------------
INSERT INTO festivos (fecha, nombre) VALUES
 ('2026-10-12','Día de la Raza'),
 ('2026-11-02','Todos los Santos'),
 ('2026-11-16','Independencia de Cartagena'),
 ('2026-12-08','Inmaculada Concepción'),
 ('2026-12-25','Navidad')
ON CONFLICT (fecha) DO NOTHING;
