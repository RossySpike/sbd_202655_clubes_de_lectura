# Chuleta de Defensa — Entrega 2, Parte I

## Qué se evalúa
1. Estructura completa de la BD (tablas, vistas, índices, secuencias)
2. Inserts en todas las tablas tipo Entrada
3. Demostración de las 4 funciones

---

## 1. Estructura completa de la BD

### Secuencias (15 en total)
Todas usan `NOCYCLE` — cuando llega al máximo no se reinicia, lanza error. Justificación: evita colisiones silenciosas de PKs.

| Secuencia | Tabla que alimenta | MAXVALUE |
|---|---|---|
| `MJV_seq_pais` | `MJV_pais.id_pais` | 999 |
| `MJV_seq_ciudad` | `MJV_ciudad.id_ciudad` | 999 |
| `MJV_seq_institucion` | `MJV_institucion.id_institucion` | 999 |
| `MJV_seq_idioma` | `MJV_idioma.id_idioma` | 999 |
| `MJV_seq_club` | `MJV_club.id_club` | sin límite |
| `MJV_seq_representante` | `MJV_representante.id_representante` | sin límite |
| `MJV_seq_lector` | `MJV_lector.id_lector` | sin límite |
| `MJV_seq_idioma_miembro` | `MJV_idioma_miembro.id_idioma_miembro` | sin límite |
| `MJV_seq_autor` | `MJV_autor.id_autor` | sin límite |
| `MJV_seq_grupo` | `MJV_grupo.id_grupo` | sin límite |
| `MJV_seq_obra_actuada` | `MJV_obra_actuada.id_obra_act` | sin límite |
| `MJV_seq_pago_membresia` | `MJV_pago_membresia.id_pago` | sin límite |
| `MJV_seq_funcion` | `MJV_funcion.id_funcion` | sin límite |
| `MJV_seq_voto_publico` | `MJV_voto_publico.id_voto` | sin límite |

---

### Tablas por tipo de entidad

**Entrada (E) — datos maestros, nunca se generan solos:**
`MJV_pais`, `MJV_ciudad`, `MJV_institucion`, `MJV_idioma`, `MJV_club`, `MJV_representante`, `MJV_lector`, `MJV_autor`, `MJV_libro`, `MJV_grupo`

**Entrada/Salida (E/S) — se crean por operación del sistema:**
`MJV_asociado`, `MJV_idioma_miembro`, `MJV_libro_autor`, `MJV_obra_actuada`, `MJV_historia_membresia`, `MJV_preferencia_obra`, `MJV_g_lec`, `MJV_calendario_reunion_mes`, `MJV_elenco`

**Salida (S) — generadas por procesos/reglas de negocio:**
`MJV_pago_membresia`, `MJV_inasistencia`, `MJV_funcion`, `MJV_voto_publico`, `MJV_mejor_actor`

> Si la profe pregunta por qué `MJV_inasistencia` es tipo S: porque no la ingresa un usuario directamente, se genera al registrar la ausencia de un miembro en una reunión ya realizada. Es consecuencia de un evento, no un dato maestro.

---

### Índices activos (los no comentados)

| Índice | Tabla | Columna(s) | Por qué |
|---|---|---|---|
| `MJV_idx_lector_rep` | `MJV_lector` | `id_representante` | FK sin índice → lock escalation al eliminar representantes |
| `MJV_idx_lector_rep_lec` | `MJV_lector` | `id_representante_lector` | ídem para representante-lector |
| `MJV_idx_lector_pais_nac` | `MJV_lector` | `id_pais_nac` | FK frecuente en joins de reportes |
| `MJV_idx_historia_membresia_club` | `MJV_historia_membresia` | `id_club` | tabla grande, filtros por club son frecuentes |
| `MJV_idx_preferencia_obra_isbn` | `MJV_preferencia_obra` | `isbn` | FK hacia libro, búsquedas por ISBN |
| `MJV_idx_g_lec_grupo` | `MJV_g_lec` | `id_grupo` | tabla pivote más consultada del sistema |

> Los índices comentados están justificados en el script: se marcaron como "sugeridos" o "redundantes según el orden de filtros". Si la profe pregunta, se pueden crear pero no aportan en las consultas actuales porque el optimizador los ignoraría.

---

### Vistas (10 en total)

| Vista | Tipo | Para qué sirve |
|---|---|---|
| `MJV_v_directorio_lector` | Simple (1 tabla) | Contactos públicos sin doc_identidad |
| `MJV_v_catalogo_libros` | Simple | Catálogo liviano sin sinopsis |
| `MJV_v_reuniones_mes` | Compleja (JOIN) | Soporte módulo de reuniones |
| `MJV_v_participacion_mensual_tipo_grupo` | Compleja (JOIN+GROUP BY) | Base de cálculo de `MJV_promedio_part_mensual_tipo_grupo` |
| `MJV_v_ficha_lector` | Compleja | Reporte 1 del enunciado (pág. 10) |
| `MJV_v_ficha_club` | Compleja (subconsulta en FROM) | Reporte ficha de club |
| `MJV_v_ficha_libro` | Compleja | Historial de análisis del libro |
| `MJV_v_crecimiento_clubes` | Compleja | Crecimiento anual y % de membresías |
| `MJV_v_obras_presentadas` | Compleja | Obras, valoración pública e ingresos |
| `MJV_v_asistencia_bimestre` | Compleja (CTE) | Auditoría de inasistencias bimestrales |

---

## 2. Inserts en tablas tipo Entrada

El script carga datos en este orden (respetando dependencias de FK):

1. Países → Ciudades → Instituciones
2. Idiomas
3. Representantes → Lectores (con arco exclusivo: adulto sin tutor / menor con tutor externo / menor con tutor lector)
4. Autores → Libros → Libro-Autor
5. Clubes → Grupos
6. Historia membresía → Preferencias → G_lec
7. Asociaciones entre clubes
8. Idiomas de clubes y lectores
9. Calendario de reuniones
10. Elenco de obras
11. **Sección 20:** 2 reuniones realizadas + 4 inasistencias (datos para las funciones)

> Tip para la profe: los inserts usan subconsultas en lugar de IDs hardcodeados (`WHERE nombre_club = '...'`) para que el script sea reutilizable aunque las secuencias empiecen desde valores distintos.

---

## 3. Las 4 funciones

---

### `MJV_conversion_monetaria(p_monto, p_moneda_origen, p_moneda_destino, p_tasa)`

**Qué hace:** convierte un monto entre dos monedas usando la tasa que tú le pasas (el sistema no la almacena, la recibe como parámetro).

**Validaciones internas:**
- Si monto o tasa son NULL → retorna NULL sin error
- Si origen = destino → retorna el mismo monto
- Si tasa ≤ 0 → error -20101
- Si la moneda origen no existe en `MJV_pais.moneda_local` → error -20102
- Si la moneda destino no existe → error -20103

**Fórmula:** `ROUND(p_monto * p_tasa, 2)`

**Demo:**
```sql
-- USD a VES (tasa referencial)
SELECT MJV_conversion_monetaria(100, 'USD', 'VES', 36.50) AS monto_ves FROM DUAL;
-- Resultado esperado: 3650

-- Misma moneda (caso borde)
SELECT MJV_conversion_monetaria(100, 'USD', 'USD', 1) AS mismo FROM DUAL;
-- Resultado esperado: 100

-- Moneda inventada (debe lanzar error -20102)
SELECT MJV_conversion_monetaria(100, 'XYZ', 'USD', 1) FROM DUAL;
```

> Si la profe pregunta por qué la tasa la pasa el usuario y no está en la BD: el enunciado no pide una tabla de tasas, y las tasas cambian constantemente; guardarlas requeriría un módulo de gestión cambiaria fuera del alcance del proyecto.

---

### `MJV_edad_miembro(p_id_lector)`

**Qué hace:** devuelve la edad en años cumplidos de un lector.

**Fórmula:** `TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nac) / 12)`
- `MONTHS_BETWEEN` da los meses exactos entre dos fechas (con decimales).
- Dividir entre 12 da los años con fracción.
- `TRUNC` elimina la fracción → años cumplidos, no redondeados.

**Validación:** si el `id_lector` no existe → error -20110.

**Demo:**
```sql
-- Ver edad de varios lectores con su fecha de nacimiento para verificar
SELECT
  l.doc_identidad,
  l.fecha_nac,
  MJV_edad_miembro(l.id_lector) AS edad_actual
FROM MJV_lector l
WHERE l.doc_identidad IN ('V-ADU01', 'V-JOV01', 'V-NIN01')
ORDER BY l.doc_identidad;
```

> Si la profe pregunta por qué TRUNC y no FLOOR o ROUND: ROUND podría sumar un año antes del cumpleaños; FLOOR funciona igual que TRUNC para positivos, pero TRUNC es semánticamente más claro en fechas en Oracle.

---

### `MJV_antiguedad_en_club_miembro(p_id_lector, p_id_club)`

**Qué hace:** devuelve los años completos que lleva un lector en un club específico.

**Fórmula:** `TRUNC(MONTHS_BETWEEN(NVL(fecha_f, SYSDATE), fecha_i) / 12)`
- Busca el registro con `estatus = 'activo'` en `MJV_historia_membresia`.
- Si ya fue retirado (fecha_f NOT NULL), calcula desde `fecha_i` hasta `fecha_f`.
- Si sigue activo (fecha_f NULL), calcula desde `fecha_i` hasta `SYSDATE`.

**Validación:** si no hay membresía activa → error -20111.

**Demo:**
```sql
-- Antigüedad de todos los miembros activos del Refugio Literario del Sur
SELECT
  l.doc_identidad,
  l.p_nombre || ' ' || l.p_apellido AS nombre,
  MJV_antiguedad_en_club_miembro(l.id_lector,
    (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur')
  ) AS anios_en_club
FROM MJV_lector l
JOIN MJV_historia_membresia hm ON hm.id_lector = l.id_lector
WHERE hm.id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur')
  AND hm.estatus = 'activo'
ORDER BY l.doc_identidad;
```

> Todos los miembros entraron el 01/01/2026 y hoy es 2026, así que el resultado será 0 años (menos de 12 meses). Ese es el resultado correcto — si la profe cuestiona, confirmar que la función es correcta y los datos son recientes.

---

### `MJV_promedio_part_mensual_tipo_grupo(p_id_club, p_tipo_grupo, p_mes, p_anio)`

**Qué hace:** devuelve el % promedio de asistencia de todos los grupos de un tipo en un club, para un mes y año específico.

**Cómo calcula:**
1. Para cada grupo del tipo indicado en el club, cuenta cuántas "oportunidades de asistencia" hubo (reuniones realizadas × miembros activos en ese periodo).
2. Cuenta cuántas inasistencias se registraron para ese grupo en ese mes.
3. Calcula `((esperadas - faltas) / esperadas) × 100` por grupo.
4. Promedia los porcentajes de todos los grupos del tipo.

**Validación:** si `p_mes` no está entre 1 y 12 → error -20120. Si no hay datos → retorna 0.

**Demo (con los datos de la sección 20):**
```sql
SELECT MJV_promedio_part_mensual_tipo_grupo(
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'),
  'adultos',
  1,     -- enero
  2026
) AS pct_participacion FROM DUAL;
-- Resultado esperado: 50
-- Matemática: 4 miembros × 2 reuniones = 8 esperadas. 4 faltas. (8-4)/8*100 = 50
```

**También se puede ver en la vista de soporte:**
```sql
SELECT * FROM MJV_v_participacion_mensual_tipo_grupo
WHERE nombre_club = 'Refugio Literario del Sur'
  AND mes = 1 AND anio = 2026;
```

---

### `MJV_participacion_bimestre_miembro(p_id_lector, p_id_club, p_bimestre, p_anio)`

**Qué hace:** devuelve el % de asistencia individual de un lector en un bimestre.

**Bimestres:**
| Número | Meses |
|---|---|
| 1 | Enero – Febrero |
| 2 | Marzo – Abril |
| 3 | Mayo – Junio |
| 4 | Julio – Agosto |
| 5 | Septiembre – Octubre |
| 6 | Noviembre – Diciembre |

**Cómo calcula:**
1. Cuenta reuniones realizadas (`realizada = 'S'`) dentro del bimestre en las que el lector estaba activo en su `g_lec`.
2. Si esperadas = 0 → retorna 100 (no se penaliza sin reuniones).
3. Cuenta sus filas en `MJV_inasistencia` para ese periodo.
4. Retorna `((esperadas - faltas) / esperadas) × 100`.

**Validación:** si `p_bimestre` no está entre 1 y 6 → error -20121.

**Demo (con los datos de la sección 20):**
```sql
SELECT
  l.doc_identidad,
  l.p_nombre || ' ' || l.p_apellido AS nombre,
  MJV_participacion_bimestre_miembro(
    l.id_lector,
    (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'),
    1,    -- bimestre 1: ene-feb
    2026
  ) AS pct_asistencia
FROM MJV_lector l
WHERE l.doc_identidad IN ('V-ADU01', 'V-ADU02', 'V-ADU03', 'V-ADU04')
ORDER BY l.doc_identidad;
```

**Resultados esperados:**
| doc_identidad | Faltas | Resultado |
|---|---|---|
| V-ADU01 | 0 de 2 | **100%** |
| V-ADU02 | 2 de 2 | **0%** |
| V-ADU03 | 1 de 2 | **50%** |
| V-ADU04 | 1 de 2 | **50%** |

**También se puede ver en la vista de soporte:**
```sql
SELECT * FROM MJV_v_asistencia_bimestre
WHERE nombre_club = 'Refugio Literario del Sur'
  AND bimestre = 1 AND anio = 2026;
```

> Punto de conexión con la regla de negocio: V-ADU02 tiene 0% → supera el 30% de inasistencias del bimestre → es candidato a retiro según las reglas del enunciado (pág. X). `MJV_inasistencia` es tipo Salida precisamente porque registra este evento para que el sistema pueda tomar esa acción.

---

## Orden recomendado para la demo completa

1. Verificar estructura: `SELECT object_type, COUNT(*) FROM user_objects WHERE object_type IN ('TABLE','SEQUENCE','TRIGGER','INDEX') GROUP BY object_type;`
2. Mostrar inserts de tablas Entrada representativas (pais, lector, libro, club).
3. `MJV_conversion_monetaria` — conversión USD→VES, caso mismo código, caso error.
4. `MJV_edad_miembro` — tabla con ADU01, JOV01, NIN01 y sus fechas.
5. `MJV_antiguedad_en_club_miembro` — todos los miembros del Refugio, resultado 0 años (correcto).
6. `MJV_promedio_part_mensual_tipo_grupo` — resultado 50, explicar la matemática.
7. `MJV_participacion_bimestre_miembro` — los 4 lectores, mostrar la tabla de resultados.
8. Mostrar vistas de soporte `MJV_v_participacion_mensual_tipo_grupo` y `MJV_v_asistencia_bimestre` para reforzar visualmente.
