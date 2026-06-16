-- =============================================================================
-- menu_op_3.sql — Retirar miembro
-- =============================================================================

PROMPT
PROMPT --- RETIRAR MIEMBRO ---
PROMPT

-- -----------------------------------------------------------------------------
-- REFERENCIA: Miembros activos con su ID y club
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** MIEMBROS ACTIVOS DISPONIBLES PARA RETIRAR ***
PROMPT

SELECT m.id_grupo,
       m.nombre_club,
       m.cedula,
       m.nombre_completo,
       m.fecha_ingreso
FROM   MJV_vw_miembros_activos m
ORDER  BY m.nombre_club, m.nombre_completo;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Solvencia de los miembros activos (util para saber si tienen deuda)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** SOLVENCIA DE MIEMBROS (clubes con cuota) ***
PROMPT

SELECT rs.id_lector,
       rs.nombre_completo,
       rs.nombre_club,
       rs.deuda_pendiente_usd,
       rs.estatus_solvencia
FROM   MJV_vw_reporte_solvencia rs
ORDER  BY rs.nombre_club, rs.id_lector;

PROMPT
PROMPT *** INGRESE LOS DATOS DEL RETIRO ***
PROMPT

ACCEPT p_id_lector NUMBER PROMPT "ID lector (ver tabla)                            : "
ACCEPT p_club      CHAR   PROMPT "Nombre exacto del club                           : "
ACCEPT p_motivo    CHAR   PROMPT "Motivo  voluntario / inasistencia / deuda / otro : "

BEGIN
    MJV_PKG_ADMIN_CLUBES.retirar_miembro(
        pi_id_lector     => &p_id_lector,
        pi_nombre_club   => TRIM('&p_club'),
        pi_motivo_retiro => LOWER(TRIM('&p_motivo'))
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Retirar Miembro] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- RESULTADO: Confirmacion del retiro en el historial
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — RETIRO REGISTRADO ***
PROMPT

SELECT hr.id_lector,
       hr.nombre_completo,
       hr.doc_identidad,
       hr.nombre_club,
       hr.fecha_ingreso,
       hr.fecha_retiro,
       hr.motivo_retiro
FROM   MJV_vw_historial_retiros hr
WHERE  hr.id_lector = &p_id_lector
ORDER  BY hr.fecha_retiro DESC;

UNDEF p_id_lector p_club p_motivo
