-- =============================================================================
-- ADMINISTRACIÓN DE REUNIONES - ACTIVIDAD 2 (CORREGIDO)
-- Registro de asistencia/inasistencia y penalización del 30% calculada de 
-- =============================================================================
-- =============================================================================
-- ADMINISTRACIÓN DE REUNIONES - ACTIVIDAD 2
-- Registro de asistencia/inasistencia de un miembro en una reunión y penalización
-- automática cuando el 30% de las reuniones de un bimestre son faltas.
-- =============================================================================
CREATE OR REPLACE PROCEDURE MJV_sp_registrar_asistencia_miembro (
    pi_id_lector     IN NUMBER,
    pi_id_club       IN NUMBER,
    pi_id_grupo      IN NUMBER,
    pi_fecha_reunion IN DATE,
    pi_isbn          IN VARCHAR2,
    pi_asistio       IN CHAR
) IS
    v_asistio_norm       CHAR(1);
    v_fecha_i            DATE;
    v_fec_i_g_lec        DATE;
    v_realizada          CHAR(1);
    v_reunion_existe     NUMBER;
    
    v_mes                NUMBER;
    v_anio               NUMBER;
    v_bimestre           NUMBER;
    v_pct_inasistencias  NUMBER;
BEGIN
    v_asistio_norm := UPPER(TRIM(pi_asistio));
    IF v_asistio_norm NOT IN ('S', 'N') THEN
        RAISE_APPLICATION_ERROR(-20070, 'Error: el valor de asistencia debe ser S o N.');
    END IF;

    -- 1. Validar vinculación activa en el grupo de lectura
    BEGIN
        SELECT gl.fecha_i, gl.fec_i
          INTO v_fecha_i, v_fec_i_g_lec
          FROM MJV_g_lec gl
         WHERE gl.id_lector = pi_id_lector
           AND gl.id_club   = pi_id_club
           AND gl.id_grupo  = pi_id_grupo
           AND gl.fec_f     IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20074, 'Error: El lector no posee una inscripción activa aquí.');
    END;

    -- 2. Validar que la reunión exista programada
    SELECT COUNT(*), MAX(realizada)
      INTO v_reunion_existe, v_realizada
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.id_club = pi_id_club
       AND crm.id_grupo = pi_id_grupo
       AND crm.fecha = TRUNC(pi_fecha_reunion)
       AND crm.isbn = TRIM(pi_isbn);

    IF v_reunion_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20071, 'Error: No existe la reunión especificada.');
    END IF;

    -- Si es el primer listado, marcar la sesión como realizada
    IF v_realizada = 'N' THEN
        UPDATE MJV_calendario_reunion_mes
           SET realizada = 'S'
         WHERE id_club = pi_id_club AND id_grupo = pi_id_grupo AND fecha = TRUNC(pi_fecha_reunion) AND isbn = TRIM(pi_isbn);
    END IF;

    -- 3. Registrar falta si corresponde
    IF v_asistio_norm = 'N' THEN
        SELECT COUNT(*) INTO v_reunion_existe FROM MJV_inasistencia i
         WHERE i.id_lector = pi_id_lector AND i.id_club = pi_id_club AND i.id_grupo = pi_id_grupo AND i.fecha_reunion = TRUNC(pi_fecha_reunion) AND i.isbn = TRIM(pi_isbn);

        IF v_reunion_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20072, 'Error: Ya tiene inasistencia registrada.');
        END IF;

        INSERT INTO MJV_inasistencia (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec, fecha_reunion, isbn)
        VALUES (pi_id_lector, pi_id_club, v_fecha_i, pi_id_grupo, v_fec_i_g_lec, TRUNC(pi_fecha_reunion), TRIM(pi_isbn));
    END IF;

    -- 4. CONTROL DE EXPULSIÓN AUTOMÁTICA CON LA FUNCIÓN ADAPTADA
    v_mes  := TO_NUMBER(TO_CHAR(pi_fecha_reunion, 'MM'));
    v_anio := TO_NUMBER(TO_CHAR(pi_fecha_reunion, 'YYYY'));
    v_bimestre := CEIL(v_mes / 2);

    -- CORRECCIÓN MATEMÁTICA: Convertimos el % de asistencia de tu función en % de inasistencia real
    v_pct_inasistencias := 100 - MJV_participacion_bimestre_miembro(pi_id_lector, pi_id_club, v_bimestre, v_anio);

    -- EVALUACIÓN DIRECTA DEL 30% REQUERIDO POR EL ENUNCIADO
    IF v_pct_inasistencias >= 30 THEN
        -- Desvincular de los grupos de lectura actuales
        UPDATE MJV_g_lec SET fec_f = SYSDATE WHERE id_lector = pi_id_lector AND id_club = pi_id_club AND id_grupo = pi_id_grupo AND fec_f IS NULL;

        -- Registrar retiro en el historial de membresía del club
        UPDATE MJV_historia_membresia SET estatus = 'retirado', fecha_f = SYSDATE, motivo_retiro = 'inasistencia'
         WHERE id_lector = pi_id_lector AND id_club = pi_id_club AND estatus = 'activo';

        DBMS_OUTPUT.PUT_LINE('👉 RETIRO AUTOMÁTICO: Lector ID ' || pi_id_lector || ' expulsado por alcanzar el ' || ROUND(v_pct_inasistencias, 1) || '% de faltas en el bimestre.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Registro procesado. Porcentaje de inasistencias acumulado en el bimestre: ' || ROUND(v_pct_inasistencias, 1) || '%');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_registrar_asistencia_miembro;
/