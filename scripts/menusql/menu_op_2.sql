-- =============================================================================
-- menu_op_2.sql — Registrar pago de membresia
-- =============================================================================

PROMPT
PROMPT --- REGISTRAR PAGO DE MEMBRESIA ---
PROMPT

-- -----------------------------------------------------------------------------
-- REFERENCIA: Lectores activos con su ID y club (solo clubes con cuota)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** LECTORES ACTIVOS EN CLUBES CON CUOTA (solvencia actual) ***
PROMPT

SELECT rs.id_lector,
       rs.nombre_completo,
       rs.nombre_club,
       rs.deuda_pendiente_usd,
       rs.estatus_solvencia
FROM   MJV_vw_reporte_solvencia rs
ORDER  BY rs.nombre_club, rs.id_lector;

PROMPT
PROMPT *** INGRESE LOS DATOS DEL PAGO ***
PROMPT

ACCEPT p_id_lector NUMBER PROMPT "ID lector (ver tabla)                  : "
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

-- -----------------------------------------------------------------------------
-- RESULTADO: Solvencia actualizada del lector tras el pago
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — SOLVENCIA ACTUALIZADA DEL LECTOR ***
PROMPT

SELECT rs.id_lector,
       rs.nombre_completo,
       rs.doc_identidad,
       rs.nombre_club,
       rs.fecha_ingreso,
       rs.anos_iniciados,
       rs.deuda_total_usd,
       rs.total_pagado_usd,
       rs.deuda_pendiente_usd,
       rs.estatus_solvencia
FROM   MJV_vw_reporte_solvencia rs
WHERE  rs.id_lector = &p_id_lector;

UNDEF p_id_lector p_club p_monto p_moneda p_tasa
