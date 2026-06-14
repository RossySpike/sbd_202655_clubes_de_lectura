CREATE OR REPLACE PROCEDURE MJV_sp_inscribir_miembro (
    pi_p_nombre        IN VARCHAR2,
    pi_p_apellido      IN VARCHAR2,
    pi_s_nombre        IN VARCHAR2 DEFAULT NULL,
    pi_s_apellido      IN VARCHAR2,
    pi_doc_identidad   IN VARCHAR2,
    pi_telefono        IN VARCHAR2,
    pi_email           IN VARCHAR2,
    pi_genero          IN VARCHAR2,
    pi_fecha_nac       IN DATE,
    pi_nombre_pais_nac IN VARCHAR2,
    pi_nombre_club     IN VARCHAR2,
    pi_titulo_pref1    IN VARCHAR2,
    pi_titulo_pref2    IN VARCHAR2,
    pi_titulo_pref3    IN VARCHAR2,
    pi_id_rep          IN NUMBER DEFAULT NULL,
    pi_tipo_rep        IN VARCHAR2 DEFAULT NULL
) IS
    v_id_lector     NUMBER;
    v_age           NUMBER;
    v_tipo_grupo    VARCHAR2(10);
    v_id_grupo      NUMBER;
    v_id_club       NUMBER;
    v_id_pais_nac   NUMBER;
    v_isbn1         VARCHAR2(20);
    v_isbn2         VARCHAR2(20);
    v_isbn3         VARCHAR2(20);
    v_id_rep_lector NUMBER := NULL;
    v_tiene_deuda   NUMBER;
    v_vetado        NUMBER;
    v_lector_existente NUMBER;
BEGIN
    -- 1. Resolver club y país
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    SELECT id_pais INTO v_id_pais_nac
      FROM MJV_pais
     WHERE UPPER(TRIM(nombre_pais)) = UPPER(TRIM(pi_nombre_pais_nac))
       AND ROWNUM = 1;

    -- 2. Resolver ISBN de preferencias
    v_isbn1 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref1);
    v_isbn2 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref2);
    v_isbn3 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref3);

    -- 3. Insertar lector (dispara MJV_tgr_validar_edad)
    INSERT INTO MJV_lector (
        p_nombre, p_apellido, s_apellido, doc_identidad, telefono,
        email, genero, fecha_nac, id_pais_nac, s_nombre,
        id_representante, id_representante_lector
    ) VALUES (
        pi_p_nombre, pi_p_apellido, pi_s_apellido, pi_doc_identidad, pi_telefono,
        pi_email, pi_genero, pi_fecha_nac, v_id_pais_nac, pi_s_nombre,
        CASE WHEN UPPER(TRIM(pi_tipo_rep)) = 'EXTERNO' THEN pi_id_rep ELSE NULL END, 
        CASE WHEN UPPER(TRIM(pi_tipo_rep)) = 'LECTOR' THEN pi_id_rep ELSE NULL END
    )
    RETURNING id_lector INTO v_id_lector;

    -- 4. Calcular edad
    v_age := MJV_edad_miembro(v_id_lector);

    -- [BRECHA 1] Bloqueo por deudas históricas en cualquier club anterior
    v_tiene_deuda := MJV_fn_tiene_deuda_historica(v_id_lector);
    IF v_tiene_deuda = 1 THEN
        -- Revertir el INSERT del lector antes de lanzar el error
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20054,
            'INSCRIPCIÓN DENEGADA: El lector con documento ' || pi_doc_identidad
            || ' tiene deudas pendientes de membresía en un club anterior. '
            || 'Debe saldar su deuda antes de unirse a un nuevo club.'
        );
    END IF;

    -- [BRECHA 2] Bloqueo permanente por inasistencia en este mismo club
    v_vetado := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
    IF v_vetado = 1 THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20055,
            'INSCRIPCIÓN DENEGADA: El lector con documento ' || pi_doc_identidad
            || ' fue retirado del club "' || pi_nombre_club
            || '" por inasistencia y tiene prohibido el reingreso permanentemente.'
        );
    END IF;

    -- 6. Registrar preferencias
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn3, 3);

    -- 7. Iniciar historial de membresía (dispara MJV_tgr_un_club_activo)
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    -- 8. Clasificar tipo de grupo por edad
    IF v_age BETWEEN 6 AND 12 THEN
        v_tipo_grupo := 'niños';
    ELSIF v_age BETWEEN 13 AND 25 THEN
        v_tipo_grupo := 'jovenes';
    ELSIF v_age > 25 THEN
        v_tipo_grupo := 'adultos';
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Error: La edad mínima de ingreso es 6 años.');
    END IF;

    -- 9. Buscar o crear el grupo correspondiente
    BEGIN
        SELECT id_grupo
          INTO v_id_grupo
          FROM MJV_grupo
         WHERE id_club    = v_id_club
           AND tipo_grupo = v_tipo_grupo
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
            VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
            RETURNING id_grupo INTO v_id_grupo;
    END;

    -- 10. Asignar al grupo (dispara MJV_tgr_bloquear_inscripcion_libro_activo
    --     y MJV_tgr_grupo_lleno → MJV_sp_split_grupo si aplica)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_lector, v_id_club, SYSDATE, v_id_grupo, SYSDATE, NULL);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Inscripción exitosa. ID Lector: ' || v_id_lector
        || ' | Edad: ' || v_age || ' | Grupo: ' || v_tipo_grupo
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_inscribir_miembro;
/


/* -- ejemplo de ejecución:
SET SERVEROUTPUT ON;

DECLARE
    v_p_nom    VARCHAR2(100) := '&primer_nombre';
    v_s_nom    VARCHAR2(100) := '&segundo_nombre_o_NULL';
    v_p_ape    VARCHAR2(100) := '&primer_apellido';
    v_s_ape    VARCHAR2(100) := '&segundo_apellido';
    v_doc      VARCHAR2(20)  := '&documento_identidad_ej_V_ADU01';
    v_tel      VARCHAR2(20)  := '&telefono';
    v_email    VARCHAR2(100) := '&email';
    v_gen      VARCHAR2(1)   := '&genero_M_o_F';
    v_fec_nac  DATE          := TO_DATE('&fecha_nacimiento_DD_MM_YYYY', 'DD/MM/YYYY');
    v_pais_nac VARCHAR2(100) := '&nombre_pais_nacimiento';
    v_club     VARCHAR2(150) := '&nombre_exacto_del_club'; 
    v_pref1    VARCHAR2(200) := '&titulo_libro_preferido_1';
    v_pref2    VARCHAR2(200) := '&titulo_libro_preferido_2';
    v_pref3    VARCHAR2(200) := '&titulo_libro_preferido_3';
    v_rep_id   NUMBER        := &id_representante_o_NULL; 
    v_rep_tipo VARCHAR2(20)  := '&tipo_rep_LECTOR_o_EXTERNO_o_NULL'; 
BEGIN
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => v_p_nom,
        pi_p_apellido      => v_p_ape,
        pi_s_apellido      => v_s_ape,
        pi_doc_identidad   => v_doc,
        pi_telefono        => v_tel,
        pi_email           => v_email,
        pi_genero          => v_gen,
        pi_fecha_nac       => v_fec_nac,
        pi_nombre_pais_nac => v_pais_nac,
        pi_nombre_club     => v_club,
        pi_titulo_pref1    => v_pref1,
        pi_titulo_pref2    => v_pref2,
        pi_titulo_pref3    => v_pref3,
        pi_s_nombre        => v_s_nom,
        pi_id_rep          => v_rep_id,   
        pi_tipo_rep        => v_rep_tipo   
    );
END; */