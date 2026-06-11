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

-----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE MJV_sp_inscribir_miembro (
    p_nombre       IN VARCHAR2,
    p_apellido     IN VARCHAR2,
    p_fec_nac      IN DATE,
    p_telefono     IN VARCHAR2,
    p_email        IN VARCHAR2,
    p_id_pais      IN NUMBER,
    p_nombre_club  IN VARCHAR2, 
    p_titulo_pref1 IN VARCHAR2,
    p_titulo_pref2 IN VARCHAR2,
    p_titulo_pref3 IN VARCHAR2,
    p_id_rep_legal IN NUMBER DEFAULT NULL
) IS
    v_id_lector    NUMBER; -- Se convierte en variable interna para capturar el valor de la secuencia
    v_age          NUMBER;
    v_tipo_grupo   VARCHAR2(10);
    v_id_grupo     NUMBER;
    v_id_club      NUMBER; 
    v_isbn1        VARCHAR2(20);
    v_isbn2        VARCHAR2(20);
    v_isbn3        VARCHAR2(20);
BEGIN
    -- 1. Resolver el nombre del club a su ID correspondiente
    v_id_club := MJV_fn_obtener_id_club_por_nombre(p_nombre_club);

    -- 2. Resolver los títulos de libros preferidos a sus respectivos ISBN
    v_isbn1 := MJV_fn_obtener_isbn_por_titulo(p_titulo_pref1);
    v_isbn2 := MJV_fn_obtener_isbn_por_titulo(p_titulo_pref2);
    v_isbn3 := MJV_fn_obtener_isbn_por_titulo(p_titulo_pref3);

    -- 3. Calcular edad exacta para validar consistencia de representante
    v_age := MJV_edad_miembro(p_fec_nac);

    IF v_age < 18 AND p_id_rep_legal IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error: Los lectores menores de 18 años requieren un representante legal.');
    END IF;

    -- 4. Insertar datos básicos del Lector utilizando la secuencia implícita o explícita
    -- Usamos RETURNING para capturar el id_lector generado automáticamente por el motor
    INSERT INTO MJV_lector (nombre, apellido, fec_nac, telefono, email, id_pais, id_rep_legal)
    VALUES (p_nombre, p_apellido, p_fec_nac, p_telefono, p_email, p_id_pais, p_id_rep_legal)
    RETURNING id_lector INTO v_id_lector;

    -- 5. Registrar la tabla de preferencias (usando el ID recuperado y los ISBN)
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, posicion) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, posicion) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, posicion) VALUES (v_id_lector, v_isbn3, 3);

    -- 6. Iniciar historial de membresía activa en el club resuelto
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fec_i, fec_f, estatus)
    VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    -- 7. Clasificar el tipo de grupo según la edad
    IF v_age BETWEEN 6 AND 12 THEN
        v_tipo_grupo := 'niños';
    ELSIF v_age BETWEEN 13 AND 25 THEN
        v_tipo_grupo := 'jovenes';
    ELSIF v_age > 25 THEN
        v_tipo_grupo := 'adultos';
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Error: La edad del lector no cumple con los rangos permitidos (mínimo 6 años).');
    END IF;

    -- 8. Buscar un grupo existente y activo de ese tipo en el club resuelto
    BEGIN
        SELECT id_grupo
          INTO v_id_grupo
          FROM MJV_grupo
         WHERE id_club = v_id_club
           AND tipo_grupo = v_tipo_grupo
           AND ROWNUM = 1; 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no existe ningún grupo de ese tipo en el club, se inicializa el primero
            INSERT INTO MJV_grupo (id_grupo, id_club, tipo_grupo)
            VALUES (1, v_id_club, v_tipo_grupo);
            v_id_grupo := 1;
    END;

    -- 9. Asignar al lector al grupo correspondiente
    -- Al ejecutar este INSERT, saltarán los triggers de exclusividad y de grupo lleno (split)
    INSERT INTO MJV_g_lec (id_lector, id_grupo, id_club, fec_i, fec_f)
    VALUES (v_id_lector, v_id_grupo, v_id_club, SYSDATE, NULL);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inscripción exitosa. Se ha generado automáticamente el ID de Lector: ' || v_id_lector);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_inscribir_miembro;


-- EJECUCION --
SET SERVEROUTPUT ON;

DECLARE
    v_p_nom    VARCHAR2(100) := '&primer_nombre';
    v_s_nom    VARCHAR2(100) := '&segundo_nombre_o_NULL';
    v_p_ape    VARCHAR2(100) := '&primer_apellido';
    v_s_ape    VARCHAR2(100) := '&segundo_apellido';
    v_doc      VARCHAR2(20)  := '&documento_identidad_ej_V_ADU01';
    v_tel      VARCHAR2(20)  := '&telefono';
    v_email    VARCHAR2(100) := '&email';
    v_gen      VARCHAR2(1)   := '&genero_M_F';
    v_fec_nac  DATE          := TO_DATE('&fecha_nacimiento_DD_MM_YYYY', 'DD/MM/YYYY');
    v_pais_nac VARCHAR2(100) := '&nombre_pais_nacimiento';
    v_club     VARCHAR2(150) := '&nombre_exacto_del_club'; 
    v_pref1    VARCHAR2(200) := '&titulo_libro_preferido_1';
    v_pref2    VARCHAR2(200) := '&titulo_libro_preferido_2';
    v_pref3    VARCHAR2(200) := '&titulo_libro_preferido_3';
    v_rep      NUMBER        := &id_representante_o_NULL;
    v_rep_lec  NUMBER        := &id_representante_lector_o_NULL;
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
        pi_id_rep          => v_rep,
        pi_id_rep_lector   => v_rep_lec
    );
END;