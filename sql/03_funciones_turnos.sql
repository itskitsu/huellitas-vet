-- =====================================================================
-- Huellitas Vet · 03 · Funciones de la fila virtual (turnos)
-- Depende de: 01_tablas.sql
-- Todas usan la hora de Bogotá de forma explícita.
-- =====================================================================

-- ¿La fila está abierta ahora? L-V 8:00-17:00, sábados 8:00-12:00.
-- Domingos y festivos: cerrada.
CREATE OR REPLACE FUNCTION fila_abierta() RETURNS boolean
LANGUAGE sql STABLE AS $$
  WITH t AS (SELECT now() AT TIME ZONE 'America/Bogota' AS ahora)
  SELECT NOT EXISTS (SELECT 1 FROM festivos f, t WHERE f.fecha = t.ahora::date)
     AND CASE extract(isodow FROM t.ahora)::int
           WHEN 6 THEN t.ahora::time >= '08:00' AND t.ahora::time < '12:00'
           WHEN 7 THEN false
           ELSE        t.ahora::time >= '08:00' AND t.ahora::time < '17:00'
         END
  FROM t;
$$;

-- Pide el siguiente turno del día. Un turno por cliente por día.
-- Resultado: TURNO_ASIGNADO | YA_TIENE_TURNO | FILA_CERRADA
CREATE OR REPLACE FUNCTION pedir_turno(p_cliente integer, p_mascota integer, p_motivo text)
RETURNS TABLE(resultado text, numero integer, delante integer, espera_min integer)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  v_hoy   date := (now() AT TIME ZONE 'America/Bogota')::date;
  t       record;
  v_num   integer;
  v_del   integer;
BEGIN
  IF NOT fila_abierta() THEN
    RETURN QUERY SELECT 'FILA_CERRADA'::text, NULL::int, NULL::int, NULL::int; RETURN;
  END IF;

  PERFORM pg_advisory_xact_lock(7001);          -- evita números repetidos

  SELECT * INTO t FROM turnos
   WHERE fecha = v_hoy AND cliente_id = p_cliente AND estado IN ('en_espera','llamado')
   LIMIT 1;
  IF FOUND THEN
    SELECT count(*)::int INTO v_del FROM turnos x
     WHERE x.fecha = v_hoy AND x.numero < t.numero AND x.estado IN ('en_espera','llamado');
    RETURN QUERY SELECT 'YA_TIENE_TURNO'::text, t.numero, v_del, v_del * 30; RETURN;
  END IF;

  SELECT coalesce(max(x.numero), 0) + 1 INTO v_num FROM turnos x WHERE x.fecha = v_hoy;
  INSERT INTO turnos (fecha, numero, cliente_id, mascota_id, motivo)
  VALUES (v_hoy, v_num, p_cliente, p_mascota, nullif(p_motivo, '-'));

  SELECT count(*)::int INTO v_del FROM turnos x
   WHERE x.fecha = v_hoy AND x.numero < v_num AND x.estado IN ('en_espera','llamado');
  RETURN QUERY SELECT 'TURNO_ASIGNADO'::text, v_num, v_del, v_del * 30;
END $$;

-- Estado del turno de hoy del cliente. Siempre devuelve una fila.
-- Resultado: SIN_TURNO | EN_ESPERA | LLAMADO
CREATE OR REPLACE FUNCTION mi_turno(p_cliente integer)
RETURNS TABLE(resultado text, numero integer, delante integer, espera_min integer)
LANGUAGE plpgsql STABLE AS $$
#variable_conflict use_column
DECLARE
  v_hoy date := (now() AT TIME ZONE 'America/Bogota')::date;
  t     record;
  v_del integer;
BEGIN
  SELECT * INTO t FROM turnos
   WHERE fecha = v_hoy AND cliente_id = p_cliente AND estado IN ('en_espera','llamado')
   ORDER BY numero LIMIT 1;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'SIN_TURNO'::text, NULL::int, NULL::int, NULL::int; RETURN;
  END IF;
  SELECT count(*)::int INTO v_del FROM turnos x
   WHERE x.fecha = v_hoy AND x.numero < t.numero AND x.estado IN ('en_espera','llamado');
  RETURN QUERY SELECT CASE WHEN t.estado = 'llamado' THEN 'LLAMADO' ELSE 'EN_ESPERA' END,
                      t.numero, v_del, v_del * 30;
END $$;

-- Turnos de hoy en espera o llamados (comando /fila de recepción).
CREATE OR REPLACE FUNCTION fila_hoy()
RETURNS TABLE(numero integer, estado text, cliente text, mascota text, motivo text)
LANGUAGE sql STABLE AS $$
  SELECT t.numero, t.estado, coalesce(c.nombre, c.usuario_id), coalesce(m.nombre, '-'), coalesce(t.motivo, '-')
  FROM turnos t
  JOIN clientes c ON c.id = t.cliente_id
  LEFT JOIN mascotas m ON m.id = t.mascota_id
  WHERE t.fecha = (now() AT TIME ZONE 'America/Bogota')::date
    AND t.estado IN ('en_espera','llamado')
  ORDER BY t.numero;
$$;

-- Comandos /siguiente y /noasistio.
--   p_accion = 'siguiente'  → el turno llamado pasa a 'atendido'
--   p_accion = 'noasistio'  → el turno llamado pasa a 'no_asistio'
-- Después llama al siguiente en espera. Siempre devuelve una fila:
--   resultado = LLAMADO (con los datos del cliente a avisar) | FILA_VACIA
CREATE OR REPLACE FUNCTION avanzar_fila(p_accion text)
RETURNS TABLE(resultado text, numero integer, canal text, usuario_id text,
              cliente text, mascota text, motivo text)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  v_hoy date := (now() AT TIME ZONE 'America/Bogota')::date;
  v_id  integer;
BEGIN
  PERFORM pg_advisory_xact_lock(7001);

  UPDATE turnos
     SET estado = CASE WHEN p_accion = 'noasistio' THEN 'no_asistio' ELSE 'atendido' END,
         hora_atencion = now() AT TIME ZONE 'America/Bogota'
   WHERE fecha = v_hoy AND estado = 'llamado';

  SELECT t.id INTO v_id FROM turnos t
   WHERE t.fecha = v_hoy AND t.estado = 'en_espera'
   ORDER BY t.numero LIMIT 1;

  IF v_id IS NULL THEN
    RETURN QUERY SELECT 'FILA_VACIA'::text, NULL::int, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text;
    RETURN;
  END IF;

  UPDATE turnos SET estado = 'llamado', hora_llamado = now() AT TIME ZONE 'America/Bogota' WHERE id = v_id;

  RETURN QUERY
    SELECT 'LLAMADO'::text, t.numero, c.canal, c.usuario_id, coalesce(c.nombre, c.usuario_id),
           coalesce(m.nombre, '-'), coalesce(t.motivo, '-')
    FROM turnos t
    JOIN clientes c ON c.id = t.cliente_id
    LEFT JOIN mascotas m ON m.id = t.mascota_id
    WHERE t.id = v_id;
END $$;

-- Clientes a quienes les quedan 2 turnos o menos. Marca el aviso como enviado
-- para no repetirlo. Devuelve cero filas si no hay nadie a quien avisar.
CREATE OR REPLACE FUNCTION avisos_pendientes()
RETURNS TABLE(numero integer, canal text, usuario_id text, mascota text, delante integer)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
BEGIN
  RETURN QUERY
  WITH pend AS (
    SELECT t.id, t.numero, t.cliente_id, t.mascota_id,
           (SELECT count(*)::int FROM turnos x
             WHERE x.fecha = t.fecha AND x.numero < t.numero
               AND x.estado IN ('en_espera','llamado')) AS delante
    FROM turnos t
    WHERE t.fecha = (now() AT TIME ZONE 'America/Bogota')::date
      AND t.estado = 'en_espera' AND NOT t.aviso_enviado
  ), marcados AS (
    UPDATE turnos t SET aviso_enviado = true
    FROM pend p WHERE t.id = p.id AND p.delante <= 2
    RETURNING t.id
  )
  SELECT p.numero, c.canal, c.usuario_id, coalesce(m.nombre, '-'), p.delante
  FROM pend p
  JOIN marcados mk ON mk.id = p.id
  JOIN clientes c ON c.id = p.cliente_id
  LEFT JOIN mascotas m ON m.id = p.mascota_id
  ORDER BY p.numero;
END $$;

-- Cierre del día: los turnos pendientes pasan a 'expirado'.
-- Devuelve a quién avisar (cero filas si no había pendientes).
CREATE OR REPLACE FUNCTION cerrar_fila()
RETURNS TABLE(numero integer, canal text, usuario_id text, mascota text)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
BEGIN
  RETURN QUERY
  WITH cerrados AS (
    UPDATE turnos t SET estado = 'expirado'
    WHERE t.fecha = (now() AT TIME ZONE 'America/Bogota')::date
      AND t.estado IN ('en_espera','llamado')
    RETURNING t.numero, t.cliente_id, t.mascota_id
  )
  SELECT x.numero, c.canal, c.usuario_id, coalesce(m.nombre, '-')
  FROM cerrados x
  JOIN clientes c ON c.id = x.cliente_id
  LEFT JOIN mascotas m ON m.id = x.mascota_id
  ORDER BY x.numero;
END $$;
