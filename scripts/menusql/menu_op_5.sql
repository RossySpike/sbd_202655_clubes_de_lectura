-- =============================================================================
-- menu_op_5.sql — Registrar asistencia de miembro
-- =============================================================================

PROMPT
PROMPT --- REGISTRAR ASISTENCIA DE MIEMBRO ---
PROMPT

ACCEPT p_id_lector NUMBER PROMPT "ID lector                              : "
ACCEPT p_id_club   NUMBER PROMPT "ID club                                : "
ACCEPT p_id_grupo  NUMBER PROMPT "ID grupo                               : "
ACCEPT p_fec_reu   CHAR   PROMPT "Fecha reunion  DD/MM/YYYY              : "
ACCEPT p_isbn      CHAR   PROMPT "ISBN del libro                         : "
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

UNDEF p_id_lector p_id_club p_id_grupo p_fec_reu p_isbn p_asistio
