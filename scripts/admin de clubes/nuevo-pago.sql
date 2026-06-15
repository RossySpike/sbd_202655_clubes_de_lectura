CREATE OR REPLACE PROCEDURE MJV_sp_registrar_pago_membresia (
    pi_id_lector     IN NUMBER,
    pi_nombre_club   IN VARCHAR2,
    pi_monto         IN NUMBER,
    pi_moneda        IN VARCHAR2,
    pi_tasa          IN NUMBER
) IS
    v_id_club     NUMBER;
    v_fecha_i     DATE;
    v_monto_usd   NUMBER;
    v_cuota_anual CHAR(1);
BEGIN
    -- 1. Resolver club
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 3. [BRECHA 6] Verificar que el club cobra cuota antes de todo
    SELECT cuota_anual INTO v_cuota_anual FROM MJV_club WHERE id_club = v_id_club;

    IF v_cuota_anual = 'N' THEN
        RAISE_APPLICATION_ERROR(
            -20053,
            'Error: El club "' || pi_nombre_club
            || '" es dependiente de una institución y no cobra cuota de membresía.'
        );
    END IF;

    -- 4. Obtener fecha_i de membresía activa
    BEGIN
        SELECT fecha_i INTO v_fecha_i
          FROM MJV_historia_membresia
         WHERE id_lector = pi_id_lector
           AND id_club   = v_id_club
           AND estatus   = 'activo';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Error: El lector no tiene membresía activa en este club.'
            );
    END;

    -- 5. Conversión y validación de monto mínimo
    v_monto_usd := MJV_conversion_monetaria(pi_monto, pi_moneda, pi_tasa);

    IF v_monto_usd < 100 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Error de Pago: El monto equivale a ' || ROUND(v_monto_usd, 2)
            || ' USD. La cuota anual mínima es 100 USD.'
        );
    END IF;

    -- 6. Registrar pago
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    VALUES (pi_id_lector, v_id_club, v_fecha_i, SYSDATE, v_monto_usd);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Pago registrado: ' || ROUND(v_monto_usd, 2) || ' USD para lector ID '
        || pi_id_lector || ' en club ' || pi_nombre_club || '.'
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_registrar_pago_membresia;
/

-- ejemplo de ejecución:
/*
SET SERVEROUTPUT ON;

DECLARE
    v_id_lec NUMBER        := &id_lector;
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_monto  NUMBER        := &monto_pagado;
    v_moneda VARCHAR2(3)   := '&codigo_moneda_ej_VES_o_USD';
    v_tasa   NUMBER        := &tasa_de_cambio_actual;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_id_lector     => v_id_lec,
        pi_nombre_club   => v_club,
        pi_monto         => v_monto,
        pi_moneda        => v_moneda,
        pi_tasa          => v_tasa
    );
END;
*/
