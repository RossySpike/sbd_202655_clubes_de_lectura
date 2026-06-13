CREATE OR REPLACE PROCEDURE MJV_sp_retirar_miembro (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_motivo_retiro IN VARCHAR2
) IS
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_msj_error VARCHAR2(200);
BEGIN
    -- 1. Identificación
    SELECT id_lector INTO v_id_lector 
      FROM MJV_lector 
     WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));

    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 2. LLAMADA A LA NUEVA FUNCIÓN DE VALIDACIÓN
    v_msj_error := MJV_fn_validar_solvencia_retiro(v_id_lector, v_id_club);
    
    IF v_msj_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20040, 'RETIRO DENEGADO: ' || v_msj_error);
    END IF;

    -- 3. Ejecutar Retiro (Solo si pasó la validación)
    UPDATE MJV_g_lec
       SET fec_f = SYSDATE
     WHERE id_lector = v_id_lector AND id_club = v_id_club AND fec_f IS NULL; 

    UPDATE MJV_historia_membresia
       SET estatus = 'retirado', fecha_f = SYSDATE, motivo_retiro = LOWER(TRIM(pi_motivo_retiro))
     WHERE id_lector = v_id_lector AND id_club = v_id_club AND estatus = 'activo';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error: El miembro ya no estaba activo.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Retiro procesado correctamente.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'No encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_retirar_miembro;
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