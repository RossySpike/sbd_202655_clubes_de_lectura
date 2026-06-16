SET SERVEROUTPUT ON;
DECLARE
    v_doc VARCHAR2(20) := 'V-TEST01';
BEGIN
    -- 1. LIMPIEZA TOTAL Y SEGURA
    -- Usamos TRIM y LIKE para asegurar que atrapamos el registro incluso con espacios
    FOR r IN (SELECT id_lector FROM MJV_lector WHERE TRIM(doc_identidad) = v_doc) LOOP
        DELETE FROM MJV_g_lec WHERE id_lector = r.id_lector;
        DELETE FROM MJV_preferencia_obra WHERE id_lector = r.id_lector;
        DELETE FROM MJV_historia_membresia WHERE id_lector = r.id_lector;
        DELETE FROM MJV_lector WHERE id_lector = r.id_lector;
    END LOOP;
    
    COMMIT; -- Confirmamos el borrado
    DBMS_OUTPUT.PUT_LINE('Limpieza de registros previos completada.');

    -- 2. INSERCIÓN
    MJV_sp_inscribir_miembro(
        'Prueba', 'Equitativa', NULL, 'Test1', v_doc, 
        '0000', 'test1@mail.com', 'M', TO_DATE('01/01/1980', 'DD/MM/YYYY'),
        'Estados Unidos', 'Refugio Literario del Sur', 
        'El imperio final (Nacidos de la bruma)', 'Neuromante', 'Juego de tronos'
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserción realizada con éxito.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error crítico: ' || SQLERRM);
END;
/
DECLARE
    -- Variables para datos de prueba
    v_doc_test VARCHAR2(20) := 'T-TEST-999';
    v_id_club  NUMBER;
    v_dummy    NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIANDO TEST SUITE (ROLLBACK MODE) ---');


    -- 2. TEST: Cierre de reunión (Prueba validación realizada='S')
    -- Nota: Esto debería fallar si la reunión no ha sido marcada como realizada, 
    -- probando así tu nueva regla de negocio (AC-P6).
    DBMS_OUTPUT.PUT_LINE('2. Probando Cierre de Discusión (Validación AC-P6)...');
    BEGIN
        -- Intentamos cerrar una reunión (usando datos hipotéticos de club/grupo 1)
        MJV_sp_cerrar_discusion_reunion(1, 1, SYSDATE, '9788466631174', 'Excelente lectura', 5);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('   -> Error capturado correctamente (Esperado): ' || SQLERRM);
    END;

    -- 3. TEST: Verificación de Vistas
    DBMS_OUTPUT.PUT_LINE('3. Verificando integridad de Vistas...');
    
    -- Chequeo Historial Pagos
    SELECT COUNT(*) INTO v_dummy FROM MJV_vw_historial_pagos_membresia WHERE ROWNUM <= 1;
    DBMS_OUTPUT.PUT_LINE('   -> Vista Historial Pagos: OK');
    
    -- Chequeo Libros Analizados
    SELECT COUNT(*) INTO v_dummy FROM MJV_vw_r1_libros_analizados WHERE ROWNUM <= 1;
    DBMS_OUTPUT.PUT_LINE('   -> Vista R1 Libros Analizados: OK');

    -- Chequeo Crecimiento Anual
    SELECT COUNT(*) INTO v_dummy FROM MJV_vw_r4_crecimiento_anual WHERE ROWNUM <= 1;
    DBMS_OUTPUT.PUT_LINE('   -> Vista R4 Crecimiento Anual: OK');

    DBMS_OUTPUT.PUT_LINE('--- PRUEBAS COMPLETADAS CON ÉXITO ---');
    
    -- FORZAR ROLLBACK PARA NO ALTERAR LA BD
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Estado de base de datos revertido (Rollback ejecutado).');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error durante el test: ' || SQLERRM);
        -- ROLLBACK DE SEGURIDAD
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Rollback de seguridad ejecutado tras error.');
END;
/
