SET SERVEROUTPUT ON;

DECLARE
    v_doc    VARCHAR2(20)  := '&documento_identidad_lector';
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_monto  NUMBER        := &monto_pagado;
    v_moneda VARCHAR2(3)   := '&codigo_moneda_ej_VES_o_USD';
    v_tasa   NUMBER        := &tasa_de_cambio_actual;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => v_doc,
        pi_nombre_club   => v_club,
        pi_monto         => v_monto,
        pi_moneda        => v_moneda,
        pi_tasa          => v_tasa
    );
END;


-- tests especializados
-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-31066026', 
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => 4000,   -- 4000 VES
        pi_moneda        => 'VES',  
        pi_tasa          => 36.5    -- A esta tasa, son ~109.58 USD
    );
END;

-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-31066026', 
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => 2000,   -- 2000 VES (apenas ~54.79 USD)
        pi_moneda        => 'VES',  
        pi_tasa          => 36.5    
    );
END;

-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-31066026', 
        pi_nombre_club   => 'Ecos del Pergamino', -- Club donde no estás inscrito
        pi_monto         => 150,    
        pi_moneda        => 'USD',  -- Pago directo en dólares
        pi_tasa          => 1       -- Tasa 1 a 1
    );
END;

-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-31066026', 
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => 4000,
        pi_moneda        => 'VES',  
        pi_tasa          => 0       -- ¡Peligro matemático!
    );
END;

-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-31066026', 
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => NULL,   -- Monto vacío
        pi_moneda        => 'VES',  
        pi_tasa          => 36.5    
    );
END;

-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-31066026', 
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => 4000,
        pi_moneda        => 'XYZ',  -- Moneda falsa
        pi_tasa          => 36.5    
    );
END;
