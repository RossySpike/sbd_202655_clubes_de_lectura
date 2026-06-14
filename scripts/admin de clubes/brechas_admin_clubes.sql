-- =============================================================================
-- BRECHAS DE ADMINISTRACIÓN DE CLUBES - Clubes de Lectura
-- Análisis de reglas de negocio faltantes + código Oracle PL/SQL corrector
-- Nivel: Sistemas de Bases de Datos - Universidad
-- Prefijo de objetos: MJV_
-- =============================================================================
-- RANGO DE ERRORES UTILIZADOS EN ESTE ARCHIVO: -20050 a -20099
-- (Rango -20000 a -20049 ya está ocupado por los archivos existentes)
-- =============================================================================


-- =============================================================================
-- ANÁLISIS DE BRECHAS
-- =============================================================================
--
-- REGLAS YA CUBIERTAS (referencia):
--   [R1]  Edad mínima 6 años y clasificación niños/jóvenes/adultos          → MJV_tgr_validar_edad + MJV_tgr_g_lec_validar_edad
--   [R2]  Menores de 18 requieren representante legal                        → MJV_tgr_validar_edad
--   [R3]  Un lector activo en un solo club a la vez                          → MJV_tgr_un_club_activo
--   [R4]  Grupos de niños inician máximo a las 17:00                         → MJV_tgr_hora_grupo_ninos
--   [R5]  Retiro requiere motivo y fecha_f                                   → MJV_tgr_retiro_completo
--   [R6]  Auto-split al exceder capacidad máxima                             → MJV_tgr_grupo_lleno + MJV_sp_split_grupo
--   [R7]  Miembro debe tener membresía activa para estar en un grupo         → MJV_tgr_validar_membresia_glec
--   [R8]  Moderador debe ser miembro activo; niños → moderador de adultos    → MJV_tgr_validar_moderador
--   [R9]  Solo miembros activos pueden registrar pagos                       → MJV_tgr_validar_membresia_pago
--   [R10] Solvencia al retirarse (pagos al día + aviso 1 mes)               → MJV_fn_validar_solvencia_retiro
--   [R11] Cuota mínima 100 USD por año con conversión monetaria              → MJV_sp_registrar_pago_membresia
--   [R12] Regla de oro: no inscribir/split con libro bajo discusión          → MJV_tgr_grupo_lleno (parcial, ver BRECHA 3)
--
-- =============================================================================
-- BRECHAS IDENTIFICADAS:
-- =============================================================================
--
-- [BRECHA 1] No se bloquea la inscripción de un lector que tiene DEUDAS
--            HISTÓRICAS en otro club anterior.  El enunciado (pág. 6) indica:
--            "no se aceptan nuevos miembros que tengan deudas pendientes en
--            el club anterior". MJV_sp_inscribir_miembro no verifica esto.
--            SOLUCIÓN: Función MJV_fn_tiene_deuda_historica + validación en
--            MJV_sp_inscribir_miembro.
--
-- [BRECHA 2] No se impide el REINGRESO PERMANENTE por motivo 'inasistencia'.
--            El enunciado (pág. 7) dice: "si un integrante deja de asistir a
--            más del 30% en un bimestre es retirado del club y NO SE PUEDE
--            VOLVER A UNIR AL MISMO".  MJV_sp_inscribir_miembro no consulta
--            el historial de retiros del lector en ese club.
--            SOLUCIÓN: Función MJV_fn_vetado_por_inasistencia + validación en
--            MJV_sp_inscribir_miembro.
--
-- [BRECHA 3] La "Regla de Oro" (no inscribir ni hacer split mientras se
--            discute un libro) está implementada INCORRECTAMENTE en
--            MJV_tgr_grupo_lleno: comprueba si la ÚLTIMA reunión realizada
--            tiene ultima='S', pero eso es al revés — ultima='S' significa
--            que ya cerró el debate, no que está abierto. La condición debe
--            bloquear cuando existe una reunión realizada con ultima='N'.
--            Además, el check vive solo en el trigger del split; la inserción
--            directa en MJV_g_lec también debe estar protegida.
--            SOLUCIÓN: Función MJV_fn_grupo_discutiendo_libro + trigger
--            MJV_tgr_bloquear_inscripcion_libro_activo correcto.
--
-- [BRECHA 4] El moderador de una reunión NO puede estar moderando
--            SIMULTÁNEAMENTE otro grupo con un libro aún en discusión.
--            El enunciado (pág. 6) dice: "Un mismo moderador no está
--            simultáneamente asignado a más de un grupo – cuando terminen las
--            reuniones de discusión del libro que está moderando entonces la
--            persona estaría disponible para otra moderación."
--            MJV_tgr_validar_moderador no comprueba esto.
--            SOLUCIÓN: Validación adicional en MJV_tgr_validar_moderador.
--
-- [BRECHA 5] No existe la automatización del RETIRO AUTOMÁTICO por exceder
--            el 30% de inasistencias en un bimestre.  Se tienen la función de
--            cálculo y la tabla MJV_inasistencia, pero ningún trigger dispara
--            el retiro al registrar una inasistencia.
--            SOLUCIÓN: Función MJV_fn_pct_inasistencia_bimestre + trigger
--            MJV_tgr_retirar_por_inasistencia.
--
-- [BRECHA 6] Los clubes DEPENDIENTES (cuota_anual='N') no deberían permitir
--            el registro de pagos de membresía.  Actualmente nada lo impide.
--            SOLUCIÓN: Validación en MJV_sp_registrar_pago_membresia y en el
--            trigger MJV_tgr_validar_membresia_pago.
--
-- [BRECHA 7] El motivo de retiro ingresado en MJV_sp_retirar_miembro no es
--            validado contra el dominio permitido antes de ejecutar el UPDATE.
--            Si el usuario envía un valor fuera del CHECK constraint de la
--            tabla, el error llega como ORA-02290 sin mensaje de negocio.
--            SOLUCIÓN: Guardia explícita en MJV_sp_retirar_miembro.
-- =============================================================================


-- =============================================================================
-- BRECHA 1 — Bloqueo de inscripción por deudas históricas en club anterior
-- =============================================================================
-- Función auxiliar: devuelve TRUE (1) si el lector tiene saldo pendiente en
-- cualquier membresía retirada de otro club.
-- Lógica: suma pagado vs. (años_iniciados * 100) para cada período retirado.
-- =============================================================================
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


-- =============================================================================
-- BRECHA 2 — Bloqueo permanente de reingreso por motivo 'inasistencia'
-- =============================================================================
-- Función auxiliar: devuelve 1 si el lector fue retirado por inasistencia
-- en ese club específico (veto permanente).
-- =============================================================================
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
-- BRECHA 3 — Función canónica para detectar libro en discusión activa
-- =============================================================================
-- Reemplaza la lógica inversa del trigger existente.
-- Devuelve 1 si el grupo tiene al menos una reunión REALIZADA cuyo libro
-- NO ha sido cerrado (ultima = 'N'), lo que significa que la discusión
-- está en curso.
-- =============================================================================
CREATE OR REPLACE FUNCTION MJV_fn_grupo_discutiendo_libro (
    p_id_club  IN NUMBER,
    p_id_grupo IN NUMBER
) RETURN NUMBER   -- 1 = discusión activa, 0 = sin discusión activa
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.id_club  = p_id_club
       AND crm.id_grupo = p_id_grupo
       AND crm.realizada = 'S'
       AND crm.ultima    = 'N';   -- Reuniones realizadas pero el libro aún no cierra

    RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END MJV_fn_grupo_discutiendo_libro;
/


-- =============================================================================
-- BRECHA 3 (continuación) — Trigger corregido para la Regla de Oro
-- =============================================================================
-- Reemplaza la lógica incorrecta dentro de MJV_tgr_grupo_lleno y añade
-- la misma guardia para inserciones directas en MJV_g_lec.
-- Nota: Al ser BEFORE INSERT, puede leer MJV_calendario_reunion_mes sin
-- problema de tabla mutante (es una tabla diferente a MJV_g_lec).
-- =============================================================================
CREATE OR REPLACE TRIGGER MJV_tgr_bloquear_inscripcion_libro_activo
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
    v_discutiendo NUMBER;
BEGIN
    v_discutiendo := MJV_fn_grupo_discutiendo_libro(:NEW.id_club, :NEW.id_grupo);

    IF v_discutiendo = 1 THEN
        RAISE_APPLICATION_ERROR(
            -20050,
            'REGLA DE ORO: No se puede inscribir un nuevo miembro al grupo '
            || :NEW.id_grupo
            || ' mientras se esté discutiendo un libro activamente.'
        );
    END IF;
END MJV_tgr_bloquear_inscripcion_libro_activo;
/

-- =============================================================================
-- BRECHA 3 (continuación) — Corrección del split en MJV_sp_split_grupo
-- =============================================================================
-- El procedimiento de split también debe verificar la regla de oro antes de
-- dividir el grupo. Se reemplaza el procedimiento con la guardia correcta.
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
    -- Guardia de Regla de Oro (versión corregida)
    v_discutiendo := MJV_fn_grupo_discutiendo_libro(p_id_club_original, p_id_grupo_original);
    IF v_discutiendo = 1 THEN
        RAISE_APPLICATION_ERROR(
            -20051,
            'REGLA DE ORO: No se puede realizar el split del grupo '
            || p_id_grupo_original
            || ' mientras se esté discutiendo un libro activamente.'
        );
    END IF;

    IF p_tipo_grupo = 'adultos' THEN
        v_min_miem := 10;
    ELSIF p_tipo_grupo = 'jovenes' THEN
        v_min_miem := 5;
    ELSE  -- niños
        v_min_miem := 10;
    END IF;

    -- Crear nuevo grupo
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (p_id_club_original, p_tipo_grupo, SYSDATE, p_dia_reunion, p_hora_reunion)
    RETURNING id_grupo INTO p_nuevo_grupo_id;

    -- Mover los miembros más recientes (los últimos en unirse) al nuevo grupo
    -- Los más ANTIGUOS se quedan en el grupo original (enunciado pág. 3)
    UPDATE MJV_g_lec
       SET id_grupo = p_nuevo_grupo_id
     WHERE id_club  = p_id_club_original
       AND id_grupo = p_id_grupo_original
       AND fec_f    IS NULL
       AND id_lector IN (
           SELECT id_lector
             FROM (
               SELECT id_lector, fec_i
                 FROM MJV_g_lec
                WHERE id_club  = p_id_club_original
                  AND id_grupo = p_id_grupo_original
                  AND fec_f    IS NULL
                ORDER BY fec_i DESC
               FETCH FIRST v_min_miem ROWS ONLY
             )
       );

    COMMIT;
END MJV_sp_split_grupo;
/


-- =============================================================================
-- BRECHA 4 — Moderador ocupado en discusión activa de otro grupo
-- =============================================================================
-- Reemplaza MJV_tgr_validar_moderador añadiendo la validación de
-- "un moderador no está simultáneamente asignado a más de un grupo".
-- Un moderador está "ocupado" si está asignado como mod en alguna reunión
-- de otro grupo cuyo libro aún no ha cerrado (ultima='N').
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
    -- [R8-a] El moderador debe ser miembro activo del mismo club
    SELECT COUNT(*)
      INTO v_es_miembro_club
      FROM MJV_g_lec
     WHERE id_lector = :NEW.mod_id_lector
       AND id_club   = :NEW.id_club
       AND fec_f     IS NULL;

    IF v_es_miembro_club = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20030,
            'El moderador debe ser un miembro activo del mismo club.'
        );
    END IF;

    -- [R8-b] Para grupos de niños el moderador debe ser de un grupo adultos
    SELECT tipo_grupo
      INTO v_tipo_grupo
      FROM MJV_grupo
     WHERE id_grupo = :NEW.id_grupo
       AND id_club  = :NEW.id_club;

    IF v_tipo_grupo = 'niños' THEN
        SELECT COUNT(*)
          INTO v_es_adulto
          FROM MJV_g_lec gl
          JOIN MJV_grupo g ON gl.id_grupo = g.id_grupo AND gl.id_club = g.id_club
         WHERE gl.id_lector  = :NEW.mod_id_lector
           AND gl.id_club    = :NEW.id_club
           AND gl.fec_f      IS NULL
           AND g.tipo_grupo  = 'adultos';

        IF v_es_adulto = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20031,
                'Para reuniones de niños el moderador debe pertenecer a un grupo de adultos del mismo club.'
            );
        END IF;
    END IF;

    -- [BRECHA 4] Un moderador no puede estar moderando simultáneamente
    -- otro grupo con un libro en discusión activa (ultima='N').
    -- Se excluye el propio grupo/isbn de la fila que se está insertando
    -- para permitir registrar la siguiente reunión del mismo libro.
    SELECT COUNT(*)
      INTO v_mod_ocupado
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.mod_id_lector = :NEW.mod_id_lector
       AND crm.id_club        = :NEW.id_club
       AND crm.realizada      = 'S'
       AND crm.ultima         = 'N'
       -- Excluir el mismo grupo+libro que se está registrando
       AND NOT (crm.id_grupo = :NEW.id_grupo AND crm.isbn = :NEW.isbn);

    IF v_mod_ocupado > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20052,
            'El moderador (ID: ' || :NEW.mod_id_lector
            || ') ya está moderando activamente la discusión de otro libro en otro grupo. '
            || 'Solo puede tomar una nueva moderación cuando termine la discusión actual.'
        );
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20032,
            'No se encontró información del grupo o club asociado a la reunión.'
        );
END MJV_tgr_validar_moderador;
/


-- =============================================================================
-- BRECHA 5 — Retiro automático por superar 30% de inasistencias en un bimestre
-- =============================================================================
-- POR QUÉ NO SE USA PRAGMA AUTONOMOUS_TRANSACTION + lectura de MJV_inasistencia:
--   El trigger es AFTER INSERT ON MJV_inasistencia. Con AUTONOMOUS_TRANSACTION,
--   Oracle abre una transacción separada que NO ve la fila recién insertada
--   (aún no comiteada por la transacción padre). El conteo de inasistencias
--   quedaría siempre 1 por debajo del real → el umbral nunca se detecta bien.
--
-- SOLUCIÓN: calcular directamente con los valores de :NEW (ya disponibles en
--   el contexto del trigger) sin releer MJV_inasistencia. La función recibe
--   las inasistencias ya comiteadas del bimestre y suma 1 (la fila nueva) para
--   comparar contra las reuniones esperadas. Los UPDATEs van a tablas distintas
--   (MJV_g_lec y MJV_historia_membresia) → sin problema de tabla mutante.
--   No se necesita PRAGMA: el trigger AFTER puede hacer DML en otras tablas.
-- =============================================================================
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


-- Trigger AFTER INSERT sobre MJV_inasistencia.
-- Sin PRAGMA AUTONOMOUS_TRANSACTION: los UPDATEs van a MJV_g_lec y
-- MJV_historia_membresia, que son tablas distintas → no hay tabla mutante.
-- La función de cálculo suma +1 internamente para incluir la fila :NEW.
-- =============================================================================
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


-- =============================================================================
-- BRECHA 6 — Bloquear pagos en clubes dependientes (cuota_anual = 'N')
-- =============================================================================
-- Reemplaza MJV_tgr_validar_membresia_pago añadiendo la verificación del
-- tipo de club.  Los clubes dependientes de instituciones no cobran cuota.
-- =============================================================================
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


-- =============================================================================
-- BRECHA 6 (continuación) — Misma guardia en el procedimiento de pago
-- =============================================================================
-- Reemplaza MJV_sp_registrar_pago_membresia con la validación adicional.
-- =============================================================================
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


-- =============================================================================
-- BRECHA 7 + BRECHAS 1 y 2 — Procedure de inscripción reforzado
-- =============================================================================
-- Reemplaza MJV_sp_inscribir_miembro incorporando:
--   · [BRECHA 1] Bloqueo por deuda histórica en club anterior
--   · [BRECHA 2] Bloqueo permanente por retiro por inasistencia en ese club
--   · [BRECHA 7] Validación de motivo de retiro en MJV_sp_retirar_miembro
--                (se resuelve aquí parcialmente y al final del archivo)
-- =============================================================================
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


-- =============================================================================
-- BRECHA 7 — Validación de dominio del motivo de retiro en el procedure
-- =============================================================================
-- Reemplaza MJV_sp_retirar_miembro añadiendo una guardia explícita de negocio
-- antes de intentar el UPDATE, para producir un error claro en lugar del
-- genérico ORA-02290 del CHECK constraint.
-- =============================================================================
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


-- =============================================================================
-- RESUMEN DE OBJETOS CREADOS / MODIFICADOS EN ESTE ARCHIVO
-- =============================================================================
--
--  FUNCIONES NUEVAS:
--    · MJV_fn_tiene_deuda_historica(p_id_lector)           → BRECHA 1
--    · MJV_fn_vetado_por_inasistencia(p_id_lector,p_id_club) → BRECHA 2
--    · MJV_fn_grupo_discutiendo_libro(p_id_club,p_id_grupo) → BRECHA 3
--    · MJV_fn_pct_inasistencia_bimestre(p_id_lector,p_id_club,p_fecha) → BRECHA 5
--
--  TRIGGERS NUEVOS:
--    · MJV_tgr_bloquear_inscripcion_libro_activo  (BEFORE INSERT ON MJV_g_lec)          → BRECHA 3
--    · MJV_tgr_retirar_por_inasistencia           (AFTER INSERT ON MJV_inasistencia)    → BRECHA 5
--
--  TRIGGERS REEMPLAZADOS (CREATE OR REPLACE):
--    · MJV_tgr_validar_moderador   → añade BRECHA 4 (moderador ocupado)
--    · MJV_tgr_validar_membresia_pago → añade BRECHA 6 (club sin cuota)
--
--  PROCEDURES REEMPLAZADOS (CREATE OR REPLACE):
--    · MJV_sp_split_grupo          → corrección Regla de Oro + BRECHA 3
--    · MJV_sp_inscribir_miembro    → añade BRECHAS 1 y 2
--    · MJV_sp_registrar_pago_membresia → añade BRECHA 6
--    · MJV_sp_retirar_miembro      → añade BRECHA 7 (validación motivo)
--
-- =============================================================================
