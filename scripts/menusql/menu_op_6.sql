-- =============================================================================
-- menu_op_6.sql — Cerrar discusion de libro
-- =============================================================================

PROMPT
PROMPT --- CERRAR DISCUSION DE LIBRO ---
PROMPT

ACCEPT p_id_club   NUMBER PROMPT "ID club                                : "
ACCEPT p_id_grupo  NUMBER PROMPT "ID grupo                               : "
ACCEPT p_fec_reu   CHAR   PROMPT "Fecha reunion  DD/MM/YYYY              : "
ACCEPT p_isbn      CHAR   PROMPT "ISBN del libro                         : "
ACCEPT p_concl     CHAR   PROMPT "Conclusiones del grupo                 : "
ACCEPT p_valor     NUMBER PROMPT "Valoracion final  1-5                  : "

BEGIN
    MJV_PKG_ADMIN_REUNIONES.cerrar_discusion(
        pi_id_club       => &p_id_club,
        pi_id_grupo      => &p_id_grupo,
        pi_fecha_reunion => TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY'),
        pi_isbn          => TRIM('&p_isbn'),
        pi_conclusiones  => TRIM('&p_concl'),
        pi_valoracion    => &p_valor
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Cerrar Discusion] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

UNDEF p_id_club p_id_grupo p_fec_reu p_isbn p_concl p_valor
