-- =====================================================================
-- Huellitas Vet · 04 · Recordatorios y vacunas
-- Depende de: 01_tablas.sql
-- Ejecuta el workflow "Recordatorios" cada 15 minutos.
-- =====================================================================

-- Citas a las que toca avisar. Marca la bandera correspondiente al devolverlas.
--   tipo_aviso = '24h'   → entre 23 y 24 h antes
--              = '2h'    → entre 1 y 2 h antes
--              = 'ayuno' → desde las 8 pm del día anterior, solo cirugías
-- Devuelve cero filas si no hay nada pendiente.
CREATE OR REPLACE FUNCTION recordatorios_citas()
RETURNS TABLE(cita_id integer, tipo_aviso text, canal text, usuario_id text,
              mascota text, servicio text, fecha_hora timestamp, instrucciones text)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  v_ahora timestamp := now() AT TIME ZONE 'America/Bogota';
BEGIN
  RETURN QUERY
  WITH cand AS (
    SELECT c.id,
           CASE
             WHEN NOT c.recordatorio_2h_enviado
                  AND c.fecha_hora_inicio - v_ahora BETWEEN interval '1 hour' AND interval '2 hours' THEN '2h'
             WHEN NOT c.recordatorio_24h_enviado
                  AND c.fecha_hora_inicio - v_ahora BETWEEN interval '23 hours' AND interval '24 hours' THEN '24h'
             WHEN c.tipo_servicio = 'cirugia' AND NOT c.recordatorio_ayuno_enviado
                  AND v_ahora >= (c.fecha_hora_inicio::date - 1) + time '20:00'
                  AND v_ahora <  c.fecha_hora_inicio THEN 'ayuno'
           END AS aviso
    FROM citas c
    WHERE c.estado = 'agendada' AND c.fecha_hora_inicio > v_ahora
  ), marcadas AS (
    UPDATE citas c SET
      recordatorio_2h_enviado    = c.recordatorio_2h_enviado    OR k.aviso = '2h',
      recordatorio_24h_enviado   = c.recordatorio_24h_enviado   OR k.aviso = '24h',
      recordatorio_ayuno_enviado = c.recordatorio_ayuno_enviado OR k.aviso = 'ayuno'
    FROM cand k WHERE c.id = k.id AND k.aviso IS NOT NULL
    RETURNING c.id, k.aviso
  )
  SELECT c.id, mk.aviso, cl.canal, cl.usuario_id, coalesce(m.nombre, '-'), c.servicio,
         c.fecha_hora_inicio, coalesce(sv.instrucciones, '-')
  FROM marcadas mk
  JOIN citas c ON c.id = mk.id
  JOIN clientes cl ON cl.id = c.cliente_id
  LEFT JOIN mascotas m ON m.id = c.mascota_id
  LEFT JOIN servicios sv ON sv.nombre = c.servicio
  ORDER BY c.fecha_hora_inicio;
END $$;

-- Vacunas cuya próxima dosis vence en 7 días o menos. Solo entre 8 am y 6 pm.
-- Marca la bandera al devolverlas.
CREATE OR REPLACE FUNCTION recordatorios_vacunas()
RETURNS TABLE(vacuna_id integer, canal text, usuario_id text, mascota text, vacuna text, fecha_proxima date)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  v_ahora timestamp := now() AT TIME ZONE 'America/Bogota';
BEGIN
  IF v_ahora::time < '08:00' OR v_ahora::time >= '18:00' THEN
    RETURN;
  END IF;
  RETURN QUERY
  WITH marcadas AS (
    UPDATE vacunas v SET recordatorio_enviado = true
    WHERE NOT v.recordatorio_enviado AND v.fecha_proxima IS NOT NULL
      AND v.fecha_proxima <= v_ahora::date + 7
      AND v.fecha_proxima >= v_ahora::date
    RETURNING v.id
  )
  SELECT v.id, c.canal, c.usuario_id, m.nombre, v.nombre, v.fecha_proxima
  FROM marcadas mk
  JOIN vacunas v ON v.id = mk.id
  JOIN mascotas m ON m.id = v.mascota_id
  JOIN clientes c ON c.id = m.cliente_id
  ORDER BY v.fecha_proxima;
END $$;

-- Comando de recepción: /vacuna idCliente Mascota Vacuna días
-- Ejemplo: '123456789 Luna Quíntuple 365'
-- Registra la vacuna aplicada hoy; la próxima dosis queda a 'días' de distancia.
-- Resultado: REGISTRADA | FORMATO_INVALIDO | CLIENTE_NO_ENCONTRADO | MASCOTA_NO_ENCONTRADA
CREATE OR REPLACE FUNCTION registrar_vacuna(p_texto text)
RETURNS TABLE(resultado text, cliente text, mascota text, vacuna text, fecha_proxima date)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
  partes text[] := regexp_split_to_array(btrim(p_texto), '\s+');
  n       integer := array_length(partes, 1);
  v_dias  integer;
  v_cli   record;
  v_masc  record;
  v_nom   text;
  v_hoy   date := (now() AT TIME ZONE 'America/Bogota')::date;
BEGIN
  IF n IS NULL OR n < 4 OR partes[n] !~ '^\d+$' THEN
    RETURN QUERY SELECT 'FORMATO_INVALIDO'::text, NULL::text, NULL::text, NULL::text, NULL::date; RETURN;
  END IF;
  v_dias := partes[n]::int;
  v_nom  := array_to_string(partes[3:n-1], ' ');

  SELECT * INTO v_cli FROM clientes c WHERE c.usuario_id = partes[1] LIMIT 1;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'CLIENTE_NO_ENCONTRADO'::text, NULL::text, NULL::text, NULL::text, NULL::date; RETURN;
  END IF;

  SELECT * INTO v_masc FROM mascotas m
   WHERE m.cliente_id = v_cli.id AND lower(m.nombre) = lower(partes[2]) LIMIT 1;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 'MASCOTA_NO_ENCONTRADA'::text, coalesce(v_cli.nombre, v_cli.usuario_id), NULL::text, NULL::text, NULL::date; RETURN;
  END IF;

  INSERT INTO vacunas (mascota_id, tipo, nombre, fecha_aplicacion, fecha_proxima)
  VALUES (v_masc.id, 'vacuna', v_nom, v_hoy, v_hoy + v_dias);

  RETURN QUERY SELECT 'REGISTRADA'::text, coalesce(v_cli.nombre, v_cli.usuario_id), v_masc.nombre, v_nom, v_hoy + v_dias;
END $$;
