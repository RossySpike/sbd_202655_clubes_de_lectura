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
BEGIN
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

    UPDATE MJV_calendario_reunion_mes
       SET ultima = 'N'
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo
       AND isbn = TRIM(pi_isbn)
       AND fecha != TRUNC(pi_fecha_reunion)
       AND ultima = 'S';

    UPDATE MJV_calendario_reunion_mes
       SET realizada   = 'S',
           ultima      = 'S',
           conclusiones = v_conclusiones_norm,
           valoracion   = pi_valoracion
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo
       AND fecha = TRUNC(pi_fecha_reunion)
       AND isbn = TRIM(pi_isbn);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Discusión cerrada: club ' || pi_id_club ||
        ', grupo ' || pi_id_grupo ||
        ', libro ' || TRIM(pi_isbn) ||
        ', fecha ' || TO_CHAR(TRUNC(pi_fecha_reunion), 'DD/MM/YYYY') ||
        ', valoración ' || pi_valoracion
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20083,
            'Error: no se encontró la reunión para cerrar.'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_cerrar_discusion_reunion;
/

-- Ejemplo de ejecución:
/*
SET SERVEROUTPUT ON;
DECLARE
    v_id_club       NUMBER := &id_club;
    v_id_grupo      NUMBER := &id_grupo;
    -- Nota: este procedimiento no solicita doc_identidad; usa id_club/id_grupo/fecha/isbn.
    v_fecha         DATE := TO_DATE('&fecha_reunion_DD/MM/YYYY', 'DD/MM/YYYY');
    v_isbn          VARCHAR2(20) := '&isbn_libro';
    v_conclusiones  VARCHAR2(4000) := '&conclusiones';
    v_valoracion    NUMBER := &valoracion_final;
BEGIN
    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_conclusiones  => v_conclusiones,
        pi_valoracion    => v_valoracion
    );
END;
*/
