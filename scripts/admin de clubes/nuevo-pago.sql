CREATE OR REPLACE PROCEDURE MJV_sp_registrar_pago_membresia (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_monto         IN NUMBER,
    pi_moneda        IN VARCHAR2,
    pi_tasa          IN NUMBER      
) IS
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_fecha_i   DATE;
    v_monto_usd NUMBER;
BEGIN
    -- 1. Obtener el ID del Lector por su Cédula
    BEGIN
        SELECT id_lector INTO v_id_lector 
          FROM MJV_lector 
         WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error: No se encontró ningún lector registrado con el documento: ' || pi_doc_identidad);
    END;

    -- 2. Obtener el ID del Club
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);
    
    -- 3. Obtener la FECHA_I de la membresía activa
    -- (Esto cumple con tu columna FECHA_I y valida que el lector esté activo en el club)
    BEGIN
        SELECT fecha_i INTO v_fecha_i
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector
           AND id_club = v_id_club
           AND estatus = 'activo';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007, 'Error: El lector no tiene una membresía activa en este club para asociar el pago.');
    END;

    -- 4. Convertir el monto ingresado a dólares
    v_monto_usd := MJV_conversion_monetaria(pi_monto, pi_moneda, 'USD', pi_tasa);

    -- 5. Validar la cuota mínima de 100 USD
    IF v_monto_usd < 100 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Error de Pago: El monto ingresado equivale a ' || ROUND(v_monto_usd, 2) || ' USD. La cuota anual mínima es de 100 USD.');
    END IF;

    -- 6. Insertar el pago con las columnas exactas de la tabla
    -- Nota: Omitimos ID_PAGO porque la imagen muestra que tiene un DEFAULT / SEQUENCE automático.
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    VALUES (v_id_lector, v_id_club, v_fecha_i, SYSDATE, v_monto_usd);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pago registrado exitosamente en la base de datos por: ' || ROUND(v_monto_usd, 2) || ' USD.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_registrar_pago_membresia;

-- ejemplo de ejecución:
/*
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
*/