-- =============================================================================
-- menu_op_5.sql — Registrar asistencia de miembro
-- =============================================================================

PROMPT
PROMPT --- REGISTRAR ASISTENCIA DE MIEMBRO ---
PROMPT

-- -----------------------------------------------------------------------------
-- REFERENCIA: Reuniones pendientes de registrar asistencia
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** REUNIONES AGENDADAS (pendientes y realizadas) ***
PROMPT

SELECT cr.id_club,
       cr.nombre_club,
       cr.id_grupo,
       cr.tipo_grupo,
       cr.fecha_reunion,
       cr.isbn,
       cr.titulo_libro,
       cr.realizada
FROM   MJV_vw_reuniones_mes cr
ORDER  BY cr.id_club, cr.id_grupo, cr.fecha_reunion;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Miembros activos por grupo (para saber que ID ingresar)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** MIEMBROS ACTIVOS POR GRUPO ***
PROMPT

SELECT l.id_lector,
       l.p_nombre || ' ' || l.p_apellido AS nombre,
       gl.id_club,
       gl.id_grupo
FROM   MJV_g_lec gl
JOIN   MJV_lector l ON l.id_lector = gl.id_lector
WHERE  gl.fec_f IS NULL
ORDER  BY gl.id_club, gl.id_grupo, l.id_lector;

PROMPT
PROMPT *** INGRESE LOS DATOS DE LA ASISTENCIA ***
PROMPT

ACCEPT p_id_lector NUMBER PROMPT "ID lector (ver tabla)                  : "
ACCEPT p_id_club   NUMBER PROMPT "ID club (ver tabla)                    : "
ACCEPT p_id_grupo  NUMBER PROMPT "ID grupo (ver tabla)                   : "
ACCEPT p_fec_reu   CHAR   PROMPT "Fecha reunion  DD/MM/YYYY              : "
ACCEPT p_isbn      CHAR   PROMPT "ISBN del libro (ver tabla)             : "
ACCEPT p_asistio   CHAR   PROMPT "Asistio?  S / N                        : "

BEGIN
    MJV_PKG_ADMIN_REUNIONES.registrar_asistencia(
        pi_id_lector     => &p_id_lector,
        pi_id_club       => &p_id_club,
        pi_id_grupo      => &p_id_grupo,
        pi_fecha_reunion => TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY'),
        pi_isbn          => TRIM('&p_isbn'),
        pi_asistio       => UPPER(TRIM('&p_asistio'))
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Registrar Asistencia] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- RESULTADO: Inasistencias acumuladas del lector (si aplica)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — INASISTENCIAS REGISTRADAS PARA EL LECTOR ***
PROMPT

SELECT ri.id_lector,
       ri.nombre_lector,
       ri.id_club,
       ri.id_grupo,
       ri.fecha_reunion,
       ri.isbn
FROM   MJV_vw_reporte_inasistencias ri
WHERE  ri.id_lector = &p_id_lector
ORDER  BY ri.id_club, ri.fecha_reunion;

-- -----------------------------------------------------------------------------
-- RESULTADO: Estado de participacion bimestral del lector
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — PARTICIPACION BIMESTRAL DEL LECTOR ***
PROMPT

SELECT ab.anio,
       ab.bimestre,
       ab.nombre_lector,
       ab.nombre_club,
       ab.tipo_grupo,
       ab.reuniones_ejecutadas,
       ab.inasistencias_registradas,
       ab.pct_inasistencia
FROM   MJV_v_asistencia_bimestre ab
WHERE  ab.id_lector = &p_id_lector
ORDER  BY ab.anio DESC, ab.bimestre DESC;

UNDEF p_id_lector p_id_club p_id_grupo p_fec_reu p_isbn p_asistio
