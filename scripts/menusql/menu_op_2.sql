-- =============================================================================
-- menu_op_2.sql — Registrar pago de membresia
-- =============================================================================

PROMPT
PROMPT --- REGISTRAR PAGO DE MEMBRESIA ---
PROMPT

ACCEPT p_id_lector NUMBER PROMPT "ID lector                              : "
ACCEPT p_club      CHAR   PROMPT "Nombre exacto del club                 : "
ACCEPT p_monto     NUMBER PROMPT "Monto pagado                           : "
ACCEPT p_moneda    CHAR   PROMPT "Codigo moneda  USD / VES / COP ...     : "
ACCEPT p_tasa      NUMBER PROMPT "Tasa de cambio a USD  (1 si es USD)    : "

BEGIN
    MJV_PKG_ADMIN_CLUBES.registrar_pago(
        pi_id_lector   => &p_id_lector,
        pi_nombre_club => TRIM('&p_club'),
        pi_monto       => &p_monto,
        pi_moneda      => UPPER(TRIM('&p_moneda')),
        pi_tasa        => &p_tasa
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Registrar Pago] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

UNDEF p_id_lector p_club p_monto p_moneda p_tasa
