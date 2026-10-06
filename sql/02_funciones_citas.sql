-- =====================================================================
-- Huellitas Vet · 02 · Funciones de citas (agenda)
-- Depende de: 01_tablas.sql
-- =====================================================================

-- Huecos libres de un servicio en una fecha, sin cruces con otras citas
-- del mismo profesional, respetando cupos diarios y la hora actual.
-- Huecos cada 30 minutos; la duración depende del tamaño de la mascota.
CREATE OR REPLACE FUNCTION horarios_libres_base(p_codigo text, p_fecha date, p_tamano text)
RETURNS TABLE(inicio timestamp, fin timestamp, nombre_servicio text, tipo text, prof text, duracion_min integer)
LANGUAGE sql STABLE AS $$
  WITH s AS (
    SELECT sv.*,
           CASE WHEN p_tamano ILIKE 'peque%' THEN sv.dur_pequeno
                WHEN p_tamano ILIKE 'grande%' THEN sv.dur_grande
                ELSE sv.dur_mediano END AS dur
    FROM servicios sv
    WHERE sv.codigo = p_codigo
      AND extract(isodow FROM p_fecha)::int = ANY (sv.dias_semana)
      AND (sv.cupos_dia IS NULL OR
           (SELECT count(*) FROM citas c
             WHERE c.servicio = sv.nombre AND c.estado = 'agendada'
               AND c.fecha_hora_inicio::date = p_fecha) < sv.cupos_dia)
  ),
  slots AS (
    SELECT s.*, g AS ini, g + make_interval(mins => s.dur) AS fn
    FROM s,
         generate_series(p_fecha + s.hora_inicio,
                         p_fecha + s.hora_fin - make_interval(mins => s.dur),
                         interval '30 minutes') g
  )
  SELECT sl.ini, sl.fn, sl.nombre, sl.tipo, sl.profesional, sl.dur
  FROM slots sl
  WHERE sl.ini > (now() AT TIME ZONE 'America/Bogota')
    AND NOT EXISTS (
      SELECT 1 FROM citas c
      WHERE c.profesional = sl.profesional AND c.estado = 'agendada'
        AND c.fecha_hora_inicio < sl.fn AND c.fecha_hora_fin > sl.ini)
  ORDER BY sl.ini;
$$;

-- Envoltorio público: igual que la base, pero sin horarios en festivos.
-- (Las herramientas del agente llaman a esta función.)
CREATE OR REPLACE FUNCTION horarios_libres(p_codigo text, p_fecha date, p_tamano text)
RETURNS TABLE(inicio timestamp, fin timestamp, nombre_servicio text, tipo text, prof text, duracion_min integer)
LANGUAGE sql STABLE AS $$
  SELECT b.* FROM horarios_libres_base(p_codigo, p_fecha, p_tamano) b
  WHERE NOT EXISTS (SELECT 1 FROM festivos f WHERE f.fecha = p_fecha);
$$;

-- Agenda una cita validando que el hueco siga libre.
-- Siempre devuelve una fila: AGENDADA | NO_DISPONIBLE | MASCOTA_NO_ENCONTRADA
CREATE OR REPLACE FUNCTION agendar_cita(p_cliente integer, p_mascota integer, p_codigo text, p_inicio timestamp)
RETURNS TABLE(resultado text, cita_id integer, servicio text, fecha_hora timestamp, instrucciones text)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  v_tamano text;
  h        record;
  v_id     integer;
BEGIN
  PERFORM pg_advisory_xact_lock(7002);          -- evita dos reservas del mismo hueco a la vez

  SELECT m.tamano INTO v_tamano FROM mascotas m
   WHERE m.id = p_mascota AND m.cliente_id = p_cliente;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'MASCOTA_NO_ENCONTRADA'::text, NULL::int, NULL::text, NULL::timestamp, NULL::text;
    RETURN;
  END IF;

  SELECT * INTO h FROM horarios_libres(p_codigo, p_inicio::date, v_tamano) x WHERE x.inicio = p_inicio;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'NO_DISPONIBLE'::text, NULL::int, NULL::text, NULL::timestamp, NULL::text;
    RETURN;
  END IF;

  INSERT INTO citas (cliente_id, mascota_id, tipo_servicio, servicio, profesional, fecha_hora_inicio, fecha_hora_fin)
  VALUES (p_cliente, p_mascota, h.tipo, h.nombre_servicio, h.prof, h.inicio, h.fin)
  RETURNING id INTO v_id;

  RETURN QUERY
    SELECT 'AGENDADA'::text, v_id, h.nombre_servicio, h.inicio,
           (SELECT sv.instrucciones FROM servicios sv WHERE sv.codigo = p_codigo);
END $$;

-- Citas futuras agendadas del cliente (con su id, para poder cancelarlas).
-- Siempre devuelve una fila.
CREATE OR REPLACE FUNCTION mis_citas(p_cliente integer)
RETURNS TABLE(resultado text, total integer, lista text)
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN count(*) = 0 THEN 'SIN_CITAS' ELSE 'OK' END,
         count(*)::int,
         coalesce(string_agg(
           'id ' || c.id || ': ' || c.servicio || ' de ' || coalesce(m.nombre, 'sin mascota') ||
           ' el ' || to_char(c.fecha_hora_inicio, 'YYYY-MM-DD "a las" HH24:MI'),
           E'\n' ORDER BY c.fecha_hora_inicio), '')
  FROM citas c
  LEFT JOIN mascotas m ON m.id = c.mascota_id
  WHERE c.cliente_id = p_cliente
    AND c.estado = 'agendada'
    AND c.fecha_hora_inicio > (now() AT TIME ZONE 'America/Bogota');
$$;

-- Cancela una cita propia, agendada y con más de 2 horas de anticipación.
-- Resultado: CANCELADA | MUY_TARDE | NO_ENCONTRADA | YA_NO_ESTA_AGENDADA
CREATE OR REPLACE FUNCTION cancelar_cita(p_cliente integer, p_cita integer)
RETURNS TABLE(resultado text, servicio text, fecha_hora timestamp)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  c record;
BEGIN
  SELECT * INTO c FROM citas WHERE id = p_cita AND cliente_id = p_cliente;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'NO_ENCONTRADA'::text, NULL::text, NULL::timestamp; RETURN;
  END IF;
  IF c.estado <> 'agendada' THEN
    RETURN QUERY SELECT 'YA_NO_ESTA_AGENDADA'::text, c.servicio, c.fecha_hora_inicio; RETURN;
  END IF;
  IF c.fecha_hora_inicio < (now() AT TIME ZONE 'America/Bogota') + interval '2 hours' THEN
    RETURN QUERY SELECT 'MUY_TARDE'::text, c.servicio, c.fecha_hora_inicio; RETURN;
  END IF;
  UPDATE citas SET estado = 'cancelada' WHERE id = p_cita;
  RETURN QUERY SELECT 'CANCELADA'::text, c.servicio, c.fecha_hora_inicio;
END $$;
