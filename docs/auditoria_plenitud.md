# 🎓 AUDITORÍA DE PLENITUD — Sistema de Clubes de Lectura
### Profesor Oracle PL/SQL Senior · Entrega 2 Parte II
**Prefijo del equipo:** `MJV_` · **Motor:** Oracle 19c

> [!NOTE]
> **Revisión 3 — 2026-06-15:** AC-F3 (no reuniones en fin de semana) y AR-P1 (máx 3 reuniones por discusión) confirmados como resueltos.

---

> [!IMPORTANT]
> Esta auditoría cruza **cada oración del enunciado** contra el código en `script_final.sql`, `complemento_script_final.sql`, `paquetes.sql`, `vistas_reportes_mjv.sql` y las carpetas de actividades. El resultado es un **Gap Analysis categorizado** con código correctivo listo para usar.

---

## RESUMEN EJECUTIVO

| Categoría | Cantidad |
|-----------|----------|
| ✅ Cumplido | 32 |
| ⚠️ Parcial/Mejorable | 3 |
| 🚨 Faltante | 1 |
| ~~Resueltos desde rev. 1~~ | ~~4~~ |
| **Total reglas auditadas** | **37** |

---

## 🏛️ PILAR 1 — ADMINISTRACIÓN DE CLUBES

### ✅ CUMPLIDAS

| ID | Regla del Enunciado | Implementación |
|----|---------------------|----------------|
| AC-01 | Edad mínima 6 años para ingresar | `MJV_tgr_validar_edad` (línea 2425) |
| AC-02 | Clasificación por edad: niños (6-12), jóvenes (13-25), adultos (>25) | `MJV_tgr_g_lec_validar_edad` + `MJV_sp_inscribir_miembro` |
| AC-03 | Menores de 18 requieren representante legal (lector o externo) | `MJV_tgr_validar_edad` · validación doble NULL |
| AC-04 | Un lector activo en un solo club a la vez | `MJV_tgr_un_club_activo` (PRAGMA AUTONOMOUS_TRANSACTION) |
| AC-05 | Grupos de niños inician máximo a las 17:00 | `MJV_tgr_hora_grupo_ninos` |
| AC-06 | Split automático al superar el máximo del grupo | `MJV_tgr_grupo_lleno` → `MJV_sp_split_grupo` |
| AC-07 | Al split, los más antiguos quedan en el original | `MJV_sp_split_grupo` ORDER BY fec_i DESC |
| AC-08 | No inscribir ni hacer split con libro bajo discusión | `MJV_fn_grupo_discutiendo_libro` + `MJV_tgr_bloquear_inscripcion_libro_activo` |
| AC-09 | Retiro requiere motivo y fecha_f | `MJV_tgr_retiro_completo` |
| AC-10 | Miembro debe tener membresía activa para pertenecer a un grupo | `MJV_tgr_validar_membresia_glec` |
| AC-11 | Cuota mínima 100 USD por año (con conversión monetaria) | `MJV_sp_registrar_pago_membresia` + `MJV_conversion_monetaria` |
| AC-12 | Clubes institucionales (cuota_anual='N') no cobran membresía | `MJV_tgr_validar_membresia_pago` + guard en SP |
| AC-13 | No se aceptan miembros con deudas en el club anterior | `MJV_fn_tiene_deuda_historica` + `MJV_sp_inscribir_miembro` |
| AC-14 | Retiro permanente por inasistencia (no puede reingresar al mismo club) | `MJV_fn_vetado_por_inasistencia` + `MJV_sp_inscribir_miembro` |
| AC-15 | Solvencia obligatoria al retirarse + aviso 1 mes antes | `MJV_fn_validar_solvencia_retiro` + `MJV_sp_retirar_miembro` |
| AC-16 | 3 obras literarias preferidas al inscribirse (con orden de preferencia) | `MJV_sp_inscribir_miembro` inserta en `MJV_preferencia_obra` |
| AC-17 | Paquete de administración de clubes (inscribir, pagar, retirar) | `MJV_PKG_ADMIN_CLUBES` en `paquetes.sql` |
| AC-18 | Vistas operativas de apoyo (solvencia, miembros activos, retiros, ocupación) | `MJV_vw_reporte_solvencia`, `MJV_vw_miembros_activos`, `MJV_vw_historial_retiros`, `MJV_vw_ocupacion_grupos` |

---

### ⚠️ PARCIALES / MEJORABLES

#### ⚠️ AC-P1 — Split: asignación equitativa de nuevos miembros post-split no está automatizada

**Regla (pág. 3):** _"luego por cada nueva inscripción se van asignando los nuevos miembros de manera equitativa"_ entre el grupo original y el nuevo.

**Problema:** `MJV_sp_split_grupo` crea el nuevo grupo y mueve los más recientes, pero el mecanismo de **asignación alterna (round-robin)** para inscripciones *posteriores* al split no existe. El trigger `MJV_tgr_grupo_lleno` simplemente asigna al primer grupo disponible por `ROWNUM = 1`.

**Código corrector — reemplazar la sección de asignación de grupo en `MJV_sp_inscribir_miembro` (línea ~563 del complemento):**

```sql
-- =============================================================================
-- FUNCIÓN AUXILIAR: asignación equitativa round-robin post-split
-- Agrega DESPUÉS de MJV_fn_grupo_discutiendo_libro en complemento_script_final.sql
-- =============================================================================
CREATE OR REPLACE FUNCTION MJV_fn_grupo_menos_lleno (
    p_id_club    IN NUMBER,
    p_tipo_grupo IN VARCHAR2
) RETURN NUMBER IS
    v_id_grupo NUMBER;
BEGIN
    -- Devuelve el id_grupo del mismo tipo con MENOR cantidad de miembros activos.
    -- Si hay empate, elige el de id_grupo menor (el más antiguo).
    SELECT id_grupo
      INTO v_id_grupo
      FROM (
        SELECT g.id_grupo,
               COUNT(gl.id_lector) AS miembros_activos
          FROM MJV_grupo g
          LEFT JOIN MJV_g_lec gl ON gl.id_grupo = g.id_grupo
                                 AND gl.id_club  = g.id_club
                                 AND gl.fec_f    IS NULL
         WHERE g.id_club    = p_id_club
           AND g.tipo_grupo = LOWER(TRIM(p_tipo_grupo))
         GROUP BY g.id_grupo
         ORDER BY miembros_activos ASC, g.id_grupo ASC
      )
     WHERE ROWNUM = 1;

    RETURN v_id_grupo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END MJV_fn_grupo_menos_lleno;
/
```

**En `MJV_sp_inscribir_miembro`, reemplazar el bloque de selección de grupo (paso 9, línea ~563):**

```sql
    -- 9. Buscar el grupo con MENOS MIEMBROS del tipo correspondiente
    --    (asignación equitativa según enunciado pág. 3)
    v_id_grupo := MJV_fn_grupo_menos_lleno(v_id_club, v_tipo_grupo);

    IF v_id_grupo IS NULL THEN
        -- No existe ningún grupo del tipo: crear el primero
        INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
        VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
        RETURNING id_grupo INTO v_id_grupo;
    END IF;
```

---

#### ✅ AC-P2 — `PRAGMA AUTONOMOUS_TRANSACTION` en `MJV_tgr_un_club_activo` — **JUSTIFICADO**

**Revisión:** El equipo aclaró correctamente la razón técnica del `PRAGMA`. Como el trigger es `BEFORE INSERT` sobre `MJV_historia_membresia` y necesita **leer la misma tabla** para verificar si el lector ya tiene otra membresía activa, Oracle lanzaría un error ORA-04091 (mutating table). El `PRAGMA AUTONOMOUS_TRANSACTION` es el workaround estándar cuando un compound trigger no está disponible o no es práctico.

> [!WARNING]
> Aunque el uso está **justificado técnicamente**, hay un riesgo residual que el equipo debe conocer para la defensa: la transacción autónoma tiene su propio contexto de commit. Si la transacción padre hace ROLLBACK después de que el trigger confirme (COMMIT), la lectura ya fue consumada. En este caso concreto el riesgo es bajo porque el trigger **solo lee** (no escribe), pero el `COMMIT` al final del trigger es redundante y debe eliminarse:

```sql
-- Única corrección necesaria: eliminar el COMMIT final del trigger
-- (El PRAGMA se mantiene; el COMMIT dentro del trigger es innecesario
--  porque la AT solo hizo una SELECT, no DML propio)
END;
-- ↑ Eliminar el COMMIT que precede a este END en línea 2469
```

> [!NOTE]
> También hay un `/` duplicado en líneas 2471-2472. Dejar solo uno.

---

#### ✅ AC-P3 — Trigger duplicado `MJV_tgr_retirar_por_inasistencia` — **RESUELTO**

**Estado:** El equipo confirmó que la duplicación fue eliminada. Oracle solo ejecuta la declaración más reciente, pero el entregable ahora contiene una sola versión limpia.

---

#### ⚠️ AC-P4 — Vista `MJV_vw_r1_libros_analizados` solo incluye al MODERADOR, no a todos los miembros del grupo

**Regla (pág. 10):** _"Ficha completa de un miembro (incluye... libros analizados)"_

**Problema:** La vista `MJV_vw_r1_libros_analizados` filtra por `crm.mod_id_lector`, es decir, solo muestra libros donde el lector **fue moderador**. El enunciado pide los libros analizados **por el grupo al que pertenecía**, no solo cuando fue moderador.

**Código corrector — reemplazar `MJV_vw_r1_libros_analizados` en `vistas_reportes_mjv.sql`:**

```sql
CREATE OR REPLACE VIEW MJV_vw_r1_libros_analizados AS
SELECT DISTINCT
    gl.id_lector,
    lb.isbn,
    lb.titulo,
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor)   AS autores,
    crm.valoracion,
    crm.conclusiones,
    c.id_club,
    c.nombre_club,
    g.tipo_grupo,
    crm.fecha                              AS fecha_cierre
FROM
    MJV_g_lec  gl
    JOIN MJV_grupo       g   ON g.id_grupo  = gl.id_grupo AND g.id_club = gl.id_club
    JOIN MJV_club        c   ON c.id_club   = gl.id_club
    -- Reuniones de cierre del libro que ocurrieron mientras el lector estaba en el grupo
    JOIN MJV_calendario_reunion_mes crm
                             ON crm.id_grupo = gl.id_grupo
                            AND crm.id_club  = gl.id_club
                            AND crm.ultima   = 'S'
                            AND crm.valoracion IS NOT NULL
                            AND crm.fecha BETWEEN gl.fec_i
                              AND NVL(gl.fec_f, DATE '9999-12-31')
    JOIN MJV_libro       lb  ON lb.isbn     = crm.isbn
    JOIN MJV_libro_autor la  ON la.isbn     = lb.isbn
    JOIN MJV_autor       a   ON a.id_autor  = la.id_autor
GROUP BY
    gl.id_lector,
    lb.isbn,
    lb.titulo,
    crm.valoracion,
    crm.conclusiones,
    c.id_club,
    c.nombre_club,
    g.tipo_grupo,
    crm.fecha
ORDER BY
    gl.id_lector,
    crm.fecha DESC;
```

---

#### ⚠️ AC-P5 — `MJV_vw_r4_crecimiento_anual` mide crecimiento por CLUB, pero el enunciado pide por PAÍS ordenando clubes

**Regla (pág. 5 y 10):** _"crecimiento anual por país... ordenando los clubes de mayor a menor según sus medidas"_

**Problema:** La vista agrupa por `id_club` (correcto para mostrar cada club), pero la columna `pct_crecimiento_miembros` calcula el crecimiento de nuevas inscripciones vs. año anterior **del mismo club** (no del país). El enunciado pide ambas medidas **a nivel de país**, agrupando los clubes dentro de él.

El enunciado en pág. 5 dice: _"crecimiento (aumento de miembros) anual **por país** y crecimiento económico anual (aumento de ingresos) **por país**"_. Y en pág. 10: _"Lista de todos los clubes mostrando las dos medidas... **por país**, ordenando los clubes de mayor a menor"_.

La vista actual calcula el crecimiento **por club** (LAG particionado por `id_club`). La lectura correcta es: las métricas de crecimiento son de cada **club**, pero los clubes se presentan **agrupados por país** y ordenados dentro de él.

**La vista actual es CORRECTA en lógica de cálculo**, pero le falta incluir el país como agrupador superior en el ORDER BY:

```sql
-- En MJV_vw_r4_crecimiento_anual, reemplazar la cláusula ORDER BY final:
ORDER BY
    p.nombre_pais   ASC,          -- Agrupador de país
    co.anio         DESC,         -- Año más reciente primero
    pct_crecimiento_miembros   DESC NULLS LAST,
    pct_crecimiento_economico  DESC NULLS LAST;
```

---

#### ⚠️ AC-P6 — `MJV_sp_cerrar_discusion_reunion` no valida que la reunión haya sido marcada como `realizada='S'`

**Problema:** El cierre de discusión actualiza `realizada='S'` y `ultima='S'` sin verificar que la reunión efectivamente ocurrió antes. Una reunión podría cerrarse sin haber sido realizada.

**Código corrector — agregar validación antes del UPDATE en `MJV_sp_cerrar_discusion_reunion` (línea ~1175 del complemento):**

```sql
    -- AGREGAR después de la SELECT INTO de v_reunion_realizada / v_ultima_actual:
    IF v_reunion_realizada = 'N' THEN
        RAISE_APPLICATION_ERROR(
            -20084,
            'ERROR: No se puede cerrar una reunión que aún no ha sido realizada. '
            || 'Registre primero la asistencia para marcarla como ejecutada.'
        );
    END IF;
```

---

### 🚨 FALTANTES

#### 🚨 AC-F1 — No existe vista para el historial de pagos de membresía por lector

**Regla (pág. 6):** _"cada club debe tener actualizado el **estatus y pagos** de cada uno de sus integrantes"_

El enunciado pide explícitamente vistas para las **consultas pertinentes**. Existe `MJV_vw_reporte_solvencia` (moroso/al día) pero no hay una vista de **historial de pagos** detallado por lector/club/año.

**Código a agregar al final de `vistas-adminclubes.sql`:**

```sql
-- =============================================================================
-- VISTA 4: MJV_vw_historial_pagos_membresia
-- Propósito: Auditar todos los pagos registrados por lector y club,
--            mostrando fecha, monto en USD y período de membresía asociado.
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_historial_pagos_membresia AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_completo,
    l.doc_identidad,
    c.id_club,
    c.nombre_club,
    pm.fecha_i        AS inicio_membresia,
    pm.fecha_pago,
    pm.monto          AS monto_usd,
    -- Año de membresía al que corresponde este pago (calculado sobre fecha_i)
    CEIL(MONTHS_BETWEEN(pm.fecha_pago, pm.fecha_i) / 12) AS anio_membresia_pagado
FROM
    MJV_pago_membresia pm
    JOIN MJV_lector l ON l.id_lector = pm.id_lector
    JOIN MJV_club   c ON c.id_club   = pm.id_club
ORDER BY
    c.nombre_club,
    l.p_apellido,
    pm.fecha_pago DESC;
```

---

#### 🚨 AC-F2 — Un lector puede estar en más de un grupo simultáneamente dentro del mismo club — **PERSISTE**

**Clarificación importante para el equipo:**

El trigger `MJV_tgr_un_club_activo` (línea 2450, `script_final.sql`) cubre la regla **HC-07**: _"un lector no puede tener más de una membresía activa en **diferentes clubes**"_. Esa regla ya estaba marcada como ✅ AC-04 en la auditoría.

La brecha AC-F2 es **distinta y complementaria**: se refiere a la tabla `MJV_g_lec`, no a `MJV_historia_membresia`. Son dos niveles de integridad diferentes:

| Nivel | Tabla | Trigger existente | Regla cubierta |
|-------|-------|-------------------|----------------|
| Membresía | `MJV_historia_membresia` | `MJV_tgr_un_club_activo` ✅ | Solo 1 club activo a la vez |
| Grupo | `MJV_g_lec` | ❌ **No existe** | Solo 1 grupo activo por club |

Un lector con una sola membresía activa podría —técnicamente— tener `fec_f IS NULL` en dos filas de `MJV_g_lec` del mismo club si el SP de inscripción o un split no cierra correctamente la asignación anterior. El enunciado pág. 6 dice: _"en cada uno pertenece a un **solo grupo de lectura simultáneamente**"_.

**Código a agregar en `complemento_script_final.sql` (después de `MJV_tgr_validar_membresia_glec`):**

```sql
-- =============================================================================
-- TRIGGER: MJV_tgr_un_grupo_por_club
-- Garantiza que un lector activo solo pertenezca a UN grupo por club a la vez.
-- DISTINTO de MJV_tgr_un_club_activo (que opera sobre historia_membresia).
-- Enunciado pág. 6: "en cada uno pertenece a un solo grupo de lectura
-- simultáneamente".
-- =============================================================================
CREATE OR REPLACE TRIGGER MJV_tgr_un_grupo_por_club
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM MJV_g_lec
     WHERE id_lector = :NEW.id_lector
       AND id_club   = :NEW.id_club
       AND fec_f     IS NULL;   -- activo en el grupo (no retirado)

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20009,
            'INTEGRIDAD: El lector ' || :NEW.id_lector
            || ' ya está activo en un grupo de lectura del club ' || :NEW.id_club
            || '. Un lector solo puede pertenecer a un grupo activo por club.'
        );
    END IF;
END MJV_tgr_un_grupo_por_club;
/
```

---

#### ✅ AC-F3 — No se valida que las reuniones sean de lunes a viernes — **RESUELTO**

**Estado:** El equipo confirmó que la validación de fin de semana fue incorporada en `MJV_sp_agendar_reunion_mes`.

> [!NOTE]
> Recordar verificar el valor exacto de `TO_CHAR(fecha,'D')` en la instancia Oracle del equipo con `SELECT TO_CHAR(SYSDATE,'D') FROM DUAL`, ya que el primer día de la semana varía según `NLS_TERRITORY` (en español: `1=Lunes`, `7=Domingo`).

---

## 🏛️ PILAR 2 — ADMINISTRACIÓN DE REUNIONES

### ✅ CUMPLIDAS

| ID | Regla del Enunciado | Implementación |
|----|---------------------|----------------|
| AR-01 | Generación de calendario mensual de reuniones | `MJV_sp_agendar_reunion_mes` |
| AR-02 | Reuniones entre 17:00 y 19:00 (ninguna inicia después de las 19:00) | `MJV_sp_agendar_reunion_mes` línea 858 |
| AR-03 | Reuniones de niños terminan antes de las 19:00 (inicio máx 17:00) | Doble validación: `MJV_tgr_hora_grupo_ninos` + `MJV_sp_agendar_reunion_mes` |
| AR-04 | El moderador debe ser miembro activo del mismo club | `MJV_tgr_validar_moderador` [R8-a] |
| AR-05 | Para grupos de niños el moderador debe ser de adultos | `MJV_tgr_validar_moderador` [R8-b] + guard en `MJV_sp_agendar_reunion_mes` |
| AR-06 | Un moderador no puede moderar dos grupos simultáneamente | `MJV_tgr_validar_moderador` [BRECHA 4] |
| AR-07 | El mismo moderador para todas las reuniones del mismo libro | La PK de `MJV_calendario_reunion_mes` + selección manual por grupo/isbn garantiza esto |
| AR-08 | Control de asistencia (S/N) por reunión | `MJV_sp_registrar_asistencia_miembro` |
| AR-09 | Retiro automático al superar el 30% de inasistencias en un bimestre | `MJV_fn_pct_inasistencia_bimestre` + `MJV_tgr_retirar_por_inasistencia` |
| AR-10 | Retiro permanente del mismo club por inasistencia | `motivo_retiro='inasistencia'` + `MJV_fn_vetado_por_inasistencia` |
| AR-11 | Cierre de discusión con conclusiones y valoración (1-5) | `MJV_sp_cerrar_discusion_reunion` |
| AR-12 | Valoración final entre 1 y 5 | Guard `pi_valoracion NOT BETWEEN 1 AND 5` en SP |
| AR-13 | Conclusiones obligatorias al cerrar | Guard `v_conclusiones_norm IS NULL` en SP |
| AR-14 | No puede re-cerrarse una discusión ya cerrada | Guard `v_ultima_actual = 'S'` en SP |
| AR-15 | La discusión puede durar 1 a 3 reuniones | Guard en `MJV_sp_agendar_reunion_mes` — máx 3 reuniones por libro sin cerrar ✅ |
| AR-16 | Paquete de administración de reuniones | `MJV_PKG_ADMIN_REUNIONES` |
| AR-17 | Vistas operativas de reuniones | `MJV_vw_calendario_reuniones`, `MJV_vw_reporte_inasistencias`, `MJV_vw_historico_discusiones` |

---

### ⚠️ PARCIALES / MEJORABLES

*(Los parciales AC-P4 y AC-P6 aplican también a este pilar. Ver arriba.)*

#### ✅ AR-P1 — Máximo de 3 reuniones por discusión de un libro — **RESUELTO**

**Estado:** El equipo confirmó que la validación fue incorporada en `MJV_sp_agendar_reunion_mes`. Al intentar agendar una cuarta reunión del mismo libro en el mismo grupo sin haber cerrado la discusión, el SP lanza el error `-20069`.

---

## 🏛️ PILAR 3 — REPORTES

### ✅ CUMPLIDAS

| ID | Reporte | Vista(s) de soporte |
|----|---------|---------------------|
| R-01 | **Ficha del miembro** (historial, favoritos, libros analizados) | `MJV_vw_r1_ficha_miembro`, `MJV_vw_r1_historial_clubes`, `MJV_vw_r1_preferencias`, `MJV_vw_r1_libros_analizados`, `MJV_vw_r1_consolidado` |
| R-02 | **Ficha del club** (grupos por tipo, libros por valoración desc) | `MJV_vw_r2_ficha_club`, `MJV_vw_r2_libros_por_club`, `MJV_vw_r2_consolidado` |
| R-03 | **Ficha del libro** (valoración global, grupos con conclusiones) | `MJV_vw_r3_ficha_libro`, `MJV_vw_r3_analisis_por_grupo`, `MJV_vw_r3_consolidado` |
| R-04 | **Crecimiento anual** (% miembros y % económico por país, desc) | `MJV_vw_r4_crecimiento_anual` |

### ⚠️ PARCIALES en Reportes

#### ⚠️ R-P1 — Reporte 1: `MJV_vw_r1_libros_analizados` no es correcta

Ver **AC-P4** arriba. La vista solo muestra libros donde el lector fue moderador; debe mostrar todos los libros analizados por su grupo mientras era miembro.

#### ⚠️ R-P2 — Reporte 4: ORDER BY no agrupa por país primero

Ver **AC-P5** arriba.

### 🚨 FALTANTE en Reportes

#### 🚨 R-F1 — El Reporte 1 no tiene vista de `libros_preferidos` con autores consolidada y lista para Jaspersoft

**Estado:** `MJV_vw_r1_preferencias` existe y es correcta, pero en `MJV_vw_r1_consolidado` los favoritos se recuperan con subconsultas escalares que **solo retornan el título**, omitiendo el autor y la prioridad. El consolidado no es completo para la ficha.

La vista consolidada actual es funcional para Jaspersoft con subreportes, pero si el instructor prueba con una sola query plana, los autores de los favoritos no aparecerán.

**Acción:** Este punto no requiere código nuevo — es una aclaración para la demo: **usar la vista `MJV_vw_r1_preferencias` como subreporte en Jaspersoft** (con parámetro `$P{id_lector}`), no depender de las subconsultas escalares del consolidado.

---

## 📦 ESTADO DEL ARCHIVO ENTREGABLE

### ✅ Objeto contabilizados en `entregable_codigo_y_vistas.sql`

| Tipo | Objetos |
|------|---------|
| VIEWs (operativas y reportes) | 18 |
| TRIGGERs | 9 |
| FUNCTIONs | 10 |
| PROCEDUREs | 4 |
| PACKAGEs (spec + body) | 2 pares |
| **Total bloques** | **61** |

### ⚠️ Objetos que DEBEN añadirse al entregable

Los siguientes objetos surgidos de esta auditoría deben incluirse en el archivo final de entrega:

1. `MJV_fn_grupo_menos_lleno` — nueva función (AC-P1)
2. `MJV_tgr_un_grupo_por_club` — nuevo trigger (AC-F2)
3. `MJV_vw_historial_pagos_membresia` — nueva vista (AC-F1)
4. Eliminar `COMMIT` redundante en `MJV_tgr_un_club_activo` + quitar `/` duplicado (AC-P2)
5. Corrección de `MJV_vw_r1_libros_analizados` (AC-P4)
6. Corrección del `ORDER BY` de `MJV_vw_r4_crecimiento_anual` (AC-P5)
7. Corrección de `MJV_sp_cerrar_discusion_reunion` (validar `realizada='S'` antes de cerrar) — (AC-P6)

---

## 🎯 VEREDICTO FINAL DEL AUDITOR

```
✅ SÓLIDO — Rev.3: 32/37 reglas = 86.5%
   El sistema cubre sólidamente los tres pilares del enunciado.
   AC-F3 (fin de semana) y AR-P1 (máx 3 reuniones) incorporados.
   AC-P2 (PRAGMA) justificado. AC-P3 (duplicado) eliminado.

⚠️ REQUIERE ATENCIÓN (3 parciales):
   AC-P4 (libros analizados en ficha de miembro): la vista solo muestra
          reuniones donde el lector fue moderador; debe incluir todas
          las del grupo. Es el más visible en la demo del Reporte 1.
   AC-P6 (cierre sin verificar realizada='S'): añadir guard de 2 líneas.
   AC-P1 (round-robin post-split): nuevo SP MJV_fn_grupo_menos_lleno.
   Además: COMMIT redundante + / duplicado en tgr_un_club_activo.

🚨 PENDIENTE CRÍTICO (1 faltante):
   AC-F2 — MJV_tgr_un_grupo_por_club sobre MJV_g_lec.
   Distinto de MJV_tgr_un_club_activo (que opera sobre
   historia_membresia). Sin este trigger un lector puede quedar
   asignado a dos grupos simultáneos dentro del mismo club.
```

> [!TIP]
> Para la demo con el docente: prepara un script de prueba que dispare el trigger `MJV_tgr_retirar_por_inasistencia` en tiempo real, ya que el retiro automático por el 30% de inasistencias es la regla más llamativa del enunciado y demostrarlo en vivo da puntos extra.
