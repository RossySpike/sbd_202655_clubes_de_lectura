-- =============================================================================
-- PROYECTO: Sistema de Gestión de Clubes de Lectura
-- ARCHIVO:  vistas_reportes_mjv.sql
-- AUTOR:    MJV
-- FECHA:    2026-06-14
-- MOTOR:    Oracle 19c
--
-- PROPÓSITO:
--   Vistas de soporte para los 4 reportes de Jaspersoft Studio.
--   Estrategia anti-producto-cartesiano: cada relación 1-N se separa en una
--   "Vista Principal" (cabecera) y "Vista(s) de Detalle".
--
-- CONVENCIÓN DE NOMBRES:  MJV_vw_<reporte>_<rol>
-- CONVENCIÓN DE NOMBRES:  p_nombre || ' ' || p_apellido || ' ' || s_apellido
--                         (con NVL donde s_apellido puede ser NULL)
-- =============================================================================


-- =============================================================================
-- REPORTE 1 — FICHA COMPLETA DE UN MIEMBRO
-- Parámetro Jaspersoft: $P{id_lector}
--
--   VW A — Cabecera: datos personales del lector
--   VW B — Detalle historial en cada club (1 fila por membresía)
--   VW C — Detalle 3 libros preferidos (ordenados por prioridad)
--   VW D — Detalle libros analizados (discusiones cerradas con valoración)
-- =============================================================================

-- ----------------------------------------------------------------------------
-- VW A: Datos personales del lector
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r1_ficha_miembro AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_completo,
    l.doc_identidad,
    l.telefono,
    l.email,
    CASE l.genero WHEN 'M' THEN 'Masculino' WHEN 'F' THEN 'Femenino' END AS genero,
    l.fecha_nac,
    -- Edad calculada en años completos al día de hoy
    TRUNC(MONTHS_BETWEEN(SYSDATE, l.fecha_nac) / 12) AS edad,
    p.nombre_pais      AS pais_nacimiento,
    p.nacionalidad
FROM
    MJV_lector l
    JOIN MJV_pais p ON p.id_pais = l.id_pais_nac;

-- ----------------------------------------------------------------------------
-- VW B: Historial completo de membresías del lector
--       Una fila por período en cada club (activo o retirado)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r1_historial_clubes AS
SELECT
    hm.id_lector,
    c.id_club,
    c.nombre_club,
    p.nombre_pais   AS pais_club,
    ci.nombre_ciudad AS ciudad_club,
    hm.fecha_i      AS fecha_ingreso,
    hm.fecha_f      AS fecha_retiro,
    hm.estatus,
    hm.motivo_retiro
FROM
    MJV_historia_membresia hm
    JOIN MJV_club   c  ON c.id_club  = hm.id_club
    JOIN MJV_pais   p  ON p.id_pais  = c.id_pais
    JOIN MJV_ciudad ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad
ORDER BY
    hm.id_lector,
    hm.fecha_i DESC;

-- ----------------------------------------------------------------------------
-- VW C: Los 3 libros preferidos del lector, ordenados por prioridad
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r1_preferencias AS
SELECT
    po.id_lector,
    po.prioridad,
    lb.isbn,
    lb.titulo,
    -- Autores concatenados (puede ser coautoría)
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor) AS autores,
    lb.genero,
    lb.primera_edicion
FROM
    MJV_preferencia_obra po
    JOIN MJV_libro      lb ON lb.isbn     = po.isbn
    JOIN MJV_libro_autor la ON la.isbn     = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor  = la.id_autor
GROUP BY
    po.id_lector,
    po.prioridad,
    lb.isbn,
    lb.titulo,
    lb.genero,
    lb.primera_edicion
ORDER BY
    po.id_lector,
    po.prioridad;

-- ----------------------------------------------------------------------------
-- VW D: Libros analizados por el lector como moderador de reuniones cerradas
--       (ultima = 'S' indica que el grupo ya terminó de analizar ese libro)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r1_libros_analizados AS
SELECT DISTINCT
    crm.mod_id_lector                                      AS id_lector,
    lb.isbn,
    lb.titulo,
    -- Autores concatenados
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor)                   AS autores,
    crm.valoracion,
    crm.conclusiones,
    c.nombre_club,
    g.tipo_grupo,
    crm.fecha                                              AS fecha_reunion
FROM
    MJV_calendario_reunion_mes crm
    JOIN MJV_libro      lb ON lb.isbn     = crm.isbn
    JOIN MJV_libro_autor la ON la.isbn    = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor = la.id_autor
    JOIN MJV_club        c  ON c.id_club  = crm.id_club
    JOIN MJV_grupo       g  ON g.id_grupo = crm.id_grupo AND g.id_club = crm.id_club
WHERE
    crm.ultima = 'S'       -- Solo reuniones de cierre con conclusiones y valoración
GROUP BY
    crm.mod_id_lector,
    lb.isbn,
    lb.titulo,
    crm.valoracion,
    crm.conclusiones,
    c.nombre_club,
    g.tipo_grupo,
    crm.fecha
ORDER BY
    crm.mod_id_lector,
    crm.fecha DESC;


-- =============================================================================
-- REPORTE 2 — FICHA DE UN CLUB
-- Parámetro Jaspersoft: $P{id_club}
--
--   VW A — Cabecera: datos del club + conteo de grupos por tipo
--   VW B — Detalle libros analizados en el club, ordenados por valoración promedio
-- =============================================================================

-- ----------------------------------------------------------------------------
-- VW A: Datos del club con conteo de grupos por tipo
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r2_ficha_club AS
SELECT
    c.id_club,
    c.nombre_club,
    p.nombre_pais,
    ci.nombre_ciudad,
    c.cod_postal,
    CASE c.cuota_anual WHEN 'S' THEN 'Independiente (cobra cuota)' ELSE 'Institucional (sin cuota)' END AS tipo_club,
    -- Cantidad de grupos por tipo (subconsulta escalar por tipo)
    NVL(
        (SELECT COUNT(*) FROM MJV_grupo g2
          WHERE g2.id_club = c.id_club AND g2.tipo_grupo = 'adultos'), 0
    ) AS grupos_adultos,
    NVL(
        (SELECT COUNT(*) FROM MJV_grupo g2
          WHERE g2.id_club = c.id_club AND g2.tipo_grupo = 'jovenes'), 0
    ) AS grupos_jovenes,
    NVL(
        (SELECT COUNT(*) FROM MJV_grupo g2
          WHERE g2.id_club = c.id_club AND g2.tipo_grupo = 'niños'), 0
    ) AS grupos_ninos,
    (SELECT COUNT(*) FROM MJV_grupo g2 WHERE g2.id_club = c.id_club) AS total_grupos
FROM
    MJV_club    c
    JOIN MJV_pais   p  ON p.id_pais  = c.id_pais
    JOIN MJV_ciudad ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad;

-- ----------------------------------------------------------------------------
-- VW B: Lista de libros analizados por el club, de mayor a menor valoración
--       Valoración promedio calculada entre todas las sesiones de cierre
--       del club para ese libro.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r2_libros_por_club AS
SELECT
    crm.id_club,
    lb.isbn,
    lb.titulo,
    -- Autores concatenados
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor)         AS autores,
    lb.genero,
    ROUND(AVG(crm.valoracion), 2)                AS valoracion_promedio_club,
    COUNT(DISTINCT crm.id_grupo)                 AS cantidad_grupos_que_lo_analizaron
FROM
    MJV_calendario_reunion_mes crm
    JOIN MJV_libro      lb ON lb.isbn     = crm.isbn
    JOIN MJV_libro_autor la ON la.isbn    = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor = la.id_autor
WHERE
    crm.ultima    = 'S'
    AND crm.valoracion IS NOT NULL
GROUP BY
    crm.id_club,
    lb.isbn,
    lb.titulo,
    lb.genero
ORDER BY
    crm.id_club,
    valoracion_promedio_club DESC;


-- =============================================================================
-- REPORTE 3 — FICHA DE UN LIBRO
-- Parámetro Jaspersoft: $P{isbn}
--
--   VW A — Cabecera: datos del libro + valoración global promedio (todos los clubes)
--   VW B — Detalle de clubes y grupos que lo analizaron, con sus conclusiones
-- =============================================================================

-- ----------------------------------------------------------------------------
-- VW A: Datos del libro y su valoración global
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r3_ficha_libro AS
SELECT
    lb.isbn,
    lb.titulo,
    lb.tipo_narrativa,
    lb.sinopsis,
    lb.genero,
    lb.primera_edicion,
    lb.total_paginas,
    p.nombre_pais          AS pais_origen,
    -- Autores concatenados (puede ser coautoría)
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor) AS autores,
    -- Valoración global: promedio de TODAS las sesiones de cierre de TODOS los clubes
    ROUND(
        (SELECT AVG(crm2.valoracion)
           FROM MJV_calendario_reunion_mes crm2
          WHERE crm2.isbn   = lb.isbn
            AND crm2.ultima = 'S'
            AND crm2.valoracion IS NOT NULL),
        2
    ) AS valoracion_global
FROM
    MJV_libro      lb
    JOIN MJV_pais       p  ON p.id_pais   = lb.id_pais
    JOIN MJV_libro_autor la ON la.isbn    = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor = la.id_autor
GROUP BY
    lb.isbn,
    lb.titulo,
    lb.tipo_narrativa,
    lb.sinopsis,
    lb.genero,
    lb.primera_edicion,
    lb.total_paginas,
    p.nombre_pais;

-- ----------------------------------------------------------------------------
-- VW B: Lista de grupos que analizaron el libro con las conclusiones de cierre
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW MJV_vw_r3_analisis_por_grupo AS
SELECT
    crm.isbn,
    c.id_club,
    c.nombre_club,
    p.nombre_pais    AS pais_club,
    ci.nombre_ciudad AS ciudad_club,
    g.id_grupo,
    g.tipo_grupo,
    crm.valoracion,
    crm.conclusiones,
    crm.fecha        AS fecha_cierre,
    -- Moderador del cierre
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_moderador
FROM
    MJV_calendario_reunion_mes crm
    JOIN MJV_club    c  ON c.id_club   = crm.id_club
    JOIN MJV_pais    p  ON p.id_pais   = c.id_pais
    JOIN MJV_ciudad  ci ON ci.id_pais  = c.id_pais  AND ci.id_ciudad = c.id_ciudad
    JOIN MJV_grupo   g  ON g.id_grupo  = crm.id_grupo AND g.id_club  = crm.id_club
    JOIN MJV_lector  l  ON l.id_lector = crm.mod_id_lector
WHERE
    crm.ultima     = 'S'
    AND crm.valoracion IS NOT NULL
ORDER BY
    crm.isbn,
    crm.valoracion DESC,
    crm.fecha DESC;


-- =============================================================================
-- REPORTE 4 — FINANCIERO Y DE CRECIMIENTO ANUAL DE CLUBES
-- Vista única: todos los clubes con % de crecimiento de miembros y económico
--              comparado año a año.
--
-- Lógica:
--   • "Año de operación" = año calendario (EXTRACT(YEAR FROM fecha_i)).
--   • Miembros por año = cantidad de nuevas membresías iniciadas ese año.
--   • Ingresos por año = SUM de pagos de membresía (equivalente 100 USD cada uno)
--     registrados ese año en ese club.
--   • LAG() calcula el valor del año anterior dentro del mismo club.
--   • Fórmula de crecimiento: ((Actual - Anterior) / NULLIF(Anterior, 0)) * 100
--     NULLIF evita ORA-01476 (división por cero).
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_r4_crecimiento_anual AS
WITH
-- CTE 1: Nuevas membresías por club y año de ingreso
miembros_por_anio AS (
    SELECT
        hm.id_club,
        EXTRACT(YEAR FROM hm.fecha_i)  AS anio,
        COUNT(*)                        AS nuevos_miembros
    FROM
        MJV_historia_membresia hm
    GROUP BY
        hm.id_club,
        EXTRACT(YEAR FROM hm.fecha_i)
),
-- CTE 2: Ingresos por membresías por club y año de pago
--         Solo se cuentan pagos de clubes que cobran cuota (cuota_anual = 'S')
ingresos_por_anio AS (
    SELECT
        pm.id_club,
        EXTRACT(YEAR FROM pm.fecha_pago) AS anio,
        SUM(pm.monto)                     AS ingresos_usd
    FROM
        MJV_pago_membresia pm
        JOIN MJV_club c ON c.id_club = pm.id_club
    WHERE
        c.cuota_anual = 'S'
    GROUP BY
        pm.id_club,
        EXTRACT(YEAR FROM pm.fecha_pago)
),
-- CTE 3: Unión de años existentes por club (puede que un año haya miembros pero
--         sin pagos aún, o viceversa)
anios_por_club AS (
    SELECT id_club, anio FROM miembros_por_anio
    UNION
    SELECT id_club, anio FROM ingresos_por_anio
),
-- CTE 4: Datos consolidados por club y año, con LAG para obtener año anterior
consolidado AS (
    SELECT
        ac.id_club,
        ac.anio,
        NVL(m.nuevos_miembros, 0)  AS nuevos_miembros,
        NVL(i.ingresos_usd, 0)     AS ingresos_usd,
        -- Año anterior: LAG particionado por club, ordenado por año
        LAG(NVL(m.nuevos_miembros, 0))
            OVER (PARTITION BY ac.id_club ORDER BY ac.anio) AS miembros_anio_anterior,
        LAG(NVL(i.ingresos_usd, 0))
            OVER (PARTITION BY ac.id_club ORDER BY ac.anio) AS ingresos_anio_anterior
    FROM
        anios_por_club     ac
        LEFT JOIN miembros_por_anio m ON m.id_club = ac.id_club AND m.anio = ac.anio
        LEFT JOIN ingresos_por_anio i ON i.id_club = ac.id_club AND i.anio = ac.anio
)
-- Consulta final: une con datos del club y calcula porcentajes
SELECT
    c.id_club,
    c.nombre_club,
    p.nombre_pais,
    ci.nombre_ciudad,
    CASE c.cuota_anual WHEN 'S' THEN 'Independiente' ELSE 'Institucional' END AS tipo_club,
    co.anio,
    co.nuevos_miembros,
    co.ingresos_usd,
    co.miembros_anio_anterior,
    co.ingresos_anio_anterior,
    -- % Crecimiento de miembros vs. año anterior
    -- NULLIF(miembros_anio_anterior, 0) evita ORA-01476
    ROUND(
        ((co.nuevos_miembros - co.miembros_anio_anterior)
         / NULLIF(co.miembros_anio_anterior, 0)) * 100,
        2
    ) AS pct_crecimiento_miembros,
    -- % Crecimiento económico vs. año anterior
    ROUND(
        ((co.ingresos_usd - co.ingresos_anio_anterior)
         / NULLIF(co.ingresos_anio_anterior, 0)) * 100,
        2
    ) AS pct_crecimiento_economico
FROM
    consolidado       co
    JOIN MJV_club    c  ON c.id_club  = co.id_club
    JOIN MJV_pais    p  ON p.id_pais  = c.id_pais
    JOIN MJV_ciudad  ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad
ORDER BY
    -- Mayor crecimiento de miembros primero; NULLs al final (primer año sin comparativo)
    pct_crecimiento_miembros DESC NULLS LAST,
    pct_crecimiento_economico DESC NULLS LAST,
    co.anio DESC;


-- =============================================================================
-- FIN DEL ARCHIVO
-- Compilación sugerida en SQL*Plus / SQLcl:
--   @vistas_reportes_mjv.sql
-- Verificación:
--   SELECT object_name, status
--     FROM user_objects
--    WHERE object_type = 'VIEW'
--      AND object_name LIKE 'MJV_VW_R%'
--    ORDER BY object_name;
-- =============================================================================
