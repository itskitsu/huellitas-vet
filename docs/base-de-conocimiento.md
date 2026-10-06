# Huellitas Vet — Base de conocimiento

> **Datos ficticios.** Este documento es la fuente del RAG: el workflow *Cargar base de conocimiento* lo divide en fragmentos, los vectoriza y los guarda en Postgres. Cambia estos datos por los de tu negocio real y vuelve a ejecutar el workflow.
> Escribe cada sección de forma autocontenida (con el nombre del servicio en el texto): la búsqueda semántica recupera fragmentos sueltos.

## Sobre Huellitas Vet

Huellitas Vet es una clínica veterinaria y peluquería canina en Ibagué, Tolima. Atendemos perros y gatos con consulta general, vacunación, desparasitación, cirugías (esterilización y profilaxis dental) y peluquería.

## Ubicación y contacto

- Dirección: Carrera 00 # 00-00, barrio Ejemplo, Ibagué (dirección ficticia).
- Teléfono de recepción: 000 000 0000 (ficticio).
- Canal de atención virtual: este chat.

## Horarios de atención

- Lunes a viernes: 8:00 am a 5:00 pm.
- Sábados: 8:00 am a 12:00 m.
- Domingos y festivos: cerrado.
- Para urgencias fuera de horario, no tenemos servicio nocturno: se recomienda acudir a una clínica con atención 24 horas.

## Consulta general (turno virtual, sin cita)

La consulta general se atiende **por turno, sin cita previa**. El cliente pide su turno por este chat durante el horario de atención y recibe un número.

- La fila se reinicia cada día.
- Cada cliente puede tener un solo turno al día.
- La espera estimada es de unos 30 minutos por cada persona que esté delante (es aproximada).
- El sistema avisa por este chat cuando faltan 2 turnos o menos.
- Al cierre del día, los turnos que no fueron atendidos vencen y hay que pedir uno nuevo al día siguiente.
- Precio de la consulta general: $60.000 COP.
- Atiende: Dr. Andrés (veterinario).

## Servicios con cita

Los siguientes servicios se agendan con cita. Los huecos se ofrecen cada 30 minutos.

### Baño completo
- Peluquera: Camila. Lunes a sábado, de 8:00 am a 5:00 pm.
- Duración: perro pequeño 60 min, mediano 90 min, grande 120 min.
- Precio: pequeño $45.000, mediano $60.000, grande $80.000 COP.
- Incluye baño, secado, cepillado, limpieza de oídos y corte de uñas.
- Indicaciones: llegar con collar o arnés y el carné de vacunas al día.

### Baño y corte
- Peluquera: Camila. Lunes a sábado, de 8:00 am a 5:00 pm.
- Duración: pequeño 90 min, mediano 120 min, grande 150 min.
- Precio: pequeño $65.000, mediano $85.000, grande $110.000 COP.
- Indicar al llegar el tipo de corte que se prefiere.

### Baño de gato
- Peluquera: Camila. Martes, jueves y sábados, de 8:00 am a 12:00 m.
- Duración: 60 minutos.
- Precio: $50.000 COP.
- Los gatos deben llegar en transportadora.

### Vacunación
- Veterinario: Dr. Andrés. Lunes a sábado, de 8:00 am a 5:00 pm. Duración: 30 minutos.
- La mascota debe estar sana al momento de vacunarse. Traer el carné de vacunas.
- Precios: quíntuple canina $55.000, séxtuple canina $65.000, antirrábica $35.000, triple felina $60.000 COP.
- La clínica recuerda la próxima dosis por este chat una semana antes.

### Desparasitación
- Veterinario: Dr. Andrés. Lunes a sábado, de 8:00 am a 5:00 pm. Duración: 30 minutos.
- El precio depende del peso: hasta 10 kg $25.000, de 10 a 25 kg $35.000, más de 25 kg $45.000 COP.
- Indicar el peso aproximado de la mascota.

### Esterilización (cirugía)
- Cirujana: Dra. Valentina. Martes y jueves, desde las 7:30 am. Cupo: 2 cirugías por día.
- Duración: pequeño 90 min, mediano 120 min, grande 150 min.
- Precio: hembra pequeña $280.000, hembra mediana $350.000, hembra grande $450.000; macho pequeño $200.000, macho mediano $250.000, macho grande $320.000 COP. Gatos: hembra $220.000, macho $150.000.
- **Ayuno:** sólidos 8 horas y agua 4 horas antes. Llegar a las 7:30 am.
- La clínica envía un recordatorio de ayuno la noche anterior, a las 8 pm.
- La mascota debe tener las vacunas al día y estar sana.

### Profilaxis dental (limpieza dental con anestesia)
- Cirujana: Dra. Valentina. Miércoles y viernes, desde las 7:30 am. Cupo: 2 por día.
- Duración: pequeño 60 min, mediano 90 min, grande 120 min.
- Precio: pequeño $180.000, mediano $220.000, grande $260.000 COP.
- Ayuno de sólidos 8 horas antes.

## Cancelar o cambiar una cita

- Se puede cancelar por este chat **hasta 2 horas antes** de la cita.
- Con menos de 2 horas de anticipación, hay que comunicarse con recepción.
- Cambiar una cita equivale a agendar el nuevo horario y cancelar el anterior.

## Recordatorios que envía la clínica

- 24 horas antes de la cita.
- 2 horas antes de la cita.
- Cirugías: recordatorio de ayuno a las 8 pm del día anterior.
- Vacunas: una semana antes de la próxima dosis.

## Formas de pago

Efectivo, tarjeta débito o crédito y transferencia. El pago se hace en la clínica (datos ficticios).

## Urgencias

Si la mascota tiene dificultad para respirar, convulsiones, sangrado abundante, atropello, intoxicación, abdomen hinchado y duro, o no puede orinar, debe llevarse **de inmediato** a la clínica en horario de atención. Fuera de horario, a una clínica de urgencias 24 horas. El agente no da diagnósticos ni dosis de medicamentos por chat.

## Preguntas frecuentes

**¿Necesito cita para consulta general?** No. Se pide un turno virtual por este chat, durante el horario de atención.

**¿Puedo reservar un turno para mañana?** No. Los turnos se piden el mismo día; la fila se reinicia cada mañana.

**¿Atienden otras especies además de perros y gatos?** No. Solo perros y gatos.

**¿Cuánto cuesta el baño?** Depende del tamaño del perro. Ver la sección de baño completo y baño y corte.

**¿Qué pasa si llego tarde a mi cita?** Comunícate con recepción; si el horario siguiente ya está ocupado, habrá que reagendar.
