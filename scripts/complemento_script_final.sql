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

CREATE OR REPLACE PROCEDURE MJV_sp_inscribir_miembro (
    pi_p_nombre        IN VARCHAR2,
    pi_p_apellido      IN VARCHAR2,
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
    pi_s_nombre        IN VARCHAR2 DEFAULT NULL,
    pi_doc_rep         IN VARCHAR2 DEFAULT NULL, -- Ahora pedimos la Cédula/Documento
    pi_tipo_rep        IN VARCHAR2 DEFAULT NULL  -- 'LECTOR' o 'EXTERNO'
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
    
    -- Variables para la lógica del representante
    v_id_rep        NUMBER := NULL;
    v_id_rep_lector NUMBER := NULL;
BEGIN
    -- 1. Resolver el nombre del club y el país a sus respectivos IDs
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);
    
    SELECT id_pais INTO v_id_pais_nac 
      FROM MJV_pais 
     WHERE UPPER(TRIM(nombre_pais)) = UPPER(TRIM(pi_nombre_pais_nac))
       AND ROWNUM = 1;

    -- 2. Resolver los títulos de libros preferidos a sus respectivos ISBN
    v_isbn1 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref1);
    v_isbn2 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref2);
    v_isbn3 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref3);

    -- 3. LÓGICA DE REPRESENTANTE SOLICITADA
    IF pi_doc_rep IS NOT NULL AND pi_tipo_rep IS NOT NULL THEN
        IF UPPER(TRIM(pi_tipo_rep)) = 'LECTOR' THEN
            v_id_rep_lector := MJV_fn_obtener_id_rep_por_doc(pi_doc_rep, pi_tipo_rep);
        ELSIF UPPER(TRIM(pi_tipo_rep)) = 'EXTERNO' THEN
            v_id_rep := MJV_fn_obtener_id_rep_por_doc(pi_doc_rep, pi_tipo_rep);
        ELSE
            RAISE_APPLICATION_ERROR(-20012, 'Error: El tipo de representante debe ser LECTOR o EXTERNO.');
        END IF;
    END IF;

    -- 4. Insertar datos en la tabla padre
    -- El trigger MJV_tgr_validar_edad hará la validación automática de tu fecha_nac vs los v_id_rep
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

    -- 5. Obtener la edad EXACTA
    v_age := MJV_edad_miembro(v_id_lector);

    -- 6. Registrar las preferencias
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn3, 3);

    -- 7. Iniciar historial de membresía activa
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus)
    VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    -- 8. Clasificar el tipo de grupo
    IF v_age BETWEEN 6 AND 12 THEN
        v_tipo_grupo := 'niños';
    ELSIF v_age BETWEEN 13 AND 25 THEN
        v_tipo_grupo := 'jovenes';
    ELSIF v_age > 25 THEN
        v_tipo_grupo := 'adultos';
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Error: La edad mínima es de 6 años.');
    END IF;

    -- 9. Buscar/Crear el grupo
    BEGIN
        SELECT id_grupo
          INTO v_id_grupo
          FROM MJV_grupo
         WHERE id_club = v_id_club
           AND tipo_grupo = v_tipo_grupo
           AND ROWNUM = 1; 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
            VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS'))
            RETURNING id_grupo INTO v_id_grupo;
    END;

    -- 10. Asignar al grupo 
    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f)
    VALUES (v_id_lector, v_id_club, SYSDATE, v_id_grupo, SYSDATE, NULL);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inscripción exitosa. ID de Lector asignado: ' || v_id_lector || ' | Grupo: ' || v_tipo_grupo);
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

create or replace TRIGGER MJV_tgr_validar_membresia_pago
BEFORE INSERT ON MJV_pago_membresia
FOR EACH ROW
DECLARE
  v_lector_estatus VARCHAR2(8);
BEGIN
    SELECT estatus INTO v_lector_estatus 
      FROM MJV_historia_membresia 
     WHERE id_club = :NEW.id_club 
       AND id_lector = :NEW.id_lector 
       AND estatus = 'activo';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'Error: No se puede registrar el pago. El lector no tiene una membresía activa en este club.');
END;
/

CREATE OR REPLACE PROCEDURE MJV_sp_registrar_pago_membresia (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_monto         IN NUMBER,
    pi_moneda        IN VARCHAR2,
    pi_tasa          IN NUMBER      
) IS
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_fecha_i   DATE;
    v_monto_usd NUMBER;
BEGIN
    -- 1. Obtener el ID del Lector por su Cédula
    BEGIN
        SELECT id_lector INTO v_id_lector 
          FROM MJV_lector 
         WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error: No se encontró ningún lector registrado con el documento: ' || pi_doc_identidad);
    END;

    -- 2. Obtener el ID del Club
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);
    
    -- 3. Obtener la FECHA_I de la membresía activa
    -- (Esto cumple con tu columna FECHA_I y valida que el lector esté activo en el club)
    BEGIN
        SELECT fecha_i INTO v_fecha_i
          FROM MJV_historia_membresia
         WHERE id_lector = v_id_lector
           AND id_club = v_id_club
           AND estatus = 'activo';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007, 'Error: El lector no tiene una membresía activa en este club para asociar el pago.');
    END;

    -- 4. Convertir el monto ingresado a dólares
    v_monto_usd := MJV_conversion_monetaria(pi_monto, pi_moneda, 'USD', pi_tasa);

    -- 5. Validar la cuota mínima de 100 USD
    IF v_monto_usd < 100 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Error de Pago: El monto ingresado equivale a ' || ROUND(v_monto_usd, 2) || ' USD. La cuota anual mínima es de 100 USD.');
    END IF;

    -- 6. Insertar el pago con las columnas exactas de la tabla
    -- Nota: Omitimos ID_PAGO porque la imagen muestra que tiene un DEFAULT / SEQUENCE automático.
    INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
    VALUES (v_id_lector, v_id_club, v_fecha_i, SYSDATE, v_monto_usd);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pago registrado exitosamente en la base de datos por: ' || ROUND(v_monto_usd, 2) || ' USD.');

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

CREATE OR REPLACE PROCEDURE MJV_sp_retirar_miembro (
    pi_doc_identidad IN VARCHAR2,
    pi_nombre_club   IN VARCHAR2,
    pi_motivo_retiro IN VARCHAR2
) IS
    v_id_lector NUMBER;
    v_id_club   NUMBER;
    v_msj_error VARCHAR2(200);
BEGIN
    -- 1. Identificación
    SELECT id_lector INTO v_id_lector 
      FROM MJV_lector 
     WHERE UPPER(TRIM(doc_identidad)) = UPPER(TRIM(pi_doc_identidad));

    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);

    -- 2. LLAMADA A LA NUEVA FUNCIÓN DE VALIDACIÓN
    v_msj_error := MJV_fn_validar_solvencia_retiro(v_id_lector, v_id_club);
    
    IF v_msj_error IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20040, 'RETIRO DENEGADO: ' || v_msj_error);
    END IF;

    -- 3. Ejecutar Retiro (Solo si pasó la validación)
    UPDATE MJV_g_lec
       SET fec_f = SYSDATE
     WHERE id_lector = v_id_lector AND id_club = v_id_club AND fec_f IS NULL; 

    UPDATE MJV_historia_membresia
       SET estatus = 'retirado', fecha_f = SYSDATE, motivo_retiro = LOWER(TRIM(pi_motivo_retiro))
     WHERE id_lector = v_id_lector AND id_club = v_id_club AND estatus = 'activo';

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error: El miembro ya no estaba activo.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Retiro procesado correctamente.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'No encontrado.');
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