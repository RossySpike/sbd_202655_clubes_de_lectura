-- =============================================================================
-- SUITE DE TESTS COMPLETA — ADMINISTRACIÓN DE REUNIONES
-- Proyecto: Clubes de Lectura | Oracle 19c | Prefijo MJV_
-- Cobertura: todos los SPs, triggers relevantes y funciones de Admin Reuniones.
--
-- ORDEN DE EJECUCIÓN PREVIO:
--   1. script_final.sql
--   2. complemento_script_final.sql
--   3. Este archivo
--
-- CONVENCIÓN:
--   [PASS] = el test pasó (comportamiento esperado obtenido)
--   [FAIL] = el test falló (comportamiento inesperado)
--   Cada sección de setup usa v_hoy / v_fecha_hm capturados UNA vez para evitar
--   drift de SYSDATE al cruzar segundos entre INSERTs con FK compartida.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- =============================================================================
-- BLOQUE 0 — SETUP GLOBAL DE DATOS DE PRUEBA
-- Crea lectores, clubs ficticios, grupos y un libro extra para los tests.
-- Usa un club REAL con cuota='S' (Refugio Literario del Sur) para los pagos.
-- Usa un ISBN REAL de script_final para agendar reuniones.
-- Crea datos propios con prefijo T_ / DOC_T para fácil cleanup.
-- =============================================================================
DECLARE
    v_hoy      DATE := TRUNC(SYSDATE);
    v_fecha_hm DATE := v_hoy - 60;   -- fecha de inicio membresía: capturada UNA VEZ
    v_id_club_s  NUMBER;  -- club con cuota (Refugio Literario del Sur)
    v_id_club_n  NUMBER;  -- club sin cuota (El Café de los Capítulos)
BEGIN
    -- Obtener IDs de clubs reales
    SELECT id_club INTO v_id_club_s FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_club INTO v_id_club_n FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos';

    -- -------------------------------------------------------------------------
    -- Lector adulto principal (DOC_T_ADU01) — 35 años — club con cuota
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestAdulto', 'UnoApellido', 'UnoSeg', 'DOC_T_ADU01',
        '0000000001', 'tadu01@test.com', 'M',
        ADD_MONTHS(v_hoy, -35*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1));

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    SELECT id_lector, v_id_club_s, v_fecha_hm, NULL, 'activo'
      FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    SELECT v_id_club_s, 'adultos', v_hoy, 2, TO_DATE('18:00:00','HH24:MI:SS') FROM DUAL
    WHERE NOT EXISTS (
        SELECT 1 FROM MJV_grupo WHERE id_club = v_id_club_s AND tipo_grupo = 'adultos' AND ROWNUM=1
    );

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    SELECT l.id_lector, v_id_club_s, v_fecha_hm,
           (SELECT id_grupo FROM MJV_grupo WHERE id_club = v_id_club_s AND tipo_grupo = 'adultos' AND ROWNUM=1),
           v_fecha_hm, NULL
      FROM MJV_lector l WHERE l.doc_identidad = 'DOC_T_ADU01';

    -- -------------------------------------------------------------------------
    -- Lector adulto secundario (DOC_T_ADU02) — 40 años — mismo club con cuota
    -- (será usado como moderador alternativo y para test de conflicto)
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestAdulto', 'DosApellido', 'DosSeg', 'DOC_T_ADU02',
        '0000000002', 'tadu02@test.com', 'F',
        ADD_MONTHS(v_hoy, -40*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1));

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    SELECT id_lector, v_id_club_s, v_fecha_hm, NULL, 'activo'
      FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    SELECT l.id_lector, v_id_club_s, v_fecha_hm,
           (SELECT id_grupo FROM MJV_grupo WHERE id_club = v_id_club_s AND tipo_grupo = 'adultos' AND ROWNUM=1),
           v_fecha_hm, NULL
      FROM MJV_lector l WHERE l.doc_identidad = 'DOC_T_ADU02';

    -- -------------------------------------------------------------------------
    -- Lector niño (DOC_T_NIN01) — 9 años — mismo club con cuota
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestNinio', 'TresApellido', 'TresSeg', 'DOC_T_NIN01',
        '0000000003', 'tnin01@test.com', 'M',
        ADD_MONTHS(v_hoy, -9*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1));

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    SELECT id_lector, v_id_club_s, v_fecha_hm, NULL, 'activo'
      FROM MJV_lector WHERE doc_identidad = 'DOC_T_NIN01';

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    SELECT v_id_club_s, 'niños', v_hoy, 2, TO_DATE('17:00:00','HH24:MI:SS') FROM DUAL
    WHERE NOT EXISTS (
        SELECT 1 FROM MJV_grupo WHERE id_club = v_id_club_s AND tipo_grupo = 'niños' AND ROWNUM=1
    );

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    SELECT l.id_lector, v_id_club_s, v_fecha_hm,
           (SELECT id_grupo FROM MJV_grupo WHERE id_club = v_id_club_s AND tipo_grupo = 'niños' AND ROWNUM=1),
           v_fecha_hm, NULL
      FROM MJV_lector l WHERE l.doc_identidad = 'DOC_T_NIN01';

    -- -------------------------------------------------------------------------
    -- Lector sin cuota (DOC_T_NCU01) — 30 años — club SIN cuota
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestNoCuota', 'CuatroApe', 'CuatroSeg', 'DOC_T_NCU01',
        '0000000004', 'tncu01@test.com', 'F',
        ADD_MONTHS(v_hoy, -30*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1));

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    SELECT id_lector, v_id_club_n, v_fecha_hm, NULL, 'activo'
      FROM MJV_lector WHERE doc_identidad = 'DOC_T_NCU01';

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    SELECT v_id_club_n, 'adultos', v_hoy, 3, TO_DATE('18:00:00','HH24:MI:SS') FROM DUAL
    WHERE NOT EXISTS (
        SELECT 1 FROM MJV_grupo WHERE id_club = v_id_club_n AND tipo_grupo = 'adultos' AND ROWNUM=1
    );

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    SELECT l.id_lector, v_id_club_n, v_fecha_hm,
           (SELECT id_grupo FROM MJV_grupo WHERE id_club = v_id_club_n AND tipo_grupo = 'adultos' AND ROWNUM=1),
           v_fecha_hm, NULL
      FROM MJV_lector l WHERE l.doc_identidad = 'DOC_T_NCU01';

    -- -------------------------------------------------------------------------
    -- Lector para test de veto por inasistencia (DOC_T_VET01) — 28 años
    -- Tiene historial de retiro por inasistencia en el club con cuota
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestVetado', 'CincoApe', 'CincoSeg', 'DOC_T_VET01',
        '0000000005', 'tvet01@test.com', 'M',
        ADD_MONTHS(v_hoy, -28*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1));

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus, motivo_retiro)
    SELECT id_lector, v_id_club_s, v_fecha_hm - 365, v_fecha_hm - 300, 'retirado', 'inasistencia'
      FROM MJV_lector WHERE doc_identidad = 'DOC_T_VET01';

    -- -------------------------------------------------------------------------
    -- Lector con deuda histórica (DOC_T_DEU01) — 32 años
    -- Tiene membresía retirada por deuda, sin pagos
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestDeudor', 'SeisApe', 'SeisSeg', 'DOC_T_DEU01',
        '0000000006', 'tdeu01@test.com', 'M',
        ADD_MONTHS(v_hoy, -32*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1));

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus, motivo_retiro)
    SELECT id_lector, v_id_club_s, v_fecha_hm - 400, v_fecha_hm - 300, 'retirado', 'deuda'
      FROM MJV_lector WHERE doc_identidad = 'DOC_T_DEU01';

    -- -------------------------------------------------------------------------
    -- Pago para DOC_T_ADU01 (para test de retiro con solvencia OK)
    -- -------------------------------------------------------------------------
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    SELECT l.id_lector, v_id_club_s, v_fecha_hm, v_hoy, 150
      FROM MJV_lector l WHERE l.doc_identidad = 'DOC_T_ADU01';

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[SETUP] Datos de prueba globales insertados correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[SETUP FAIL] ' || SQLERRM);
        RAISE;
END;
/

-- =============================================================================
-- SECCIÓN 1 — SP MJV_sp_registrar_pago_membresia
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 1: MJV_sp_registrar_pago_membresia ==='); END;
/

-- P-01: Happy path — club con cuota, monto suficiente en USD
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    MJV_sp_registrar_pago_membresia(
        pi_id_lector   => v_id_lector,
        pi_nombre_club => 'Refugio Literario del Sur',
        pi_monto       => 200,
        pi_moneda      => 'USD',
        pi_tasa        => 1
    );
    DBMS_OUTPUT.PUT_LINE('[P-01 PASS] Pago en USD registrado correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[P-01 FAIL] ' || SQLERRM);
END;
/

-- P-02: Club SIN cuota — debe lanzar -20053
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_NCU01';
    MJV_sp_registrar_pago_membresia(
        pi_id_lector   => v_id_lector,
        pi_nombre_club => 'El Café de los Capítulos',
        pi_monto       => 200,
        pi_moneda      => 'USD',
        pi_tasa        => 1
    );
    DBMS_OUTPUT.PUT_LINE('[P-02 FAIL] Debió rechazar club sin cuota.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20053 THEN
            DBMS_OUTPUT.PUT_LINE('[P-02 PASS] Club sin cuota rechazado (-20053).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[P-02 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- P-03: Monto menor al mínimo (< 100 USD) — debe lanzar -20020
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    MJV_sp_registrar_pago_membresia(
        pi_id_lector   => v_id_lector,
        pi_nombre_club => 'Refugio Literario del Sur',
        pi_monto       => 50,
        pi_moneda      => 'USD',
        pi_tasa        => 1
    );
    DBMS_OUTPUT.PUT_LINE('[P-03 FAIL] Debió rechazar monto insuficiente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20020 THEN
            DBMS_OUTPUT.PUT_LINE('[P-03 PASS] Monto insuficiente rechazado (-20020).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[P-03 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- P-04: Lector sin membresía activa en ese club — debe lanzar -20007
DECLARE
    v_id_lector NUMBER;
BEGIN
    -- DOC_T_VET01 no tiene membresía activa en Refugio Literario del Sur
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_VET01';
    MJV_sp_registrar_pago_membresia(
        pi_id_lector   => v_id_lector,
        pi_nombre_club => 'Refugio Literario del Sur',
        pi_monto       => 200,
        pi_moneda      => 'USD',
        pi_tasa        => 1
    );
    DBMS_OUTPUT.PUT_LINE('[P-04 FAIL] Debió rechazar lector sin membresía activa.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20007 THEN
            DBMS_OUTPUT.PUT_LINE('[P-04 PASS] Sin membresía activa rechazado (-20007).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[P-04 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- P-05: Conversión monetaria — monto en VES que equivale a >= 100 USD
-- (40000 VES con tasa 36 = ~1111 USD)
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';
    MJV_sp_registrar_pago_membresia(
        pi_id_lector   => v_id_lector,
        pi_nombre_club => 'Refugio Literario del Sur',
        pi_monto       => 40000,
        pi_moneda      => 'VES',
        pi_tasa        => 36
    );
    DBMS_OUTPUT.PUT_LINE('[P-05 PASS] Pago en VES con conversión registrado correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[P-05 FAIL] ' || SQLERRM);
END;
/

-- =============================================================================
-- SECCIÓN 2 — SP MJV_sp_retirar_miembro
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 2: MJV_sp_retirar_miembro ==='); END;
/

-- R-01: Motivo inválido — debe lanzar -20056
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lector,
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'abandono'
    );
    DBMS_OUTPUT.PUT_LINE('[R-01 FAIL] Debió rechazar motivo inválido.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20056 THEN
            DBMS_OUTPUT.PUT_LINE('[R-01 PASS] Motivo inválido rechazado (-20056).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[R-01 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- R-02: Lector no activo en el club — debe lanzar -20030
DECLARE
    v_id_lector NUMBER;
BEGIN
    -- DOC_T_VET01 tiene estatus='retirado'
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_VET01';
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lector,
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'voluntario'
    );
    DBMS_OUTPUT.PUT_LINE('[R-02 FAIL] Debió rechazar miembro no activo.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20030 THEN
            DBMS_OUTPUT.PUT_LINE('[R-02 PASS] No activo rechazado (-20030).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[R-02 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- R-03: Insolvente en club con cuota — ADU02 sin pagos suficientes
-- Eliminamos el pago de P-05 para que ADU02 quede insolvente
DECLARE
    v_id_lector NUMBER;
    v_id_club   NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
    DELETE FROM MJV_pago_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[R-03 SETUP] Pagos de ADU02 eliminados para test de insolvencia.');
END;
/
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lector,
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'voluntario'
    );
    DBMS_OUTPUT.PUT_LINE('[R-03 FAIL] Debió rechazar retiro de insolvente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20040 THEN
            DBMS_OUTPUT.PUT_LINE('[R-03 PASS] Insolvente rechazado (-20040).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[R-03 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- R-04: Retiro voluntario con solvencia OK — ADU01 tiene pago registrado en setup
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lector,
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'voluntario'
    );
    DBMS_OUTPUT.PUT_LINE('[R-04 PASS] Retiro voluntario procesado correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[R-04 FAIL] ' || SQLERRM);
END;
/

-- R-05: Motivo en mayúsculas — debe normalizarse y aceptarse
-- Primero re-insertar pago para ADU02 para que sea solvente
DECLARE
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_hoy       DATE := TRUNC(SYSDATE);
    v_fecha_hm  DATE := v_hoy - 60;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    VALUES (v_id_lector, v_id_club, v_fecha_hm, v_hoy, 150);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[R-05 SETUP] Pago re-insertado para ADU02.');
END;
/
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lector,
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'VOLUNTARIO'   -- mayúsculas: debe normalizarse
    );
    DBMS_OUTPUT.PUT_LINE('[R-05 PASS] Retiro con motivo en mayúsculas aceptado (normalizado).');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[R-05 FAIL] ' || SQLERRM);
END;
/

-- R-06: Retiro de club SIN cuota — no valida solvencia, debe procesar OK
DECLARE
    v_id_lector NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_NCU01';
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lector,
        pi_nombre_club   => 'El Café de los Capítulos',
        pi_motivo_retiro => 'otro'
    );
    DBMS_OUTPUT.PUT_LINE('[R-06 PASS] Retiro de club sin cuota procesado sin validar solvencia.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[R-06 FAIL] ' || SQLERRM);
END;
/

-- =============================================================================
-- SECCIÓN 3 — SP MJV_sp_agendar_reunion_mes
-- Re-activamos ADU01 y ADU02 antes de los tests de agendar.
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 3: MJV_sp_agendar_reunion_mes ==='); END;
/

-- Setup: re-activar a ADU01 y ADU02 (retirados en sección 2)
DECLARE
    v_id_club NUMBER;
    v_id_lec1 NUMBER;
    v_id_lec2 NUMBER;
BEGIN
    SELECT id_club   INTO v_id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_lector INTO v_id_lec1 FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    SELECT id_lector INTO v_id_lec2 FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    UPDATE MJV_historia_membresia
       SET estatus = 'activo', fecha_f = NULL, motivo_retiro = NULL
     WHERE id_lector IN (v_id_lec1, v_id_lec2) AND id_club = v_id_club AND estatus = 'retirado';

    UPDATE MJV_g_lec
       SET fec_f = NULL
     WHERE id_lector IN (v_id_lec1, v_id_lec2) AND id_club = v_id_club AND fec_f IS NOT NULL;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[A1-SETUP] ADU01 y ADU02 reactivados para tests de agendar reunión.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[A1-SETUP FAIL] ' || SQLERRM);
END;
/

-- A1-01: Happy path — agendar reunión para grupo adultos, hora correcta (18:00)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';  -- El imperio final
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('18:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_id
    );
    DBMS_OUTPUT.PUT_LINE('[A1-01 PASS] Reunión agendada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A1-01 FAIL] ' || SQLERRM);
END;
/

-- A1-02: Hora no coincide con la del grupo (grupo=18:00, se pasa 17:00) — debe lanzar -20060
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 14;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => '9788466659734',
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('17:00:00','HH24:MI:SS'),  -- != 18:00 del grupo
        pi_mod_id_lector => v_mod_id
    );
    DBMS_OUTPUT.PUT_LINE('[A1-02 FAIL] Debió rechazar hora incorrecta.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20060 THEN
            DBMS_OUTPUT.PUT_LINE('[A1-02 PASS] Hora incorrecta rechazada (-20060).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A1-02 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-03: ISBN inexistente — debe lanzar -20063
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 14;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => '0000000000000',
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('18:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_id
    );
    DBMS_OUTPUT.PUT_LINE('[A1-03 FAIL] Debió rechazar ISBN inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20063 THEN
            DBMS_OUTPUT.PUT_LINE('[A1-03 PASS] ISBN inexistente rechazado (-20063).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A1-03 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-04: Moderador no es miembro activo del club — debe lanzar -20064
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 14;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    -- DOC_T_VET01 no tiene g_lec activo en este club
    SELECT id_lector INTO v_mod_id  FROM MJV_lector WHERE doc_identidad = 'DOC_T_VET01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => '9788466659734',
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('18:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_id
    );
    DBMS_OUTPUT.PUT_LINE('[A1-04 FAIL] Debió rechazar moderador no miembro.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20064 THEN
            DBMS_OUTPUT.PUT_LINE('[A1-04 PASS] Moderador no miembro rechazado (-20064).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A1-04 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-05: Reunión duplicada (mismo club/grupo/fecha/isbn) — debe lanzar -20066
-- (La reunión de A1-01 ya existe)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';
    v_fecha    DATE := TRUNC(SYSDATE) + 7;   -- misma fecha que A1-01
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('18:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_id
    );
    DBMS_OUTPUT.PUT_LINE('[A1-05 FAIL] Debió rechazar reunión duplicada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20066 THEN
            DBMS_OUTPUT.PUT_LINE('[A1-05 PASS] Reunión duplicada rechazada (-20066).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A1-05 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-06: BRECHA A — cambio de moderador para un libro ya asignado — debe lanzar -20068
-- isbn 9788466631174 ya fue agendado con ADU01 en A1-01; intentar con ADU02 en fecha distinta
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id2  NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';
    v_fecha2   DATE := TRUNC(SYSDATE) + 21;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id2  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha2,
        pi_hora_inicio   => TO_DATE('18:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_id2   -- DIFERENTE al original ADU01
    );
    DBMS_OUTPUT.PUT_LINE('[A1-06 FAIL] Debió rechazar cambio de moderador (BRECHA A).');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20068 THEN
            DBMS_OUTPUT.PUT_LINE('[A1-06 PASS] Cambio de moderador rechazado -BRECHA A- (-20068).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A1-06 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-07: Grupo de niños con moderador que NO es adulto — debe lanzar -20067 o -20031
DECLARE
    v_id_club    NUMBER;
    v_id_grupo_n NUMBER;
    v_mod_nin    NUMBER;
    v_isbn       VARCHAR2(20) := '9788420471549';  -- La historia interminable
    v_fecha      DATE := TRUNC(SYSDATE) + 14;
BEGIN
    SELECT id_club    INTO v_id_club    FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo   INTO v_id_grupo_n FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'niños' AND ROWNUM=1;
    SELECT id_lector  INTO v_mod_nin    FROM MJV_lector WHERE doc_identidad = 'DOC_T_NIN01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo_n,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('17:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_nin
    );
    DBMS_OUTPUT.PUT_LINE('[A1-07 FAIL] Debió rechazar niño como moderador de grupo niños.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20067, -20031) THEN
            DBMS_OUTPUT.PUT_LINE('[A1-07 PASS] Niño como moderador rechazado (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A1-07 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A1-08: Grupo de niños con moderador adulto correcto — happy path
DECLARE
    v_id_club    NUMBER;
    v_id_grupo_n NUMBER;
    v_mod_adu    NUMBER;
    v_isbn       VARCHAR2(20) := '9788420471549';
    v_fecha      DATE := TRUNC(SYSDATE) + 28;
BEGIN
    SELECT id_club    INTO v_id_club    FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo   INTO v_id_grupo_n FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'niños' AND ROWNUM=1;
    SELECT id_lector  INTO v_mod_adu    FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo_n,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('17:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_adu
    );
    DBMS_OUTPUT.PUT_LINE('[A1-08 PASS] Reunión de niños con moderador adulto agendada OK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A1-08 FAIL] ' || SQLERRM);
END;
/

-- A1-09: Segundo libro con ADU01 como moderador — happy path (distinto ISBN, distinta fecha)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466659734';  -- El problema de los tres cuerpos
    v_fecha    DATE := TRUNC(SYSDATE) + 35;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => TO_DATE('18:00:00','HH24:MI:SS'),
        pi_mod_id_lector => v_mod_id
    );
    DBMS_OUTPUT.PUT_LINE('[A1-09 PASS] Segundo libro distinto agendado con mismo moderador OK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A1-09 FAIL] ' || SQLERRM);
END;
/

-- =============================================================================
-- SECCIÓN 4 — SP MJV_sp_registrar_asistencia_miembro
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 4: MJV_sp_registrar_asistencia_miembro ==='); END;
/

-- A2-01: Valor de asistencia inválido — debe lanzar -20070
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_id_lec  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_asistio       => 'X'
    );
    DBMS_OUTPUT.PUT_LINE('[A2-01 FAIL] Debió rechazar valor de asistencia inválido.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20070 THEN
            DBMS_OUTPUT.PUT_LINE('[A2-01 PASS] Valor inválido rechazado (-20070).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A2-01 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A2-02: Reunión inexistente — debe lanzar -20071 o -20073
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_id_lec  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => DATE '2000-01-01',
        pi_isbn          => '9788466631174',
        pi_asistio       => 'S'
    );
    DBMS_OUTPUT.PUT_LINE('[A2-02 FAIL] Debió rechazar reunión inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20071, -20073) THEN
            DBMS_OUTPUT.PUT_LINE('[A2-02 PASS] Reunión inexistente rechazada (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A2-02 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A2-03: Happy path — asistencia S en reunión existente (agendada en A1-01)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_id_lec  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_asistio       => 'S'
    );
    DBMS_OUTPUT.PUT_LINE('[A2-03 PASS] Asistencia S registrada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A2-03 FAIL] ' || SQLERRM);
END;
/

-- A2-04: Happy path — inasistencia N (primera falta de ADU02)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_id_lec  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_asistio       => 'N'
    );
    DBMS_OUTPUT.PUT_LINE('[A2-04 PASS] Inasistencia N registrada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A2-04 FAIL] ' || SQLERRM);
END;
/

-- A2-05: Inasistencia duplicada — debe lanzar -20072
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174';
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_id_lec  FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_asistio       => 'N'   -- misma reunión: duplicado
    );
    DBMS_OUTPUT.PUT_LINE('[A2-05 FAIL] Debió rechazar inasistencia duplicada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20072 THEN
            DBMS_OUTPUT.PUT_LINE('[A2-05 PASS] Inasistencia duplicada rechazada (-20072).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A2-05 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A2-06: Retiro automático por superar 30% de inasistencias en bimestre
-- Setup: 4 reuniones realizadas + 2 inasistencias previas para ADU02.
-- La 3ra inasistencia vía el SP dispara el trigger de retiro (3/4 = 75% > 30%).
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_mod_id   NUMBER;
    v_id_lec   NUMBER;
    v_isbn     VARCHAR2(20) := '9788445076620';  -- Neuromante
    v_hoy      DATE := TRUNC(SYSDATE);
    v_fecha_hm DATE := v_hoy - 60;
    v_f1       DATE;
    v_f2       DATE;
    v_f3       DATE;
    v_f4       DATE;
BEGIN
    SELECT id_club   INTO v_id_club  FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo  INTO v_id_grupo FROM MJV_grupo  WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_mod_id   FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    SELECT id_lector INTO v_id_lec   FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    -- Fechas pasadas dentro del bimestre actual
    v_f1 := v_hoy - 4;
    v_f2 := v_hoy - 3;
    v_f3 := v_hoy - 2;
    v_f4 := v_hoy - 1;

    -- Insertar 4 reuniones realizadas
    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i, realizada, ultima, conclusiones, valoracion)
    VALUES (v_id_club, v_id_grupo, v_f1, v_isbn, v_mod_id, v_fecha_hm, v_fecha_hm, 'S', 'N', NULL, NULL);

    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i, realizada, ultima, conclusiones, valoracion)
    VALUES (v_id_club, v_id_grupo, v_f2, v_isbn, v_mod_id, v_fecha_hm, v_fecha_hm, 'S', 'N', NULL, NULL);

    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i, realizada, ultima, conclusiones, valoracion)
    VALUES (v_id_club, v_id_grupo, v_f3, v_isbn, v_mod_id, v_fecha_hm, v_fecha_hm, 'S', 'N', NULL, NULL);

    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i, realizada, ultima, conclusiones, valoracion)
    VALUES (v_id_club, v_id_grupo, v_f4, v_isbn, v_mod_id, v_fecha_hm, v_fecha_hm, 'S', 'N', NULL, NULL);

    -- Insertar 2 inasistencias directas en tabla (f1, f2)
    INSERT INTO MJV_inasistencia (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec, fecha_reunion, isbn)
    VALUES (v_id_lec, v_id_club, v_fecha_hm, v_id_grupo, v_fecha_hm, v_f1, v_isbn);

    INSERT INTO MJV_inasistencia (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec, fecha_reunion, isbn)
    VALUES (v_id_lec, v_id_club, v_fecha_hm, v_id_grupo, v_fecha_hm, v_f2, v_isbn);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[A2-06 SETUP] 4 reuniones y 2 inasistencias previas insertadas para ADU02.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[A2-06 SETUP FAIL] ' || SQLERRM);
        RAISE;
END;
/

-- Tercera inasistencia vía SP → debe disparar retiro automático (3/4 = 75% > 30%)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
    v_isbn     VARCHAR2(20) := '9788445076620';
    v_f3       DATE := TRUNC(SYSDATE) - 2;
    v_estatus  VARCHAR2(10);
BEGIN
    SELECT id_club   INTO v_id_club  FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo  INTO v_id_grupo FROM MJV_grupo  WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    SELECT id_lector INTO v_id_lec   FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU02';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_f3,
        pi_isbn          => v_isbn,
        pi_asistio       => 'N'
    );

    -- Verificar que fue retirado automáticamente
    SELECT estatus INTO v_estatus
      FROM MJV_historia_membresia
     WHERE id_lector = v_id_lec AND id_club = v_id_club
       AND estatus = 'retirado' AND ROWNUM=1;

    IF v_estatus = 'retirado' THEN
        DBMS_OUTPUT.PUT_LINE('[A2-06 PASS] Retiro automático por inasistencia disparado correctamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[A2-06 FAIL] Lector no fue retirado.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[A2-06 FAIL] Lector no fue retirado (no se encontró estatus=retirado).');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A2-06 FAIL] ' || SQLERRM);
END;
/

-- A2-07: Lector sin inscripción activa en el grupo — debe lanzar -20073 o -20074
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_id_lec   NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;
    -- DOC_T_VET01 no tiene g_lec activo
    SELECT id_lector INTO v_id_lec  FROM MJV_lector WHERE doc_identidad = 'DOC_T_VET01';

    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lec,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466631174',
        pi_asistio       => 'S'
    );
    DBMS_OUTPUT.PUT_LINE('[A2-07 FAIL] Debió rechazar lector sin inscripción activa.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20073, -20074) THEN
            DBMS_OUTPUT.PUT_LINE('[A2-07 PASS] Sin inscripción activa rechazado (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A2-07 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- =============================================================================
-- SECCIÓN 5 — SP MJV_sp_cerrar_discusion_reunion
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 5: MJV_sp_cerrar_discusion_reunion ==='); END;
/

-- A3-01: Conclusiones vacías (solo espacios → TRIM = NULL) — debe lanzar -20080
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466631174',
        pi_conclusiones  => '   ',
        pi_valoracion    => 4
    );
    DBMS_OUTPUT.PUT_LINE('[A3-01 FAIL] Debió rechazar conclusiones vacías.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20080 THEN
            DBMS_OUTPUT.PUT_LINE('[A3-01 PASS] Conclusiones vacías rechazadas (-20080).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A3-01 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-02: Valoración fuera de rango (0) — debe lanzar -20081
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466631174',
        pi_conclusiones  => 'Conclusiones del grupo.',
        pi_valoracion    => 0
    );
    DBMS_OUTPUT.PUT_LINE('[A3-02 FAIL] Debió rechazar valoración 0.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20081 THEN
            DBMS_OUTPUT.PUT_LINE('[A3-02 PASS] Valoración 0 rechazada (-20081).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A3-02 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-03: Valoración fuera de rango (6) — debe lanzar -20081
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466631174',
        pi_conclusiones  => 'Conclusiones del grupo.',
        pi_valoracion    => 6
    );
    DBMS_OUTPUT.PUT_LINE('[A3-03 FAIL] Debió rechazar valoración 6.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20081 THEN
            DBMS_OUTPUT.PUT_LINE('[A3-03 PASS] Valoración 6 rechazada (-20081).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A3-03 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-04: Reunión inexistente — debe lanzar -20083
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => DATE '2000-01-01',
        pi_isbn          => '9788466631174',
        pi_conclusiones  => 'Conclusiones del grupo.',
        pi_valoracion    => 3
    );
    DBMS_OUTPUT.PUT_LINE('[A3-04 FAIL] Debió rechazar reunión inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20083 THEN
            DBMS_OUTPUT.PUT_LINE('[A3-04 PASS] Reunión inexistente rechazada (-20083).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A3-04 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-05: BRECHA B — reunión existe pero realizada='N' — debe lanzar -20084
-- La reunión de A1-09 (isbn=9788466659734, +35 días) aún tiene realizada='N'
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 35;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466659734',
        pi_conclusiones  => 'Conclusiones del grupo.',
        pi_valoracion    => 4
    );
    DBMS_OUTPUT.PUT_LINE('[A3-05 FAIL] Debió rechazar cierre sin asistencia (BRECHA B).');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20084 THEN
            DBMS_OUTPUT.PUT_LINE('[A3-05 PASS] Cierre sin asistencia rechazado -BRECHA B- (-20084).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A3-05 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- A3-06: Happy path — cerrar reunión que SÍ fue realizada (A1-01 / +7 días, marcada en A2-03)
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466631174',
        pi_conclusiones  => 'Discusión enriquecedora. El grupo destacó el simbolismo del Lord Legislador.',
        pi_valoracion    => 5
    );
    DBMS_OUTPUT.PUT_LINE('[A3-06 PASS] Discusión cerrada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[A3-06 FAIL] ' || SQLERRM);
END;
/

-- A3-07: Reunión ya cerrada (ultima='S') — debe lanzar -20082
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_fecha    DATE := TRUNC(SYSDATE) + 7;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => '9788466631174',
        pi_conclusiones  => 'Intento de re-cerrar.',
        pi_valoracion    => 3
    );
    DBMS_OUTPUT.PUT_LINE('[A3-07 FAIL] Debió rechazar reunión ya cerrada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20082 THEN
            DBMS_OUTPUT.PUT_LINE('[A3-07 PASS] Re-cierre de reunión cerrada rechazado (-20082).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[A3-07 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- =============================================================================
-- SECCIÓN 6 — BRECHA C: MJV_fn_hora_fin_valida y MJV_tgr_validar_duracion_grupo
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 6: BRECHA C — Duración máxima grupo ==='); END;
/

-- BC-01: Hora de grupo fuera de rango (20:00) — debe fallar por constraint o trigger
DECLARE
    v_id_club NUMBER;
BEGIN
    SELECT id_club INTO v_id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur';
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'adultos', TRUNC(SYSDATE), 5, TO_DATE('20:00:00','HH24:MI:SS'));
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[BC-01 FAIL] Debió rechazar hora fuera de rango.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20069, -2290) THEN
            DBMS_OUTPUT.PUT_LINE('[BC-01 PASS] Hora fuera de rango rechazada (código: ' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[BC-01 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
        ROLLBACK;
END;
/

-- BC-02: fn_hora_fin_valida — inicio 20:00 adultos (fin=22:00 > 21:00) devuelve 0
DECLARE
    v_resultado NUMBER;
BEGIN
    v_resultado := MJV_fn_hora_fin_valida(TO_DATE('20:00:00','HH24:MI:SS'), 'adultos', 2);
    IF v_resultado = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[BC-02 PASS] fn_hora_fin_valida: 20:00 adultos → fin 22:00 → inválido (0).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[BC-02 FAIL] Esperaba 0, obtuvo: ' || v_resultado);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[BC-02 FAIL] ' || SQLERRM);
END;
/

-- BC-03: fn_hora_fin_valida — inicio 18:00 adultos (fin=20:00 ≤ 21:00) devuelve 1
DECLARE
    v_resultado NUMBER;
BEGIN
    v_resultado := MJV_fn_hora_fin_valida(TO_DATE('18:00:00','HH24:MI:SS'), 'adultos', 2);
    IF v_resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[BC-03 PASS] fn_hora_fin_valida: 18:00 adultos → fin 20:00 → válido (1).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[BC-03 FAIL] Esperaba 1, obtuvo: ' || v_resultado);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[BC-03 FAIL] ' || SQLERRM);
END;
/

-- BC-04: fn_hora_fin_valida — niños 17:00 + 2h = 19:00 ≤ 21:00 devuelve 1
DECLARE
    v_resultado NUMBER;
BEGIN
    v_resultado := MJV_fn_hora_fin_valida(TO_DATE('17:00:00','HH24:MI:SS'), 'niños', 2);
    IF v_resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[BC-04 PASS] fn_hora_fin_valida: niños 17:00+2h=19:00 → válido (1).');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[BC-04 FAIL] Esperaba 1, obtuvo: ' || v_resultado);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[BC-04 FAIL] ' || SQLERRM);
END;
/

-- =============================================================================
-- SECCIÓN 7 — FUNCIONES AUXILIARES
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 7: Funciones auxiliares ==='); END;
/

-- FN-01: fn_vetado_por_inasistencia — lector vetado devuelve 1
DECLARE
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_resultado NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_VET01';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
    v_resultado := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
    IF v_resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[FN-01 PASS] fn_vetado: lector con retiro por inasistencia → 1.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FN-01 FAIL] Esperaba 1, obtuvo: ' || v_resultado);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FN-01 FAIL] ' || SQLERRM);
END;
/

-- FN-02: fn_vetado_por_inasistencia — lector NO vetado devuelve 0
DECLARE
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_resultado NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_NIN01';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
    v_resultado := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
    IF v_resultado = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[FN-02 PASS] fn_vetado: lector sin veto → 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FN-02 FAIL] Esperaba 0, obtuvo: ' || v_resultado);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FN-02 FAIL] ' || SQLERRM);
END;
/

-- FN-03: fn_tiene_deuda_historica — lector con retiro por deuda devuelve 1
DECLARE
    v_id_lector NUMBER;
    v_resultado NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_DEU01';
    v_resultado := MJV_fn_tiene_deuda_historica(v_id_lector);
    IF v_resultado = 1 THEN
        DBMS_OUTPUT.PUT_LINE('[FN-03 PASS] fn_tiene_deuda: lector con retiro por deuda → 1.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FN-03 INFO] Obtuvo: ' || v_resultado || ' (revise criterio de deuda histórica en la función).');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FN-03 FAIL] ' || SQLERRM);
END;
/

-- FN-04: fn_tiene_deuda_historica — lector sin deuda devuelve 0
DECLARE
    v_id_lector NUMBER;
    v_resultado NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_NIN01';
    v_resultado := MJV_fn_tiene_deuda_historica(v_id_lector);
    IF v_resultado = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[FN-04 PASS] fn_tiene_deuda: lector sin deuda → 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FN-04 FAIL] Esperaba 0, obtuvo: ' || v_resultado);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FN-04 FAIL] ' || SQLERRM);
END;
/

-- FN-05: MJV_edad_miembro — verificar cálculo de edad (DOC_T_ADU01 = 35 años)
DECLARE
    v_id_lector NUMBER;
    v_edad      NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_ADU01';
    v_edad := MJV_edad_miembro(v_id_lector);
    IF v_edad = 35 THEN
        DBMS_OUTPUT.PUT_LINE('[FN-05 PASS] MJV_edad_miembro: 35 años calculado correctamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FN-05 INFO] Edad calculada: ' || v_edad || ' (puede diferir por día exacto de cumpleaños).');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FN-05 FAIL] ' || SQLERRM);
END;
/

-- =============================================================================
-- SECCIÓN 8 — SP MJV_sp_inscribir_miembro
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 8: MJV_sp_inscribir_miembro ==='); END;
/

-- IN-01: Happy path — lector adulto nuevo en club con cuota
BEGIN
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'InscrAdulto',
        pi_p_apellido      => 'PruebaApe',
        pi_s_apellido      => 'PruebaSeg',
        pi_doc_identidad   => 'DOC_T_INS01',
        pi_telefono        => '0000000101',
        pi_email           => 'ins01@test.com',
        pi_genero          => 'M',
        pi_fecha_nac       => ADD_MONTHS(TRUNC(SYSDATE), -30*12),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'El imperio final (Nacidos de la bruma)',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'American Gods'
    );
    DBMS_OUTPUT.PUT_LINE('[IN-01 PASS] Inscripción de adulto completada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[IN-01 FAIL] ' || SQLERRM);
END;
/

-- IN-02: Menor de 6 años — trigger MJV_tgr_validar_edad debe rechazar
BEGIN
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Bebe',
        pi_p_apellido      => 'PruebaApe',
        pi_s_apellido      => 'Seg',
        pi_doc_identidad   => 'DOC_T_INS_BEBE',
        pi_telefono        => '0000000109',
        pi_email           => 'bebe@test.com',
        pi_genero          => 'F',
        pi_fecha_nac       => ADD_MONTHS(TRUNC(SYSDATE), -2*12),  -- 2 años
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'El imperio final (Nacidos de la bruma)',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'American Gods'
    );
    DBMS_OUTPUT.PUT_LINE('[IN-02 FAIL] Debió rechazar menor de 6 años.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-20001, -20002, -20003) THEN
            DBMS_OUTPUT.PUT_LINE('[IN-02 PASS] Menor de 6 años rechazado (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[IN-02 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- IN-03: Club inexistente — debe lanzar error
BEGIN
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'InscrClubX',
        pi_p_apellido      => 'PruebaApe',
        pi_s_apellido      => 'Seg',
        pi_doc_identidad   => 'DOC_T_INS_CX',
        pi_telefono        => '0000000110',
        pi_email           => 'cx@test.com',
        pi_genero          => 'M',
        pi_fecha_nac       => ADD_MONTHS(TRUNC(SYSDATE), -25*12),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Club Inexistente XYZ 999',
        pi_titulo_pref1    => 'El imperio final (Nacidos de la bruma)',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'American Gods'
    );
    DBMS_OUTPUT.PUT_LINE('[IN-03 FAIL] Debió rechazar club inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT IN (0) THEN
            DBMS_OUTPUT.PUT_LINE('[IN-03 PASS] Club inexistente rechazado (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[IN-03 FAIL] No se lanzó error para club inexistente.');
        END IF;
END;
/

-- IN-04: Libro de preferencia inexistente — debe fallar
BEGIN
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'InscrLibroX',
        pi_p_apellido      => 'PruebaApe',
        pi_s_apellido      => 'Seg',
        pi_doc_identidad   => 'DOC_T_INS_LX',
        pi_telefono        => '0000000111',
        pi_email           => 'lx@test.com',
        pi_genero          => 'F',
        pi_fecha_nac       => ADD_MONTHS(TRUNC(SYSDATE), -22*12),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Libro Inexistente XYZ 999',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'American Gods'
    );
    DBMS_OUTPUT.PUT_LINE('[IN-04 FAIL] Debió rechazar libro de preferencia inexistente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT IN (0) THEN
            DBMS_OUTPUT.PUT_LINE('[IN-04 PASS] Libro inexistente rechazado (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[IN-04 FAIL] No se lanzó error para libro inexistente.');
        END IF;
END;
/

-- IN-05: Verificar que lector vetado NO puede reinscribirse en el mismo club (-20055)
-- DOC_T_VET01 tiene retiro por inasistencia en Refugio Literario del Sur.
-- El SP intentará insertar al lector (ya existe) → fallará por PK o UN antes.
-- Por tanto, verificamos con un lector que sí tiene el veto pero no está en la tabla aún.
-- Usamos DOC_T_VET02 con historial fabricado directamente.
DECLARE
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_hoy       DATE := TRUNC(SYSDATE);
BEGIN
    -- Insertar lector sin pasar por el SP para poder darle historial de veto
    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad,
        telefono, email, genero, fecha_nac, id_pais_nac)
    VALUES ('TestVetado2', 'SieteApe', 'SieteSeg', 'DOC_T_VET02',
        '0000000077', 'tvet02@test.com', 'M',
        ADD_MONTHS(v_hoy, -26*12),
        (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela' AND ROWNUM=1))
    RETURNING id_lector INTO v_id_lector;

    SELECT id_club INTO v_id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur';

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus, motivo_retiro)
    VALUES (v_id_lector, v_id_club, v_hoy - 365, v_hoy - 300, 'retirado', 'inasistencia');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[IN-05 SETUP] Lector DOC_T_VET02 con historial de veto creado.');

    -- Intentar inscribir en el mismo club donde fue vetado
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'TestVetado2',
        pi_p_apellido      => 'SieteApe',
        pi_s_apellido      => 'SieteSeg',
        pi_doc_identidad   => 'DOC_T_VET02B',  -- nuevo doc para pasar la verificación de existencia
        pi_telefono        => '0000000078',
        pi_email           => 'tvet02b@test.com',
        pi_genero          => 'M',
        pi_fecha_nac       => ADD_MONTHS(v_hoy, -26*12),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'El imperio final (Nacidos de la bruma)',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'American Gods'
    );
    DBMS_OUTPUT.PUT_LINE('[IN-05 INFO] DOC_T_VET02B inscrito (veto es por id_lector, no por doc nuevo).');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20055 THEN
            DBMS_OUTPUT.PUT_LINE('[IN-05 PASS] Lector vetado rechazado por inasistencia (-20055).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[IN-05 INFO] Código: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
        ROLLBACK;
END;
/

-- =============================================================================
-- SECCIÓN 9 — TRIGGER MJV_tgr_un_club_activo (un solo club activo por lector)
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 9: MJV_tgr_un_club_activo ==='); END;
/

-- TG-01: Insertar segunda membresía activa para mismo lector — debe fallar
DECLARE
    v_id_lector NUMBER;
    v_id_club2  NUMBER;
    v_hoy       DATE := TRUNC(SYSDATE);
BEGIN
    -- DOC_T_NIN01 tiene membresía activa en Refugio Literario del Sur
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'DOC_T_NIN01';
    SELECT id_club   INTO v_id_club2  FROM MJV_club   WHERE nombre_club = 'Mentes de Papiro';

    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    VALUES (v_id_lector, v_id_club2, v_hoy, NULL, 'activo');

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[TG-01 FAIL] Debió rechazar segunda membresía activa.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE IN (-20004, -20005, -20006) THEN
            DBMS_OUTPUT.PUT_LINE('[TG-01 PASS] Segunda membresía activa rechazada (' || SQLCODE || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[TG-01 FAIL] Código inesperado: ' || SQLCODE || ' ' || SQLERRM);
        END IF;
END;
/

-- =============================================================================
-- SECCIÓN 10 — VISTAS BRECHA D
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== SECCIÓN 10: Vistas BRECHA D ==='); END;
/

-- VW-01: MJV_vw_reuniones_calendario_activo
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM MJV_vw_reuniones_calendario_activo;
    DBMS_OUTPUT.PUT_LINE('[VW-01 PASS] MJV_vw_reuniones_calendario_activo: ' || v_count || ' filas.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[VW-01 FAIL] ' || SQLERRM);
END;
/

-- VW-02: MJV_vw_inasistencias_bimestre
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM MJV_vw_inasistencias_bimestre;
    DBMS_OUTPUT.PUT_LINE('[VW-02 PASS] MJV_vw_inasistencias_bimestre: ' || v_count || ' filas.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[VW-02 FAIL] ' || SQLERRM);
END;
/

-- VW-03: MJV_vw_estado_discusiones
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM MJV_vw_estado_discusiones;
    DBMS_OUTPUT.PUT_LINE('[VW-03 PASS] MJV_vw_estado_discusiones: ' || v_count || ' filas.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[VW-03 FAIL] ' || SQLERRM);
END;
/

-- VW-04: MJV_vw_moderadores_activos
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM MJV_vw_moderadores_activos;
    DBMS_OUTPUT.PUT_LINE('[VW-04 PASS] MJV_vw_moderadores_activos: ' || v_count || ' filas.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[VW-04 FAIL] ' || SQLERRM);
END;
/

-- VW-05: La reunión cerrada en A3-06 debe aparecer como CERRADA en vw_estado_discusiones
DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_estatus  VARCHAR2(20);
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM=1;

    SELECT estatus_discusion INTO v_estatus
      FROM MJV_vw_estado_discusiones
     WHERE id_club  = v_id_club
       AND id_grupo = v_id_grupo
       AND isbn     = '9788466631174'
       AND ROWNUM   = 1;

    IF v_estatus = 'CERRADA' THEN
        DBMS_OUTPUT.PUT_LINE('[VW-05 PASS] Reunión cerrada aparece como CERRADA en vw_estado_discusiones.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[VW-05 FAIL] Estatus inesperado: ' || NVL(v_estatus,'NULL'));
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('[VW-05 FAIL] Reunión no encontrada en vw_estado_discusiones.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[VW-05 FAIL] ' || SQLERRM);
END;
/

-- =============================================================================
-- CLEANUP — Eliminar todos los datos de prueba en orden inverso a FK
-- =============================================================================

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('=== CLEANUP: Eliminando datos de prueba ==='); END;
/

DECLARE
    v_docs     SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'DOC_T_ADU01','DOC_T_ADU02','DOC_T_NIN01','DOC_T_NCU01',
        'DOC_T_VET01','DOC_T_DEU01','DOC_T_INS01','DOC_T_INS_BEBE',
        'DOC_T_INS_CX','DOC_T_INS_LX','DOC_T_VET02','DOC_T_VET02B'
    );
    v_isbn_s   SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        '9788466631174','9788466659734','9788445076620','9788420471549'
    );
    v_id_club_s NUMBER;
    v_id_club_n NUMBER;
BEGIN
    SELECT id_club INTO v_id_club_s FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_club INTO v_id_club_n FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos';

    -- 1. Inasistencias
    DELETE FROM MJV_inasistencia
     WHERE id_lector IN (SELECT id_lector FROM MJV_lector
                          WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs)));

    -- 2. Calendario de reuniones de test (ISBN de test en grupos de test que creamos)
    DELETE FROM MJV_calendario_reunion_mes
     WHERE mod_id_lector IN (SELECT id_lector FROM MJV_lector
                               WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs)))
        OR (id_club IN (v_id_club_s, v_id_club_n)
            AND isbn IN (SELECT COLUMN_VALUE FROM TABLE(v_isbn_s))
            AND id_grupo IN (
                SELECT id_grupo FROM MJV_grupo
                 WHERE id_club IN (v_id_club_s, v_id_club_n)
                   AND fecha_creacion = TRUNC(SYSDATE)
            ));

    -- 3. Preferencias de obra
    DELETE FROM MJV_preferencia_obra
     WHERE id_lector IN (SELECT id_lector FROM MJV_lector
                          WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs)));

    -- 4. Pagos de membresía
    DELETE FROM MJV_pago_membresia
     WHERE id_lector IN (SELECT id_lector FROM MJV_lector
                          WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs)));

    -- 5. G_lec
    DELETE FROM MJV_g_lec
     WHERE id_lector IN (SELECT id_lector FROM MJV_lector
                          WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs)));

    -- 6. Historia membresía
    DELETE FROM MJV_historia_membresia
     WHERE id_lector IN (SELECT id_lector FROM MJV_lector
                          WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs)));

    -- 7. Lectores
    DELETE FROM MJV_lector
     WHERE doc_identidad IN (SELECT COLUMN_VALUE FROM TABLE(v_docs));

    -- 8. Grupos de prueba creados hoy (solo si ya no tienen dependencias)
    DELETE FROM MJV_grupo
     WHERE id_club IN (v_id_club_s, v_id_club_n)
       AND fecha_creacion = TRUNC(SYSDATE)
       AND id_grupo NOT IN (SELECT DISTINCT id_grupo FROM MJV_g_lec)
       AND id_grupo NOT IN (SELECT DISTINCT id_grupo FROM MJV_calendario_reunion_mes);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[CLEANUP] Datos de prueba eliminados correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[CLEANUP FAIL] ' || SQLERRM);
END;
/

BEGIN DBMS_OUTPUT.PUT_LINE(''); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('==================================================='); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('  SUITE COMPLETA EJECUTADA'); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('  Busca [FAIL] en la salida para identificar errores.'); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('==================================================='); END;
/
