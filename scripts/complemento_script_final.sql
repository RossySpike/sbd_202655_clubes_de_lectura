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

CREATE OR REPLACE TRIGGER MJV_tgr_un_grupo_por_club
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM MJV_g_lec
     WHERE id_lector = :NEW.id_lector
       AND id_club   = :NEW.id_club
       AND fec_f     IS NULL;   -- activo en el grupo (no retirado)
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20009,
            'INTEGRIDAD: El lector ' || :NEW.id_lector
            || ' ya está activo en un grupo de lectura del club ' || :NEW.id_club
            || '. Un lector solo puede pertenecer a un grupo activo por club.'
        );
    END IF;
END MJV_tgr_un_grupo_por_club;
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

-- =============================================================================
-- BRECHA 3: Función canónica para detectar libro en discusión activa
-- =============================================================================
CREATE OR REPLACE FUNCTION MJV_fn_grupo_discutiendo_libro (
    p_id_club  IN NUMBER,
    p_id_grupo IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.id_club   = p_id_club
       AND crm.id_grupo  = p_id_grupo
       AND crm.realizada = 'S'
       AND crm.ultima    = 'N';
    RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END MJV_fn_grupo_discutiendo_libro;
/

-- =============================================================================
-- BRECHA 3: Trigger corregido — Regla de Oro (inscripción bloqueada si hay libro activo)
-- =============================================================================
CREATE OR REPLACE TRIGGER MJV_tgr_bloquear_inscripcion_libro_activo
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
    v_discutiendo NUMBER;
BEGIN
    v_discutiendo := MJV_fn_grupo_discutiendo_libro(:NEW.id_club, :NEW.id_grupo);
    IF v_discutiendo = 1 THEN
        RAISE_APPLICATION_ERROR(-20050,
            'REGLA DE ORO: No se puede inscribir un nuevo miembro al grupo '
            || :NEW.id_grupo || ' mientras se esté discutiendo un libro activamente.');
    END IF;
END MJV_tgr_bloquear_inscripcion_libro_activo;
/

-- =============================================================================
-- BRECHA 3: SP de split corregido con Regla de Oro
-- =============================================================================
CREATE OR REPLACE PROCEDURE MJV_sp_split_grupo (
    p_id_club_original  IN  NUMBER,
    p_id_grupo_original IN  NUMBER,
    p_tipo_grupo        IN  VARCHAR2,
    p_dia_reunion       IN  NUMBER,
    p_hora_reunion      IN  DATE,
    p_nuevo_grupo_id    OUT NUMBER
) AS
    v_min_miem    NUMBER;
    v_discutiendo NUMBER;
BEGIN
    v_discutiendo := MJV_fn_grupo_discutiendo_libro(p_id_club_original, p_id_grupo_original);
    IF v_discutiendo = 1 THEN
        RAISE_APPLICATION_ERROR(-20051,
            'REGLA DE ORO: No se puede realizar el split del grupo '
            || p_id_grupo_original || ' mientras se esté discutiendo un libro activamente.');
    END IF;
    IF p_tipo_grupo = 'adultos' THEN v_min_miem := 10;
    ELSIF p_tipo_grupo = 'jovenes' THEN v_min_miem := 5;
    ELSE v_min_miem := 10; END IF;
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (p_id_club_original, p_tipo_grupo, SYSDATE, p_dia_reunion, p_hora_reunion)
    RETURNING id_grupo INTO p_nuevo_grupo_id;
    UPDATE MJV_g_lec
       SET id_grupo = p_nuevo_grupo_id
     WHERE id_club  = p_id_club_original
       AND id_grupo = p_id_grupo_original
       AND fec_f    IS NULL
       AND id_lector IN (
           SELECT id_lector FROM (
               SELECT id_lector, fec_i FROM MJV_g_lec
                WHERE id_club = p_id_club_original AND id_grupo = p_id_grupo_original AND fec_f IS NULL
                ORDER BY fec_i DESC FETCH FIRST v_min_miem ROWS ONLY));
    COMMIT;
END MJV_sp_split_grupo;
/

-- =============================================================================
-- BRECHA 4: Trigger de moderador reforzado (simultáneo en otro grupo)
-- =============================================================================
CREATE OR REPLACE TRIGGER MJV_tgr_validar_moderador
BEFORE INSERT OR UPDATE ON MJV_calendario_reunion_mes
FOR EACH ROW
DECLARE
    v_es_miembro_club  NUMBER;
    v_tipo_grupo       VARCHAR2(10);
    v_es_adulto        NUMBER;
    v_mod_ocupado      NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_es_miembro_club
      FROM MJV_g_lec
     WHERE id_lector = :NEW.mod_id_lector AND id_club = :NEW.id_club AND fec_f IS NULL;
    IF v_es_miembro_club = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'El moderador debe ser un miembro activo del mismo club.');
    END IF;
    SELECT tipo_grupo INTO v_tipo_grupo FROM MJV_grupo
     WHERE id_grupo = :NEW.id_grupo AND id_club = :NEW.id_club;
    IF v_tipo_grupo = 'niños' THEN
        SELECT COUNT(*) INTO v_es_adulto
          FROM MJV_g_lec gl JOIN MJV_grupo g ON gl.id_grupo = g.id_grupo AND gl.id_club = g.id_club
         WHERE gl.id_lector = :NEW.mod_id_lector AND gl.id_club = :NEW.id_club
           AND gl.fec_f IS NULL AND g.tipo_grupo = 'adultos';
        IF v_es_adulto = 0 THEN
            RAISE_APPLICATION_ERROR(-20031,
                'Para reuniones de niños el moderador debe pertenecer a un grupo de adultos del mismo club.');
        END IF;
    END IF;
    -- [BRECHA 4] Bloquear si el moderador tiene otro libro activo en otro grupo
    SELECT COUNT(*) INTO v_mod_ocupado
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.mod_id_lector = :NEW.mod_id_lector
       AND crm.id_club        = :NEW.id_club
       AND crm.realizada      = 'S'
       AND crm.ultima         = 'N'
       AND NOT (crm.id_grupo = :NEW.id_grupo AND crm.isbn = :NEW.isbn);
    IF v_mod_ocupado > 0 THEN
        RAISE_APPLICATION_ERROR(-20052,
            'El moderador (ID: ' || :NEW.mod_id_lector
            || ') ya está moderando activamente la discusión de otro libro en otro grupo. '
            || 'Solo puede tomar una nueva moderación cuando termine la discusión actual.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'No se encontró información del grupo o club asociado a la reunión.');
END MJV_tgr_validar_moderador;
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
    pi_id_rep          IN NUMBER DEFAULT NULL,
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

    -- 3. Insertar lector (dispara MJV_tgr_validar_edad)
    INSERT INTO MJV_lector (
        p_nombre, p_apellido, s_apellido, doc_identidad, telefono,
        email, genero, fecha_nac, id_pais_nac, s_nombre,
        id_representante, id_representante_lector
    ) VALUES (
        pi_p_nombre, pi_p_apellido, pi_s_apellido, pi_doc_identidad, pi_telefono,
        pi_email, pi_genero, pi_fecha_nac, v_id_pais_nac, pi_s_nombre,
        CASE WHEN UPPER(TRIM(pi_tipo_rep)) = 'EXTERNO' THEN pi_id_rep ELSE NULL END, 
        CASE WHEN UPPER(TRIM(pi_tipo_rep)) = 'LECTOR' THEN pi_id_rep ELSE NULL END
    )
    RETURNING id_lector INTO v_id_lector;

    -- 4. Calcular edad
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

    -- 9. Seleccionar grupo con round-robin (grupo con menos miembros activos del tipo)
    v_id_grupo := MJV_fn_grupo_menos_lleno(v_id_club, v_tipo_grupo);
    IF v_id_grupo IS NULL THEN
        INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
        VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
        RETURNING id_grupo INTO v_id_grupo;
    END IF;

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
    v_rep_id   NUMBER        := &id_representante_o_NULL; 
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
        pi_id_rep          => v_rep_id,   
        pi_tipo_rep        => v_rep_tipo   
    );
END; */

CREATE OR REPLACE PROCEDURE MJV_sp_registrar_pago_membresia (
    pi_id_lector     IN NUMBER,
    pi_nombre_club   IN VARCHAR2,
    pi_monto         IN NUMBER,
    pi_moneda        IN VARCHAR2,
    pi_tasa          IN NUMBER
) IS
    v_id_club     NUMBER;
    v_fecha_i     DATE;
    v_monto_usd   NUMBER;
    v_cuota_anual CHAR(1);
BEGIN
    -- 1. Resolver club
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
         WHERE id_lector = pi_id_lector
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
    v_monto_usd := MJV_conversion_monetaria(pi_monto, pi_moneda, pi_tasa);

    IF v_monto_usd < 100 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Error de Pago: El monto equivale a ' || ROUND(v_monto_usd, 2)
            || ' USD. La cuota anual mínima es 100 USD.'
        );
    END IF;

    -- 6. Registrar pago
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    VALUES (pi_id_lector, v_id_club, v_fecha_i, SYSDATE, v_monto_usd);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Pago registrado: ' || ROUND(v_monto_usd, 2) || ' USD para lector ID '
        || pi_id_lector || ' en club ' || pi_nombre_club || '.'
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
    v_id_lec NUMBER        := &id_lector;
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_monto  NUMBER        := &monto_pagado;
    v_moneda VARCHAR2(3)   := '&codigo_moneda_ej_VES_o_USD';
    v_tasa   NUMBER        := &tasa_de_cambio_actual;
BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_id_lector     => v_id_lec,
        pi_nombre_club   => v_club,
        pi_monto         => v_monto,
        pi_moneda        => v_moneda,
        pi_tasa          => v_tasa
    );
END;
*/

CREATE OR REPLACE PROCEDURE MJV_sp_retirar_miembro (
    pi_id_lector     IN NUMBER,
    pi_nombre_club   IN VARCHAR2,
    pi_motivo_retiro IN VARCHAR2
) IS
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

    -- 1. Identificar club
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 2. Validar solvencia (solo para clubes que cobran cuota)
    DECLARE
        v_cuota CHAR(1);
    BEGIN
        SELECT cuota_anual INTO v_cuota FROM MJV_club WHERE id_club = v_id_club;
        IF v_cuota = 'S' THEN
            v_msj_error := MJV_fn_validar_solvencia_retiro(pi_id_lector, v_id_club);
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
     WHERE id_lector = pi_id_lector
       AND id_club   = v_id_club
       AND fec_f     IS NULL;

    -- 4. Cerrar membresía
    UPDATE MJV_historia_membresia
       SET estatus       = 'retirado',
           fecha_f       = SYSDATE,
           motivo_retiro = v_motivo_valido
     WHERE id_lector = pi_id_lector
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
        'Retiro procesado. ID Lector: ' || pi_id_lector
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
    v_id_lec NUMBER        := &id_lector;
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_motivo VARCHAR2(200) := '&motivo_retiro_voluntario_inasistencia_deuda_otro';
BEGIN
    MJV_sp_retirar_miembro(
        pi_id_lector     => v_id_lec,
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

     -- [REGLA] Las reuniones solo pueden agendarse de lunes a viernes
    IF TO_CHAR(TRUNC(pi_fecha_reunion), 'D') IN ('1', '7') THEN
        RAISE_APPLICATION_ERROR(
            -20068,
            'ERROR: No se pueden programar reuniones los fines de semana. '
            || 'La fecha ' || TO_CHAR(TRUNC(pi_fecha_reunion), 'DD/MM/YYYY')
            || ' corresponde a un ' || TO_CHAR(TRUNC(pi_fecha_reunion), 'DAY', 'NLS_DATE_LANGUAGE=SPANISH') || '.'
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

        -- [REGLA] Máximo 3 reuniones por libro por grupo (sin haber cerrado discusión)
    DECLARE
        v_reuniones_libro NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_reuniones_libro
          FROM MJV_calendario_reunion_mes
         WHERE id_club  = pi_id_club
           AND id_grupo = pi_id_grupo
           AND isbn     = TRIM(pi_isbn)
           AND ultima   = 'N';   -- Reuniones ya realizadas y aún no cerradas
        IF v_reuniones_libro >= 3 THEN
            RAISE_APPLICATION_ERROR(
                -20069,
                'ERROR: El grupo ' || pi_id_grupo || ' ya tiene 3 reuniones registradas '
                || 'para el libro ' || pi_isbn || ' sin haber cerrado la discusión. '
                || 'Debe cerrar la discusión antes de agendar más reuniones de este libro.'
            );
        END IF;
    END;

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

    -- [BRECHA B] No cerrar si la reunión aún no ha sido realizada
    IF v_reunion_realizada = 'N' THEN
        RAISE_APPLICATION_ERROR(-20084, 'ERROR: No se puede cerrar una reunión que aún no ha sido realizada. Registre la asistencia primero.');
    END IF;

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

-- =============================================================================
-- BRECHA C: Función y trigger de duración máxima de reunión (2h; adultos/jóvenes ≤ 21:00)
-- =============================================================================
CREATE OR REPLACE FUNCTION MJV_fn_hora_fin_valida (
    p_tipo_grupo   IN VARCHAR2,
    p_hora_inicio  IN DATE,
    p_duracion_min IN NUMBER
) RETURN VARCHAR2 IS
    v_hora_fin DATE;
    v_minutos  NUMBER := NVL(p_duracion_min, 0);
BEGIN
    IF v_minutos > 120 THEN
        RETURN 'ERROR: La duración máxima de una reunión es 120 minutos (2 horas).';
    END IF;
    v_hora_fin := p_hora_inicio + v_minutos / 1440;
    IF LOWER(TRIM(p_tipo_grupo)) IN ('adultos', 'jovenes') THEN
        IF TO_CHAR(v_hora_fin, 'HH24:MI') > '21:00' THEN
            RETURN 'ERROR: Las reuniones de adultos y jóvenes deben terminar a más tardar a las 21:00.';
        END IF;
    END IF;
    IF LOWER(TRIM(p_tipo_grupo)) = 'niños' THEN
        IF TO_CHAR(v_hora_fin, 'HH24:MI') > '19:00' THEN
            RETURN 'ERROR: Las reuniones de niños deben terminar a más tardar a las 19:00.';
        END IF;
    END IF;
    RETURN NULL;
END MJV_fn_hora_fin_valida;
/

CREATE OR REPLACE TRIGGER MJV_tgr_validar_duracion_grupo
BEFORE INSERT OR UPDATE ON MJV_grupo
FOR EACH ROW
DECLARE
    v_error VARCHAR2(300);
BEGIN
    IF :NEW.duracion_min IS NOT NULL THEN
        v_error := MJV_fn_hora_fin_valida(:NEW.tipo_grupo, :NEW.hora_reunion, :NEW.duracion_min);
        IF v_error IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20069, v_error);
        END IF;
    END IF;
END MJV_tgr_validar_duracion_grupo;
/

-- =============================================================================
-- BRECHA D: 4 vistas operativas de administración de reuniones
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_reuniones_calendario_activo AS
SELECT
    c.id_club,
    c.nombre_club,
    g.id_grupo,
    INITCAP(g.tipo_grupo) AS tipo_grupo,
    crm.fecha,
    TO_CHAR(g.hora_reunion, 'HH24:MI') AS hora_inicio,
    crm.isbn,
    lb.titulo AS titulo_libro,
    crm.mod_id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_moderador,
    DECODE(crm.realizada, 'S', 'Realizada', 'N', 'Pendiente') AS estado_reunion,
    DECODE(crm.ultima,    'S', 'Cerrada',   'N', 'En curso')  AS estado_discusion
FROM MJV_calendario_reunion_mes crm
JOIN MJV_grupo  g  ON g.id_grupo = crm.id_grupo AND g.id_club = crm.id_club
JOIN MJV_club   c  ON c.id_club  = crm.id_club
JOIN MJV_libro  lb ON lb.isbn    = crm.isbn
JOIN MJV_lector l  ON l.id_lector = crm.mod_id_lector
WHERE crm.ultima = 'N'
ORDER BY crm.fecha, c.nombre_club, g.id_grupo;
/

CREATE OR REPLACE VIEW MJV_vw_inasistencias_bimestre AS
SELECT
    EXTRACT(YEAR FROM crm.fecha)             AS anio,
    CEIL(EXTRACT(MONTH FROM crm.fecha) / 2)  AS bimestre,
    i.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_lector,
    i.id_club,
    c.nombre_club,
    i.id_grupo,
    COUNT(*)                                 AS total_inasistencias,
    (SELECT COUNT(*) FROM MJV_calendario_reunion_mes crm2
       JOIN MJV_g_lec gl2 ON gl2.id_grupo = crm2.id_grupo AND gl2.id_club = i.id_club
      WHERE gl2.id_lector = i.id_lector AND gl2.id_club = i.id_club
        AND crm2.realizada = 'S'
        AND EXTRACT(YEAR  FROM crm2.fecha) = EXTRACT(YEAR FROM crm.fecha)
        AND CEIL(EXTRACT(MONTH FROM crm2.fecha) / 2) = CEIL(EXTRACT(MONTH FROM crm.fecha) / 2)
        AND crm2.fecha BETWEEN gl2.fec_i AND NVL(gl2.fec_f, DATE '9999-12-31')
    )                                        AS total_reuniones_esperadas,
    ROUND(COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM MJV_calendario_reunion_mes crm2
                  JOIN MJV_g_lec gl2 ON gl2.id_grupo = crm2.id_grupo AND gl2.id_club = i.id_club
                 WHERE gl2.id_lector = i.id_lector AND gl2.id_club = i.id_club
                   AND crm2.realizada = 'S'
                   AND EXTRACT(YEAR FROM crm2.fecha) = EXTRACT(YEAR FROM crm.fecha)
                   AND CEIL(EXTRACT(MONTH FROM crm2.fecha) / 2) = CEIL(EXTRACT(MONTH FROM crm.fecha) / 2)
                   AND crm2.fecha BETWEEN gl2.fec_i AND NVL(gl2.fec_f, DATE '9999-12-31')), 0)
    , 2)                                     AS pct_inasistencia
FROM MJV_inasistencia i
JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = i.id_grupo
                                   AND crm.id_club  = i.id_club
                                   AND crm.fecha    = i.fecha_reunion
                                   AND crm.isbn     = i.isbn
JOIN MJV_lector l ON l.id_lector = i.id_lector
JOIN MJV_club   c ON c.id_club   = i.id_club
GROUP BY
    EXTRACT(YEAR FROM crm.fecha),
    CEIL(EXTRACT(MONTH FROM crm.fecha) / 2),
    i.id_lector, l.p_nombre, l.p_apellido, l.s_apellido,
    i.id_club, c.nombre_club, i.id_grupo
ORDER BY pct_inasistencia DESC;
/

CREATE OR REPLACE VIEW MJV_vw_estado_discusiones AS
SELECT
    c.id_club,
    c.nombre_club,
    g.id_grupo,
    INITCAP(g.tipo_grupo) AS tipo_grupo,
    lb.isbn,
    lb.titulo,
    COUNT(crm.fecha)                                          AS sesiones_realizadas,
    MAX(crm.fecha)                                            AS ultima_sesion,
    MAX(CASE WHEN crm.ultima = 'S' THEN crm.valoracion END)  AS valoracion_final,
    MAX(CASE WHEN crm.ultima = 'S' THEN crm.conclusiones END) AS conclusiones_finales,
    CASE
        WHEN MAX(CASE WHEN crm.ultima = 'S' THEN 1 ELSE 0 END) = 1 THEN 'Cerrada'
        WHEN COUNT(CASE WHEN crm.realizada = 'S' THEN 1 END) > 0    THEN 'En curso'
        ELSE 'Pendiente'
    END AS estado_discusion
FROM MJV_calendario_reunion_mes crm
JOIN MJV_grupo  g  ON g.id_grupo = crm.id_grupo AND g.id_club = crm.id_club
JOIN MJV_club   c  ON c.id_club  = crm.id_club
JOIN MJV_libro  lb ON lb.isbn    = crm.isbn
GROUP BY c.id_club, c.nombre_club, g.id_grupo, g.tipo_grupo, lb.isbn, lb.titulo
ORDER BY c.nombre_club, g.id_grupo, lb.titulo;
/

CREATE OR REPLACE VIEW MJV_vw_moderadores_activos AS
SELECT
    c.id_club,
    c.nombre_club,
    crm.mod_id_lector AS id_moderador,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_moderador,
    COUNT(DISTINCT crm.isbn || '|' || crm.id_grupo)  AS libros_en_moderacion,
    MIN(crm.fecha)                                    AS fecha_inicio_moderacion_mas_antigua,
    LISTAGG(lb.titulo, '; ') WITHIN GROUP (ORDER BY lb.titulo) AS titulos_en_moderacion
FROM MJV_calendario_reunion_mes crm
JOIN MJV_club   c  ON c.id_club   = crm.id_club
JOIN MJV_lector l  ON l.id_lector = crm.mod_id_lector
JOIN MJV_libro  lb ON lb.isbn     = crm.isbn
WHERE crm.realizada = 'S'
  AND crm.ultima    = 'N'
GROUP BY c.id_club, c.nombre_club, crm.mod_id_lector, l.p_nombre, l.p_apellido, l.s_apellido
ORDER BY c.nombre_club, libros_en_moderacion DESC;
/

-- =============================================================================
-- AC-F1: Vista de Historial de Pagos de Membresía
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_historial_pagos_membresia AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_completo,
    l.doc_identidad,
    c.id_club,
    c.nombre_club,
    pm.fecha_i        AS inicio_membresia,
    pm.fecha_pago,
    pm.monto          AS monto_usd,
    CEIL(MONTHS_BETWEEN(pm.fecha_pago, pm.fecha_i) / 12) AS anio_membresia_pagado
FROM
    MJV_pago_membresia pm
    JOIN MJV_lector l ON l.id_lector = pm.id_lector
    JOIN MJV_club   c ON c.id_club   = pm.id_club
ORDER BY
    c.nombre_club,
    l.p_apellido,
    pm.fecha_pago DESC;
/

-- =============================================================================
-- AC-P1: Función Round-Robin para asignación equitativa de grupos
-- =============================================================================
CREATE OR REPLACE FUNCTION MJV_fn_grupo_menos_lleno (
    p_id_club    IN NUMBER,
    p_tipo_grupo IN VARCHAR2
) RETURN NUMBER IS
    v_id_grupo NUMBER;
BEGIN
    SELECT id_grupo
      INTO v_id_grupo
      FROM (
        SELECT g.id_grupo,
               COUNT(gl.id_lector) AS miembros_activos
          FROM MJV_grupo g
          LEFT JOIN MJV_g_lec gl ON gl.id_grupo = g.id_grupo
                                 AND gl.id_club  = g.id_club
                                 AND gl.fec_f    IS NULL
         WHERE g.id_club    = p_id_club
           AND g.tipo_grupo = LOWER(TRIM(p_tipo_grupo))
         GROUP BY g.id_grupo
         ORDER BY miembros_activos ASC, g.id_grupo ASC
      )
     WHERE ROWNUM = 1;
    RETURN v_id_grupo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END MJV_fn_grupo_menos_lleno;
/

-- =============================================================================
-- AC-F1 / REPORTES: Vista MJV_vw_r1_libros_analizados corregida
-- Corrige: vincula por membresía activa del lector (no solo por moderador)
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_r1_libros_analizados AS
SELECT DISTINCT
    gl.id_lector,
    lb.isbn,
    lb.titulo,
    LISTAGG(NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''), ', ')
        WITHIN GROUP (ORDER BY a.id_autor) AS autores,
    crm.valoracion,
    crm.conclusiones,
    c.id_club,
    c.nombre_club,
    g.tipo_grupo,
    crm.fecha AS fecha_cierre
FROM MJV_g_lec gl
    JOIN MJV_grupo g ON g.id_grupo = gl.id_grupo AND g.id_club = gl.id_club
    JOIN MJV_club c ON c.id_club = gl.id_club
    JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = gl.id_grupo
                                       AND crm.id_club  = gl.id_club
                                       AND crm.ultima   = 'S'
                                       AND crm.valoracion IS NOT NULL
                                       AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, DATE '9999-12-31')
    JOIN MJV_libro lb ON lb.isbn = crm.isbn
    JOIN MJV_libro_autor la ON la.isbn = lb.isbn
    JOIN MJV_autor a ON a.id_autor = la.id_autor
GROUP BY
    gl.id_lector, lb.isbn, lb.titulo, crm.valoracion,
    crm.conclusiones, c.id_club, c.nombre_club, g.tipo_grupo, crm.fecha;
/

-- =============================================================================
-- AC-F1 / REPORTES: Vista MJV_vw_r4_crecimiento_anual corregida
-- Corrige: orden por país ASC, año DESC (no solo por crecimiento)
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_r4_crecimiento_anual AS
WITH
miembros_por_anio AS (
    SELECT hm.id_club, EXTRACT(YEAR FROM hm.fecha_i) AS anio, COUNT(*) AS nuevos_miembros
    FROM MJV_historia_membresia hm
    GROUP BY hm.id_club, EXTRACT(YEAR FROM hm.fecha_i)
),
ingresos_por_anio AS (
    SELECT pm.id_club, EXTRACT(YEAR FROM pm.fecha_pago) AS anio, SUM(pm.monto) AS ingresos_usd
    FROM MJV_pago_membresia pm
    JOIN MJV_club c ON c.id_club = pm.id_club
    WHERE c.cuota_anual = 'S'
    GROUP BY pm.id_club, EXTRACT(YEAR FROM pm.fecha_pago)
),
anios_por_club AS (
    SELECT id_club, anio FROM miembros_por_anio
    UNION
    SELECT id_club, anio FROM ingresos_por_anio
),
consolidado AS (
    SELECT ac.id_club, ac.anio,
           NVL(m.nuevos_miembros, 0) AS nuevos_miembros,
           NVL(i.ingresos_usd, 0)    AS ingresos_usd,
           LAG(NVL(m.nuevos_miembros, 0)) OVER (PARTITION BY ac.id_club ORDER BY ac.anio) AS miembros_anio_anterior,
           LAG(NVL(i.ingresos_usd, 0))    OVER (PARTITION BY ac.id_club ORDER BY ac.anio) AS ingresos_anio_anterior
    FROM anios_por_club ac
    LEFT JOIN miembros_por_anio m ON m.id_club = ac.id_club AND m.anio = ac.anio
    LEFT JOIN ingresos_por_anio i ON i.id_club = ac.id_club AND i.anio = ac.anio
)
SELECT
    c.id_club,
    c.nombre_club,
    p.nombre_pais,
    ci.nombre_ciudad,
    CASE c.cuota_anual WHEN 'S' THEN 'Independiente' ELSE 'Institucional' END AS tipo_club,
    co.anio,
    co.nuevos_miembros,
    co.ingresos_usd,
    co.miembros_anio_anterior,
    co.ingresos_anio_anterior,
    ROUND(((co.nuevos_miembros - co.miembros_anio_anterior) / NULLIF(co.miembros_anio_anterior, 0)) * 100, 2) AS pct_crecimiento_miembros,
    ROUND(((co.ingresos_usd   - co.ingresos_anio_anterior)  / NULLIF(co.ingresos_anio_anterior,  0)) * 100, 2) AS pct_crecimiento_economico
FROM consolidado co
JOIN MJV_club   c  ON c.id_club  = co.id_club
JOIN MJV_pais   p  ON p.id_pais  = c.id_pais
JOIN MJV_ciudad ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad
ORDER BY
    p.nombre_pais ASC,
    co.anio DESC,
    pct_crecimiento_miembros DESC NULLS LAST,
    pct_crecimiento_economico DESC NULLS LAST;
/