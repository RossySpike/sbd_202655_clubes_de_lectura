CREATE OR REPLACE TRIGGER MJV_tgr_g_lec_validar_edad
BEFORE INSERT ON MJV_g_lec 
FOR EACH ROW
DECLARE
  v_años NUMBER;
  v_tipo_grupo VARCHAR2(10);
  v_fecha_nac DATE;
BEGIN
  SELECT tipo_grupo INTO v_tipo_grupo 
  FROM MJV_grupo 
  WHERE id_grupo = :NEW.id_grupo AND id_club = :NEW.id_club;
  
  SELECT fecha_nac INTO v_fecha_nac 
  FROM MJV_lector 
  WHERE id_lector = :NEW.id_lector;
  
  v_años := FLOOR(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);
  
  IF v_años < 13 AND v_tipo_grupo != 'niños' THEN
    RAISE_APPLICATION_ERROR(-20008, 'Tipo de grupo incorrecto.');
  END IF;
  IF v_años BETWEEN 13 AND 25 AND v_tipo_grupo != 'jovenes' THEN
    RAISE_APPLICATION_ERROR(-20008, 'Tipo de grupo incorrecto.');
  END IF;
  IF v_años > 25 AND v_tipo_grupo != 'adultos' THEN
    RAISE_APPLICATION_ERROR(-20008, 'Tipo de grupo incorrecto.');
  END IF;
END;
/
-- NOTE: trigger para validar mayoria de edad y necesidad de representante
CREATE OR REPLACE TRIGGER MJV_tgr_validar_edad
BEFORE INSERT OR UPDATE ON MJV_lector
FOR EACH ROW
DECLARE
  meses NUMBER;
  edad NUMBER;
BEGIN
  meses := MONTHS_BETWEEN(SYSDATE, :NEW.fecha_nac) ;
  edad := TRUNC(meses/12);
IF edad < 6 THEN
      RAISE_APPLICATION_ERROR(-20000, 'La edad minima es 6.');
END IF;
  IF edad >= 18 THEN
    IF :NEW.id_representante IS NOT NULL OR :NEW.id_representante_lector IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20001, 'Los mayores de edad no necesitan representante');
    END IF;
  ELSE
    IF :NEW.id_representante IS NULL AND :NEW.id_representante_lector IS NULL THEN
      RAISE_APPLICATION_ERROR(-20001, 'Menor de edad sin representante asignado.');
    END IF;
  END IF;
END;
/

-- HC-07: Un lector no puede tener más de una membresía activa en diferentes clubes al mismo tiempo
CREATE OR REPLACE TRIGGER MJV_tgr_un_club_activo
BEFORE INSERT OR UPDATE ON MJV_historia_membresia
FOR EACH ROW
WHEN (NEW.estatus = 'activo')
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM MJV_historia_membresia
  WHERE id_lector = :NEW.id_lector
    AND estatus   = 'activo'
    AND NOT (id_club = :NEW.id_club AND fecha_i = :NEW.fecha_i);

  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20002,
      'El lector ya tiene membresía activa en otro club.');
  END IF;
END;
/

-- HC-08: Grupos de ninos deben iniciar a las 17:00 como maximo para terminar antes de las 19:00
-- (duracion maxima de reunion = 2 horas segun enunciado)
CREATE OR REPLACE TRIGGER MJV_tgr_hora_grupo_ninos
BEFORE INSERT OR UPDATE ON MJV_grupo
FOR EACH ROW
WHEN (NEW.tipo_grupo = 'niños')
BEGIN
  IF TO_CHAR(:NEW.hora_reunion, 'HH24:MI') > '17:00' THEN -- here '>' -> '>='
    RAISE_APPLICATION_ERROR(-20003,
      'Los grupos de niños deben iniciar a más tardar a las 17:00 para terminar antes de las 19:00.');
  END IF;
END;
/

-- HC-10: Al retirar un miembro, motivo_retiro y fecha_f son obligatorios
CREATE OR REPLACE TRIGGER MJV_tgr_retiro_completo
BEFORE INSERT OR UPDATE ON MJV_historia_membresia
FOR EACH ROW
WHEN (NEW.estatus = 'retirado')
BEGIN
  IF :NEW.motivo_retiro IS NULL THEN
    RAISE_APPLICATION_ERROR(-20004, 'El motivo de retiro es obligatorio al cambiar estatus a retirado.');
  END IF;
  IF :NEW.fecha_f IS NULL THEN
    RAISE_APPLICATION_ERROR(-20005, 'La fecha de fin es obligatoria al cambiar estatus a retirado.');
  END IF;
END;
/

-- Convierte un monto entre monedas usando una tasa suministrada por quien ejecuta.
-- p_tasa = unidades de p_moneda_destino por cada 1 unidad de p_moneda_origen.
-- Valida que ambas monedas existan en pais.moneda_local.
CREATE OR REPLACE FUNCTION MJV_conversion_monetaria(
  p_monto          NUMBER,
  p_moneda_origen  VARCHAR2,
  p_moneda_destino VARCHAR2,
  p_tasa           NUMBER
) RETURN NUMBER
IS
  v_origen  VARCHAR2(3) := UPPER(TRIM(p_moneda_origen));
  v_destino VARCHAR2(3) := UPPER(TRIM(p_moneda_destino));
  v_count   NUMBER;
BEGIN
  IF p_monto IS NULL OR p_tasa IS NULL THEN
    RETURN NULL;
  END IF;

    IF v_origen = v_destino THEN
    RAISE_APPLICATION_ERROR(-20105, 'No se puede realizar la conversion porque las monedas son la misma.');
  END IF;

  IF p_tasa <= 0 THEN
    RAISE_APPLICATION_ERROR(-20101, 'La tasa de conversión debe ser mayor que cero.');
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM MJV_pais
  WHERE moneda_local = v_origen;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20102, 'Moneda origen no registrada: ' || v_origen);
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM MJV_pais
  WHERE moneda_local = v_destino;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20103, 'Moneda destino no registrada: ' || v_destino);
  END IF;

  RETURN ROUND(p_monto * p_tasa, 2);
END MJV_conversion_monetaria;  


CREATE OR REPLACE FUNCTION MJV_edad_miembro(p_id_lector NUMBER)
RETURN NUMBER
IS
  v_fecha_nac DATE;
BEGIN
  SELECT fecha_nac INTO v_fecha_nac
  FROM MJV_lector
  WHERE id_lector = p_id_lector;

  -- TRUNC elimina los decimales dejando los años exactos cumplidos
  RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20110, 'Lector no encontrado con ID: ' || p_id_lector);
END MJV_edad_miembro;  
/

CREATE OR REPLACE FUNCTION MJV_antiguedad_en_club_miembro(
  p_id_lector NUMBER,
  p_id_club   NUMBER
) RETURN NUMBER
IS
  v_fecha_i DATE;
  v_fecha_f DATE;
BEGIN
  -- Se busca el registro activo (o el último) en la historia de membresía
  SELECT fecha_i, fecha_f INTO v_fecha_i, v_fecha_f
  FROM MJV_historia_membresia
  WHERE id_lector = p_id_lector
    AND id_club   = p_id_club
    AND estatus   = 'activo';

  RETURN TRUNC(MONTHS_BETWEEN(NVL(v_fecha_f, SYSDATE), v_fecha_i) / 12);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20111,
      'No se encontró una membresía activa para el lector ' || p_id_lector || ' en el club ' || p_id_club);
END MJV_antiguedad_en_club_miembro;  
/

-- Promedio de asistencia (0-100) de los grupos de un tipo en un club, para un mes/año.
-- Por cada grupo: ((oportunidades - inasistencias) / oportunidades) * 100; luego AVG entre grupos.
-- Oportunidad = miembro activo en g_lec que debía asistir a una reunión realizada del mes.
CREATE OR REPLACE FUNCTION MJV_promedio_part_mensual_tipo_grupo(
  p_id_club    NUMBER,
  p_tipo_grupo VARCHAR2,
  p_mes        NUMBER,
  p_anio       NUMBER
) RETURN NUMBER
IS
  v_tipo     VARCHAR2(10) := LOWER(TRIM(p_tipo_grupo));
  v_promedio NUMBER;
BEGIN
  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE_APPLICATION_ERROR(-20120, 'El mes debe estar entre 1 y 12.');
  END IF;

  SELECT ROUND(AVG(((esperadas - faltas) / esperadas) * 100), 2)
  INTO v_promedio
  FROM (
    SELECT g.id_grupo,
      (SELECT COUNT(*)
       FROM MJV_calendario_reunion_mes crm
       JOIN MJV_g_lec gl ON gl.id_grupo = crm.id_grupo AND gl.id_club = g.id_club
       WHERE crm.id_grupo = g.id_grupo
         AND crm.realizada = 'S'
         AND EXTRACT(MONTH FROM crm.fecha) = p_mes
         AND EXTRACT(YEAR FROM crm.fecha)  = p_anio
         AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'))
      ) AS esperadas,
      (SELECT COUNT(*)
       FROM MJV_inasistencia i
       JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = i.id_grupo AND crm.fecha = i.fecha_reunion
       WHERE i.id_grupo = g.id_grupo
         AND i.id_club  = g.id_club
         AND crm.realizada = 'S'
         AND EXTRACT(MONTH FROM crm.fecha) = p_mes
         AND EXTRACT(YEAR FROM crm.fecha)  = p_anio
      ) AS faltas
    FROM MJV_grupo g
    WHERE g.id_club = p_id_club
      AND LOWER(g.tipo_grupo) = v_tipo
  )
  WHERE esperadas > 0;

  RETURN NVL(v_promedio, 0);
END MJV_promedio_part_mensual_tipo_grupo;
/
-- Porcentaje de asistencia (0-100) de un lector en un club durante un bimestre.
-- Bimestre 1 = ene-feb, 2 = mar-abr, 3 = may-jun, 4 = jul-ago, 5 = sep-oct, 6 = nov-dic.
CREATE OR REPLACE FUNCTION MJV_participacion_bimestre_miembro(
  p_id_lector NUMBER,
  p_id_club   NUMBER,
  p_bimestre  NUMBER,
  p_anio      NUMBER
) RETURN NUMBER
IS
  v_mes_ini   NUMBER;
  v_mes_fin   NUMBER;
  v_esperadas NUMBER;
  v_faltas    NUMBER;
BEGIN
  IF p_bimestre < 1 OR p_bimestre > 6 THEN
    RAISE_APPLICATION_ERROR(-20121, 'El bimestre debe estar entre 1 y 6.');
  END IF;
 v_mes_ini := (p_bimestre - 1) * 2 + 1;
  v_mes_fin := p_bimestre * 2;

  -- Reuniones totales programadas y ejecutadas a las que el lector pertenecía en ese bimestre
  SELECT COUNT(*)
  INTO v_esperadas
  FROM MJV_calendario_reunion_mes crm
  JOIN MJV_g_lec gl ON gl.id_grupo = crm.id_grupo AND gl.id_club = p_id_club
  WHERE gl.id_lector = p_id_lector
    AND gl.id_club   = p_id_club
    AND crm.realizada = 'S'
    AND EXTRACT(YEAR FROM crm.fecha) = p_anio
    AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin
    AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'));

  IF v_esperadas = 0 THEN
    RETURN 100;
  END IF;

  -- Inasistencias registradas del lector en ese mismo periodo
  SELECT COUNT(*)
  INTO v_faltas
  FROM MJV_inasistencia i
  JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = i.id_grupo AND crm.fecha = i.fecha_reunion
  WHERE i.id_lector = p_id_lector
    AND i.id_club   = p_id_club
    AND crm.realizada = 'S'
    AND EXTRACT(YEAR FROM crm.fecha) = p_anio
    AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin;

  RETURN ROUND(((v_esperadas - v_faltas) / v_esperadas) * 100, 2);
END MJV_participacion_bimestre_miembro;  
/


-- SPLITS:      Max       Min
-- ADULTOS      30        10
-- JOVENES      15        5
-- NIÑOS        15        10
-- "no se puede incluir un nuevo integrante o realizar un split mientras se esté discutiendo un libro" PAG 3
-- "Cuando se realiza esa división o split se dejan en el grupo original los miembros más antiguos y, luego por cada nueva inscripción se van asignando los nuevos miembros de manera equitativa" PAG 3
-- NOTE: creo que no es necesario revisar por el moderador aca puesto que condicion necesaria de split es que no se este analizando un libro, osea,
-- no hay reuniones que implica que tampoco hay un moderador elegido ya que el moderador tampoco es un puesto unico
CREATE OR REPLACE PROCEDURE MJV_sp_split_grupo(
    p_id_club_original IN NUMBER,
    p_id_grupo_original IN NUMBER,
    p_tipo_grupo IN VARCHAR2,
    p_dia_reunion IN NUMBER,
    p_hora_reunion IN DATE,
    p_nuevo_grupo_id OUT NUMBER
) AS
    v_min_miem NUMBER;
BEGIN
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
    
    -- (traspaso)
    UPDATE MJV_g_lec 
    SET id_grupo = p_nuevo_grupo_id
    WHERE id_club = p_id_club_original AND id_grupo = p_id_grupo_original 
      AND fec_f IS NULL
      AND id_lector IN (
          SELECT id_lector FROM (
              SELECT id_lector, fec_i
              FROM MJV_g_lec
              WHERE id_club = p_id_club_original AND id_grupo = p_id_grupo_original 
                AND fec_f IS NULL
              ORDER BY fec_i DESC
              FETCH FIRST v_min_miem ROWS ONLY
          )
      );
    
    COMMIT;
END;
/


CREATE OR REPLACE TRIGGER MJV_tgr_grupo_lleno
BEFORE INSERT ON MJV_g_lec
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION; 
    f_grupo MJV_grupo%ROWTYPE;
    num_miembros NUMBER;
    max_miem NUMBER;
    v_nuevo_grupo_id NUMBER;
    v_se_hizo_ultima CHAR(1);
BEGIN
    -- 1. Regla de Oro (Se mantiene igual)
    BEGIN
        SELECT ultima INTO v_se_hizo_ultima FROM MJV_calendario_reunion_mes  
        WHERE id_club = :NEW.id_club AND id_grupo = :NEW.id_grupo AND realizada = 'S' 
        ORDER BY fecha DESC FETCH FIRST 1 ROWS ONLY;

        IF v_se_hizo_ultima != 'S' THEN
            RAISE_APPLICATION_ERROR(-20006, 'No se puede agregar miembros mientras se discute un libro');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; 
    END;
    
    -- 2. Datos del Grupo
    SELECT * INTO f_grupo 
    FROM MJV_grupo 
    WHERE id_club = :NEW.id_club AND id_grupo = :NEW.id_grupo;
  
    -- 3. Contar Miembros
    SELECT COUNT(*) INTO num_miembros FROM MJV_g_lec gl 
    WHERE gl.id_club = :NEW.id_club AND gl.id_grupo = :NEW.id_grupo AND gl.fec_f IS NULL;
    
    -- 4. Límites (¡Recuerda que para tu prueba debe estar en 5, aquí lo dejé en 15 como el original!)
    IF f_grupo.tipo_grupo = 'adultos' THEN
      max_miem := 30;
    END IF;
    IF f_grupo.tipo_grupo = 'jovenes' THEN
      max_miem := 15; 
    END IF;
    IF f_grupo.tipo_grupo = 'niños' THEN
      max_miem := 15;
    END IF;
    
    -- 5. Lógica de División
    IF num_miembros >= max_miem THEN
         MJV_sp_split_grupo(
            p_id_club_original => f_grupo.id_club,
            p_id_grupo_original => f_grupo.id_grupo,
            p_tipo_grupo => f_grupo.tipo_grupo,
            p_dia_reunion => f_grupo.dia_reunion,
            p_hora_reunion => f_grupo.hora_reunion,
            p_nuevo_grupo_id => v_nuevo_grupo_id
        );
        :NEW.id_grupo := v_nuevo_grupo_id;
    END IF;
    
    COMMIT;
END;

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


CREATE OR REPLACE TRIGGER MJV_tgr_validar_moderador
BEFORE INSERT OR UPDATE ON MJV_calendario_reunion_mes
FOR EACH ROW
DECLARE
    v_es_miembro_club NUMBER;
    v_tipo_grupo      VARCHAR2(10);
    v_es_adulto       NUMBER;
BEGIN
    -- Validar que el moderador sea miembro activo del mismo club
    SELECT COUNT(*)
    INTO v_es_miembro_club
    FROM MJV_g_lec
    WHERE id_lector = :NEW.mod_id_lector
      AND id_club   = :NEW.id_club
      AND fec_f IS NULL;  -- Miembro activo en el club

    IF v_es_miembro_club = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 
            'El moderador debe ser un miembro activo del mismo club (no de un club asociado).');
    END IF;

    -- tipo de grupo de la reunion
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
        WHERE gl.id_lector = :NEW.mod_id_lector
          AND gl.id_club   = :NEW.id_club
          AND gl.fec_f IS NULL
          AND g.tipo_grupo = 'adultos';

        IF v_es_adulto = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 
                'Para reuniones de grupo de niños, el moderador debe ser miembro de un grupo de adultos del mismo club.');
        END IF;
    END IF;


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'No se encontró información del grupo o club asociado a la reunión.');
END;

CREATE OR REPLACE FUNCTION MJV_fn_obtener_isbn_por_titulo (
    p_titulo IN VARCHAR2
) RETURN VARCHAR2 IS
    v_isbn VARCHAR2(20);
BEGIN
    SELECT isbn 
      INTO v_isbn 
      FROM MJV_obra 
     WHERE UPPER(TRIM(titulo)) = UPPER(TRIM(p_titulo))
       AND ROWNUM = 1; -- Gana tolerancia ante ligeras variantes o duplicados
       
    RETURN v_isbn;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: La obra "' || p_titulo || '" no está registrada en el catálogo general.');
END MJV_fn_obtener_isbn_por_titulo;

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