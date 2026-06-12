CREATE OR REPLACE FUNCTION MJV_fn_obtener_isbn_por_titulo (
    p_titulo IN VARCHAR2
) RETURN VARCHAR2 IS
    v_isbn VARCHAR2(20);
BEGIN
    SELECT isbn 
      INTO v_isbn 
      FROM MJV_obra 
     WHERE UPPER(TRIM(titulo)) = UPPER(TRIM(p_titulo))
       AND ROWNUM = 1; -- Gana tolerancia ante ligeras variantes o duplicados
       
    RETURN v_isbn;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: La obra "' || p_titulo || '" no está registrada en el catálogo general.');
END MJV_fn_obtener_isbn_por_titulo;

CREATE OR REPLACE FUNCTION MJV_fn_obtener_id_club_por_nombre (
    p_nombre_club IN VARCHAR2
) RETURN NUMBER IS
    v_id_club NUMBER;
BEGIN
    SELECT id_club 
      INTO v_id_club 
      FROM MJV_club 
     WHERE UPPER(TRIM(nombre_club)) = UPPER(TRIM(p_nombre_club))
       AND ROWNUM = 1; -- Tolerancia ante registros duplicados o similares
       
    RETURN v_id_club;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Error: El club de lectura "' || p_nombre_club || '" no está registrado en el sistema.');
END MJV_fn_obtener_id_club_por_nombre;

CREATE OR REPLACE FUNCTION MJV_fn_obtener_id_rep_por_doc (
    p_doc_identidad IN VARCHAR2,
    p_tipo_rep      IN VARCHAR2
) RETURN NUMBER IS
    v_id_rep NUMBER;
    v_tipo   VARCHAR2(20) := UPPER(TRIM(p_tipo_rep));
    v_doc    VARCHAR2(20) := UPPER(TRIM(p_doc_identidad));
BEGIN
    -- Validar si la búsqueda es en la tabla de Lectores o en la de Representantes Externos
    IF v_tipo = 'LECTOR' THEN
        SELECT id_lector 
          INTO v_id_rep 
          FROM MJV_lector 
         WHERE UPPER(TRIM(doc_identidad)) = v_doc
           AND ROWNUM = 1;
           
    ELSIF v_tipo = 'EXTERNO' THEN
        SELECT id_representante 
          INTO v_id_rep 
          FROM MJV_representante 
         WHERE UPPER(TRIM(doc_identidad)) = v_doc
           AND ROWNUM = 1;
           
    ELSE
        RAISE_APPLICATION_ERROR(-20012, 'Error: El tipo de representante especificado ("' || p_tipo_rep || '") no es válido. Debe ser LECTOR o EXTERNO.');
    END IF;

    RETURN v_id_rep;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF v_tipo = 'LECTOR' THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error: No se encontró ningún miembro LECTOR registrado con el documento: ' || p_doc_identidad);
        ELSE
            RAISE_APPLICATION_ERROR(-20011, 'Error: No se encontró ningún representante EXTERNO registrado con el documento: ' || p_doc_identidad);
        END IF;
END MJV_fn_obtener_id_rep_por_doc;

CREATE OR REPLACE TRIGGER MJV_tgr_validar_membresia_glec
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
  lector_estatus VARCHAR2(8);
BEGIN
    SELECT estatus INTO lector_estatus 
      FROM MJV_historia_membresia 
     WHERE id_club = :NEW.id_club 
       AND id_lector = :NEW.id_lector 
       AND estatus = 'activo';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'El lector no tiene una membresia activa en el club asociado al grupo.');
END;

-----------------------------------------------------------------------

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
    pi_doc_rep         IN VARCHAR2 DEFAULT NULL, -- Ahora pedimos la Cédula/Documento
    pi_tipo_rep        IN VARCHAR2 DEFAULT NULL  -- 'LECTOR' o 'EXTERNO'
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
    
    -- Variables para la lógica del representante
    v_id_rep        NUMBER := NULL;
    v_id_rep_lector NUMBER := NULL;
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

    -- 3. LÓGICA DE REPRESENTANTE SOLICITADA
    IF pi_doc_rep IS NOT NULL AND pi_tipo_rep IS NOT NULL THEN
        IF UPPER(TRIM(pi_tipo_rep)) = 'LECTOR' THEN
            v_id_rep_lector := MJV_fn_obtener_id_rep_por_doc(pi_doc_rep, pi_tipo_rep);
        ELSIF UPPER(TRIM(pi_tipo_rep)) = 'EXTERNO' THEN
            v_id_rep := MJV_fn_obtener_id_rep_por_doc(pi_doc_rep, pi_tipo_rep);
        ELSE
            RAISE_APPLICATION_ERROR(-20012, 'Error: El tipo de representante debe ser LECTOR o EXTERNO.');
        END IF;
    END IF;

    -- 4. Insertar datos en la tabla padre
    -- El trigger MJV_tgr_validar_edad hará la validación automática de tu fecha_nac vs los v_id_rep
    INSERT INTO MJV_lector (
        p_nombre, p_apellido, s_apellido, doc_identidad, telefono, 
        email, genero, fecha_nac, id_pais_nac, s_nombre, 
        id_representante, id_representante_lector
    ) VALUES (
        pi_p_nombre, pi_p_apellido, pi_s_apellido, pi_doc_identidad, pi_telefono, 
        pi_email, pi_genero, pi_fecha_nac, v_id_pais_nac, pi_s_nombre, 
        v_id_rep, v_id_rep_lector
    )
    RETURNING id_lector INTO v_id_lector;

    -- 5. Obtener la edad EXACTA
    v_age := MJV_edad_miembro(v_id_lector);

    -- 6. Registrar las preferencias
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn3, 3);

    -- 7. Iniciar historial de membresía activa
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    -- 8. Clasificar el tipo de grupo
    IF v_age BETWEEN 6 AND 12 THEN
        v_tipo_grupo := 'niños';
    ELSIF v_age BETWEEN 13 AND 25 THEN
        v_tipo_grupo := 'jovenes';
    ELSIF v_age > 25 THEN
        v_tipo_grupo := 'adultos';
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Error: La edad mínima es de 6 años.');
    END IF;

    -- 9. Buscar/Crear el grupo
    BEGIN
        SELECT id_grupo
          INTO v_id_grupo
          FROM MJV_grupo
         WHERE id_club = v_id_club
           AND tipo_grupo = v_tipo_grupo
           AND ROWNUM = 1; 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
            VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
            RETURNING id_grupo INTO v_id_grupo;
    END;

    -- 10. Asignar al grupo 
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_lector, v_id_club, SYSDATE, v_id_grupo, SYSDATE, NULL);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inscripción exitosa. ID de Lector asignado: ' || v_id_lector || ' | Grupo: ' || v_tipo_grupo);
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