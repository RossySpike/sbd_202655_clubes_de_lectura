-- =============================================================================
-- menu_op_4.sql — Agendar reunion mensual
-- =============================================================================

PROMPT
PROMPT --- AGENDAR REUNION MENSUAL ---
PROMPT

ACCEPT p_id_club   NUMBER PROMPT "ID club                                : "
ACCEPT p_id_grupo  NUMBER PROMPT "ID grupo                               : "
ACCEPT p_isbn      CHAR   PROMPT "ISBN del libro                         : "
ACCEPT p_fec_reu   CHAR   PROMPT "Fecha reunion  DD/MM/YYYY              : "
ACCEPT p_hora      CHAR   PROMPT "Hora inicio  HH24:MI  (ej. 17:00)     : "
ACCEPT p_id_mod    NUMBER PROMPT "ID moderador                           : "

BEGIN
    MJV_PKG_ADMIN_REUNIONES.agendar_reunion(
        pi_id_club       => &p_id_club,
        pi_id_grupo      => &p_id_grupo,
        pi_isbn          => TRIM('&p_isbn'),
        pi_fecha_reunion => TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY'),
        pi_hora_inicio   => TO_DATE(TRIM('&p_hora'),    'HH24:MI'),
        pi_mod_id_lector => &p_id_mod
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Agendar Reunion] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

UNDEF p_id_club p_id_grupo p_isbn p_fec_reu p_hora p_id_mod
