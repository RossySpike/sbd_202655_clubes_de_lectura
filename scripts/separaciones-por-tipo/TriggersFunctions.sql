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
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM MJV_historia_membresia
  WHERE id_lector = :NEW.id_lector
    AND estatus   = 'activo'
    AND id_club != :NEW.id_club;


  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20002,
      'El lector ya tiene membresía activa en otro club.');
  END IF;
  COMMIT;
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
  p_tasa           NUMBER
) RETURN NUMBER
IS
  v_origen        VARCHAR2(3) := UPPER(TRIM(p_moneda_origen));
  v_destino       CONSTANT VARCHAR2(3) := 'USD'; -- Moneda destino fija por requerimiento
  v_count_origen  NUMBER := 0;
BEGIN
  -- 1. Control de Nulos: Si el monto es nulo, no hay nada que transformar
  IF p_monto IS NULL THEN
    RETURN NULL;
  END IF;

  -- 2. Regla de Eficiencia: Si la moneda origen ya es USD, se retorna el monto directo
  -- No se requiere validar tasas ni consultar la base de datos
  IF v_origen = v_destino THEN
    RETURN ROUND(p_monto, 2);
  END IF;

  -- 3. Validaciones obligatorias si es una moneda extranjera distinta a USD
  IF p_tasa IS NULL THEN
    RETURN NULL;
  END IF;

  IF p_tasa <= 0 THEN
    RAISE_APPLICATION_ERROR(-20101, 'La tasa de conversión hacia USD debe ser mayor que cero.');
  END IF;

  -- 4. Verificación de integridad: Validar que la moneda origen exista en el catálogo de países
  SELECT COUNT(*)
    INTO v_count_origen
    FROM MJV_pais
   WHERE moneda_local = v_origen;

  IF v_count_origen = 0 THEN
    RAISE_APPLICATION_ERROR(-20102, 'Moneda origen no registrada en el sistema: ' || v_origen);
  END IF;

  -- 5. Ejecución del cálculo monetario (Monto Origen / Tasa = Equivalente en USD)
  RETURN ROUND(p_monto / p_tasa, 2);
END MJV_conversion_monetaria;
/ 


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
) RETURN VARCHAR2 -- Cambiado a VARCHAR2 para retornar texto
IS
  v_tipo        VARCHAR2(10) := LOWER(TRIM(p_tipo_grupo));
  v_promedio    NUMBER;
  v_nombre_mes  VARCHAR2(20);
BEGIN
  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE_APPLICATION_ERROR(-20120, 'El mes debe estar entre 1 y 12.');
  END IF;

  -- Convertir el número de mes a su nombre en español para una salida más amigable con el usuario 
  v_nombre_mes := INITCAP(TO_CHAR(TO_DATE(p_mes, 'MM'), 'MONTH', 'NLS_DATE_LANGUAGE = SPANISH'));

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
  RETURN TRIM(v_nombre_mes) || ': ' || NVL(TO_CHAR(v_promedio, '990.99'), '0.00') || '%';
END MJV_promedio_part_mensual_tipo_grupo;
/
-- Porcentaje de asistencia (0-100) de un lector en un club durante un bimestre.
-- Bimestre 1 = ene-feb, 2 = mar-abr, 3 = may-jun, 4 = jul-ago, 5 = sep-oct, 6 = nov-dic.
CREATE OR REPLACE FUNCTION MJV_participacion_bimestre_miembro(
    p_id_lector NUMBER,
    p_id_club   NUMBER,
    p_bimestre  NUMBER,
    p_anio      NUMBER
) RETURN VARCHAR2 -- Cambiado a VARCHAR2 para retornar texto
IS
    v_mes_ini         NUMBER;
    v_mes_fin         NUMBER;
    v_esperadas       NUMBER;
    v_faltas          NUMBER;
    v_nombre_bimestre VARCHAR2(40);
BEGIN
    IF p_bimestre < 1 OR p_bimestre > 6 THEN
        RAISE_APPLICATION_ERROR(-20121, 'El bimestre debe estar entre 1 y 6.');
    END IF;
    
    -- Determinar el rango de meses
    v_mes_ini := (p_bimestre - 1) * 2 + 1;
    v_mes_fin := p_bimestre * 2;

    -- Mapeo estricto de nombres de bimestres separados por guion
    v_nombre_bimestre := CASE p_bimestre
        WHEN 1 THEN 'Enero-Febrero'
        WHEN 2 THEN 'Marzo-Abril'
        WHEN 3 THEN 'Mayo-Junio'
        WHEN 4 THEN 'Julio-Agosto'
        WHEN 5 THEN 'Septiembre-Octubre'
        WHEN 6 THEN 'Noviembre-Diciembre'
    END;

    -- Cálculo del universo obligatorio del lector (Se mantiene tu lógica)
    SELECT COUNT(*)
      INTO v_esperadas
      FROM MJV_calendario_reunion_mes crm
     WHERE crm.id_club = p_id_club
       AND crm.realizada = 'S'
       AND EXTRACT(YEAR FROM crm.fecha) = p_anio
       AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin
       AND crm.id_grupo = (
           SELECT gl.id_grupo 
             FROM MJV_g_lec gl 
            WHERE gl.id_lector = p_id_lector 
              AND gl.id_club = p_id_club 
              AND EXTRACT(YEAR FROM gl.fec_i) <= p_anio
              AND ROWNUM = 1
       );

    IF v_esperadas = 0 THEN
        RETURN v_nombre_bimestre || ': 0.00% (Inasistencias)';
    END IF;

    -- Inasistencias registradas
    SELECT COUNT(*)
      INTO v_faltas
      FROM MJV_inasistencia i
      JOIN MJV_calendario_reunion_mes crm 
        ON crm.id_club = i.id_club 
       AND crm.id_grupo = i.id_grupo 
       AND crm.fecha = i.fecha_reunion 
       AND crm.isbn = i.isbn
     WHERE i.id_lector = p_id_lector
       AND i.id_club   = p_id_club
       AND crm.realizada = 'S'
       AND EXTRACT(YEAR FROM crm.fecha) = p_anio
       AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin;

    -- Retorna el texto formateado con los dos meses y el % de inasistencia
    RETURN v_nombre_bimestre || ': ' || TO_CHAR(ROUND((v_faltas / v_esperadas) * 100, 2), '990.99') || '%';
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