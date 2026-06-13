CREATE OR REPLACE PROCEDURE MJV_sp_retirar_miembro (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_motivo_retiro IN VARCHAR2
) IS
    v_id_lector     NUMBER;
    v_id_club       NUMBER;
    v_msj_error     VARCHAR2(200);
    v_motivo_valido VARCHAR2(12);
BEGIN
    -- [BRECHA 7] Validar dominio del motivo antes de cualquier DML
    v_motivo_valido := LOWER(TRIM(pi_motivo_retiro));
    IF v_motivo_valido NOT IN ('voluntario', 'inasistencia', 'deuda', 'otro') THEN
        RAISE_APPLICATION_ERROR(
            -20056,
            'RETIRO INVÁLIDO: El motivo "' || pi_motivo_retiro
            || '" no es válido. Los valores permitidos son: '
            || 'voluntario, inasistencia, deuda, otro.'
        );
    END IF;

    -- 1. Identificar lector y club
    BEGIN
        SELECT id_lector INTO v_id_lector
          FROM MJV_lector
         WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20010,
                'Error: No se encontró lector con documento: ' || pi_doc_identidad
            );
    END;

    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 2. Validar solvencia (solo para clubes que cobran cuota)
    DECLARE
        v_cuota CHAR(1);
    BEGIN
        SELECT cuota_anual INTO v_cuota FROM MJV_club WHERE id_club = v_id_club;
        IF v_cuota = 'S' THEN
            v_msj_error := MJV_fn_validar_solvencia_retiro(v_id_lector, v_id_club);
            IF v_msj_error IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20040,
                    'RETIRO DENEGADO: ' || v_msj_error
                );
            END IF;
        END IF;
    END;

    -- 3. Cerrar asignación de grupo
    UPDATE MJV_g_lec
       SET fec_f = SYSDATE
     WHERE id_lector = v_id_lector
       AND id_club   = v_id_club
       AND fec_f     IS NULL;

    -- 4. Cerrar membresía
    UPDATE MJV_historia_membresia
       SET estatus       = 'retirado',
           fecha_f       = SYSDATE,
           motivo_retiro = v_motivo_valido
     WHERE id_lector = v_id_lector
       AND id_club   = v_id_club
       AND estatus   = 'activo';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20030,
            'Error: El miembro no estaba activo en este club.'
        );
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Retiro procesado. Lector: ' || pi_doc_identidad
        || ' | Club: ' || pi_nombre_club
        || ' | Motivo: ' || v_motivo_valido
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_retirar_miembro;
/
/*
SET SERVEROUTPUT ON;

DECLARE
    v_doc    VARCHAR2(20)  := '&documento_identidad_lector';
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_motivo VARCHAR2(200) := '&motivo_retiro_voluntario_inasistencia_deuda_otro';
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => v_doc,
        pi_nombre_club   => v_club,
        pi_motivo_retiro => LOWER(TRIM(v_motivo))
    );
END;
/*