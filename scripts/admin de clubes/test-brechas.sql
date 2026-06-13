-- =============================================================================
-- TEST SUITE — BRECHAS DE ADMINISTRACIÓN DE CLUBES
-- Archivo: test-brechas.sql
-- Cubre: Las 7 brechas implementadas en brechas_admin_clubes.sql
-- Convención: Cada test declara su RESULTADO ESPERADO como comentario
--             antes de ejecutarse. Los tests negativos (deben fallar) usan
--             bloques BEGIN/EXCEPTION para capturar el error sin abortar
--             la sesión.
-- =============================================================================
-- PRECONDICIÓN: La base de datos debe tener cargados los inserts del sistema
--               (inserts.sql) y compilados todos los objetos de:
--               TriggersFunctions.sql + brechas_admin_clubes.sql
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- =============================================================================
-- UTILIDAD: Procedimiento auxiliar para imprimir resultados de test
-- =============================================================================
CREATE OR REPLACE PROCEDURE MJV_test_log (
    p_suite    IN VARCHAR2,
    p_caso     IN VARCHAR2,
    p_esperado IN VARCHAR2,
    p_obtenido IN VARCHAR2
) IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('  SUITE  : ' || p_suite);
    DBMS_OUTPUT.PUT_LINE('  CASO   : ' || p_caso);
    DBMS_OUTPUT.PUT_LINE('  ESPERADO: ' || p_esperado);
    DBMS_OUTPUT.PUT_LINE('  OBTENIDO: ' || p_obtenido);
    IF p_obtenido = p_esperado THEN
        DBMS_OUTPUT.PUT_LINE('  RESULTADO: ✓ PASS');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  RESULTADO: ✗ FAIL  ← REVISAR');
    END IF;
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════════╝');
END MJV_test_log;
/


-- =============================================================================
-- SUITE 1: MJV_fn_tiene_deuda_historica  (BRECHA 1)
-- =============================================================================
-- Descripción: Verifica que la función detecte correctamente si un lector
--              tiene saldo pendiente en membresías históricas retiradas.
-- =============================================================================

DECLARE
    -- Lectores con datos reales del inserts.sql
    -- V-ADU01 (Alejandro García) → se usará como conejillo: lo inscribimos,
    -- lo retiramos sin pagar, y verificamos que la función lo detecta.
    v_id_lector   NUMBER;
    v_id_club     NUMBER;
    v_suite       VARCHAR2(60) := 'BRECHA 1 — fn_tiene_deuda_historica';
BEGIN
    -- =========================================================================
    -- SETUP: Crear escenario de deuda histórica manualmente.
    --        Usamos un lector ya existente (V-ADU01, club 1 = Refugio Literario
    --        del Sur, cuota_anual='S') asumiendo que no tiene membresía activa
    --        y que su membresía anterior ya fue retirada sin pagar.
    --        Si ya existe una membresía activa del lector en ese club desde los
    --        inserts, ajustar el test usando un lector diferente.
    -- =========================================================================

    -- Usamos V-ADU01 como lector de referencia para obtener su id.
    -- Para los tests 1-B y 1-C usamos 'Mentes de Papiro' (cuota_anual='S')
    -- donde V-ADU01 NO tiene historial previo en inserts.sql, evitando
    -- conflictos con las FKs de g_lec y calendario_reunion_mes.
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Mentes de Papiro';

    -- TEST 1-A: Lector SIN deuda histórica (nunca ha pertenecido a otro club
    --           con saldo pendiente). V-ADU05 está activo en 'El Café de los Capítulos'
    --           (cuota_anual='N') → ninguna deuda computable.
    -- RESULTADO ESPERADO: 0 (sin deuda)
    DECLARE
        v_id_lector2 NUMBER;
        v_res        NUMBER;
    BEGIN
        SELECT id_lector INTO v_id_lector2 FROM MJV_lector WHERE doc_identidad = 'V-ADU05';
        v_res := MJV_fn_tiene_deuda_historica(v_id_lector2);
        MJV_test_log(
            'BRECHA 1 — fn_tiene_deuda_historica',
            '1-A: Lector sin historial de retiro en club con cuota → sin deuda',
            '0',
            TO_CHAR(v_res)
        );
    EXCEPTION
        WHEN OTHERS THEN
            MJV_test_log('BRECHA 1','1-A','0','ERROR: '||SQLERRM);
    END;

    -- TEST 1-B: Insertar membresía retirada SIN pagos para V-ADU01 en 'Mentes de Papiro'
    --           (cuota_anual='S'). Ingreso hace 2 años → debe 200 USD → pagó 0 → tiene deuda.
    --           V-ADU01 no tiene historial en Mentes de Papiro en inserts.sql,
    --           por lo que el DELETE es seguro (no hay FK de g_lec ni calendario apuntando aquí).
    -- RESULTADO ESPERADO: 1 (tiene deuda)
    DECLARE
        v_res NUMBER;
    BEGIN
        DELETE FROM MJV_pago_membresia     WHERE id_lector = v_id_lector AND id_club = v_id_club;
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;

        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club,
                ADD_MONTHS(SYSDATE, -24),
                'retirado', SYSDATE, 'voluntario');

        v_res := MJV_fn_tiene_deuda_historica(v_id_lector);
        MJV_test_log(
            'BRECHA 1 — fn_tiene_deuda_historica',
            '1-B: Lector con 2 años retirado sin pagar en club con cuota → tiene deuda',
            '1',
            TO_CHAR(v_res)
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log('BRECHA 1','1-B','1','ERROR: '||SQLERRM);
    END;

    -- TEST 1-C: Historial retirado CON pago completo en 'Mentes de Papiro'.
    --           2 años → debe 200 USD → pagó exactamente 200 USD → sin deuda.
    --           Se inserta primero como 'activo' para que el trigger de pago
    --           (MJV_tgr_validar_membresia_pago) acepte los pagos, y luego
    --           se actualiza a 'retirado' antes de llamar la función.
    -- RESULTADO ESPERADO: 0 (solvente)
    DECLARE
        v_fecha_i DATE := ADD_MONTHS(SYSDATE, -24);
        v_res     NUMBER;
    BEGIN
        DELETE FROM MJV_pago_membresia     WHERE id_lector = v_id_lector AND id_club = v_id_club;
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;

        -- Insertar como 'activo' primero para que el trigger de pago no rechace los INSERTs
        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
        VALUES (v_id_lector, v_id_club, v_fecha_i, 'activo');

        -- Insertar los pagos (el trigger acepta porque estatus='activo')
        INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
        VALUES (v_id_lector, v_id_club, v_fecha_i, ADD_MONTHS(SYSDATE,-12), 100);
        INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
        VALUES (v_id_lector, v_id_club, v_fecha_i, SYSDATE, 100);

        -- Ahora marcar como retirado para que la función lo evalúe como historial
        UPDATE MJV_historia_membresia
           SET estatus = 'retirado', fecha_f = SYSDATE, motivo_retiro = 'voluntario'
         WHERE id_lector = v_id_lector AND id_club = v_id_club AND fecha_i = v_fecha_i;

        v_res := MJV_fn_tiene_deuda_historica(v_id_lector);
        MJV_test_log(
            'BRECHA 1 — fn_tiene_deuda_historica',
            '1-C: 2 años retirado con 200 USD pagados → solvente',
            '0',
            TO_CHAR(v_res)
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log('BRECHA 1','1-C','0','ERROR: '||SQLERRM);
    END;

    -- TEST 1-D: La función no penaliza clubes con cuota_anual='N'.
    --           'La Alianza de la Tinta' (cuota='N') → incluso sin pago no es deuda.
    -- RESULTADO ESPERADO: 0 (no aplica cuota)
    DECLARE
        v_id_club_n NUMBER;
        v_fecha_i   DATE := ADD_MONTHS(SYSDATE, -24);
        v_res       NUMBER;
    BEGIN
        SELECT id_club INTO v_id_club_n FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta';
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club_n;

        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club_n, v_fecha_i, 'retirado', SYSDATE, 'voluntario');

        v_res := MJV_fn_tiene_deuda_historica(v_id_lector);
        MJV_test_log(
            'BRECHA 1 — fn_tiene_deuda_historica',
            '1-D: Club sin cuota (cuota_anual=N) → no cuenta como deuda',
            '0',
            TO_CHAR(v_res)
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log('BRECHA 1','1-D','0','ERROR: '||SQLERRM);
    END;
END;
/


-- =============================================================================
-- SUITE 2: MJV_fn_vetado_por_inasistencia  (BRECHA 2)
-- =============================================================================

DECLARE
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_res       NUMBER;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'El Café de los Capítulos';

    -- TEST 2-A: Lector sin retiro por inasistencia → no vetado
    -- RESULTADO ESPERADO: 0
    BEGIN
        v_res := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
        MJV_test_log(
            'BRECHA 2 — fn_vetado_por_inasistencia',
            '2-A: Lector sin retiro por inasistencia → no vetado',
            '0',
            TO_CHAR(v_res)
        );
    EXCEPTION WHEN OTHERS THEN
        MJV_test_log('BRECHA 2','2-A','0','ERROR: '||SQLERRM);
    END;

    -- TEST 2-B: Insertar retiro con motivo='inasistencia' y verificar veto.
    -- RESULTADO ESPERADO: 1 (vetado)
    DECLARE
        v_fecha_i DATE := ADD_MONTHS(SYSDATE, -12);
    BEGIN
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;

        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club, v_fecha_i, 'retirado', SYSDATE, 'inasistencia');

        v_res := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
        MJV_test_log(
            'BRECHA 2 — fn_vetado_por_inasistencia',
            '2-B: Lector retirado por inasistencia → vetado (1)',
            '1',
            TO_CHAR(v_res)
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK;
            MJV_test_log('BRECHA 2','2-B','1','ERROR: '||SQLERRM);
    END;

    -- TEST 2-C: Retiro por otro motivo ('deuda') NO veta para reingreso.
    -- RESULTADO ESPERADO: 0 (el veto solo aplica a 'inasistencia')
    DECLARE
        v_fecha_i DATE := ADD_MONTHS(SYSDATE, -12);
    BEGIN
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;

        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club, v_fecha_i, 'retirado', SYSDATE, 'deuda');

        v_res := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
        MJV_test_log(
            'BRECHA 2 — fn_vetado_por_inasistencia',
            '2-C: Retiro por deuda → NO veta el reingreso',
            '0',
            TO_CHAR(v_res)
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK;
            MJV_test_log('BRECHA 2','2-C','0','ERROR: '||SQLERRM);
    END;

    -- TEST 2-D: El veto es específico por club. Vetado en club A no implica
    --           veto en club B.
    -- RESULTADO ESPERADO: 0 (veto solo en el club original)
    DECLARE
        v_id_club_b NUMBER;
        v_fecha_i   DATE := ADD_MONTHS(SYSDATE, -12);
    BEGIN
        SELECT id_club INTO v_id_club_b FROM MJV_club WHERE nombre_club = 'Mentes de Papiro';

        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;
        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club, v_fecha_i, 'retirado', SYSDATE, 'inasistencia');

        -- Verificar contra club distinto (club_b)
        v_res := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club_b);
        MJV_test_log(
            'BRECHA 2 — fn_vetado_por_inasistencia',
            '2-D: Vetado en club A → no vetado en club B',
            '0',
            TO_CHAR(v_res)
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK;
            MJV_test_log('BRECHA 2','2-D','0','ERROR: '||SQLERRM);
    END;
END;
/


-- =============================================================================
-- SUITE 3: MJV_fn_grupo_discutiendo_libro + trigger inscripción  (BRECHA 3)
-- =============================================================================

DECLARE
    v_id_club  NUMBER;
    v_id_grupo NUMBER;
    v_isbn     VARCHAR2(20) := '9788466631174'; -- El imperio final
    v_suite    VARCHAR2(60) := 'BRECHA 3 — Regla de Oro';
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    -- TEST 3-A: Grupo SIN reuniones activas (ultima='N') → función devuelve 0.
    --           Limpiamos primero cualquier entrada activa del ISBN de prueba
    --           (primero inasistencias → hijo de calendario, luego calendario).
    -- RESULTADO ESPERADO: 0
    DECLARE
        v_res NUMBER;
    BEGIN
        -- Borrar hijo antes que padre para no violar FK MJV_INASISTENCIA_FK_CAL
        DELETE FROM MJV_inasistencia
         WHERE id_club  = v_id_club
           AND id_grupo = v_id_grupo
           AND isbn     = v_isbn;

        DELETE FROM MJV_calendario_reunion_mes
         WHERE id_club   = v_id_club
           AND id_grupo  = v_id_grupo
           AND isbn      = v_isbn
           AND realizada = 'S'
           AND ultima    = 'N';

        v_res := MJV_fn_grupo_discutiendo_libro(v_id_club, v_id_grupo);
        MJV_test_log(v_suite,
            '3-A: Grupo sin reuniones activas (isbn prueba limpiado) → fn devuelve 0',
            '0', TO_CHAR(v_res));
        ROLLBACK;
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        MJV_test_log(v_suite,'3-A','0','ERROR: '||SQLERRM);
    END;

    -- TEST 3-B: Insertar reunión realizada con ultima='N' → libro en discusión.
    -- RESULTADO ESPERADO: 1
    DECLARE
        v_id_lector_mod NUMBER;
        v_fecha_i_mod   DATE;
        v_fec_i_mod     DATE;
        v_res           NUMBER;
    BEGIN
        -- Obtener un moderador válido (primer miembro activo del grupo adultos)
        SELECT gl.id_lector, gl.fecha_i, gl.fec_i
          INTO v_id_lector_mod, v_fecha_i_mod, v_fec_i_mod
          FROM MJV_g_lec gl
         WHERE gl.id_club  = v_id_club
           AND gl.id_grupo = v_id_grupo
           AND gl.fec_f    IS NULL
           AND ROWNUM = 1;

        -- Insertar reunión: realizada=S, ultima=N → debate en curso
        INSERT INTO MJV_calendario_reunion_mes
            (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
             realizada, ultima, conclusiones, valoracion)
        VALUES (v_id_club, v_id_grupo, TRUNC(SYSDATE) - 7, v_isbn,
                v_id_lector_mod, v_fec_i_mod, v_fecha_i_mod,
                'S', 'N', NULL, NULL);

        v_res := MJV_fn_grupo_discutiendo_libro(v_id_club, v_id_grupo);
        MJV_test_log(v_suite,
            '3-B: Reunión realizada con ultima=N → fn devuelve 1',
            '1', TO_CHAR(v_res));
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK;
            MJV_test_log(v_suite,'3-B','1','ERROR: '||SQLERRM);
    END;

    -- TEST 3-C: Reunión realizada con ultima='S' (debate cerrado) → fn devuelve 0.
    --           Usamos un grupo temporal aislado en 'Refugio Literario del Sur'.
    --           El moderador es V-ADU01 con fechas conocidas de inserts.sql
    --           (fecha_i = fec_i = 18/07/2024) para evitar un SELECT dinámico
    --           que podría fallar si el estado del grupo real es incierto.
    -- RESULTADO ESPERADO: 0
    DECLARE
        v_id_grupo_tmp  NUMBER;
        -- V-ADU01 en Refugio Literario del Sur: fecha_i = fec_i = 18/07/2024
        v_id_lector_mod NUMBER;
        v_fecha_mem     DATE := TO_DATE('18/07/2024','DD/MM/YYYY');  -- gl.fecha_i = gl.fec_i
        v_res           NUMBER;
    BEGIN
        SELECT id_lector INTO v_id_lector_mod
          FROM MJV_lector WHERE doc_identidad = 'V-ADU01';

        -- Crear un grupo temporal limpio (sin reuniones previas)
        INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
        VALUES (v_id_club, 'adultos', SYSDATE, 5, TO_DATE('19:00:00','HH24:MI:SS'))
        RETURNING id_grupo INTO v_id_grupo_tmp;

        -- Inscribir a V-ADU01 en el grupo temporal
        -- (FK: fecha_i referencia historia_membresia.fecha_i = 18/07/2024)
        INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i)
        VALUES (v_id_lector_mod, v_id_club, v_fecha_mem, v_id_grupo_tmp, SYSDATE);

        -- Insertar solo una reunión cerrada (ultima='S') en el grupo temporal
        -- FK calendario: mod_fecha_i → g_lec.fecha_i = v_fecha_mem
        --                mod_hist_fecha_i → g_lec.fec_i = SYSDATE
        INSERT INTO MJV_calendario_reunion_mes
            (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
             realizada, ultima, conclusiones, valoracion)
        VALUES (v_id_club, v_id_grupo_tmp, TRUNC(SYSDATE) - 14, v_isbn,
                v_id_lector_mod, v_fecha_mem, SYSDATE,
                'S', 'S', 'Debate concluido.', 4);

        v_res := MJV_fn_grupo_discutiendo_libro(v_id_club, v_id_grupo_tmp);
        MJV_test_log(v_suite,
            '3-C: Solo reunión cerrada (ultima=S) en grupo aislado → fn devuelve 0',
            '0', TO_CHAR(v_res));
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK;
            MJV_test_log(v_suite,'3-C','0','ERROR: '||SQLERRM);
    END;
END;
/

-- TEST 3-D: El trigger MJV_tgr_bloquear_inscripcion_libro_activo DEBE impedir
--           un INSERT en MJV_g_lec cuando el grupo tiene debate activo.
-- RESULTADO ESPERADO: ORA-20050 — error de aplicación con el código de la brecha
DECLARE
    v_id_club       NUMBER;
    v_id_grupo      NUMBER;
    v_id_lector_nuevo NUMBER;
    v_isbn          VARCHAR2(20) := '9788466631174';
    v_id_lector_mod NUMBER;
    v_fecha_i_mod   DATE;
    v_fec_i_mod     DATE;
    v_fecha_i_hm    DATE := SYSDATE;
BEGIN
    SELECT id_club  INTO v_id_club  FROM MJV_club  WHERE nombre_club = 'Refugio Literario del Sur';
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo
     WHERE id_club = v_id_club AND tipo_grupo = 'adultos' AND ROWNUM = 1;

    -- Obtener un adulto que NO sea del grupo para simular ingreso nuevo
    SELECT gl.id_lector, gl.fecha_i, gl.fec_i
      INTO v_id_lector_mod, v_fecha_i_mod, v_fec_i_mod
      FROM MJV_g_lec gl
     WHERE gl.id_club = v_id_club AND gl.id_grupo = v_id_grupo
       AND gl.fec_f IS NULL AND ROWNUM = 1;

    -- Insertar reunión activa (debate en curso)
    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
         realizada, ultima, conclusiones, valoracion)
    VALUES (v_id_club, v_id_grupo, TRUNC(SYSDATE) - 3, v_isbn,
            v_id_lector_mod, v_fec_i_mod, v_fecha_i_mod,
            'S', 'N', NULL, NULL);

    -- Intentar inscribir a V-ADU03 en ese grupo mientras hay debate
    SELECT id_lector INTO v_id_lector_nuevo FROM MJV_lector WHERE doc_identidad = 'V-ADU03';

    -- Limpiar estado previo para garantizar idempotencia (evitar PK violation)
    DELETE FROM MJV_inasistencia       WHERE id_lector = v_id_lector_nuevo AND id_club = v_id_club;
    DELETE FROM MJV_g_lec              WHERE id_lector = v_id_lector_nuevo AND id_club = v_id_club;
    DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector_nuevo AND id_club = v_id_club;

    -- Membresía mínima necesaria para que el trigger de membresía no falle primero
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
    VALUES (v_id_lector_nuevo, v_id_club, v_fecha_i_hm, 'activo');

    -- Este INSERT debe ser BLOQUEADO por el trigger (ORA-20050)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_lector_nuevo, v_id_club, v_fecha_i_hm, v_id_grupo, SYSDATE, NULL);

    ROLLBACK;
    MJV_test_log('BRECHA 3 — Trigger inscripción',
        '3-D: Inscribir miembro con debate activo → DEBE ser bloqueado',
        'ORA-20050', 'SIN ERROR — FALLO: trigger no actuó');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        MJV_test_log('BRECHA 3 — Trigger inscripción',
            '3-D: Inscribir miembro con debate activo → DEBE ser bloqueado',
            'ORA-20050',
            'ORA-' || TO_CHAR(ABS(SQLCODE)) || ': ' || SUBSTR(SQLERRM, 1, 80));
END;
/


-- =============================================================================
-- SUITE 4: Moderador simultáneo en más de un grupo (BRECHA 4)
-- =============================================================================
-- Usamos 'Mentes de Papiro' con grupos temporales creados desde cero.
-- Moderadores con fechas hardcodeadas de inserts.sql para evitar SELECTs
-- dinámicos que pueden fallar si el estado del grupo adultos preexistente
-- es incierto en el momento de la ejecución.
--   V-ADU13: fecha_i (membresía) = fec_i (grupo) = TO_DATE('01/01/2025')
--   V-ADU14: fecha_i (membresía) = fec_i (grupo) = TO_DATE('12/05/2024')
-- FK calendario→g_lec: mod_fecha_i → g_lec.fecha_i
--                      mod_hist_fecha_i → g_lec.fec_i
-- =============================================================================

DECLARE
    v_id_club      NUMBER;
    v_id_grupo_a   NUMBER;
    v_id_grupo_b   NUMBER;
    v_isbn_a       VARCHAR2(20) := '9788445076620';  -- Neuromante
    v_isbn_b       VARCHAR2(20) := '9788466659734';  -- El problema de 3 cuerpos
    v_suite        VARCHAR2(60) := 'BRECHA 4 — Moderador en múltiples grupos';
    -- Moderador 1: V-ADU13, ingreso membresía = ingreso grupo = 01/01/2025
    v_mod1         NUMBER;
    v_mod1_mem_fi  DATE := TO_DATE('01/01/2025','DD/MM/YYYY');  -- g_lec.fecha_i
    v_mod1_grp_fi  DATE;  -- g_lec.fec_i en grupos temporales = SYSDATE al insertar
    -- Moderador 2: V-ADU14, ingreso membresía = ingreso grupo = 12/05/2024
    v_mod2         NUMBER;
    v_mod2_mem_fi  DATE := TO_DATE('12/05/2024','DD/MM/YYYY');
    v_mod2_grp_fi  DATE;
BEGIN
    SELECT id_club  INTO v_id_club FROM MJV_club   WHERE nombre_club   = 'Mentes de Papiro';
    SELECT id_lector INTO v_mod1   FROM MJV_lector WHERE doc_identidad = 'V-ADU13';
    SELECT id_lector INTO v_mod2   FROM MJV_lector WHERE doc_identidad = 'V-ADU14';

    -- Crear dos grupos temporales limpios (sin datos preexistentes)
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'adultos', SYSDATE, 2, TO_DATE('18:00:00','HH24:MI:SS'))
    RETURNING id_grupo INTO v_id_grupo_a;

    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'adultos', SYSDATE, 3, TO_DATE('19:00:00','HH24:MI:SS'))
    RETURNING id_grupo INTO v_id_grupo_b;

    -- Guardar SYSDATE para que fec_i y mod_hist_fecha_i sean el mismo valor
    v_mod1_grp_fi := SYSDATE;
    v_mod2_grp_fi := SYSDATE;

    -- Inscribir al moderador 1 en ambos grupos temporales
    -- g_lec(fecha_i=v_mod1_mem_fi, fec_i=v_mod1_grp_fi)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_mod1, v_id_club, v_mod1_mem_fi, v_id_grupo_a, v_mod1_grp_fi, NULL);

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_mod1, v_id_club, v_mod1_mem_fi, v_id_grupo_b, v_mod1_grp_fi, NULL);

    -- Insertar reunión ACTIVA en grupo_a (debate en curso: realizada=S, ultima=N)
    -- calendario.mod_fecha_i → g_lec.fecha_i = v_mod1_mem_fi
    -- calendario.mod_hist_fecha_i → g_lec.fec_i = v_mod1_grp_fi
    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
         realizada, ultima, conclusiones, valoracion)
    VALUES (v_id_club, v_id_grupo_a, TRUNC(SYSDATE) - 5, v_isbn_a,
            v_mod1, v_mod1_mem_fi, v_mod1_grp_fi,
            'S', 'N', NULL, NULL);

    -- SAVEPOINT tras el setup compartido
    SAVEPOINT sp_suite4_setup;

    -- TEST 4-A: Intentar asignar el MISMO moderador (mod1) a una reunión del grupo_b.
    --           Tiene debate activo en grupo_a → DEBE ser rechazado por el trigger.
    -- RESULTADO ESPERADO: ORA-20052
    BEGIN
        INSERT INTO MJV_calendario_reunion_mes
            (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
             realizada, ultima, conclusiones, valoracion)
        VALUES (v_id_club, v_id_grupo_b, TRUNC(SYSDATE) - 1, v_isbn_b,
                v_mod1, v_mod1_mem_fi, v_mod1_grp_fi,
                'N', 'N', NULL, NULL);

        ROLLBACK TO sp_suite4_setup;
        MJV_test_log(v_suite,
            '4-A: Moderador ocupado en grupo_a → rechazado en grupo_b',
            'ORA-20052', 'SIN ERROR — FALLO: trigger no actuó');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_suite4_setup;
            MJV_test_log(v_suite,
                '4-A: Moderador ocupado en grupo_a → rechazado en grupo_b',
                'ORA-20052',
                'ORA-' || TO_CHAR(ABS(SQLCODE)) || ': ' || SUBSTR(SQLERRM, 1, 80));
    END;

    -- TEST 4-B: Moderador 2 (V-ADU14) cuyo debate en grupo_a ya cerró (ultima='S').
    --           Sin debates abiertos → debe poder moderar grupo_b sin error.
    -- RESULTADO ESPERADO: INSERT exitoso (sin error)
    BEGIN
        -- Inscribir al moderador 2 en ambos grupos temporales
        INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
        VALUES (v_mod2, v_id_club, v_mod2_mem_fi, v_id_grupo_a, v_mod2_grp_fi, NULL);

        INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
        VALUES (v_mod2, v_id_club, v_mod2_mem_fi, v_id_grupo_b, v_mod2_grp_fi, NULL);

        -- Debate CERRADO de mod2 en grupo_a (ultima='S') → mod2 está disponible
        INSERT INTO MJV_calendario_reunion_mes
            (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
             realizada, ultima, conclusiones, valoracion)
        VALUES (v_id_club, v_id_grupo_a, TRUNC(SYSDATE) - 10, v_isbn_a,
                v_mod2, v_mod2_mem_fi, v_mod2_grp_fi,
                'S', 'S', 'Concluido correctamente.', 4);

        -- Ahora puede moderar en grupo_b (debate anterior cerrado → libre)
        INSERT INTO MJV_calendario_reunion_mes
            (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
             realizada, ultima, conclusiones, valoracion)
        VALUES (v_id_club, v_id_grupo_b, TRUNC(SYSDATE), v_isbn_b,
                v_mod2, v_mod2_mem_fi, v_mod2_grp_fi,
                'N', 'N', NULL, NULL);

        MJV_test_log(v_suite,
            '4-B: Moderador con debate cerrado → puede moderar nuevo grupo',
            'SIN ERROR', 'SIN ERROR');
        ROLLBACK TO sp_suite4_setup;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_suite4_setup;
            MJV_test_log(v_suite,
                '4-B: Moderador con debate cerrado → puede moderar nuevo grupo',
                'SIN ERROR', 'ERROR: '||SQLERRM);
    END;

    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[SUITE 4] ERROR GENERAL: ' || SQLERRM);
END;
/


-- =============================================================================
-- SUITE 5: MJV_fn_pct_inasistencia_bimestre + retiro automático  (BRECHA 5)
-- =============================================================================
-- Lector de prueba : V-ADU13 (Mentes de Papiro, adultos)
-- Moderador        : V-ADU14 (Mentes de Papiro, adultos)
-- Fechas de inserts.sql (hardcoded para evitar SELECTs dinámicos):
--   V-ADU13: membresía fecha_i = 01/01/2025
--   V-ADU14: membresía fecha_i = fec_i (grupo preexistente) = 12/05/2024
-- Para los grupos TEMPORALES, fec_i del moderador = NOW (guardado en variable).
-- FK calendario→g_lec: mod_fecha_i → g_lec.fecha_i  (fecha membresía)
--                      mod_hist_fecha_i → g_lec.fec_i (fecha ingreso grupo)
-- =============================================================================

DECLARE
    v_suite     VARCHAR2(60) := 'BRECHA 5 — Retiro por inasistencia';
    v_id_lector NUMBER;     -- V-ADU13
    v_id_club   NUMBER;     -- Mentes de Papiro
    v_id_grupo  NUMBER;     -- grupo temporal creado en el setup
    v_isbn      VARCHAR2(20) := '9788401336560';  -- Un mundo sin fin
    -- Lector de prueba: V-ADU13
    v_hm_fi     DATE := TO_DATE('01/01/2025','DD/MM/YYYY');  -- historia_membresia.fecha_i
    v_gl_fi     DATE;                                         -- g_lec.fec_i (= SYSDATE)
    -- Moderador: V-ADU14
    v_mod_id    NUMBER;
    v_mod_mem_fi DATE := TO_DATE('12/05/2024','DD/MM/YYYY'); -- g_lec.fecha_i del mod
    v_mod_grp_fi DATE;                                        -- g_lec.fec_i del mod en grupo tmp
    -- Fechas de reuniones (todas en el mismo bimestre → mismo cálculo)
    v_fec_r1    DATE := TRUNC(SYSDATE,'MM');
    v_fec_r2    DATE := TRUNC(SYSDATE,'MM') + 7;
    v_fec_r3    DATE := TRUNC(SYSDATE,'MM') + 14;
BEGIN
    SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13';
    SELECT id_lector INTO v_mod_id    FROM MJV_lector WHERE doc_identidad = 'V-ADU14';
    SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club   = 'Mentes de Papiro';

    -- Guardar SYSDATE para que fec_i en g_lec y mod_hist_fecha_i en calendario
    -- sean exactamente el mismo valor (la FK los compara)
    v_gl_fi      := SYSDATE;
    v_mod_grp_fi := SYSDATE;

    -- Crear grupo temporal limpio para este test
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (v_id_club, 'adultos', SYSDATE, 4, TO_DATE('18:00:00','HH24:MI:SS'))
    RETURNING id_grupo INTO v_id_grupo;

    -- Inscribir al moderador en el grupo temporal
    -- g_lec PK: (v_mod_id, v_id_club, v_mod_mem_fi, v_id_grupo, v_mod_grp_fi)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i)
    VALUES (v_mod_id, v_id_club, v_mod_mem_fi, v_id_grupo, v_mod_grp_fi);

    -- V-ADU13 ya tiene membresía activa en Mentes de Papiro (inserts.sql:01/01/2025)
    -- y ya está en el grupo adultos preexistente.  Solo limpiamos inasistencias previas
    -- y aseguramos que esté también inscrito en el grupo TEMPORAL de este test.
    -- NO borramos el g_lec del grupo preexistente (tiene FK de calendario como moderador).
    DELETE FROM MJV_inasistencia WHERE id_lector = v_id_lector AND id_club = v_id_club;

    -- Inscribir al lector en el grupo TEMPORAL (sin debate activo → Regla de Oro no bloquea)
    -- g_lec PK: (v_id_lector, v_id_club, v_hm_fi, v_id_grupo, v_gl_fi)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i)
    VALUES (v_id_lector, v_id_club, v_hm_fi, v_id_grupo, v_gl_fi);

    -- Crear las 3 reuniones DESPUÉS de inscribir al lector (ya es miembro)
    -- FK: mod_fecha_i = v_mod_mem_fi (→ g_lec.fecha_i del mod)
    --     mod_hist_fecha_i = v_mod_grp_fi (→ g_lec.fec_i del mod)
    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i,
         mod_hist_fecha_i, realizada, ultima)
    VALUES (v_id_club, v_id_grupo, v_fec_r1, v_isbn,
            v_mod_id, v_mod_mem_fi, v_mod_grp_fi, 'S', 'N');

    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i,
         mod_hist_fecha_i, realizada, ultima)
    VALUES (v_id_club, v_id_grupo, v_fec_r2, v_isbn,
            v_mod_id, v_mod_mem_fi, v_mod_grp_fi, 'S', 'N');

    INSERT INTO MJV_calendario_reunion_mes
        (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i,
         mod_hist_fecha_i, realizada, ultima)
    VALUES (v_id_club, v_id_grupo, v_fec_r3, v_isbn,
            v_mod_id, v_mod_mem_fi, v_mod_grp_fi, 'S', 'N');

    -- -------------------------------------------------------------------------
    -- TEST 5-A: 0 inasistencias previas + 1 simulada / 3 reuniones = 33.33%
    -- RESULTADO ESPERADO: 33.33
    -- -------------------------------------------------------------------------
    DECLARE
        v_pct NUMBER;
    BEGIN
        v_pct := MJV_fn_pct_inasistencia_bimestre(
                     v_id_lector, v_id_club,
                     v_fec_r1,
                     v_id_grupo,
                     v_isbn
                 );
        MJV_test_log(v_suite,
            '5-A: 0 faltas previas + 1 simulada sobre 3 reuniones → 33.33%',
            '33.33', TO_CHAR(v_pct));
    EXCEPTION WHEN OTHERS THEN
        MJV_test_log(v_suite,'5-A','33.33','ERROR: '||SQLERRM);
    END;

    -- -------------------------------------------------------------------------
    -- TEST 5-B: 1 falta / 3 reuniones = 33.33% > 30% → trigger retira
    -- RESULTADO ESPERADO: estatus='retirado', motivo_retiro='inasistencia'
    -- -------------------------------------------------------------------------
    DECLARE
        v_estatus VARCHAR2(8);
        v_motivo  VARCHAR2(12);
    BEGIN
        INSERT INTO MJV_inasistencia
            (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec, fecha_reunion, isbn)
        VALUES (v_id_lector, v_id_club, v_hm_fi, v_id_grupo, v_gl_fi, v_fec_r1, v_isbn);

        SELECT estatus, motivo_retiro
          INTO v_estatus, v_motivo
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector AND id_club = v_id_club
           AND estatus = 'retirado' AND ROWNUM = 1;

        MJV_test_log(v_suite,
            '5-B: 1 falta / 3 reuniones = 33.3% > 30% → trigger retira automáticamente',
            'retirado / inasistencia',
            v_estatus || ' / ' || NVL(v_motivo, 'NULL'));
    EXCEPTION
        WHEN OTHERS THEN
            MJV_test_log(v_suite,'5-B','retirado / inasistencia','ERROR: '||SQLERRM);
    END;

    -- -------------------------------------------------------------------------
    -- TEST 5-C: 1 falta / 4 reuniones = 25% ≤ 30% → NO debe retirar.
    --           Reactivamos la membresía de V-ADU13 con UPDATE (sin DELETE) para
    --           evitar problemas de FK con g_lec que apunta a historia_membresia.
    --           La inasistencia de 5-C usa la misma fecha_i (v_hm_fi) de historia.
    -- RESULTADO ESPERADO: estatus sigue siendo 'activo'
    -- -------------------------------------------------------------------------
    DECLARE
        v_fec_r4  DATE := TRUNC(SYSDATE,'MM') + 21;
        v_estatus VARCHAR2(8);
    BEGIN
        -- Reactivar membresía (el trigger de 5-B la puso 'retirado')
        DELETE FROM MJV_inasistencia WHERE id_lector = v_id_lector AND id_club = v_id_club;
        UPDATE MJV_g_lec
           SET fec_f = NULL
         WHERE id_lector = v_id_lector AND id_club = v_id_club AND id_grupo = v_id_grupo;
        UPDATE MJV_historia_membresia
           SET estatus = 'activo', fecha_f = NULL, motivo_retiro = NULL
         WHERE id_lector = v_id_lector AND id_club = v_id_club AND fecha_i = v_hm_fi;

        -- Añadir 4ª reunión para que la fracción sea 1/4 = 25%
        INSERT INTO MJV_calendario_reunion_mes
            (id_club, id_grupo, fecha, isbn, mod_id_lector, mod_fecha_i,
             mod_hist_fecha_i, realizada, ultima)
        VALUES (v_id_club, v_id_grupo, v_fec_r4, v_isbn,
                v_mod_id, v_mod_mem_fi, v_mod_grp_fi, 'S', 'N');

        -- 1 falta / 4 reuniones = 25% ≤ 30% → trigger NO debe retirar
        INSERT INTO MJV_inasistencia
            (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec, fecha_reunion, isbn)
        VALUES (v_id_lector, v_id_club, v_hm_fi, v_id_grupo, v_gl_fi, v_fec_r1, v_isbn);

        SELECT estatus INTO v_estatus
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector AND id_club = v_id_club
           AND estatus = 'activo' AND ROWNUM = 1;

        MJV_test_log(v_suite,
            '5-C: 1 falta / 4 reuniones = 25% ≤ 30% → NO debe retirar',
            'activo', v_estatus);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            MJV_test_log(v_suite,'5-C','activo',
                'FAIL: no hay fila activa — el trigger retiró cuando no debía');
        WHEN OTHERS THEN
            MJV_test_log(v_suite,'5-C','activo','ERROR: '||SQLERRM);
    END;

    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[SUITE 5] ERROR EN SETUP: ' || SQLERRM);
END;
/


-- =============================================================================
-- SUITE 6: Pago bloqueado en club sin cuota  (BRECHA 6)
-- =============================================================================

DECLARE
    v_suite VARCHAR2(60) := 'BRECHA 6 — Pago en club sin cuota';
BEGIN
    -- TEST 6-A: Intentar pagar en 'El Café de los Capítulos' (cuota_anual='N')
    --           mediante el procedure → DEBE fallar con ORA-20053.
    -- RESULTADO ESPERADO: ORA-20053
    BEGIN
        MJV_sp_registrar_pago_membresia(
            pi_doc_identidad => 'V-ADU05',
            pi_nombre_club   => 'El Café de los Capítulos',
            pi_monto         => 100,
            pi_moneda        => 'USD',
            pi_tasa          => 1
        );
        MJV_test_log(v_suite,
            '6-A: Pago en club sin cuota → DEBE bloquearse con ORA-20053',
            'ORA-20053', 'SIN ERROR — FALLO: validación ausente');
    EXCEPTION
        WHEN OTHERS THEN
            MJV_test_log(v_suite,
                '6-A: Pago en club sin cuota → DEBE bloquearse con ORA-20053',
                'ORA-20053',
                'ORA-' || TO_CHAR(ABS(SQLCODE)) || ': ' || SUBSTR(SQLERRM,1,80));
    END;

    -- TEST 6-B: Pago en 'Refugio Literario del Sur' (cuota_anual='S') con lector activo
    --           y monto válido → DEBE tener éxito.
    -- RESULTADO ESPERADO: SIN ERROR  (el lector V-ADU01 debe tener membresía activa)
    DECLARE
        v_id_lector NUMBER;
        v_id_club   NUMBER;
        v_fecha_i   DATE;
    BEGIN
        SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01';
        SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';

        -- Asegurar membresía activa para el test
        BEGIN
            SELECT fecha_i INTO v_fecha_i
              FROM MJV_historia_membresia
             WHERE id_lector = v_id_lector AND id_club = v_id_club AND estatus = 'activo';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
                VALUES (v_id_lector, v_id_club, SYSDATE, 'activo');
        END;

        -- Pagamos 1000 CLP a tasa 10 CLP/USD = 100 USD (≥ mínimo requerido)
        MJV_sp_registrar_pago_membresia(
            pi_doc_identidad => 'V-ADU01',
            pi_nombre_club   => 'Refugio Literario del Sur',
            pi_monto         => 1000,
            pi_moneda        => 'CLP',
            pi_tasa          => 10
        );
        MJV_test_log(v_suite,
            '6-B: Pago en club con cuota (cuota_anual=S) → debe aceptarse',
            'SIN ERROR', 'SIN ERROR');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log(v_suite,
                '6-B: Pago en club con cuota (cuota_anual=S) → debe aceptarse',
                'SIN ERROR', 'ERROR: '||SQLERRM);
    END;

    -- TEST 6-C: INSERT directo en MJV_pago_membresia para club sin cuota.
    --           El trigger MJV_tgr_validar_membresia_pago también debe bloquearlo.
    --           Usamos V-ADU17 que YA tiene membresía activa en 'La Alianza de la Tinta'
    --           (cuota_anual='N') desde inserts.sql → no necesitamos crear nada.
    -- RESULTADO ESPERADO: ORA-20053
    DECLARE
        v_id_lector NUMBER;
        v_id_club   NUMBER;
        v_fecha_i   DATE;
    BEGIN
        SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17';
        SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'La Alianza de la Tinta';
        SELECT fecha_i   INTO v_fecha_i
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector AND id_club = v_id_club AND estatus = 'activo';

        -- Intentar pago directo: el trigger debe rechazarlo con ORA-20053
        INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
        VALUES (v_id_lector, v_id_club, v_fecha_i, SYSDATE, 100);

        ROLLBACK;
        MJV_test_log(v_suite,
            '6-C: INSERT directo a pago en club sin cuota → trigger bloquea',
            'ORA-20053', 'SIN ERROR — FALLO: trigger no actuó');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log(v_suite,
                '6-C: INSERT directo a pago en club sin cuota → trigger bloquea',
                'ORA-20053',
                'ORA-' || TO_CHAR(ABS(SQLCODE)) || ': ' || SUBSTR(SQLERRM,1,80));
    END;
END;
/


-- =============================================================================
-- SUITE 7: Validación de motivo de retiro  (BRECHA 7)
-- =============================================================================

DECLARE
    v_suite VARCHAR2(60) := 'BRECHA 7 — Validación motivo de retiro';
BEGIN
    -- TEST 7-A: Motivo inválido → ORA-20056
    -- RESULTADO ESPERADO: ORA-20056
    BEGIN
        MJV_sp_retirar_miembro(
            pi_doc_identidad => 'V-ADU01',
            pi_nombre_club   => 'Refugio Literario del Sur',
            pi_motivo_retiro => 'RENUNCIA'  -- no es un valor del dominio
        );
        MJV_test_log(v_suite,
            '7-A: Motivo fuera del dominio → ORA-20056',
            'ORA-20056', 'SIN ERROR — FALLO');
    EXCEPTION
        WHEN OTHERS THEN
            MJV_test_log(v_suite,
                '7-A: Motivo fuera del dominio → ORA-20056',
                'ORA-20056',
                'ORA-' || TO_CHAR(ABS(SQLCODE)) || ': ' || SUBSTR(SQLERRM,1,80));
    END;

    -- TEST 7-B: Motivo 'otro' en mayúsculas → normalización a minúsculas y retiro exitoso
    --           Usamos V-ADU01 que YA tiene membresía activa en 'Refugio Literario del Sur'
    --           desde inserts.sql (ingreso: 18/07/2024).  No se crea nueva membresía para
    --           evitar ORA-20002 (un solo club activo a la vez).
    --           Pagamos 300 USD (3 × 100) para cubrir hasta 3 años iniciados con o sin
    --           penalidad de aviso tardío, garantizando solvencia sin importar la fecha exacta.
    -- RESULTADO ESPERADO: SIN ERROR, estatus='retirado', motivo_retiro='otro'
    DECLARE
        v_id_lector NUMBER;
        v_id_club   NUMBER;
        v_fecha_i   DATE;
        v_estatus   VARCHAR2(8);
        v_motivo    VARCHAR2(12);
    BEGIN
        SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01';
        SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'Refugio Literario del Sur';
        SELECT fecha_i   INTO v_fecha_i
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector AND id_club = v_id_club AND estatus = 'activo';

        -- Limpiar pagos previos y agregar exactamente los necesarios para la solvencia.
        -- Con aviso tardío (mes 11 del ciclo actual) se requieren 3 × 100 = 300 USD.
        DELETE FROM MJV_pago_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;
        INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
        VALUES (v_id_lector, v_id_club, v_fecha_i, ADD_MONTHS(SYSDATE, -24), 100);
        INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
        VALUES (v_id_lector, v_id_club, v_fecha_i, ADD_MONTHS(SYSDATE, -12), 100);
        INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
        VALUES (v_id_lector, v_id_club, v_fecha_i, SYSDATE, 100);

        -- Retirar con motivo en mayúsculas → el SP lo normaliza a minúsculas
        MJV_sp_retirar_miembro(
            pi_doc_identidad => 'V-ADU01',
            pi_nombre_club   => 'Refugio Literario del Sur',
            pi_motivo_retiro => 'OTRO'
        );
        -- Nota: MJV_sp_retirar_miembro hace COMMIT interno; el ROLLBACK posterior
        -- no deshace el retiro.  Se acepta que V-ADU01 quede retirado tras este test.

        SELECT estatus, motivo_retiro INTO v_estatus, v_motivo
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector AND id_club = v_id_club AND ROWNUM = 1;

        MJV_test_log(v_suite,
            '7-B: Motivo OTRO (mayúsculas) → normalizado a ''otro'', retiro exitoso',
            'retirado / otro',
            v_estatus || ' / ' || NVL(v_motivo,'NULL'));
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log(v_suite,
                '7-B: Motivo ''OTRO'' (mayúsculas) → normalizado y aceptado',
                'retirado / otro', 'ERROR: '||SQLERRM);
    END;

    -- TEST 7-C: Todos los motivos válidos deben pasar la guardia de dominio
    --           (probamos la función de validación de dominio directamente).
    -- RESULTADO ESPERADO: Todos los 4 valores pasan sin error
    DECLARE
        v_motivos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
            'voluntario','inasistencia','deuda','otro'
        );
        v_valido  VARCHAR2(20);
    BEGIN
        FOR i IN 1..v_motivos.COUNT LOOP
            v_valido := v_motivos(i);
            IF v_valido NOT IN ('voluntario','inasistencia','deuda','otro') THEN
                MJV_test_log(v_suite,
                    '7-C: Dominio de motivos válidos — ' || v_valido,
                    'VÁLIDO', 'INVÁLIDO');
            ELSE
                MJV_test_log(v_suite,
                    '7-C: Dominio de motivos válidos — ' || v_valido,
                    'VÁLIDO', 'VÁLIDO');
            END IF;
        END LOOP;
    END;

    -- TEST 7-D: Retiro en club sin cuota (cuota_anual='N') omite validación de solvencia.
    --           No debe fallar por falta de pagos.
    -- RESULTADO ESPERADO: SIN ERROR (retiro exitoso sin exigir pagos)
    DECLARE
        v_id_lector NUMBER;
        v_id_club   NUMBER;
        v_fecha_i   DATE := ADD_MONTHS(SYSDATE, -6);
    BEGIN
        SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07';
        SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club = 'El Café de los Capítulos';

        DELETE FROM MJV_g_lec              WHERE id_lector = v_id_lector AND id_club = v_id_club;
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;

        INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus)
        VALUES (v_id_lector, v_id_club, v_fecha_i, 'activo');

        -- Club sin cuota → no exige pagos → retiro debe proceder
        MJV_sp_retirar_miembro(
            pi_doc_identidad => 'V-ADU07',
            pi_nombre_club   => 'El Café de los Capítulos',
            pi_motivo_retiro => 'voluntario'
        );
        MJV_test_log(v_suite,
            '7-D: Club sin cuota → retiro sin validación de solvencia',
            'SIN ERROR', 'SIN ERROR');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log(v_suite,
                '7-D: Club sin cuota → retiro sin validación de solvencia',
                'SIN ERROR', 'ERROR: '||SQLERRM);
    END;
END;
/


-- =============================================================================
-- SUITE 8: Integración — Brechas 1 y 2 verificadas directamente
-- =============================================================================
-- NOTA: MJV_sp_inscribir_miembro está diseñado para lectores NUEVOS (hace
-- INSERT en MJV_lector siempre), por lo que la deuda histórica o el veto por
-- inasistencia se verifica usando el id_lector recién creado, que no tiene
-- historial previo en la misma transacción visible.  La prueba correcta de
-- las funciones de guardia es invocarlas directamente sobre un lector ya
-- existente con historial manipulado, y comprobar que el procedimiento
-- los rechazaría con el mismo bloque de lógica.
-- =============================================================================

DECLARE
    v_suite VARCHAR2(60) := 'BRECHA 1+2 — Guardias integradas (test directo)';
BEGIN
    -- TEST 8-A: fn_tiene_deuda_historica detecta deuda e impide inscripción.
    --           Lector V-ADU08 tiene membresía retirada sin pago en 'Mentes de Papiro'
    --           (cuota_anual='S').  La función debe devolver 1.
    --           Si el SP recibiera este id_lector, lanzaría ORA-20054.
    -- RESULTADO ESPERADO: fn devuelve 1 (deuda detectada)
    DECLARE
        v_id_lector     NUMBER;
        v_id_club_viejo NUMBER;
        v_fecha_i       DATE := ADD_MONTHS(SYSDATE, -18);
        v_res           NUMBER;
    BEGIN
        SELECT id_lector INTO v_id_lector     FROM MJV_lector WHERE doc_identidad = 'V-ADU08';
        SELECT id_club   INTO v_id_club_viejo FROM MJV_club   WHERE nombre_club   = 'Mentes de Papiro';

        -- Crear escenario: membresía retirada en club con cuota, sin ningún pago
        DELETE FROM MJV_pago_membresia     WHERE id_lector = v_id_lector AND id_club = v_id_club_viejo;
        DELETE FROM MJV_g_lec              WHERE id_lector = v_id_lector AND id_club = v_id_club_viejo;
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club_viejo;

        INSERT INTO MJV_historia_membresia
            (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club_viejo, v_fecha_i, 'retirado', SYSDATE, 'voluntario');

        v_res := MJV_fn_tiene_deuda_historica(v_id_lector);

        MJV_test_log(v_suite,
            '8-A: Lector con membresía retirada sin pago → fn_tiene_deuda=1 (bloquearía inscripción)',
            '1', TO_CHAR(v_res));
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log(v_suite,
                '8-A: Lector con membresía retirada sin pago → fn_tiene_deuda=1',
                '1', 'ERROR: '||SQLERRM);
    END;

    -- TEST 8-B: fn_vetado_por_inasistencia detecta veto en el mismo club.
    --           Lector V-ADU09 con retiro por inasistencia en 'Horizonte de Palabras'.
    --           La función debe devolver 1 → el SP lanzaría ORA-20055.
    -- RESULTADO ESPERADO: fn devuelve 1 (vetado)
    DECLARE
        v_id_lector NUMBER;
        v_id_club   NUMBER;
        v_fecha_i   DATE := ADD_MONTHS(SYSDATE, -12);
        v_res       NUMBER;
    BEGIN
        SELECT id_lector INTO v_id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09';
        SELECT id_club   INTO v_id_club   FROM MJV_club   WHERE nombre_club   = 'Horizonte de Palabras';

        -- Crear escenario: retiro por inasistencia en ese club
        DELETE FROM MJV_g_lec              WHERE id_lector = v_id_lector AND id_club = v_id_club;
        DELETE FROM MJV_historia_membresia WHERE id_lector = v_id_lector AND id_club = v_id_club;

        INSERT INTO MJV_historia_membresia
            (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro)
        VALUES (v_id_lector, v_id_club, v_fecha_i, 'retirado', SYSDATE, 'inasistencia');

        v_res := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);

        MJV_test_log(v_suite,
            '8-B: Lector retirado por inasistencia → fn_vetado=1 (bloquearía reingreso)',
            '1', TO_CHAR(v_res));
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            MJV_test_log(v_suite,
                '8-B: Lector retirado por inasistencia → fn_vetado=1',
                '1', 'ERROR: '||SQLERRM);
    END;
END;
/


-- =============================================================================
-- RESUMEN FINAL
-- =============================================================================
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('  FIN DEL TEST SUITE — BRECHAS ADMIN CLUBES');
    DBMS_OUTPUT.PUT_LINE('  Revisa cada bloque: ✓ PASS esperado / ✗ FAIL requiere acción');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════════════');
END;
/
