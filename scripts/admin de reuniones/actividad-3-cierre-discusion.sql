-- =============================================================================
-- *** NO EJECUTAR — BORRADOR HISTÓRICO ***
-- Este archivo es una versión anterior absorbida por complemento_script_final.sql.
-- MJV_sp_cerrar_discusion_reunion vive en complemento_script_final.sql y luego
-- es reemplazado por brechas_admin_reuniones.sql (añade BRECHA B: check realizada='N').
-- Ejecutar este archivo después del complemento eliminaría la corrección de la BRECHA B.
-- =============================================================================
-- ADMINISTRACIÓN DE REUNIONES - ACTIVIDAD 3
-- Cierre de discusión de una reunión con conclusiones y valoración final.
-- =============================================================================
CREATE OR REPLACE PROCEDURE MJV_sp_cerrar_discusion_reunion (
    pi_id_club       IN NUMBER,
    pi_id_grupo      IN NUMBER,
    pi_fecha_reunion IN DATE,
    pi_isbn          IN VARCHAR2,
    pi_conclusiones  IN VARCHAR2,
    pi_valoracion    IN NUMBER
) IS
    v_reunion_realizada CHAR(1);
    v_ultima_actual     CHAR(1);
    v_conclusiones_norm VARCHAR2(4000);
    v_promedio_val      NUMBER;
BEGIN
    -- 1. NORMALIZACIÓN Y VALIDACIONES PREVIAS
    v_conclusiones_norm := TRIM(pi_conclusiones);

    IF v_conclusiones_norm IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20080,
            'Error: las conclusiones de cierre no pueden estar vacías.'
        );
    END IF;

    IF pi_valoracion NOT BETWEEN 1 AND 5 THEN
        RAISE_APPLICATION_ERROR(
            -20081,
            'Error: la valoración final debe ser un número entre 1 y 5.'
        );
    END IF;

    -- 2. VERIFICACIÓN DE EXISTENCIA Y ESTADO DE LA REUNIÓN (Usa la PK compuesta de grupo + club)
    SELECT realizada, ultima
      INTO v_reunion_realizada, v_ultima_actual
      FROM MJV_calendario_reunion_mes
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo
       AND fecha = TRUNC(pi_fecha_reunion)
       AND isbn = TRIM(pi_isbn);

    IF v_ultima_actual = 'S' THEN
        RAISE_APPLICATION_ERROR(
            -20082,
            'Error: la reunión ya está cerrada como última discusión.'
        );
    END IF;

    -- 3. ACTUALIZACIÓN DE REUNIONES ANTERIORES
    UPDATE MJV_calendario_reunion_mes
       SET ultima = 'N'
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo
       AND isbn = TRIM(pi_isbn)
       AND fecha != TRUNC(pi_fecha_reunion)
       AND ultima = 'S';

    -- 4. CIERRE DE LA REUNIÓN ACTUAL
    UPDATE MJV_calendario_reunion_mes
       SET realizada   = 'S',
           ultima      = 'S',
           conclusiones = v_conclusiones_norm,
           valoracion   = pi_valoracion
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo
       AND fecha = TRUNC(pi_fecha_reunion)
       AND isbn = TRIM(pi_isbn);

    -- 5. CÁLCULO DEL PROMEDIO DE VALORACIÓN DEL LIBRO
    SELECT NVL(AVG(valoracion), 0)
      INTO v_promedio_val
      FROM MJV_calendario_reunion_mes
     WHERE isbn = TRIM(pi_isbn)
       AND valoracion IS NOT NULL;

    -- [NOTA DE LOGÍSTICA]
    -- Al actualizar realizada = 'S' en el paso 4, el moderador asignado a esta 
    -- reunión en 'MJV_calendario_reunion_mes' queda liberado automáticamente, 
    -- ya que las validaciones de disponibilidad del Flujo 2.1 solo deberían 
    -- considerar como "ocupados" a los moderadores con reuniones donde realizada = 'N'.

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Discusión cerrada exitosamente.'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Club: ' || pi_id_club || ' | Grupo: ' || pi_id_grupo || ' | Libro: ' || TRIM(pi_isbn)
    );
    DBMS_OUTPUT.PUT_LINE(
        'Valoración de esta sesión: ' || pi_valoracion || ' | Promedio acumulado del libro: ' || ROUND(v_promedio_val, 2)
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20083,
            'Error: no se encontró la reunión con los datos especificados.'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_cerrar_discusion_reunion;
/