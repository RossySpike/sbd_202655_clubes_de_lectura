CREATE OR REPLACE FUNCTION MJV_fn_obtener_isbn_por_titulo (
    p_titulo IN VARCHAR2
) RETURN VARCHAR2 IS
    v_isbn VARCHAR2(20);
BEGIN
    SELECT isbn 
      INTO v_isbn 
      FROM MJV_Libro 
     WHERE UPPER(TRIM(titulo)) = UPPER(TRIM(p_titulo))
       AND ROWNUM = 1; -- Gana tolerancia ante ligeras variantes o duplicados
       
    RETURN v_isbn;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: La obra "' || p_titulo || '" no está registrada en el catálogo general.');
END MJV_fn_obtener_isbn_por_titulo;
/

CREATE OR REPLACE FUNCTION MJV_fn_obtener_id_club_por_nombre (
    p_nombre_club IN VARCHAR2
) RETURN NUMBER IS
    v_id_club NUMBER;
BEGIN
    SELECT id_club 
      INTO v_id_club 
      FROM MJV_club 
     WHERE UPPER(TRIM(nombre_club)) = UPPER(TRIM(p_nombre_club))
       AND ROWNUM = 1; -- Tolerancia ante registros duplicados o similares
       
    RETURN v_id_club;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Error: El club de lectura "' || p_nombre_club || '" no está registrado en el sistema.');
END MJV_fn_obtener_id_club_por_nombre;
/

CREATE OR REPLACE FUNCTION MJV_fn_obtener_id_rep_por_doc (
    p_doc_identidad IN VARCHAR2,
    p_tipo_rep      IN VARCHAR2
) RETURN NUMBER IS
    v_id_rep NUMBER;
    v_tipo   VARCHAR2(20) := UPPER(TRIM(p_tipo_rep));
    v_doc    VARCHAR2(20) := UPPER(TRIM(p_doc_identidad));
BEGIN
    -- Validar si la búsqueda es en la tabla de Lectores o en la de Representantes Externos
    IF v_tipo = 'LECTOR' THEN
        SELECT id_lector 
          INTO v_id_rep 
          FROM MJV_lector 
         WHERE UPPER(TRIM(doc_identidad)) = v_doc
           AND ROWNUM = 1;
           
    ELSIF v_tipo = 'EXTERNO' THEN
        SELECT id_representante 
          INTO v_id_rep 
          FROM MJV_representante 
         WHERE UPPER(TRIM(doc_identidad)) = v_doc
           AND ROWNUM = 1;
           
    ELSE
        RAISE_APPLICATION_ERROR(-20012, 'Error: El tipo de representante especificado ("' || p_tipo_rep || '") no es válido. Debe ser LECTOR o EXTERNO.');
    END IF;

    RETURN v_id_rep;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF v_tipo = 'LECTOR' THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error: No se encontró ningún miembro LECTOR registrado con el documento: ' || p_doc_identidad);
        ELSE
            RAISE_APPLICATION_ERROR(-20011, 'Error: No se encontró ningún representante EXTERNO registrado con el documento: ' || p_doc_identidad);
        END IF;
END MJV_fn_obtener_id_rep_por_doc;
/

CREATE OR REPLACE TRIGGER MJV_tgr_validar_membresia_glec
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
  lector_estatus VARCHAR2(8);
BEGIN
    SELECT estatus INTO lector_estatus 
      FROM MJV_historia_membresia 
     WHERE id_club = :NEW.id_club 
       AND id_lector = :NEW.id_lector 
       AND estatus = 'activo';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'El lector no tiene una membresia activa en el club asociado al grupo.');
END;
/

-----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER MJV_tgr_validar_membresia_pago
BEFORE INSERT ON MJV_pago_membresia
FOR EACH ROW
DECLARE
    v_lector_estatus VARCHAR2(8);
    v_cuota_anual    CHAR(1);
BEGIN
    -- [R9] Verificar membresía activa
    BEGIN
        SELECT hm.estatus, c.cuota_anual
          INTO v_lector_estatus, v_cuota_anual
          FROM MJV_historia_membresia hm
          JOIN MJV_club c ON c.id_club = hm.id_club
         WHERE hm.id_club   = :NEW.id_club
           AND hm.id_lector = :NEW.id_lector
           AND hm.estatus   = 'activo';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Error: No se puede registrar el pago. El lector no tiene membresía activa en este club.'
            );
    END;

    -- [BRECHA 6] Bloquear pagos en clubes institucionales (sin cuota)
    IF v_cuota_anual = 'N' THEN
        RAISE_APPLICATION_ERROR(
            -20053,
            'Error: El club es dependiente de una institución y no cobra cuota de membresía. '
            || 'No se puede registrar un pago de membresía para este club.'
        );
    END IF;
END MJV_tgr_validar_membresia_pago;
/

create or replace FUNCTION MJV_fn_validar_solvencia_retiro (
    p_id_lector IN NUMBER,
    p_id_club   IN NUMBER
) RETURN VARCHAR2 IS
    v_fecha_i        DATE;
    v_meses_trans    NUMBER;
    v_meses_ano_act  NUMBER;
    v_anos_iniciados NUMBER;
    v_pagos_req      NUMBER;
    v_total_pagado   NUMBER;
BEGIN
    -- 1. Obtener fecha de ingreso
    SELECT fecha_i INTO v_fecha_i
      FROM MJV_historia_membresia
     WHERE id_lector = p_id_lector AND id_club = p_id_club AND estatus = 'activo';

    -- 2. Calcular matemática de años y pagos
    v_meses_trans := MONTHS_BETWEEN(SYSDATE, v_fecha_i);
    v_anos_iniciados := CEIL(v_meses_trans / 12);
    v_meses_ano_act  := MOD(v_meses_trans, 12);

    -- Regla: Si avisó a menos de 1 mes (mes 11), debe pagar el año que viene
    v_pagos_req := v_anos_iniciados;
    IF v_meses_ano_act >= 11 OR (v_meses_ano_act = 0 AND v_meses_trans > 0) THEN
        v_pagos_req := v_anos_iniciados + 1;
    END IF;

    -- 3. Sumar total pagado
    SELECT COALESCE(SUM(monto), 0) INTO v_total_pagado
      FROM MJV_pago_membresia
     WHERE id_lector = p_id_lector AND id_club = p_id_club;

    -- 4. Validar
    IF v_total_pagado < (v_pagos_req * 100) THEN
        IF v_meses_ano_act >= 11 OR (v_meses_ano_act = 0 AND v_meses_trans > 0) THEN
            RETURN 'AVISO TARDÍO: Retiro fuera de plazo. Debe pagar 100 USD de penalidad.';
        ELSE
            RETURN 'INSOLVENCIA: Faltan ' || ((v_pagos_req * 100) - v_total_pagado) || ' USD por pagar.';
        END IF;
    END IF;

    RETURN NULL; -- Todo en orden
END;
/

-- =============================================================================
-- VISTAS OPERATIVAS - SISTEMA DE ADMINISTRACIÓN DE CLUBES DE LECTURA
-- Actividad 1
-- =============================================================================


-- =============================================================================
-- VISTA 0: MJV_vw_miembros_activos
CREATE OR REPLACE VIEW MJV_vw_miembros_activos AS
SELECT c.nombre_club,
       l.doc_identidad AS cedula,
       l.p_nombre || ' ' || l.p_apellido || ' ' || l.s_apellido AS nombre_completo,
       h.fecha_i AS fecha_ingreso,
       g.id_grupo
FROM MJV_lector l
JOIN MJV_historia_membresia h ON l.id_lector = h.id_lector
JOIN MJV_club c ON h.id_club = c.id_club
JOIN MJV_g_lec g ON l.id_lector = g.id_lector AND c.id_club = g.id_club
WHERE h.estatus = 'activo'
  AND g.fec_f IS NULL;

-- =============================================================================
-- VISTA 1: MJV_vw_reporte_solvencia
-- Propósito: Cruzar historial de membresía con pagos para determinar si un
--            lector está al día o moroso con la cuota anual de 100 USD.
--
-- Lógica de negocio:
--   - CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12) = años iniciados desde el ingreso
--   - Deuda total = años_iniciados * 100 USD
--   - Deuda pendiente = deuda_total - total pagado (mínimo 0 si pagó de más)
--   - Estatus 'AL DIA' cuando no hay deuda pendiente; 'MOROSO' en caso contrario
--   - Se incluyen solo membresías activas para reflejar obligaciones vigentes
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_reporte_solvencia AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || l.s_apellido AS nombre_completo,
    l.doc_identidad,
    c.id_club,
    c.nombre_club,
    hm.fecha_i                                                AS fecha_ingreso,
    -- Años calendario iniciados desde la fecha de ingreso (mínimo 1)
    GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) AS anos_iniciados,
    -- Deuda total acumulada según años iniciados
    GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) * 100 AS deuda_total_usd,
    -- Total efectivamente pagado por este lector en este club
    NVL(pagos.total_pagado, 0)                                AS total_pagado_usd,
    -- Saldo pendiente (0 si está solvente o pagó de más)
    GREATEST(
        (GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) * 100)
        - NVL(pagos.total_pagado, 0),
        0
    )                                                         AS deuda_pendiente_usd,
    -- Estatus de solvencia
    CASE
        WHEN NVL(pagos.total_pagado, 0) >=
             GREATEST(CEIL(MONTHS_BETWEEN(SYSDATE, hm.fecha_i) / 12), 1) * 100
        THEN 'AL DIA'
        ELSE 'MOROSO'
    END                                                       AS estatus_solvencia
FROM
    MJV_historia_membresia hm
    JOIN MJV_lector l ON l.id_lector = hm.id_lector
    JOIN MJV_club   c ON c.id_club   = hm.id_club
    -- Agregado de pagos por lector/club (LEFT JOIN para incluir quienes no han pagado nada)
    LEFT JOIN (
        SELECT
            id_lector,
            id_club,
            SUM(monto) AS total_pagado
        FROM MJV_pago_membresia
        GROUP BY id_lector, id_club
    ) pagos ON pagos.id_lector = hm.id_lector
           AND pagos.id_club   = hm.id_club
WHERE
    hm.estatus = 'activo'
    AND c.cuota_anual = 'S'; -- Solo aplica a clubes que cobran cuota anual


-- =============================================================================
-- VISTA 2: MJV_vw_historial_retiros
-- Propósito: Auditar todas las bajas procesadas en el sistema, mostrando
--            el lector, el club, fechas de ingreso/retiro y el motivo.
--
-- Filtra únicamente los registros con estatus = 'retirado'.
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_historial_retiros AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || l.s_apellido AS nombre_completo,
    l.doc_identidad,
    c.id_club,
    c.nombre_club,
    hm.fecha_i   AS fecha_ingreso,
    hm.fecha_f   AS fecha_retiro,
    hm.motivo_retiro
FROM
    MJV_historia_membresia hm
    JOIN MJV_lector l ON l.id_lector = hm.id_lector
    JOIN MJV_club   c ON c.id_club   = hm.id_club
WHERE
    hm.estatus = 'retirado'
ORDER BY
    hm.fecha_f DESC;


-- =============================================================================
-- VISTA 3: MJV_vw_ocupacion_grupos
-- Propósito: Control de aforo por grupo. Muestra el club, el grupo y el
--            conteo de miembros actualmente activos (fec_f IS NULL).
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_ocupacion_grupos AS
SELECT
    c.id_club,
    c.nombre_club,
    g.id_grupo,
    g.tipo_grupo,
    COUNT(gl.id_lector) AS miembros_activos
FROM
    MJV_grupo g
    JOIN MJV_club  c  ON c.id_club  = g.id_club
    -- LEFT JOIN para mostrar grupos aunque aún no tengan miembros activos
    LEFT JOIN MJV_g_lec gl ON  gl.id_grupo = g.id_grupo
                           AND gl.id_club  = g.id_club
                           AND gl.fec_f IS NULL  -- Solo membresías de grupo vigentes
GROUP BY
    c.id_club,
    c.nombre_club,
    g.id_grupo,
    g.tipo_grupo
ORDER BY
    c.nombre_club,
    g.tipo_grupo;

    CREATE OR REPLACE FUNCTION MJV_fn_tiene_deuda_historica (
    p_id_lector IN NUMBER
) RETURN NUMBER   -- 1 = tiene deuda, 0 = solvente
IS
    v_deuda NUMBER := 0;
BEGIN
    -- Por cada período de membresía RETIRADA (id_lector+id_club+fecha_i es PK)
    -- se suma solo los pagos que corresponden a ESE período específico (misma fecha_i).
    -- LEFT JOIN con GROUP BY evita la subquery escalar correlacionada que
    -- Oracle rechaza en ciertas versiones por la lista SELECT sin GROUP BY.
    SELECT COUNT(*)
      INTO v_deuda
      FROM (
        SELECT hm.id_lector,
               hm.id_club,
               hm.fecha_i,
               GREATEST(CEIL(MONTHS_BETWEEN(hm.fecha_f, hm.fecha_i) / 12), 1) AS anos_req,
               NVL(pagos.total_pagado, 0)                                       AS total_pagado
          FROM MJV_historia_membresia hm
          JOIN MJV_club c ON c.id_club = hm.id_club
          LEFT JOIN (
              SELECT pm.id_lector,
                     pm.id_club,
                     pm.fecha_i,
                     SUM(pm.monto) AS total_pagado
                FROM MJV_pago_membresia pm
               GROUP BY pm.id_lector, pm.id_club, pm.fecha_i
          ) pagos ON pagos.id_lector = hm.id_lector
                 AND pagos.id_club   = hm.id_club
                 AND pagos.fecha_i   = hm.fecha_i
         WHERE hm.id_lector  = p_id_lector
           AND hm.estatus    = 'retirado'
           AND c.cuota_anual = 'S'
      )
     WHERE total_pagado < (anos_req * 100);

    RETURN CASE WHEN v_deuda > 0 THEN 1 ELSE 0 END;
END MJV_fn_tiene_deuda_historica;
/

CREATE OR REPLACE FUNCTION MJV_fn_vetado_por_inasistencia (
    p_id_lector IN NUMBER,
    p_id_club   IN NUMBER
) RETURN NUMBER   -- 1 = vetado, 0 = permitido
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM MJV_historia_membresia
     WHERE id_lector     = p_id_lector
       AND id_club        = p_id_club
       AND estatus        = 'retirado'
       AND motivo_retiro  = 'inasistencia';

    RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END MJV_fn_vetado_por_inasistencia;
/

CREATE OR REPLACE FUNCTION MJV_fn_pct_inasistencia_bimestre (
    p_id_lector      IN NUMBER,
    p_id_club        IN NUMBER,
    p_fecha_reunion  IN DATE,   -- fecha de la fila :NEW que se acaba de insertar
    p_id_grupo       IN NUMBER, -- grupo de :NEW (para filtrar reuniones del mismo grupo)
    p_isbn           IN VARCHAR2 -- isbn de :NEW (PK de calendario junto a grupo+club+fecha)
) RETURN NUMBER                 -- porcentaje de INASISTENCIA (0-100), incluyendo la fila nueva
IS
    v_mes       NUMBER := EXTRACT(MONTH FROM p_fecha_reunion);
    v_anio      NUMBER := EXTRACT(YEAR  FROM p_fecha_reunion);
    v_bimestre  NUMBER := CEIL(v_mes / 2);
    v_mes_ini   NUMBER := (v_bimestre - 1) * 2 + 1;
    v_mes_fin   NUMBER := v_bimestre * 2;
    v_esperadas NUMBER;
    v_faltas_anteriores NUMBER;
BEGIN
    -- Reuniones realizadas del bimestre a las que el lector debía asistir
    SELECT COUNT(*)
      INTO v_esperadas
      FROM MJV_calendario_reunion_mes crm
      JOIN MJV_g_lec gl ON gl.id_grupo = crm.id_grupo AND gl.id_club = p_id_club
     WHERE gl.id_lector  = p_id_lector
       AND gl.id_club    = p_id_club
       AND crm.realizada = 'S'
       AND EXTRACT(YEAR  FROM crm.fecha) = v_anio
       AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin
       AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, DATE '9999-12-31');

    IF v_esperadas = 0 THEN
        RETURN 0;  -- sin reuniones esperadas: 0% de inasistencia
    END IF;

    -- Inasistencias YA comiteadas en el bimestre (no incluye la fila :NEW aún)
    SELECT COUNT(*)
      INTO v_faltas_anteriores
      FROM MJV_inasistencia i
      JOIN MJV_calendario_reunion_mes crm
        ON crm.id_grupo = i.id_grupo
       AND crm.id_club  = i.id_club
       AND crm.fecha    = i.fecha_reunion
       AND crm.isbn     = i.isbn
     WHERE i.id_lector  = p_id_lector
       AND i.id_club    = p_id_club
       AND crm.realizada = 'S'
       AND EXTRACT(YEAR  FROM crm.fecha) = v_anio
       AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin;

    -- Sumar 1 por la fila recién insertada (:NEW) que aún no está comiteada
    RETURN ROUND(((v_faltas_anteriores + 1) / v_esperadas) * 100, 2);
END MJV_fn_pct_inasistencia_bimestre;
/

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
            'RETIRO AUTOMÁTICO: Lector ID ' || :NEW.id_lector
            || ' — ' || ROUND(v_pct, 1) || '% de inasistencia en el bimestre.'
        );
    END IF;
END MJV_tgr_retirar_por_inasistencia;
/

CREATE OR REPLACE PROCEDURE MJV_sp_inscribir_miembro (
    pi_p_nombre        IN VARCHAR2,
    pi_p_apellido      IN VARCHAR2,
    pi_s_nombre        IN VARCHAR2 DEFAULT NULL,
    pi_s_apellido      IN VARCHAR2,
    pi_doc_identidad   IN VARCHAR2,
    pi_telefono        IN VARCHAR2,
    pi_email           IN VARCHAR2,
    pi_genero          IN VARCHAR2,
    pi_fecha_nac       IN DATE,
    pi_nombre_pais_nac IN VARCHAR2,
    pi_nombre_club     IN VARCHAR2,
    pi_titulo_pref1    IN VARCHAR2,
    pi_titulo_pref2    IN VARCHAR2,
    pi_titulo_pref3    IN VARCHAR2,
    pi_doc_rep         IN VARCHAR2 DEFAULT NULL,
    pi_tipo_rep        IN VARCHAR2 DEFAULT NULL
) IS
    v_id_lector     NUMBER;
    v_age           NUMBER;
    v_tipo_grupo    VARCHAR2(10);
    v_id_grupo      NUMBER;
    v_id_club       NUMBER;
    v_id_pais_nac   NUMBER;
    v_isbn1         VARCHAR2(20);
    v_isbn2         VARCHAR2(20);
    v_isbn3         VARCHAR2(20);
    v_id_rep        NUMBER := NULL;
    v_id_rep_lector NUMBER := NULL;
    v_tiene_deuda   NUMBER;
    v_vetado        NUMBER;
    v_lector_existente NUMBER;
BEGIN
    -- 1. Resolver club y país
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    SELECT id_pais INTO v_id_pais_nac
      FROM MJV_pais
     WHERE UPPER(TRIM(nombre_pais)) = UPPER(TRIM(pi_nombre_pais_nac))
       AND ROWNUM = 1;

    -- 2. Resolver ISBN de preferencias
    v_isbn1 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref1);
    v_isbn2 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref2);
    v_isbn3 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref3);

    -- 3. Lógica de representante
    IF pi_doc_rep IS NOT NULL AND pi_tipo_rep IS NOT NULL THEN
        IF UPPER(TRIM(pi_tipo_rep)) = 'LECTOR' THEN
            v_id_rep_lector := MJV_fn_obtener_id_rep_por_doc(pi_doc_rep, pi_tipo_rep);
        ELSIF UPPER(TRIM(pi_tipo_rep)) = 'EXTERNO' THEN
            v_id_rep := MJV_fn_obtener_id_rep_por_doc(pi_doc_rep, pi_tipo_rep);
        ELSE
            RAISE_APPLICATION_ERROR(
                -20012,
                'Error: El tipo de representante debe ser LECTOR o EXTERNO.'
            );
        END IF;
    END IF;

    -- 4. Insertar lector (dispara MJV_tgr_validar_edad)
    INSERT INTO MJV_lector (
        p_nombre, p_apellido, s_apellido, doc_identidad, telefono,
        email, genero, fecha_nac, id_pais_nac, s_nombre,
        id_representante, id_representante_lector
    ) VALUES (
        pi_p_nombre, pi_p_apellido, pi_s_apellido, pi_doc_identidad, pi_telefono,
        pi_email, pi_genero, pi_fecha_nac, v_id_pais_nac, pi_s_nombre,
        v_id_rep, v_id_rep_lector
    )
    RETURNING id_lector INTO v_id_lector;

    -- 5. Calcular edad
    v_age := MJV_edad_miembro(v_id_lector);

    -- [BRECHA 1] Bloqueo por deudas históricas en cualquier club anterior
    v_tiene_deuda := MJV_fn_tiene_deuda_historica(v_id_lector);
    IF v_tiene_deuda = 1 THEN
        -- Revertir el INSERT del lector antes de lanzar el error
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20054,
            'INSCRIPCIÓN DENEGADA: El lector con documento ' || pi_doc_identidad
            || ' tiene deudas pendientes de membresía en un club anterior. '
            || 'Debe saldar su deuda antes de unirse a un nuevo club.'
        );
    END IF;

    -- [BRECHA 2] Bloqueo permanente por inasistencia en este mismo club
    v_vetado := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
    IF v_vetado = 1 THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20055,
            'INSCRIPCIÓN DENEGADA: El lector con documento ' || pi_doc_identidad
            || ' fue retirado del club "' || pi_nombre_club
            || '" por inasistencia y tiene prohibido el reingreso permanentemente.'
        );
    END IF;

    -- 6. Registrar preferencias
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn3, 3);

    -- 7. Iniciar historial de membresía (dispara MJV_tgr_un_club_activo)
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    -- 8. Clasificar tipo de grupo por edad
    IF v_age BETWEEN 6 AND 12 THEN
        v_tipo_grupo := 'niños';
    ELSIF v_age BETWEEN 13 AND 25 THEN
        v_tipo_grupo := 'jovenes';
    ELSIF v_age > 25 THEN
        v_tipo_grupo := 'adultos';
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Error: La edad mínima de ingreso es 6 años.');
    END IF;

    -- 9. Buscar o crear el grupo correspondiente
    BEGIN
        SELECT id_grupo
          INTO v_id_grupo
          FROM MJV_grupo
         WHERE id_club    = v_id_club
           AND tipo_grupo = v_tipo_grupo
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
            VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
            RETURNING id_grupo INTO v_id_grupo;
    END;

    -- 10. Asignar al grupo (dispara MJV_tgr_bloquear_inscripcion_libro_activo
    --     y MJV_tgr_grupo_lleno → MJV_sp_split_grupo si aplica)
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_lector, v_id_club, SYSDATE, v_id_grupo, SYSDATE, NULL);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Inscripción exitosa. ID Lector: ' || v_id_lector
        || ' | Edad: ' || v_age || ' | Grupo: ' || v_tipo_grupo
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_inscribir_miembro;
/

/* -- ejemplo de ejecución:
SET SERVEROUTPUT ON;

DECLARE
    v_p_nom    VARCHAR2(100) := '&primer_nombre';
    v_s_nom    VARCHAR2(100) := '&segundo_nombre_o_NULL';
    v_p_ape    VARCHAR2(100) := '&primer_apellido';
    v_s_ape    VARCHAR2(100) := '&segundo_apellido';
    v_doc      VARCHAR2(20)  := '&documento_identidad_ej_V_ADU01';
    v_tel      VARCHAR2(20)  := '&telefono';
    v_email    VARCHAR2(100) := '&email';
    v_gen      VARCHAR2(1)   := '&genero_M_o_F';
    v_fec_nac  DATE          := TO_DATE('&fecha_nacimiento_DD_MM_YYYY', 'DD/MM/YYYY');
    v_pais_nac VARCHAR2(100) := '&nombre_pais_nacimiento';
    v_club     VARCHAR2(150) := '&nombre_exacto_del_club'; 
    v_pref1    VARCHAR2(200) := '&titulo_libro_preferido_1';
    v_pref2    VARCHAR2(200) := '&titulo_libro_preferido_2';
    v_pref3    VARCHAR2(200) := '&titulo_libro_preferido_3';
    v_rep_doc  VARCHAR2(20)  := '&doc_representante_o_NULL'; 
    v_rep_tipo VARCHAR2(20)  := '&tipo_rep_LECTOR_o_EXTERNO_o_NULL'; 
BEGIN
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => v_p_nom,
        pi_p_apellido      => v_p_ape,
        pi_s_apellido      => v_s_ape,
        pi_doc_identidad   => v_doc,
        pi_telefono        => v_tel,
        pi_email           => v_email,
        pi_genero          => v_gen,
        pi_fecha_nac       => v_fec_nac,
        pi_nombre_pais_nac => v_pais_nac,
        pi_nombre_club     => v_club,
        pi_titulo_pref1    => v_pref1,
        pi_titulo_pref2    => v_pref2,
        pi_titulo_pref3    => v_pref3,
        pi_s_nombre        => v_s_nom,
        pi_doc_rep         => v_rep_doc,   
        pi_tipo_rep        => v_rep_tipo   
    );
END; */

CREATE OR REPLACE PROCEDURE MJV_sp_registrar_pago_membresia (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_monto         IN NUMBER,
    pi_moneda        IN VARCHAR2,
    pi_tasa          IN NUMBER
) IS
    v_id_lector   NUMBER;
    v_id_club     NUMBER;
    v_fecha_i     DATE;
    v_monto_usd   NUMBER;
    v_cuota_anual CHAR(1);
BEGIN
    -- 1. Resolver lector
    BEGIN
        SELECT id_lector INTO v_id_lector
          FROM MJV_lector
         WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20010,
                'Error: No se encontró ningún lector con el documento: ' || pi_doc_identidad
            );
    END;

    -- 2. Resolver club
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 3. [BRECHA 6] Verificar que el club cobra cuota antes de todo
    SELECT cuota_anual INTO v_cuota_anual FROM MJV_club WHERE id_club = v_id_club;

    IF v_cuota_anual = 'N' THEN
        RAISE_APPLICATION_ERROR(
            -20053,
            'Error: El club "' || pi_nombre_club
            || '" es dependiente de una institución y no cobra cuota de membresía.'
        );
    END IF;

    -- 4. Obtener fecha_i de membresía activa
    BEGIN
        SELECT fecha_i INTO v_fecha_i
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector
           AND id_club   = v_id_club
           AND estatus   = 'activo';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Error: El lector no tiene membresía activa en este club.'
            );
    END;

    -- 5. Conversión y validación de monto mínimo
    v_monto_usd := MJV_conversion_monetaria(pi_monto, pi_moneda, 'USD', pi_tasa);

    IF v_monto_usd < 100 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Error de Pago: El monto equivale a ' || ROUND(v_monto_usd, 2)
            || ' USD. La cuota anual mínima es 100 USD.'
        );
    END IF;

    -- 6. Registrar pago
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    VALUES (v_id_lector, v_id_club, v_fecha_i, SYSDATE, v_monto_usd);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Pago registrado: ' || ROUND(v_monto_usd, 2) || ' USD para lector ID '
        || v_id_lector || ' en club ' || pi_nombre_club || '.'
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_registrar_pago_membresia;
/

-- ejemplo de ejecución:
/*
SET SERVEROUTPUT ON;

DECLARE
    v_doc    VARCHAR2(20)  := '&documento_identidad_lector';
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_monto  NUMBER        := &monto_pagado;
    v_moneda VARCHAR2(3)   := '&codigo_moneda_ej_VES_o_USD';
    v_tasa   NUMBER        := &tasa_de_cambio_actual;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => v_doc,
        pi_nombre_club   => v_club,
        pi_monto         => v_monto,
        pi_moneda        => v_moneda,
        pi_tasa          => v_tasa
    );
END;
*/

CREATE OR REPLACE PROCEDURE MJV_sp_retirar_miembro (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_motivo_retiro IN VARCHAR2
) IS
    v_id_lector     NUMBER;
    v_id_club       NUMBER;
    v_msj_error     VARCHAR2(200);
    v_motivo_valido VARCHAR2(12);
BEGIN
    -- [BRECHA 7] Validar dominio del motivo antes de cualquier DML
    v_motivo_valido := LOWER(TRIM(pi_motivo_retiro));
    IF v_motivo_valido NOT IN ('voluntario', 'inasistencia', 'deuda', 'otro') THEN
        RAISE_APPLICATION_ERROR(
            -20056,
            'RETIRO INVÁLIDO: El motivo "' || pi_motivo_retiro
            || '" no es válido. Los valores permitidos son: '
            || 'voluntario, inasistencia, deuda, otro.'
        );
    END IF;

    -- 1. Identificar lector y club
    BEGIN
        SELECT id_lector INTO v_id_lector
          FROM MJV_lector
         WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20010,
                'Error: No se encontró lector con documento: ' || pi_doc_identidad
            );
    END;

    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 2. Validar solvencia (solo para clubes que cobran cuota)
    DECLARE
        v_cuota CHAR(1);
    BEGIN
        SELECT cuota_anual INTO v_cuota FROM MJV_club WHERE id_club = v_id_club;
        IF v_cuota = 'S' THEN
            v_msj_error := MJV_fn_validar_solvencia_retiro(v_id_lector, v_id_club);
            IF v_msj_error IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20040,
                    'RETIRO DENEGADO: ' || v_msj_error
                );
            END IF;
        END IF;
    END;

    -- 3. Cerrar asignación de grupo
    UPDATE MJV_g_lec
       SET fec_f = SYSDATE
     WHERE id_lector = v_id_lector
       AND id_club   = v_id_club
       AND fec_f     IS NULL;

    -- 4. Cerrar membresía
    UPDATE MJV_historia_membresia
       SET estatus       = 'retirado',
           fecha_f       = SYSDATE,
           motivo_retiro = v_motivo_valido
     WHERE id_lector = v_id_lector
       AND id_club   = v_id_club
       AND estatus   = 'activo';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20030,
            'Error: El miembro no estaba activo en este club.'
        );
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Retiro procesado. Lector: ' || pi_doc_identidad
        || ' | Club: ' || pi_nombre_club
        || ' | Motivo: ' || v_motivo_valido
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END MJV_sp_retirar_miembro;
/
/*
SET SERVEROUTPUT ON;

DECLARE
    v_doc    VARCHAR2(20)  := '&documento_identidad_lector';
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_motivo VARCHAR2(200) := '&motivo_retiro_voluntario_inasistencia_deuda_otro';
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => v_doc,
        pi_nombre_club   => v_club,
        pi_motivo_retiro => LOWER(TRIM(v_motivo))
    );
END;
*/


-- =============================================================================
-- ADMINISTRACIÓN DE REUNIONES - FLUJO 2
-- Objetos del flujo de reuniones agregados al complemento del script final.
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
    SELECT tipo_grupo, hora_reunion
      INTO v_tipo_grupo, v_hora_grupo
      FROM MJV_grupo
     WHERE id_club = pi_id_club
       AND id_grupo = pi_id_grupo;

    IF TO_CHAR(pi_hora_inicio, 'HH24:MI') != TO_CHAR(v_hora_grupo, 'HH24:MI') THEN
        RAISE_APPLICATION_ERROR(
            -20060,
            'La hora de inicio (' || TO_CHAR(pi_hora_inicio, 'HH24:MI') || ') debe coincidir ' ||
            'con la hora programada del grupo (' || TO_CHAR(v_hora_grupo, 'HH24:MI') || ').'
        );
    END IF;

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

    IF v_tipo_grupo = 'niños' THEN
        SELECT COUNT(*)
          INTO v_mod_adulto_activo
          FROM MJV_g_lec gl
          JOIN MJV_grupo g ON gl.id_club = g.id_club AND gl.id_grupo = g.id_grupo
         WHERE gl.id_lector = pi_mod_id_lector
           AND gl.id_club   = pi_id_club
           AND gl.fec_f     IS NULL
           AND g.tipo_grupo = 'adultos';

        IF v_mod_adulto_activo = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20067,
                'Error: Para reuniones de niños el moderador debe pertenecer a un grupo de adultos del mismo club.'
            );
        END IF;
    END IF;

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

-- Ejemplo de ejecución: Agendar reunión (Actividad 1)
/*
SET SERVEROUTPUT ON;
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

    SELECT gl.fecha_i, gl.fec_i
      INTO v_fecha_i, v_fec_i_g_lec
      FROM MJV_g_lec gl
     WHERE gl.id_lector = pi_id_lector
       AND gl.id_club   = pi_id_club
       AND gl.id_grupo  = pi_id_grupo
       AND gl.fec_f     IS NULL;

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

    IF v_realizada = 'N' THEN
        UPDATE MJV_calendario_reunion_mes
           SET realizada = 'S'
         WHERE id_club = pi_id_club
           AND id_grupo = pi_id_grupo
           AND fecha = TRUNC(pi_fecha_reunion)
           AND isbn = TRIM(pi_isbn);
    END IF;

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

-- Ejemplo de ejecución: Registrar asistencia/inasistencia (Actividad 2)
/*
SET SERVEROUTPUT ON;
DECLARE
    v_id_lector     NUMBER := &id_lector;
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
            'RETIRO AUTOMÁTICO: Lector ID ' || :NEW.id_lector
            || ' — ' || ROUND(v_pct, 1) || '% de inasistencia en el bimestre.'
        );
    END IF;
END MJV_tgr_retirar_por_inasistencia;
/

-- Nota: el trigger se activa automáticamente cuando se inserta una inasistencia en MJV_inasistencia.

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

-- Ejemplo de ejecución: Cerrar discusión y registrar valoración (Actividad 3)
/*
SET SERVEROUTPUT ON;
DECLARE
    v_id_club       NUMBER := &id_club;
    v_id_grupo      NUMBER := &id_grupo;
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
