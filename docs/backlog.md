# Backlog Completo: Implementación de la Estructura de la Base de Datos

Este documento contiene el plan de tareas detallado (backlog) para la fase de **Implementación de la estructura de la base de datos** del proyecto "Clubes de Lectura", organizado según la clasificación de entidades del Modelo Entidad-Relación: **Entrada (E)**, **Entrada/Salida (E/S)** y **Salida (S)**.

Las tareas se ordenan de acuerdo a las dependencias de llaves foráneas (`FK`) para evitar errores de creación en el manejador relacional Oracle.

---

## ✅ Tareas Realizadas (Diseño e Implementación Base)

### 📥 Entidades de Entrada (E)

- [X] **Modelado E-R:** Diseño y validación completa del Modelo Entidad-Relación (E-R).
- [X] **Diseño Lógico:** Estructuración y validación del esquema relacional.
- [X] **Clasificación de Volatilidad:** Clasificación de volatilidad de las tablas del sistema.
- [X] **Tablas y Secuencias DDL Creadas (en [tables.sql](file:///c:/Users/USUARIO/Downloads/bd/proyecto/sbd_202655_clubes_de_lectura/scripts/tables.sql)):**
  - [X] **`pais`** (con sequence `seq_pais`)
  - [X] **`ciudad`** (con sequence `seq_ciudad`)
  - [X] **`institucion`** (con sequence `seq_institucion`)
  - [X] **`idioma`** (con sequence `seq_idioma`)
  - [X] **`club`** (con sequence `seq_club`)
  - [X] **`representante`** (con sequence `seq_representante`)
  - [X] **`autor`** (con sequence `seq_autor`)
  - [X] **`libro`** (no requiere secuencia; PK es `isbn`)

### 🔄 Entidades de Entrada/Salida (E/S)

- [X] **Tablas y Secuencias DDL Creadas (en [tables.sql](file:///c:/Users/USUARIO/Downloads/bd/proyecto/sbd_202655_clubes_de_lectura/scripts/tables.sql)):**
  - [X] **`asociado`** (Relación reflexiva N:M de `club`)
  - [X] **`lector`** (con sequence `seq_lector` y trigger `tgr_validar_mayoria_edad`)
  - [X] **`idioma_miembro`** (con sequence `seq_idioma_miembro`)
  - [X] **`libro_autor`** (L-A: tabla asociativa N:M entre `libro` y `autor`)
  - [X] **`grupo`** (con sequence `seq_grupo`)

### 📤 Entidades de Salida (S)

- [X] *(Ninguna de las tablas de tipo Salida se encuentra implementada en tables.sql actualmente).*

---

## ⏳ Tareas Faltantes (Actionable Backlog)

### 1. Secuencias Faltantes

- [X] **Creación de secuencias adicionales para llaves subrogadas:**
  - [X] Crear `seq_pago_membresia` (para los pagos de membresías).
  - [X] Crear `seq_obra_actuada` (para identificar las obras teatrales).
  - [X] Crear `seq_funcion` (para el control de cada presentación programada).
  - [X] Crear `seq_voto_publico` (para folios de calificación de la obra).

### 2. Tablas Faltantes (Organizadas por Tipo y Dependencia de FK)

#### 📥 Entidades de Entrada (E)

- [X] **`OBRA_ACTUADA`** (Obras de teatro planificadas en base a los libros analizados)
  - *PK:* `(id_obra_act)` (Usa `seq_obra_actuada`)
  - *FK:* `isbn_libro` -> `libro(isbn)`, `id_club` -> `club(id_club)`

#### 🔄 Entidades de Entrada/Salida (E/S)

Las siguientes tablas deben crearse en este orden exacto para respetar la integridad referencial:

- [X] **`HISTORIA_MEMBRESÍA`** (Historial de afiliaciones de un lector en un club)
  - *PK:* `(id_lector, id_club, fecha_i)`
  - *FK:* `id_lector` -> `lector(id_lector)`, `id_club` -> `club(id_club)`
- [X] **`PREFERENCIA_OBRA`** (Tres obras literarias preferidas indicadas por el lector al afiliarse)
  - *PK:* `(id_lector, id_club, fecha_i, isbn)`
  - *FK:* `(id_lector, id_club, fecha_i)` -> `HISTORIA_MEMBRESÍA`, `isbn` -> `libro(isbn)`
- [X] **`G_LEC`** (Asociación activa e histórica de un miembro con un grupo de lectura)
  - *PK:* `(id_lector, id_club, fecha_i, id_grupo, fec_i)`
  - *FK:* `(id_lector, id_club, fecha_i)` -> `HISTORIA_MEMBRESÍA`, `id_grupo` -> `grupo(id_grupo)`
- [X] **`CALENDARIO_REUNION_MES`** (Planificación de las reuniones semanales de análisis de libros)
  - *PK:* `(id_grupo, fecha)`
  - *FK:* `id_grupo` -> `grupo(id_grupo)`, `isbn` -> `libro(isbn)`, `(id_lector, id_club, fecha_i)` -> `HISTORIA_MEMBRESÍA` (moderador)
- [X] **`ELENCO`** (Integrantes del elenco de una obra; miembros del club o de clubes asociados)
  - *PK:* `(id_lector, id_club, fecha_i, id_obra_act)`
  - *FK:* `(id_lector, id_club, fecha_i)` -> `HISTORIA_MEMBRESÍA`, `id_obra_act` -> `OBRA_ACTUADA(id_obra_act)`

#### 📤 Entidades de Salida (S)

Las siguientes tablas deben crearse respetando las dependencias:

- [X] **`PAGO_MEMBRESÍA`** (Registro anual de cobros de membresías independientes)
  - *PK:* `(id_lector, id_club, fecha_i, id_pago)` (Usa `seq_pago_membresia`)
  - *FK:* `(id_lector, id_club, fecha_i)` -> `HISTORIA_MEMBRESÍA`
- [X] **`INASISTENCIA`** (Control detallado de faltas de miembros del grupo a reuniones de discusión)
  - *PK:* `(id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec, fecha_reunion)`
  - *FK:* `(id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec)` -> `G_LEC`, `(id_grupo, fecha_reunion)` -> `CALENDARIO_REUNION_MES`
- [X] **`FUNCIÓN`** (Presentaciones específicas programadas para cada obra teatrada)
  - *PK:* `(id_funcion)` (Usa `seq_funcion`)
  - *FK:* `id_obra_act` -> `OBRA_ACTUADA(id_obra_act)`
- [X] **`VOTO_PÚBLICO`** (Registro de votación y estrellas del público asistente para evaluar la obra)
  - *PK:* `(id_voto)` (Usa `seq_voto_publico`)
  - *FK:* `id_funcion` -> `FUNCIÓN(id_funcion)`
- [X] **`MEJOR_ACTOR`** (Control de votos del público para premiar al mejor actor de la función)
  - *PK:* `(id_funcion, id_lector, id_club, fecha_i, id_obra_act)`
  - *FK:* `id_funcion` -> `FUNCIÓN(id_funcion)`, `(id_lector, id_club, fecha_i, id_obra_act)` -> `ELENCO`

### 3. Índices de Rendimiento y Optimización

Para optimizar las consultas y evitar bloqueos en el motor relacional Oracle, se deben crear índices en todas las llaves foráneas y campos de consulta repetida:

- [X] **Índices en Llaves Foráneas:**
  - [X] `idx_asociado_der` en `asociado(id_club_der)`
  - [X] `idx_lector_rep` en `lector(id_representante)`
  - [X] `idx_lector_rep_lec` en `lector(id_representante_lector)`
  - [X] `idx_idioma_miembro_club` en `idioma_miembro(id_club)`
  - [X] `idx_idioma_miembro_lector` en `idioma_miembro(id_lector)`
  - [X] `idx_libro_pais` en `libro(id_pais)`
  - [X] `idx_libro_sig` en `libro(id_libro_siguiente)`
  - [X] `idx_libro_autor_isbn` en `libro_autor(isbn)`
  - [X] `idx_grupo_club` en `grupo(id_club)`
  - [X] `idx_historia_membresia_club` en `HISTORIA_MEMBRESÍA(id_club)`
  - [X] `idx_preferencia_obra_isbn` en `PREFERENCIA_OBRA(isbn)`
  - [X] `idx_g_lec_grupo` en `G_LEC(id_grupo)`
  - [X] `idx_calendario_reunion_mes_isbn` en `CALENDARIO_REUNION_MES(isbn)`
  - [X] `idx_calendario_reunion_mes_mod` en `CALENDARIO_REUNION_MES(id_lector, id_club, fecha_i)` (moderador)
  - [X] `idx_obra_actuada_libro` en `OBRA_ACTUADA(isbn_libro)`
  - [X] `idx_obra_actuada_club` en `OBRA_ACTUADA(id_club)`
  - [X] `idx_funcion_obra` en `FUNCIÓN(id_obra_act)`
  - [X] `idx_elenco_obra` en `ELENCO(id_obra_act)`
  - [X] `idx_mejor_actor_elenco` en `MEJOR_ACTOR(id_lector, id_club, fecha_i, id_obra_act)`
- [X] **Índices para Búsqueda y Filtros Frecuentes:**
  - [X] `idx_lector_busqueda` en `lector(p_apellido, p_nombre)` (búsquedas recurrentes de socios).
  - [X] `idx_libro_titulo` en `libro(titulo)` (filtros rápidos de obras).
  - [X] `idx_club_nombre` en `club(nombre_club)` (búsqueda de clubes por nombre).

### 4. Vistas Lógicas Requeridas

- [ ] **`v_ficha_lector`:** Consolida los datos personales del miembro, club actual, grupo, histórico de afiliación, obras preferidas y lista de libros leídos/analizados.
- [ ] **`v_ficha_club`:** Reporta datos generales del club, recuento de grupos por categorías (adultos, jóvenes, niños) y catálogo histórico de libros evaluados por los grupos, ordenados de mayor a menor valoración.
- [ ] **`v_ficha_libro`:** Consolida datos del libro, puntuación promedio de valoración general e histórico de grupos que lo analizaron con sus respectivas conclusiones.
- [ ] **`v_crecimiento_clubes`:** Genera y procesa las estadísticas del porcentaje de crecimiento anual de miembros por país y crecimiento económico en ingresos de membresías.
- [ ] **`v_obras_presentadas`:** Genera un histórico de las obras actuadas por club con su valoración promedio e ingresos acumulados en taquilla.
- [ ] **`v_reuniones_mes`:** Detalla la programación mensual del calendario de debates.
- [ ] **`v_asistencia_bimestre`:** Totaliza el porcentaje de inasistencias bimestrales por lector y club.

### 5. Funciones PL/SQL o Equivalentes

- [X] **`conversion_monetaria()`**
  * **Propósito:** Convierte importes locales a dólares americanos (`USD`) como referencia unificada.
  * **Entrada:** `p_monto` (`NUMBER`), `p_moneda_origen` (`VARCHAR2`), `p_moneda_destino` (`VARCHAR2`), `p_fecha` (`DATE` por defecto `SYSDATE`).
  * **Retorno:** `NUMBER` (monto convertido).
- [X] **`edad_miembro()` / `antiguedad_en_club_miembro()`**
  * **Propósito:** Calcular edad o tiempo de permanencia del lector en un club.
  * **Entrada:** `p_id_lector` (`NUMBER`) para edad; `p_id_lector` (`NUMBER`) y `p_id_club` (`NUMBER`) para antigüedad.
  * **Retorno:** `NUMBER` (representa años para edad, y meses/años para antigüedad).
- [X] **`promedio_part_mensual_tipo_grupo()`**
  * **Propósito:** Porcentaje de asistencia promedio en reuniones mensuales por categoría de grupo.
  * **Entrada:** `p_id_club` (`NUMBER`), `p_tipo_grupo` (`VARCHAR2`), `p_mes` (`NUMBER`), `p_anio` (`NUMBER`).
  * **Retorno:** `NUMBER` (porcentaje de 0.00 a 100.00).
- [X] **`participacion_bimestre_miembro()`**
  * **Propósito:** Porcentaje de asistencia de un lector en un bimestre específico.
  * **Entrada:** `p_id_lector` (`NUMBER`), `p_id_club` (`NUMBER`), `p_bimestre` (`NUMBER`), `p_anio` (`NUMBER`).
  * **Retorno:** `NUMBER` (porcentaje de 0.00 a 100.00).
