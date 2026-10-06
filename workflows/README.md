# Workflows de n8n

Aquí van los flujos exportados desde n8n (un `.json` por flujo):

| Archivo | Flujo |
|---|---|
| `agente-principal.json` | Agente principal (Telegram) |
| `cierre-diario.json` | Cierre diario de la fila virtual |
| `recordatorios.json` | Recordatorios de citas, ayuno y vacunas |
| `cargar-base-de-conocimiento.json` | Carga de `docs/base-de-conocimiento.md` al almacén vectorial |
| `setup-sql.json` | Ejecuta los scripts de [`sql/`](../sql/) (opcional: también puedes usar `psql`) |

## Cómo exportar un flujo

1. Abre el flujo en n8n.
2. Menú **⋯** (arriba a la derecha) → **Download**.
3. Renombra el archivo y guárdalo en esta carpeta.

## Antes de subirlos a GitHub

- Los `.json` **no** guardan el contenido de las credenciales (solo su nombre e id), pero revísalos igualmente: busca con el buscador de tu editor `token`, `apiKey`, `password` y tu chat id real.
- Reemplaza tu **chat id de recepción** (nodo `¿Es recepción?`) por un marcador como `TU_CHAT_ID_DE_RECEPCION`.
- Si algún nodo tiene datos de clientes reales, quítalos.

## Cómo importarlos

1. En n8n: **Workflows → Import from File**.
2. Asigna tus propias credenciales (Telegram, Postgres, Anthropic, Google Gemini) en los nodos que lo pidan.
3. En *Settings* de cada flujo, zona horaria `America/Bogota`.
