-- =============================================================================
-- ADMINISTRACIÓN DE REUNIONES - ACTIVIDAD 1
-- Procedimiento para generar el calendario de reuniones mensuales y asignar
-- un moderador al evento.
-- =============================================================================
CREATE OR REPLACE PROCEDURE MJV_sp_agendar_reunion_mes (
    pi_id_club        IN NUMBER,
    pi_id_grupo       IN NUMBER,
    pi_isbn           IN VARCHAR2,
    pi_fecha_reunion  IN DATE,
    pi_hora_inicio    IN DATE,
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

    -- 3. Validaciones de tiempo
    IF v_tipo_grupo = 'niños' AND TO_CHAR(pi_hora_inicio, 'HH24:MI') > '17:00' THEN
        RAISE_APPLICATION_ERROR(
            -20061,
            'Error: Las reuniones de niños deben iniciar a más tardar a las 17:00.'
        );
    END IF;

    IF TO_CHAR(pi_hora_inicio, 'HH24:MI') > '19:00' THEN
        RAISE_APPLICATION_ERROR(
            -20062,
            'Error: Ninguna reunión puede iniciar después de las 19:00.'
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
                'Error: El moderador con ID ' || pi_mod_id_lector || ' no es miembro activo del club.'
            );
    END;

    -- 6. Validar disponibilidad horaria del moderador
    SELECT COUNT(*)
      INTO v_conflicto_horario
      FROM MJV_calendario_reunion_mes crm
      JOIN MJV_grupo g ON g.id_club = crm.id_club AND g.id_grupo = crm.id_grupo
     WHERE crm.mod_id_lector = pi_mod_id_lector
       AND crm.id_club = pi_id_club
       AND crm.fecha = TRUNC(pi_fecha_reunion)
       AND TO_CHAR(g.hora_reunion, 'HH24:MI') = TO_CHAR(pi_hora_inicio, 'HH24:MI')
       AND NOT (crm.id_grupo = pi_id_grupo AND crm.isbn = TRIM(pi_isbn) AND crm.fecha = TRUNC(pi_fecha_reunion));

    IF v_conflicto_horario > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20065,
            'Error: El moderador ya tiene una reunión programada ese mismo día y hora.'
        );
    END IF;

    -- 7. Validar que no exista la reunión repetida
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
            'Error: Ya existe una reunión programada para ese grupo, libro y fecha.'
        );
    END IF;

    -- 8. Registrar reunión en el calendario
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
        'Reunión agendada: club ' || pi_id_club || ', grupo ' || pi_id_grupo || ', libro ' || pi_isbn ||
        ', fecha ' || TO_CHAR(TRUNC(pi_fecha_reunion), 'DD/MM/YYYY') || ', moderador ' || pi_mod_id_lector
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_agendar_reunion_mes;
/

-- Ejemplo de ejecución:
/*
SET SERVEROUTPUT ON;
-- Nota: usar el ID numérico del lector para el moderador (id_lector), no su documento.
DECLARE
    v_id_club       NUMBER := &id_club;
    v_id_grupo      NUMBER := &id_grupo;
    v_isbn          VARCHAR2(20) := '&isbn_libro';
    v_fecha         DATE := TO_DATE('&fecha_reunion_DD/MM/YYYY', 'DD/MM/YYYY');
    v_hora_inicio   DATE := TO_DATE('&hora_inicio_HH24:MI', 'HH24:MI');
    v_id_moderador  NUMBER := &id_moderador;
BEGIN
    MJV_sp_agendar_reunion_mes(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_isbn          => v_isbn,
        pi_fecha_reunion => v_fecha,
        pi_hora_inicio   => v_hora_inicio,
        pi_mod_id_lector => v_id_moderador
    );
END;
*/
