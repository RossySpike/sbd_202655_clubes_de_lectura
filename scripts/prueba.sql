SET SERVEROUTPUT ON;

DECLARE
    v_id_club   NUMBER;
    v_id_grupo_adultos NUMBER;
    v_id_lector1 NUMBER;
    v_id_lector2 NUMBER;
    v_isbn       VARCHAR2(20) := '978-3-16-148410-0';
    v_fecha_base DATE := TO_DATE('2025-06-01', 'YYYY-MM-DD');
    v_hist_fecha DATE;
BEGIN
    -- =====================================================
    -- LIMPIEZA PREVIA
    -- =====================================================
    DELETE FROM MJV_calendario_reunion_mes WHERE isbn = v_isbn;
    DELETE FROM MJV_g_lec WHERE id_grupo IN (SELECT id_grupo FROM MJV_grupo WHERE id_club = 9999);
    DELETE FROM MJV_grupo WHERE id_club = 9999;
    DELETE FROM MJV_historia_membresia WHERE id_club = 9999;
    DELETE FROM MJV_club WHERE id_club = 9999;
    DELETE FROM MJV_lector WHERE id_lector IN (9991, 9992);
    DELETE FROM MJV_libro WHERE isbn = v_isbn;
    DELETE FROM MJV_pais WHERE id_pais = 999;

    -- =====================================================
    -- INSERCIÓN DE DATOS BASE
    -- =====================================================
    -- 2. Insertar país de prueba
    INSERT INTO MJV_pais (id_pais, nombre_pais, moneda_local, nacionalidad)
    VALUES (999, 'PaisPrueba', 'USD', 'Pruebano');

    -- 3. Insertar ciudad
    INSERT INTO MJV_ciudad (id_pais, id_ciudad, nombre_ciudad)
    VALUES (999, 1, 'CiudadTest');

    -- 4. Insertar club
    INSERT INTO MJV_club (id_club, nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais)
    VALUES (9999, 'Club Test', 'N', '12345', 1, 999);

    -- 5. Insertar grupos (solo adultos para simplificar)
    INSERT INTO MJV_grupo (id_grupo, id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (MJV_seq_grupo.NEXTVAL, 9999, 'adultos', SYSDATE, 3, TO_DATE('18:00', 'HH24:MI'));
    
    SELECT id_grupo INTO v_id_grupo_adultos 
    FROM MJV_grupo 
    WHERE id_club = 9999 AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    -- 6. Insertar lectores (ambos adultos, sin representante)
    INSERT INTO MJV_lector (id_lector, p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, id_representante, id_representante_lector)
    VALUES (9991, 'Juan', 'Perez', 'Lopez', 'V-12345678', '04121234567', 'juan@test.com', 'M', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 999, NULL, NULL);

    INSERT INTO MJV_lector (id_lector, p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, id_representante, id_representante_lector)
    VALUES (9992, 'Maria', 'Gomez', 'Rojas', 'V-87654321', '04127654321', 'maria@test.com', 'F', TO_DATE('1995-05-15', 'YYYY-MM-DD'), 999, NULL, NULL);

    -- 7. Insertar membresías activas
    v_hist_fecha := SYSDATE;
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (9991, 9999, v_hist_fecha, 'activo');
    
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (9992, 9999, v_hist_fecha, 'activo');

    -- 8. Insertar g_lec (asignación a grupos)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (9991, 9999, v_hist_fecha, v_id_grupo_adultos, SYSDATE, NULL);

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (9992, 9999, v_hist_fecha, v_id_grupo_adultos, SYSDATE, NULL);

    -- 9. Insertar libro
    INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais)
    VALUES (v_isbn, 'Libro Prueba', 'novela', 'Sinopsis de prueba', 'misterio', 2020, 200, 999);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Datos base insertados correctamente.');

    -- =====================================================
    -- PRUEBA 1: Insertar primera reunión (debe funcionar)
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 1: Primera reunión ---');
    BEGIN
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base,
            p_isbn => v_isbn,
            p_mod_id_lector => 9991,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'N',
            p_ultima => 'N'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
    END;

    -- =====================================================
    -- PRUEBA 2: Segundo moderador en otro grupo (debe fallar)
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 2: Mismo moderador en otra reunión activa ---');
    BEGIN
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 7,
            p_isbn => v_isbn,
            p_mod_id_lector => 9991,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'N',
            p_ultima => 'N'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✅ Correcto: ' || SQLERRM);
    END;

    -- =====================================================
    -- PRUEBA 3: Liberar moderador (marcar reunión como realizada)
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 3: Liberar moderador ---');
    BEGIN
        UPDATE MJV_calendario_reunion_mes 
        SET realizada = 'S' 
        WHERE id_grupo = v_id_grupo_adultos 
          AND id_club = 9999 
          AND fecha = v_fecha_base;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✅ Reunión marcada como realizada.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
    END;

    -- =====================================================
    -- PRUEBA 4: Ahora sí se puede insertar nueva reunión con el mismo moderador
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 4: Nueva reunión con moderador liberado ---');
    BEGIN
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 14,
            p_isbn => v_isbn,
            p_mod_id_lector => 9991,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'N',
            p_ultima => 'N'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
    END;

    -- =====================================================
    -- PRUEBA 5: Insertar 3 reuniones realizadas para el mismo libro
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 5: Insertar reuniones realizadas ---');
    BEGIN
        -- Reunión 1 realizada
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 21,
            p_isbn => v_isbn,
            p_mod_id_lector => 9992,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'S',
            p_ultima => 'N'
        );
        
        -- Reunión 2 realizada
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 28,
            p_isbn => v_isbn,
            p_mod_id_lector => 9992,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'S',
            p_ultima => 'N'
        );
        
        -- Reunión 3 realizada
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 35,
            p_isbn => v_isbn,
            p_mod_id_lector => 9992,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'S',
            p_ultima => 'N'
        );
        
        DBMS_OUTPUT.PUT_LINE('✅ Tres reuniones realizadas insertadas.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
    END;

    -- =====================================================
    -- PRUEBA 6: Intentar cuarta reunión realizada (debe fallar)
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 6: Cuarta reunión realizada (debe fallar) ---');
    BEGIN
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 42,
            p_isbn => v_isbn,
            p_mod_id_lector => 9992,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'S',
            p_ultima => 'N'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✅ Correcto: ' || SQLERRM);
    END;

    -- =====================================================
    -- PRUEBA 7: Insertar reunión NO realizada (debe permitirse)
    -- =====================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Prueba 7: Reunión programada (no realizada) ---');
    BEGIN
        MJV_sp_insertar_reunion(
            p_id_club => 9999,
            p_id_grupo => v_id_grupo_adultos,
            p_fecha => v_fecha_base + 49,
            p_isbn => v_isbn,
            p_mod_id_lector => 9992,
            p_mod_fecha_i => v_hist_fecha,
            p_mod_hist_fecha_i => v_hist_fecha,
            p_realizada => 'N',
            p_ultima => 'N'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
    END;

    -- =====================================================
    -- LIMPIEZA FINAL (opcional)
    -- =====================================================
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '🧹 Datos revertidos (ROLLBACK). Las pruebas no dejan residuos.');

END;
/
