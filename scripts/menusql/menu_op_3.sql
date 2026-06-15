-- =============================================================================
-- menu_op_3.sql — Retirar miembro
-- =============================================================================

PROMPT
PROMPT --- RETIRAR MIEMBRO ---
PROMPT

ACCEPT p_id_lector NUMBER PROMPT "ID lector                                        : "
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

UNDEF p_id_lector p_club p_motivo
