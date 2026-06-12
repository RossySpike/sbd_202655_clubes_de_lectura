CREATE OR REPLACE PROCEDURE MJV_sp_inscribir_miembro (
    pi_p_nombre        IN VARCHAR2,
    pi_p_apellido      IN VARCHAR2,
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
    pi_s_nombre        IN VARCHAR2 DEFAULT NULL,
    pi_id_rep          IN NUMBER DEFAULT NULL,
    pi_id_rep_lector   IN NUMBER DEFAULT NULL
) IS
    v_id_lector    NUMBER;
    v_age          NUMBER;
    v_tipo_grupo   VARCHAR2(10);
    v_id_grupo     NUMBER;
    v_id_club      NUMBER; 
    v_id_pais_nac  NUMBER;
    v_isbn1        VARCHAR2(20);
    v_isbn2        VARCHAR2(20);
    v_isbn3        VARCHAR2(20);
BEGIN
    -- 1. Resolver el nombre del club y el país a sus respectivos IDs
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);
    
    SELECT id_pais INTO v_id_pais_nac 
      FROM MJV_pais 
     WHERE UPPER(TRIM(nombre_pais)) = UPPER(TRIM(pi_nombre_pais_nac))
       AND ROWNUM = 1;

    -- 2. Resolver los títulos de libros preferidos a sus respectivos ISBN
    v_isbn1 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref1);
    v_isbn2 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref2);
    v_isbn3 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref3);

    -- 3. Insertar datos en la tabla padre (el ID se autogenera)
    -- NOTA: Al ejecutar esto, tu trigger MJV_tgr_validar_edad validará si necesita o no representante
    INSERT INTO MJV_lector (
        p_nombre, p_apellido, s_apellido, doc_identidad, telefono, 
        email, genero, fecha_nac, id_pais_nac, s_nombre, 
        id_representante, id_representante_lector
    ) VALUES (
        pi_p_nombre, pi_p_apellido, pi_s_apellido, pi_doc_identidad, pi_telefono, 
        pi_email, pi_genero, pi_fecha_nac, v_id_pais_nac, pi_s_nombre, 
        pi_id_rep, pi_id_rep_lector
    )
    RETURNING id_lector INTO v_id_lector;

    -- 4. Obtener la edad EXACTA usando la función nativa que creaste
    v_age := MJV_edad_miembro(v_id_lector);

    -- 5. Registrar las preferencias de obras (Usando la columna 'prioridad')
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn3, 3);

    -- 6. Iniciar historial de membresía activa (Usando columnas fecha_i y fecha_f)
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    -- 7. Clasificar el tipo de grupo según la edad obtenida
    -- (Nota: se usa 'jovenes' sin tilde para respetar el constraint MJV_grupo_ck_tipo)
    IF v_age BETWEEN 6 AND 12 THEN
        v_tipo_grupo := 'niños';
    ELSIF v_age BETWEEN 13 AND 25 THEN
        v_tipo_grupo := 'jovenes';
    ELSIF v_age > 25 THEN
        v_tipo_grupo := 'adultos';
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Error: La edad mínima es de 6 años.');
    END IF;

    -- 8. Buscar un grupo existente y activo de ese tipo en el club
    BEGIN
        SELECT id_grupo
          INTO v_id_grupo
          FROM MJV_grupo
         WHERE id_club = v_id_club
           AND tipo_grupo = v_tipo_grupo
           AND ROWNUM = 1; 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no existe, se crea uno predeterminado insertando las columnas NOT NULL requeridas
            INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
            VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
            RETURNING id_grupo INTO v_id_grupo;
    END;

    -- 9. Asignar al lector al grupo correspondiente 
    -- La PK aquí incluye la fecha_i proveniente de la historia de membresía y su propia fec_i
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_lector, v_id_club, SYSDATE, v_id_grupo, SYSDATE, NULL);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inscripción transaccional exitosa. ID de Lector asignado: ' || v_id_lector || ' | Edad: ' || v_age || ' | Grupo: ' || v_tipo_grupo);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_inscribir_miembro;


-- ejemplo de ejecución:
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
    v_rep_doc  VARCHAR2(20)  := '&doc_representante_o_NULL'; 
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
        pi_doc_rep         => v_rep_doc,   
        pi_tipo_rep        => v_rep_tipo   
    );
END;