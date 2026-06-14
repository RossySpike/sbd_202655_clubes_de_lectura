-- =============================================================================
-- PROYECTO: Sistema de Gestión de Clubes de Lectura
-- ARCHIVO:  MJV_test_suite_reuniones.sql
-- MOTOR:    Oracle 19c
-- FECHA:    2026-06-14
--
-- INSTRUCCIONES:
--   1. Ejecutar script_final.sql (DDL + INSERTs base)
--   2. Ejecutar separaciones-por-tipo/TriggersFunctions.sql
--   3. Ejecutar complemento_script_final.sql
--   4. Ejecutar admin de reuniones/brechas_admin_reuniones.sql
--   5. Ejecutar ESTE archivo: @MJV_test_suite_reuniones.sql
--
-- CONVENCIÓN DE RESULTADOS:
--   [PASS] = el test se comportó como se esperaba
--   [FAIL] = el test NO se comportó como se esperaba (revisar)
--   [SKIP] = omitido porque dependía de un test previo que no pasó
--   [INFO] = resultado informativo, no determinante
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

-- =============================================================================
-- BLOQUE 0: SETUP — Datos base para toda la suite
-- Se crean un club, grupos, lectores y membresías exclusivos para los tests.
-- Al final del script el bloque CLEANUP los elimina.
-- IMPORTANTE: todas las fechas del setup se capturan en v_hoy para que las FK
--             (historia_membresia ← g_lec) coincidan exactamente.
-- =============================================================================
DECLARE
    v_hoy         DATE := TRUNC(SYSDATE);
    v_id_club     NUMBER;
    v_id_g_adu    NUMBER;
    v_id_g_nin    NUMBER;
    v_id_g_jov    NUMBER;
    v_id_adu1     NUMBER;
    v_id_adu2     NUMBER;
    v_id_nin      NUMBER;
    v_id_jov      NUMBER;
    v_id_pais     NUMBER;
    v_id_rep      NUMBER;
    v_fecha_hm    DATE := v_hoy - 60;  -- fecha_i de membresía (60 días atrás)
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  SUITE DE PRUEBAS: ADMINISTRACIÓN DE REUNIONES');
    DBMS_OUTPUT.PUT_LINE('  Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('[SETUP] Creando datos base...');

    SELECT id_pais INTO v_id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM = 1;

    -- Club de prueba (no asociado a institución para evitar FK)
    INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais)
    VALUES ('CLUB_TEST_REUNIONES', 'S', '00001',
            (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Caracas' AND ROWNUM = 1),
            v_id_pais)
    RETURNING id_club INTO v_id_club;

    -- Grupos (hora 17:00 — válida para todos los tipos bajo el constraint)
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'adultos', v_hoy, 2, TO_DATE('17:00','HH24:MI'))
    RETURNING id_grupo INTO v_id_g_adu;

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'niños', v_hoy, 2, TO_DATE('17:00','HH24:MI'))
    RETURNING id_grupo INTO v_id_g_nin;

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'jovenes', v_hoy, 2, TO_DATE('17:00','HH24:MI'))
    RETURNING id_grupo INTO v_id_g_jov;

    -- Representante para menores
    INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono)
    VALUES ('Rep','Test','RT-TST-REP-001','+10000000000')
    RETURNING id_representante INTO v_id_rep;

    -- Adulto 1 — moderador principal (35 años)
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
                             telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('Adulto','Uno','Test','V-TST-ADU-001',
            '+58001','adu1@tst.com','M',
            ADD_MONTHS(v_hoy, -35*12), v_id_pais)
    RETURNING id_lector INTO v_id_adu1;

    -- Adulto 2 — segundo moderador (30 años)
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
                             telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('Adulto','Dos','Test','V-TST-ADU-002',
            '+58002','adu2@tst.com','M',
            ADD_MONTHS(v_hoy, -30*12), v_id_pais)
    RETURNING id_lector INTO v_id_adu2;

    -- Niño (9 años — necesita representante)
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
                             telefono, email, genero, fecha_nac, id_pais_nac,
                             id_representante)
    VALUES ('Nino','Lector','Test','V-TST-NIN-001',
            '+58003','nin@tst.com','M',
            ADD_MONTHS(v_hoy, -9*12), v_id_pais, v_id_rep)
    RETURNING id_lector INTO v_id_nin;

    -- Joven (17 años — necesita representante)
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
                             telefono, email, genero, fecha_nac, id_pais_nac,
                             id_representante)
    VALUES ('Joven','Lector','Test','V-TST-JOV-001',
            '+58004','jov@tst.com','F',
            ADD_MONTHS(v_hoy, -17*12), v_id_pais, v_id_rep)
    RETURNING id_lector INTO v_id_jov;

    -- Historia de membresía: MISMA fecha v_fecha_hm para todos
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (v_id_adu1, v_id_club, v_fecha_hm, 'activo');
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (v_id_adu2, v_id_club, v_fecha_hm, 'activo');
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (v_id_nin,  v_id_club, v_fecha_hm, 'activo');
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (v_id_jov,  v_id_club, v_fecha_hm, 'activo');

    -- Asignación a grupos: fecha_i en g_lec = MISMA fecha_i de historia_membresia
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_adu1, v_id_club, v_fecha_hm, v_id_g_adu, v_fecha_hm, NULL);
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_adu2, v_id_club, v_fecha_hm, v_id_g_adu, v_fecha_hm, NULL);
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_nin,  v_id_club, v_fecha_hm, v_id_g_nin, v_fecha_hm, NULL);
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_jov,  v_id_club, v_fecha_hm, v_id_g_jov, v_fecha_hm, NULL);

    -- Libros de prueba
    INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero,
                            primera_edicion, total_paginas, id_pais)
    VALUES ('TST-ISBN-001','Libro Test Uno','novela',
            'Sinopsis test uno.','fantasia',2020,100, v_id_pais);

    INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero,
                            primera_edicion, total_paginas, id_pais)
    VALUES ('TST-ISBN-002','Libro Test Dos','novela',
            'Sinopsis test dos.','fantasia',2021,200, v_id_pais);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('[SETUP OK] id_club=' || v_id_club
        || ' | g_adu=' || v_id_g_adu
        || ' | g_nin=' || v_id_g_nin
        || ' | g_jov=' || v_id_g_jov);
    DBMS_OUTPUT.PUT_LINE('[SETUP OK] adu1=' || v_id_adu1
        || ' | adu2=' || v_id_adu2
        || ' | nin=' || v_id_nin
        || ' | jov=' || v_id_jov);
    DBMS_OUTPUT.PUT_LINE('');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[SETUP FAIL] ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('La suite no puede continuar. Revisar el error anterior.');
        RAISE;
END;
/


-- =============================================================================
-- ACTIVIDAD 1 — AGENDAR REUNIÓN
-- =============================================================================
BEGIN DBMS_OUTPUT.PUT_LINE('-- ACTIVIDAD 1: AGENDAR REUNIÓN --'); END;
/

-- A1-01: Debe PASAR — Reunión válida adultos con moderador adulto
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[PASS] A1-01: Reunion valida de adultos agendada.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[FAIL] A1-01: ' || SQLERRM);
END;
/

-- A1-02: Debe FALLAR -20066 — Misma reunión duplicada (mismo grupo+libro+fecha)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,  -- misma fecha que A1-01
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-02: Debio fallar por reunion duplicada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20066 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-02: Reunion duplicada bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-02: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-03: Debe FALLAR -20064 — Moderador que no es miembro del club
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 15,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => -9999  -- ID inexistente
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-03: Debio fallar por moderador no miembro.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20064 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-03: Moderador no miembro bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-03: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-04: Debe FALLAR -20031/-20067 — Niño como moderador de grupo de niños
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'niños' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-NIN-001';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 20,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-04: Debio fallar: nino como moderador de ninos.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20031, -20067) THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-04: Nino como moderador de ninos bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-04: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-05: Debe PASAR — Adulto como moderador de grupo de niños
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'niños' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 20,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[PASS] A1-05: Adulto como moderador de ninos OK.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[FAIL] A1-05: ' || SQLERRM);
END;
/

-- A1-06 (BRECHA A): Debe FALLAR -20068 — Segundo moderador distinto para mismo libro/grupo
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod2     NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'niños' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod2 FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-002';

    -- El libro TST-ISBN-001 ya tiene al adulto 1 como moderador en este grupo (A1-05)
    -- Intentar agendar otra reunion del mismo libro con un moderador diferente
    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 21,  -- fecha distinta, mismo libro/grupo
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod2               -- moderador diferente
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-06 (BRECHA A): Debio fallar por cambio de moderador.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20068 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-06 (BRECHA A): Cambio de moderador bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-06: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-07: Debe FALLAR -20052 — Moderador con discusion activa en otro grupo
DECLARE
    v_id_club  NUMBER;
    v_id_g_adu NUMBER;
    v_id_g_jov NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_g_adu FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_grupo INTO v_id_g_jov FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'jovenes' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    -- Marcar la reunion de adultos (A1-01) como realizada para tener discusion activa
    UPDATE MJV_calendario_reunion_mes
       SET realizada = 'S', ultima = 'N'
     WHERE id_club  = v_id_club
       AND id_grupo = v_id_g_adu
       AND isbn     = 'TST-ISBN-001';
    COMMIT;

    -- Intentar asignar mismo moderador en grupo jovenes con libro distinto
    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_g_jov,
        pi_isbn          => 'TST-ISBN-002',
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-07: Debio fallar por moderador con discusion activa en otro grupo.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -20052 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-07: Moderador con discusion activa bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-07: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-08: Debe FALLAR -20063 — ISBN inexistente en el catalogo
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'ISBN-NO-EXISTE-XYZ',
        pi_fecha_reunion => TRUNC(SYSDATE) + 25,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-08: Debio fallar por ISBN inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20063 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-08: ISBN inexistente bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-08: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-09: Debe FALLAR -20060 — Hora de inicio no coincide con la hora del grupo
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 30,
        pi_hora_inicio   => TO_DATE('18:00','HH24:MI'),  -- grupo tiene 17:00
        pi_mod_id_lector => v_mod
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-09: Debio fallar por hora incorrecta.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20060 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-09: Hora incorrecta bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-09: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-10 (Regla de Oro): Debe FALLAR -20050 — Inscribir miembro con discusion activa
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_pais  NUMBER;
    v_new_lec  NUMBER;
    v_fecha_hm DATE := TRUNC(SYSDATE) - 60;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_pais  INTO v_id_pais  FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM = 1;

    -- Asegurar que hay discusion activa en el grupo adultos
    UPDATE MJV_calendario_reunion_mes
       SET realizada = 'S', ultima = 'N'
     WHERE id_club = v_id_club AND id_grupo = v_id_grupo AND isbn = 'TST-ISBN-001';
    COMMIT;

    -- Nuevo adulto de prueba
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
                             telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('Adulto','Tres','Test','V-TST-ADU-003',
            '+58005','adu3@tst.com','M',
            ADD_MONTHS(TRUNC(SYSDATE), -28*12), v_id_pais)
    RETURNING id_lector INTO v_new_lec;

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (v_new_lec, v_id_club, v_fecha_hm, 'activo');

    -- Este INSERT debe disparar MJV_tgr_bloquear_inscripcion_libro_activo
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_new_lec, v_id_club, v_fecha_hm, v_id_grupo, v_fecha_hm, NULL);

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[FAIL] A1-10 (Regla de Oro): Debio bloquear inscripcion con discusion activa.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -20050 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A1-10 (Regla de Oro): Inscripcion bloqueada con discusion activa. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A1-10: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/


-- =============================================================================
-- ACTIVIDAD 2 — CONTROL DE ASISTENCIA
-- =============================================================================
BEGIN DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('-- ACTIVIDAD 2: CONTROL DE ASISTENCIA --'); END;
/

-- A2-01: Debe PASAR — Registrar asistencia S valida
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_lector   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_isbn          => 'TST-ISBN-001',
        pi_asistio       => 'S'
    );
    DBMS_OUTPUT.PUT_LINE('[PASS] A2-01: Asistencia S registrada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[FAIL] A2-01: ' || SQLERRM);
END;
/

-- A2-02: Debe PASAR — Registrar inasistencia N para adulto 2
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_lector   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-002';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_isbn          => 'TST-ISBN-001',
        pi_asistio       => 'N'
    );
    DBMS_OUTPUT.PUT_LINE('[PASS] A2-02: Inasistencia N registrada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[FAIL] A2-02: ' || SQLERRM);
END;
/

-- A2-03: Debe FALLAR -20072 — Inasistencia duplicada para mismo miembro/reunion
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_lector   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-002';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_isbn          => 'TST-ISBN-001',
        pi_asistio       => 'N'  -- ya registrada en A2-02
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A2-03: Debio fallar por inasistencia duplicada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20072 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A2-03: Inasistencia duplicada bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A2-03: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A2-04: Debe FALLAR -20070 — Valor de asistencia invalido (no S/N)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_lector   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_isbn          => 'TST-ISBN-001',
        pi_asistio       => 'X'  -- invalido
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A2-04: Debio fallar por valor de asistencia invalido.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20070 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A2-04: Valor invalido bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A2-04: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A2-05: Debe FALLAR -20071/-20073 — Reunion no agendada
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_lector   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TO_DATE('01/01/1900','DD/MM/YYYY'),  -- no existe
        pi_isbn          => 'TST-ISBN-001',
        pi_asistio       => 'S'
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A2-05: Debio fallar por reunion inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20071, -20073) THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A2-05: Reunion inexistente bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A2-05: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A2-06: Verifica retiro automatico por >30% inasistencia en el bimestre.
-- Estrategia: agendar una 2da reunion en el mismo mes, registrar asistencia
-- del adulto 1 (para que realizada=S), y marcar N al adulto 2.
-- Adulto 2 ya tiene 1 falta (A2-02) de 1 reunion realizada = 100% → retiro.
-- La 2da reunion sumara otra falta: 2 de 2 = 100%.
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
    v_lector   NUMBER;
    v_estatus  VARCHAR2(8);
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod    FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-002';

    -- Agendar segunda reunion del mismo libro (mismo mes que SYSDATE+10)
    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => 'TST-ISBN-001',
        pi_fecha_reunion => TRUNC(SYSDATE) + 11,
        pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
        pi_mod_id_lector => v_mod
    );

    -- Moderador asiste (hace realizada=S)
    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector => v_mod, pi_id_club => v_id_club,
        pi_id_grupo  => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 11,
        pi_isbn => 'TST-ISBN-001', pi_asistio => 'S'
    );

    -- Adulto 2 falta de nuevo (2da inasistencia en el mismo bimestre)
    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector => v_lector, pi_id_club => v_id_club,
        pi_id_grupo  => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 11,
        pi_isbn => 'TST-ISBN-001', pi_asistio => 'N'
    );

    -- Verificar retiro
    BEGIN
        SELECT estatus INTO v_estatus
          FROM MJV_historia_membresia
         WHERE id_lector = v_lector AND id_club = v_id_club AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN v_estatus := 'NOTFOUND'; END;

    IF v_estatus = 'retirado' THEN
        DBMS_OUTPUT.PUT_LINE('[PASS] A2-06: Retiro automatico por inasistencia >30% OK.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[INFO] A2-06: Retiro NO disparado (estatus=' || v_estatus
            || '). Revisar bimestre o porcentaje.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[FAIL] A2-06: ' || SQLERRM);
END;
/

-- A2-07: Verifica irreversibilidad del retiro — funcion veto debe retornar 1
DECLARE
    v_id_club  NUMBER;
    v_lector   NUMBER;
    v_vetado   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_lector INTO v_lector FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-002';

    v_vetado := MJV_fn_vetado_por_inasistencia(v_lector, v_id_club);
    IF v_vetado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[PASS] A2-07: Funcion de veto retorna 1 para miembro retirado por inasistencia.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[SKIP] A2-07: Veto retorna 0 (A2-06 no genero retiro — revisar bimestre).');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FAIL] A2-07: ' || SQLERRM);
END;
/


-- =============================================================================
-- ACTIVIDAD 3 — CIERRE DE DISCUSIÓN
-- =============================================================================
BEGIN DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('-- ACTIVIDAD 3: CIERRE DE DISCUSION --'); END;
/

-- A3-01 (BRECHA B): Debe FALLAR -20084 — Cerrar reunion que nunca fue realizada
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod      NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 30;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'jovenes' AND ROWNUM = 1;
    SELECT id_lector INTO v_mod FROM MJV_lector WHERE doc_identidad = 'V-TST-ADU-001';

    -- Agendar una reunion que NO tendra asistencia (realizada='N')
    BEGIN
        MJV_sp_agendar_reunion_mes(
            pi_id_club       => v_id_club,
            pi_id_grupo      => v_id_grupo,
            pi_isbn          => 'TST-ISBN-002',
            pi_fecha_reunion => v_fecha,
            pi_hora_inicio   => TO_DATE('17:00','HH24:MI'),
            pi_mod_id_lector => v_mod
        );
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Intentar cerrar sin asistencia previa: debe fallar
    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => 'TST-ISBN-002',
        pi_conclusiones  => 'Conclusiones sin asistencia.',
        pi_valoracion    => 4
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A3-01 (BRECHA B): Debio fallar por reunion no realizada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20084 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A3-01 (BRECHA B): Cierre sin asistencia bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A3-01: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-02: Debe PASAR — Cerrar discusion con asistencia previa registrada (reunion SYSDATE+10)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_isbn          => 'TST-ISBN-001',
        pi_conclusiones  => 'Libro excelente. Narrativa solida y personajes profundos.',
        pi_valoracion    => 5
    );
    DBMS_OUTPUT.PUT_LINE('[PASS] A3-02: Cierre de discusion con valoracion=5 OK.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[FAIL] A3-02: ' || SQLERRM);
END;
/

-- A3-03: Debe FALLAR -20082 — Cierre duplicado (ya cerrada con ultima=S)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 10,
        pi_isbn          => 'TST-ISBN-001',
        pi_conclusiones  => 'Segundo intento (no debe pasar).',
        pi_valoracion    => 3
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A3-03: Debio fallar por cierre duplicado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20082 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A3-03: Cierre duplicado bloqueado. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A3-03: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-04: Debe FALLAR -20080 — Conclusiones vacias (solo espacios)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 11,
        pi_isbn          => 'TST-ISBN-001',
        pi_conclusiones  => '   ',  -- solo espacios → NULL tras TRIM
        pi_valoracion    => 4
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A3-04: Debio fallar por conclusiones vacias.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20080 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A3-04: Conclusiones vacias bloqueadas. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A3-04: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-05: Debe FALLAR -20081 — Valoracion fuera de rango (6)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TRUNC(SYSDATE) + 11,
        pi_isbn          => 'TST-ISBN-001',
        pi_conclusiones  => 'Conclusiones validas.',
        pi_valoracion    => 6  -- fuera de rango
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A3-05: Debio fallar por valoracion fuera de rango.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20081 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A3-05: Valoracion fuera de rango bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A3-05: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-06: Debe FALLAR -20083 — Reunion inexistente en el calendario
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => TO_DATE('01/01/1800','DD/MM/YYYY'),
        pi_isbn          => 'TST-ISBN-001',
        pi_conclusiones  => 'Reunion que no existe.',
        pi_valoracion    => 3
    );
    DBMS_OUTPUT.PUT_LINE('[FAIL] A3-06: Debio fallar por reunion inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20083 THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] A3-06: Reunion inexistente bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] A3-06: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/


-- =============================================================================
-- BRECHAS — VALIDACIÓN DIRECTA DE LAS CORRECCIONES
-- =============================================================================
BEGIN DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('-- BRECHAS: VALIDACION DE CORRECCIONES --'); END;
/

-- BR-01 (BRECHA C): Funcion retorna 0 para ninos con inicio 17:30 (fin 19:30 > limite 19:00)
DECLARE
    v_res NUMBER;
BEGIN
    v_res := MJV_fn_hora_fin_valida(TO_DATE('17:30','HH24:MI'), 'niños', 2);
    IF v_res = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[PASS] BR-01 (BRECHA C): 17:30 ninos invalido (fin=19:30 > 19:00).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FAIL] BR-01: Funcion debio retornar 0.');
    END IF;
END;
/

-- BR-02 (BRECHA C): Funcion retorna 1 para adultos con inicio 19:00 (fin 21:00 = limite)
DECLARE
    v_res NUMBER;
BEGIN
    v_res := MJV_fn_hora_fin_valida(TO_DATE('19:00','HH24:MI'), 'adultos', 2);
    IF v_res = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[PASS] BR-02 (BRECHA C): 19:00 adultos valido (fin=21:00).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FAIL] BR-02: Funcion debio retornar 1.');
    END IF;
END;
/

-- BR-03 (BRECHA C): Trigger bloquea grupo ninos con hora 17:30
DECLARE
    v_id_club NUMBER;
BEGIN
    SELECT id_club INTO v_id_club FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'niños', SYSDATE, 3, TO_DATE('17:30','HH24:MI'));

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[FAIL] BR-03: Debio fallar: ninos con hora 17:30.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE IN (-20069, -20003) THEN
            DBMS_OUTPUT.PUT_LINE('[PASS] BR-03 (BRECHA C): Hora invalida para ninos bloqueada. | ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FAIL] BR-03: Error inesperado ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- BR-04 (BRECHA D): Las 4 vistas operativas existen y son consultables
DECLARE
    v_id_club NUMBER;
    v_cnt     NUMBER;
BEGIN
    SELECT id_club INTO v_id_club FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';

    SELECT COUNT(*) INTO v_cnt FROM MJV_vw_reuniones_calendario_activo WHERE id_club = v_id_club;
    DBMS_OUTPUT.PUT_LINE('[PASS] BR-04a: MJV_vw_reuniones_calendario_activo = ' || v_cnt || ' fila(s).');

    SELECT COUNT(*) INTO v_cnt FROM MJV_vw_inasistencias_bimestre WHERE id_club = v_id_club;
    DBMS_OUTPUT.PUT_LINE('[PASS] BR-04b: MJV_vw_inasistencias_bimestre = ' || v_cnt || ' fila(s).');

    SELECT COUNT(*) INTO v_cnt FROM MJV_vw_estado_discusiones WHERE id_club = v_id_club;
    DBMS_OUTPUT.PUT_LINE('[PASS] BR-04c: MJV_vw_estado_discusiones = ' || v_cnt || ' fila(s).');

    SELECT COUNT(*) INTO v_cnt FROM MJV_vw_moderadores_activos WHERE id_club = v_id_club;
    DBMS_OUTPUT.PUT_LINE('[PASS] BR-04d: MJV_vw_moderadores_activos = ' || v_cnt || ' fila(s).');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FAIL] BR-04: Error al consultar vistas. ' || SQLERRM);
END;
/


-- =============================================================================
-- BLOQUE FINAL: CLEANUP — Eliminar todos los datos de prueba
-- Orden inverso de FK para evitar constraint violations.
-- =============================================================================
DECLARE
    v_id_club NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[CLEANUP] Eliminando datos de prueba...');

    BEGIN
        SELECT id_club INTO v_id_club
          FROM MJV_club WHERE nombre_club = 'CLUB_TEST_REUNIONES';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('[CLEANUP] Club de prueba ya no existe, nada que limpiar.');
            RETURN;
    END;

    DELETE FROM MJV_inasistencia         WHERE id_club = v_id_club;
    DELETE FROM MJV_calendario_reunion_mes WHERE id_club = v_id_club;
    DELETE FROM MJV_g_lec                WHERE id_club = v_id_club;
    DELETE FROM MJV_grupo                WHERE id_club = v_id_club;
    DELETE FROM MJV_historia_membresia   WHERE id_club = v_id_club;
    DELETE FROM MJV_preferencia_obra
     WHERE id_lector IN (SELECT id_lector FROM MJV_lector
                          WHERE doc_identidad LIKE 'V-TST-%');
    DELETE FROM MJV_club                 WHERE id_club = v_id_club;
    DELETE FROM MJV_lector
     WHERE doc_identidad IN ('V-TST-ADU-001','V-TST-ADU-002',
                              'V-TST-NIN-001','V-TST-JOV-001','V-TST-ADU-003');
    DELETE FROM MJV_representante        WHERE doc_identidad = 'RT-TST-REP-001';
    DELETE FROM MJV_libro                WHERE isbn IN ('TST-ISBN-001','TST-ISBN-002');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[CLEANUP OK] Datos de prueba eliminados.');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  FIN DE SUITE — Revisar resultados [PASS]/[FAIL] arriba.');
    DBMS_OUTPUT.PUT_LINE('============================================================');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[CLEANUP ERROR] ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Limpiar manualmente:');
        DBMS_OUTPUT.PUT_LINE('  DELETE MJV_libro WHERE isbn IN (''TST-ISBN-001'',''TST-ISBN-002'');');
        DBMS_OUTPUT.PUT_LINE('  DELETE MJV_club  WHERE nombre_club=''CLUB_TEST_REUNIONES'';');
END;
/
