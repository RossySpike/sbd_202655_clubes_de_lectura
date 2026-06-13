-- =============================================================================
-- VISTAS OPERATIVAS - SISTEMA DE ADMINISTRACIÓN DE CLUBES DE LECTURA
-- Actividad 1
-- =============================================================================


-- =============================================================================
-- VISTA 0: MJV_vw_miembros_activos
CREATE OR REPLACE VIEW MJV_vw_miembros_activos AS
SELECT c.nombre_club,
       l.doc_identidad AS cedula,
       l.p_nombre || ' ' || l.p_apellido || ' ' || l.s_apellido AS nombre_completo,
       h.fecha_i AS fecha_ingreso,
       g.id_grupo
FROM MJV_lector l
JOIN MJV_historia_membresia h ON l.id_lector = h.id_lector
JOIN MJV_club c ON h.id_club = c.id_club
JOIN MJV_g_lec g ON l.id_lector = g.id_lector AND c.id_club = g.id_club
WHERE h.estatus = 'activo'
  AND g.fec_f IS NULL;

-- =============================================================================
-- VISTA 1: MJV_vw_reporte_solvencia
-- Propósito: Cruzar historial de membresía con pagos para determinar si un
--            lector está al día o moroso con la cuota anual de 100 USD.
--
-- Lógica de negocio:
--   - CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12) = años iniciados desde el ingreso
--   - Deuda total = años_iniciados * 100 USD
--   - Deuda pendiente = deuda_total - total pagado (mínimo 0 si pagó de más)
--   - Estatus 'AL DIA' cuando no hay deuda pendiente; 'MOROSO' en caso contrario
--   - Se incluyen solo membresías activas para reflejar obligaciones vigentes
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_reporte_solvencia AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || l.s_apellido AS nombre_completo,
    l.doc_identidad,
    c.id_club,
    c.nombre_club,
    hm.fecha_i                                                AS fecha_ingreso,
    -- Años calendario iniciados desde la fecha de ingreso (mínimo 1)
    GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) AS anos_iniciados,
    -- Deuda total acumulada según años iniciados
    GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) * 100 AS deuda_total_usd,
    -- Total efectivamente pagado por este lector en este club
    NVL(pagos.total_pagado, 0)                                AS total_pagado_usd,
    -- Saldo pendiente (0 si está solvente o pagó de más)
    GREATEST(
        (GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) * 100)
        - NVL(pagos.total_pagado, 0),
        0
    )                                                         AS deuda_pendiente_usd,
    -- Estatus de solvencia
    CASE
        WHEN NVL(pagos.total_pagado, 0) >=
             GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) * 100
        THEN 'AL DIA'
        ELSE 'MOROSO'
    END                                                       AS estatus_solvencia
FROM
    MJV_historia_membresia hm
    JOIN MJV_lector l ON l.id_lector = hm.id_lector
    JOIN MJV_club   c ON c.id_club   = hm.id_club
    -- Agregado de pagos por lector/club (LEFT JOIN para incluir quienes no han pagado nada)
    LEFT JOIN (
        SELECT
            id_lector,
            id_club,
            SUM(monto) AS total_pagado
        FROM MJV_pago_membresia
        GROUP BY id_lector, id_club
    ) pagos ON pagos.id_lector = hm.id_lector
           AND pagos.id_club   = hm.id_club
WHERE
    hm.estatus = 'activo'
    AND c.cuota_anual = 'S'; -- Solo aplica a clubes que cobran cuota anual


-- =============================================================================
-- VISTA 2: MJV_vw_historial_retiros
-- Propósito: Auditar todas las bajas procesadas en el sistema, mostrando
--            el lector, el club, fechas de ingreso/retiro y el motivo.
--
-- Filtra únicamente los registros con estatus = 'retirado'.
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_historial_retiros AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || l.s_apellido AS nombre_completo,
    l.doc_identidad,
    c.id_club,
    c.nombre_club,
    hm.fecha_i   AS fecha_ingreso,
    hm.fecha_f   AS fecha_retiro,
    hm.motivo_retiro
FROM
    MJV_historia_membresia hm
    JOIN MJV_lector l ON l.id_lector = hm.id_lector
    JOIN MJV_club   c ON c.id_club   = hm.id_club
WHERE
    hm.estatus = 'retirado'
ORDER BY
    hm.fecha_f DESC;


-- =============================================================================
-- VISTA 3: MJV_vw_ocupacion_grupos
-- Propósito: Control de aforo por grupo. Muestra el club, el grupo y el
--            conteo de miembros actualmente activos (fec_f IS NULL).
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_ocupacion_grupos AS
SELECT
    c.id_club,
    c.nombre_club,
    g.id_grupo,
    g.tipo_grupo,
    COUNT(gl.id_lector) AS miembros_activos
FROM
    MJV_grupo g
    JOIN MJV_club  c  ON c.id_club  = g.id_club
    -- LEFT JOIN para mostrar grupos aunque aún no tengan miembros activos
    LEFT JOIN MJV_g_lec gl ON  gl.id_grupo = g.id_grupo
                           AND gl.id_club  = g.id_club
                           AND gl.fec_f IS NULL  -- Solo membresías de grupo vigentes
GROUP BY
    c.id_club,
    c.nombre_club,
    g.id_grupo,
    g.tipo_grupo
ORDER BY
    c.nombre_club,
    g.tipo_grupo;
