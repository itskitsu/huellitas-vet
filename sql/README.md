# Scripts SQL

Ejecútalos **en orden**. Todos son repetibles (se pueden volver a correr sin romper nada).

| Orden | Archivo | Contenido |
|---|---|---|
| 0 | `00_extensiones.sql` | Extensión `pgvector` (solo para el RAG) |
| 1 | `01_tablas.sql` | Tablas, catálogo de servicios de ejemplo y festivos |
| 2 | `02_funciones_citas.sql` | `horarios_libres`, `agendar_cita`, `mis_citas`, `cancelar_cita` |
| 3 | `03_funciones_turnos.sql` | Fila virtual: `fila_abierta`, `pedir_turno`, `mi_turno`, `fila_hoy`, `avanzar_fila`, `avisos_pendientes`, `cerrar_fila` |
| 4 | `04_funciones_recordatorios.sql` | `recordatorios_citas`, `recordatorios_vacunas`, `registrar_vacuna` |

## Desde `psql`

```bash
psql -U postgres -d portafolio_veterinaria -f sql/00_extensiones.sql
psql -U postgres -d portafolio_veterinaria -f sql/01_tablas.sql
psql -U postgres -d portafolio_veterinaria -f sql/02_funciones_citas.sql
psql -U postgres -d portafolio_veterinaria -f sql/03_funciones_turnos.sql
psql -U postgres -d portafolio_veterinaria -f sql/04_funciones_recordatorios.sql
```

## Desde n8n

Crea un flujo manual con un nodo **Postgres → Execute Query** y pega el contenido de cada script.

## Notas

- Las funciones usan la hora de Bogotá de forma explícita (`now() AT TIME ZONE 'America/Bogota'`), sin depender de la zona horaria del servidor.
- **Las funciones de recordatorios y avisos marcan sus banderas al devolver filas.** Si las ejecutas a mano para probar, esa fila ya no volverá a salir; para repetir la prueba restablece la bandera (por ejemplo `UPDATE vacunas SET recordatorio_enviado = false WHERE id = 1;`).
- Los festivos de `01_tablas.sql` son de ejemplo (2026): completa cada año con el calendario oficial.
- Todas las funciones que usan la fila toman el bloqueo `pg_advisory_xact_lock(7001)`; `agendar_cita` usa el `7002`.
