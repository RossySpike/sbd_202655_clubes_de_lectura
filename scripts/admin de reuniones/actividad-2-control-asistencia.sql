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
    v_asistio_norm     CHAR(1);
    v_fecha_i          DATE;
    v_fec_i_g_lec      DATE;
    v_realizada        CHAR(1);
    v_reunion_existe   NUMBER;
BEGIN
    v_asistio_norm := UPPER(TRIM(pi_asistio));
    IF v_asistio_norm NOT IN ('S', 'N') THEN
        RAISE_APPLICATION_ERROR(
            -20070,
            'Error: el valor de asistencia debe ser S o N.'
        );
    END IF;

    -- 1. Validar que el miembro tenga membresía activa en el grupo y club.
    SELECT gl.fecha_i, gl.fec_i
      INTO v_fecha_i, v_fec_i_g_lec
      FROM MJV_g_lec gl
     WHERE gl.id_lector = pi_id_lector
       AND gl.id_club   = pi_id_club
       AND gl.id_grupo  = pi_id_grupo
       AND gl.fec_f     IS NULL;

    -- 2. Validar que la reunión está programada y pertenece al grupo.
    SELECT COUNT(*), realizada
      INTO v_reunion_existe, v_realizada
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.id_club = pi_id_club
       AND crm.id_grupo = pi_id_grupo
       AND crm.fecha = TRUNC(pi_fecha_reunion)
       AND crm.isbn = TRIM(pi_isbn)
     GROUP BY realizada;

    IF v_reunion_existe = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20071,
            'Error: No existe la reunión especificada para ese club/grupo/libro/fecha.'
        );
    END IF;

    -- Registrar que la reunión se realizó cuando se carga asistencia.
    IF v_realizada = 'N' THEN
        UPDATE MJV_calendario_reunion_mes
           SET realizada = 'S'
         WHERE id_club = pi_id_club
           AND id_grupo = pi_id_grupo
           AND fecha = TRUNC(pi_fecha_reunion)
           AND isbn = TRIM(pi_isbn);
    END IF;

    -- 3. Solo registrar inasistencia si el miembro no asistió.
    IF v_asistio_norm = 'N' THEN
        SELECT COUNT(*)
          INTO v_reunion_existe
          FROM MJV_inasistencia i
         WHERE i.id_lector = pi_id_lector
           AND i.id_club = pi_id_club
           AND i.id_grupo = pi_id_grupo
           AND i.fecha_reunion = TRUNC(pi_fecha_reunion)
           AND i.isbn = TRIM(pi_isbn);

        IF v_reunion_existe > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20072,
                'Error: Ya existe una inasistencia registrada para este miembro y reunión.'
            );
        END IF;

        INSERT INTO MJV_inasistencia (
            id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec,
            fecha_reunion, isbn
        ) VALUES (
            pi_id_lector,
            pi_id_club,
            v_fecha_i,
            pi_id_grupo,
            v_fec_i_g_lec,
            TRUNC(pi_fecha_reunion),
            TRIM(pi_isbn)
        );

        DBMS_OUTPUT.PUT_LINE(
            'Inasistencia registrada: lector ' || pi_id_lector ||
            ', club ' || pi_id_club || ', grupo ' || pi_id_grupo ||
            ', fecha ' || TO_CHAR(TRUNC(pi_fecha_reunion), 'DD/MM/YYYY')
        );
    ELSE
        DBMS_OUTPUT.PUT_LINE(
            'Asistencia confirmada: lector ' || pi_id_lector ||
            ', club ' || pi_id_club || ', grupo ' || pi_id_grupo ||
            ', fecha ' || TO_CHAR(TRUNC(pi_fecha_reunion), 'DD/MM/YYYY')
        );
    END IF;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20073,
            'Error: el miembro o la reunión no se encontró para el club/grupo indicado.'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_registrar_asistencia_miembro;
/

-- El siguiente trigger aplica la penalización automática de retiro cuando el
-- porcentaje de inasistencias en el bimestre supera el 30%.
CREATE OR REPLACE TRIGGER MJV_tgr_retirar_por_inasistencia
AFTER INSERT ON MJV_inasistencia
FOR EACH ROW
DECLARE
    v_pct NUMBER;
BEGIN
    v_pct := MJV_fn_pct_inasistencia_bimestre(
                  :NEW.id_lector,
                  :NEW.id_club,
                  :NEW.fecha_reunion,
                  :NEW.id_grupo,
                  :NEW.isbn
              );

    IF v_pct > 30 THEN
        UPDATE MJV_g_lec
           SET fec_f = SYSDATE
         WHERE id_lector = :NEW.id_lector
           AND id_club   = :NEW.id_club
           AND fec_f     IS NULL;

        UPDATE MJV_historia_membresia
           SET estatus       = 'retirado',
               fecha_f       = SYSDATE,
               motivo_retiro = 'inasistencia'
         WHERE id_lector = :NEW.id_lector
           AND id_club   = :NEW.id_club
           AND estatus   = 'activo';

        DBMS_OUTPUT.PUT_LINE(
            'RETIRO AUTOMÁTICO: Lector ID ' || :NEW.id_lector ||
            ' — ' || ROUND(v_pct, 1) || '% de inasistencia en el bimestre.'
        );
    END IF;
END MJV_tgr_retirar_por_inasistencia;
/

-- Ejemplo de ejecución:
/*
SET SERVEROUTPUT ON;
DECLARE
    v_id_lector     NUMBER := &id_miembro;
    -- Nota: se espera el ID numérico del lector (`id_lector`). Evitar usar `doc_identidad` aquí.
    v_id_club       NUMBER := &id_club;
    v_id_grupo      NUMBER := &id_grupo;
    v_fecha_reunion DATE := TO_DATE('&fecha_reunion_DD/MM/YYYY', 'DD/MM/YYYY');
    v_isbn          VARCHAR2(20) := '&isbn_libro';
    v_asistio       CHAR(1) := '&asistio_SN';
BEGIN
    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha_reunion,
        pi_isbn          => v_isbn,
        pi_asistio       => v_asistio
    );
END;
*/
