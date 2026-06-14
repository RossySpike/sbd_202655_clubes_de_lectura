-- =============================================================================
-- *** NO EJECUTAR — BORRADOR HISTÓRICO ***
-- Este archivo es una versión anterior absorbida por complemento_script_final.sql.
-- El SP MJV_sp_agendar_reunion_mes vive en complemento_script_final.sql (versión final).
-- Ejecutar este archivo después del complemento sobreescribiría la versión correcta.
-- =============================================================================
-- ADMINISTRACIÓN DE REUNIONES - ACTIVIDAD 1 (CORREGIDO)
-- Procedimiento para generar el calendario de reuniones mensuales y asignar
-- un moderador al evento con todas las reglas de negocio.
-- =============================================================================
CREATE OR REPLACE PROCEDURE MJV_sp_agendar_reunion_mes (
    pi_id_club        IN NUMBER,
    pi_id_grupo       IN NUMBER,
    pi_isbn           IN VARCHAR2,
    pi_fecha_reunion  IN DATE,
    pi_hora_inicio    IN DATE, -- Se recibe tipo DATE para extraer la hora de manera exacta
    pi_mod_id_lector  IN NUMBER
) IS
    v_tipo_grupo          VARCHAR2(10);
    v_hora_grupo          DATE;
    v_mod_fecha_i         DATE;
    v_mod_hist_fecha_i    DATE;
    v_conflicto_horario   NUMBER;
    v_existe_reunion      NUMBER;
    v_mod_adulto_activo   NUMBER;
BEGIN
    -- 1. Validar grupo y obtener la hora definida para el grupo
    SELECT tipo_grupo, hora_reunion
      INTO v_tipo_grupo, v_hora_grupo
      FROM MJV_grupo
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo;

    -- 2. La hora ingresada debe coincidir con la hora del grupo.
    IF TO_CHAR(pi_hora_inicio, 'HH24:MI') != TO_CHAR(v_hora_grupo, 'HH24:MI') THEN
        RAISE_APPLICATION_ERROR(
            -20060,
            'La hora de inicio (' || TO_CHAR(pi_hora_inicio, 'HH24:MI') || ') debe coincidir ' ||
            'con la hora programada del grupo (' || TO_CHAR(v_hora_grupo, 'HH24:MI') || ').'
        );
    END IF;

    -- 3. Validaciones de tiempo estrictas de la actividad
    IF v_tipo_grupo = 'niños' AND TO_CHAR(pi_hora_inicio, 'HH24:MI') > '17:00' THEN
        RAISE_APPLICATION_ERROR(
            -20061,
            'Error: Las reuniones de niños calculadas no pueden terminar después de las 7:00 pm (Máx inicio 17:00).'
        );
    END IF;

    IF TO_CHAR(pi_hora_inicio, 'HH24:MI') > '19:00' THEN
        RAISE_APPLICATION_ERROR(
            -20062,
            'Error: Ninguna reunión en el sistema puede iniciar después de las 19:00.'
        );
    END IF;

    -- 4. Validar existencia del libro
    BEGIN
        SELECT 1
          INTO v_existe_reunion
          FROM MJV_libro
         WHERE isbn = TRIM(pi_isbn);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20063,
                'Error: El libro con ISBN ' || pi_isbn || ' no está registrado.'
            );
    END;

    -- 5. Validar moderador activo en el club y obtener su registro de g_lec actual
    BEGIN
        SELECT gl.fecha_i, gl.fec_i
          INTO v_mod_fecha_i, v_mod_hist_fecha_i
          FROM MJV_g_lec gl
         WHERE gl.id_lector = pi_mod_id_lector
           AND gl.id_club   = pi_id_club
           AND gl.fec_f     IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20064,
                'Error: El moderador con ID ' || pi_mod_id_lector || ' no es miembro activo de este club.'
            );
    END;

    -- [BRECHA SOLUCIONADA] 5b. Si el grupo es de niños, verificar que el moderador pertenezca a un grupo de adultos
    IF v_tipo_grupo = 'niños' THEN
        SELECT COUNT(*)
          INTO v_mod_adulto_activo
          FROM MJV_g_lec gl
          JOIN MJV_grupo g ON gl.id_grupo = g.id_grupo AND gl.id_club = g.id_club
         WHERE gl.id_lector = pi_mod_id_lector
           AND gl.id_club   = pi_id_club
           AND g.tipo_grupo = 'adultos'
           AND gl.fec_f     IS NULL;

        IF v_mod_adulto_activo = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20031,
                'Error de Negocio: Para reuniones de niños, el moderador debe pertenecer obligatoriamente a un grupo de adultos del mismo club.'
            );
        END IF;
    END IF;

    -- 6. Validar disponibilidad horaria del moderador (No puede estar en 2 grupos a la misma hora el mismo día)
    SELECT COUNT(*)
      INTO v_conflicto_horario
      FROM MJV_calendario_reunion_mes crm
      JOIN MJV_grupo g ON g.id_club = crm.id_club AND g.id_grupo = crm.id_grupo
     WHERE crm.mod_id_lector = pi_mod_id_lector
       AND crm.id_club = pi_id_club
       AND crm.fecha = TRUNC(pi_fecha_reunion)
       AND TO_CHAR(g.hora_reunion, 'HH24:MI') = TO_CHAR(pi_hora_inicio, 'HH24:MI')
       AND NOT (crm.id_grupo = pi_id_grupo AND crm.isbn = TRIM(pi_isbn));

    IF v_conflicto_horario > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20065,
            'Error: El moderador ya tiene una reunión asignada en otro grupo ese mismo día y hora.'
        );
    END IF;

    -- 7. Validar que no exista la reunión exactamente repetida
    SELECT COUNT(*)
      INTO v_existe_reunion
      FROM MJV_calendario_reunion_mes
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo
       AND fecha = TRUNC(pi_fecha_reunion)
       AND isbn = TRIM(pi_isbn);

    IF v_existe_reunion > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20066,
            'Error: Ya existe una reunión registrada para este mismo grupo, libro y fecha.'
        );
    END IF;

    -- 8. Registrar reunión en el calendario mensual
    INSERT INTO MJV_calendario_reunion_mes (
        id_club, id_grupo, fecha, isbn,
        mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
        realizada, ultima, conclusiones, valoracion
    ) VALUES (
        pi_id_club, pi_id_grupo, TRUNC(pi_fecha_reunion), TRIM(pi_isbn),
        pi_mod_id_lector, v_mod_fecha_i, v_mod_hist_fecha_i,
        'N', 'N', NULL, NULL
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Reunión agendada exitosamente para el club ' || pi_id_club || ', grupo ' || pi_id_grupo
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_agendar_reunion_mes;
/