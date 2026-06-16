-- Script entregable de triggers, procedimientos, funciones, paquetes y vistas

CREATE OR REPLACE VIEW MJV_v_directorio_lector
  (id_lector, nombre_completo, genero, fecha_nac, telefono, email)
AS
SELECT
  l.id_lector,
  INITCAP(l.p_nombre) || ' ' || INITCAP(l.p_apellido) || ' ' || INITCAP(l.s_apellido),
  DECODE(l.genero, 'F', 'Femenino', 'M', 'Masculino'),
  l.fecha_nac,
  l.telefono,
  l.email
FROM MJV_lector l;


CREATE OR REPLACE VIEW MJV_v_catalogo_libros
  (isbn, titulo, tipo_narrativa, genero, primera_edicion, total_paginas)
AS
SELECT
  li.isbn,
  li.titulo,
  INITCAP(li.tipo_narrativa),
  INITCAP(li.genero),
  li.primera_edicion,
  li.total_paginas
FROM MJV_libro li;


CREATE OR REPLACE VIEW MJV_v_reuniones_mes
  (id_club, nombre_club, id_grupo, tipo_grupo, fecha_reunion,
   hora_grupo, isbn, titulo_libro, nombre_moderador, realizada, es_ultima)
AS
SELECT
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  INITCAP(g.tipo_grupo),
  cr.fecha,
  TO_CHAR(g.hora_reunion, 'HH24:MI'),
  li.isbn,
  li.titulo,
  INITCAP(lm.p_nombre) || ' ' || INITCAP(lm.p_apellido) || ' ' || INITCAP(lm.s_apellido),
  DECODE(cr.realizada, 'S', 'Realizada', 'N', 'Pendiente'),
  DECODE(cr.ultima,    'S', 'Si',        'N', 'No')
FROM  MJV_calendario_reunion_mes cr
JOIN  MJV_grupo                  g  ON  g.id_grupo = cr.id_grupo
                                    AND g.id_club  = cr.id_club
JOIN  MJV_club                   c  ON  c.id_club  = cr.id_club
JOIN  MJV_libro                  li ON  li.isbn    = cr.isbn
JOIN  MJV_lector                 lm ON  lm.id_lector = cr.mod_id_lector;


CREATE OR REPLACE VIEW MJV_v_participacion_mensual_tipo_grupo
  (id_club, nombre_club, tipo_grupo, mes, anio,
   total_inasistencias, total_reuniones, pct_participacion)
AS
SELECT
  c.id_club,
  c.nombre_club,
  INITCAP(g.tipo_grupo),
  EXTRACT(MONTH FROM cr.fecha),
  EXTRACT(YEAR  FROM cr.fecha),
  COUNT(DISTINCT cr.fecha || '|' || cr.id_grupo),
  COUNT(i.fecha_reunion),
  ROUND(
    100 - (
      COUNT(i.fecha_reunion) * 100 /
      NULLIF(
        COUNT(DISTINCT gl.id_lector) * COUNT(DISTINCT cr.fecha || '|' || cr.id_grupo),
        0
      )
    ),
  2)
FROM  MJV_calendario_reunion_mes  cr
JOIN  MJV_grupo                   g  ON  g.id_grupo = cr.id_grupo
                                     AND g.id_club  = cr.id_club
JOIN  MJV_club                    c  ON  c.id_club  = cr.id_club
JOIN  MJV_g_lec                   gl ON  gl.id_grupo = cr.id_grupo
                                     AND gl.id_club  = cr.id_club
                                     AND gl.fec_f IS NULL
LEFT JOIN MJV_inasistencia        i  ON  i.id_grupo     = cr.id_grupo
                                     AND i.id_club      = cr.id_club
                                     AND i.fecha_reunion = cr.fecha
                                     AND i.isbn         = cr.isbn
                                     AND i.id_lector    = gl.id_lector
WHERE cr.realizada = 'S'
GROUP BY
  c.id_club,
  c.nombre_club,
  g.tipo_grupo,
  EXTRACT(MONTH FROM cr.fecha),
  EXTRACT(YEAR  FROM cr.fecha);


CREATE OR REPLACE VIEW MJV_v_ficha_lector
  (id_lector, nombre_completo, edad, nacionalidad, genero, telefono, email,
   id_club, nombre_club, fecha_ingreso, fecha_retiro, estatus, motivo_retiro,
   tipo_grupo, id_grupo, fecha_ingreso_grupo, fecha_retiro_grupo,
   isbn_analizado, titulo_analizado, valoracion_grupo, conclusiones)
AS
SELECT
  l.id_lector,
  INITCAP(l.p_nombre) || ' ' || INITCAP(l.p_apellido) || ' ' || INITCAP(l.s_apellido),
  TRUNC(MONTHS_BETWEEN(SYSDATE, l.fecha_nac) / 12),
  pa.nacionalidad,
  DECODE(l.genero, 'F', 'Femenino', 'M', 'Masculino'),
  l.telefono,
  l.email,
  c.id_club,
  c.nombre_club,
  hm.fecha_i,
  hm.fecha_f,
  INITCAP(hm.estatus),
  INITCAP(hm.motivo_retiro),
  INITCAP(g.tipo_grupo),
  g.id_grupo,
  gl.fec_i,
  gl.fec_f,
  li.isbn,
  li.titulo,
  crm.valoracion,
  crm.conclusiones
FROM MJV_lector l
JOIN MJV_pais pa               ON pa.id_pais   = l.id_pais_nac
JOIN MJV_historia_membresia hm ON hm.id_lector = l.id_lector
JOIN MJV_club c                ON c.id_club    = hm.id_club
JOIN MJV_g_lec gl              ON gl.id_lector = hm.id_lector
                               AND gl.id_club  = hm.id_club
                               AND gl.fecha_i  = hm.fecha_i
JOIN MJV_grupo g               ON g.id_grupo   = gl.id_grupo
                               AND g.id_club   = gl.id_club
LEFT JOIN MJV_calendario_reunion_mes crm
                               ON crm.id_grupo  = gl.id_grupo
                               AND crm.id_club  = gl.id_club
                               AND crm.ultima   = 'S'
                               AND crm.realizada = 'S'
                               AND crm.fecha BETWEEN gl.fec_i
                                 AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'))
LEFT JOIN MJV_libro li         ON li.isbn = crm.isbn;


CREATE OR REPLACE VIEW MJV_v_ficha_club
  (id_club, nombre_club, nombre_ciudad, nombre_pais, cod_postal, cuota_anual,
   grupos_adultos, grupos_jovenes, grupos_ninos,
   isbn, titulo_libro, tipo_narrativa, valoracion_promedio)
AS
SELECT
  c.id_club,
  c.nombre_club,
  ci.nombre_ciudad,
  pa.nombre_pais,
  c.cod_postal,
  DECODE(c.cuota_anual, 'S', 'Si', 'N', 'No'),
  gc.grupos_adultos,
  gc.grupos_jovenes,
  gc.grupos_ninos,
  li.isbn,
  li.titulo,
  INITCAP(li.tipo_narrativa),
  ROUND(AVG(crm.valoracion), 2)
FROM MJV_club c
JOIN MJV_ciudad ci ON ci.id_ciudad = c.id_ciudad
                  AND ci.id_pais   = c.id_pais
JOIN MJV_pais pa   ON pa.id_pais   = c.id_pais
JOIN (
  SELECT
    id_club,
    COUNT(CASE WHEN tipo_grupo = 'adultos' THEN 1 END) AS grupos_adultos,
    COUNT(CASE WHEN tipo_grupo = 'jovenes' THEN 1 END) AS grupos_jovenes,
    COUNT(CASE WHEN tipo_grupo = 'ninos'   THEN 1 END) AS grupos_ninos
  FROM MJV_grupo
  GROUP BY id_club
) gc ON gc.id_club = c.id_club
JOIN MJV_calendario_reunion_mes crm ON crm.id_club   = c.id_club
                                   AND crm.ultima    = 'S'
                                   AND crm.realizada = 'S'
JOIN MJV_libro li ON li.isbn = crm.isbn
GROUP BY
  c.id_club, c.nombre_club, ci.nombre_ciudad, pa.nombre_pais,
  c.cod_postal, c.cuota_anual,
  gc.grupos_adultos, gc.grupos_jovenes, gc.grupos_ninos,
  li.isbn, li.titulo, li.tipo_narrativa;


CREATE OR REPLACE VIEW MJV_v_ficha_libro
  (isbn, titulo, tipo_narrativa, genero, primera_edicion, total_paginas, pais_origen,
   valoracion_promedio_global, id_club, nombre_club, id_grupo, tipo_grupo, conclusiones_grupo)
AS
SELECT
  li.isbn,
  li.titulo,
  INITCAP(li.tipo_narrativa),
  INITCAP(li.genero),
  li.primera_edicion,
  li.total_paginas,
  pa.nombre_pais,
  -- Subconsulta correlacionada para computar el promedio histórico global del libro 
  -- sin alterar el grano de la vista (que incluye el detalle por cada grupo)
  ROUND((SELECT AVG(crm2.valoracion) 
         FROM MJV_calendario_reunion_mes crm2 
         WHERE crm2.isbn = li.isbn AND crm2.ultima = 'S' AND crm2.realizada = 'S'), 2),
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  INITCAP(g.tipo_grupo),
  crm.conclusiones
FROM MJV_libro li
JOIN MJV_pais pa ON pa.id_pais = li.id_pais
LEFT JOIN MJV_calendario_reunion_mes crm ON crm.isbn = li.isbn 
                                        AND crm.ultima = 'S' 
                                        AND crm.realizada = 'S'
LEFT JOIN MJV_grupo g  ON g.id_grupo = crm.id_grupo AND g.id_club = crm.id_club
LEFT JOIN MJV_club c   ON c.id_club = crm.id_club;


CREATE OR REPLACE VIEW MJV_v_crecimiento_clubes
  (anio, id_pais, nombre_pais, total_miembros, pct_crecimiento_miembros, 
   ingresos_membresias, pct_crecimiento_ingresos)
AS
WITH stats_consolidadas AS (
  SELECT 
    p.id_pais,
    p.nombre_pais,
    periodos.anio,
    COUNT(DISTINCT hm.id_lector) AS miembros_totales,
    NVL(SUM(pm.monto), 0) AS ingresos_totales
  FROM MJV_pais p
  JOIN MJV_club c ON c.id_pais = p.id_pais
  CROSS JOIN (
    SELECT DISTINCT EXTRACT(YEAR FROM fecha_i) AS anio FROM MJV_historia_membresia
    UNION
    SELECT DISTINCT EXTRACT(YEAR FROM fecha_pago) AS anio FROM MJV_pago_membresia
  ) periodos
  LEFT JOIN MJV_historia_membresia hm ON hm.id_club = c.id_club 
                                     AND EXTRACT(YEAR FROM hm.fecha_i) <= periodos.anio
                                     AND (hm.fecha_f IS NULL OR EXTRACT(YEAR FROM hm.fecha_f) >= periodos.anio)
  LEFT JOIN MJV_pago_membresia pm     ON pm.id_club = c.id_club 
                                     AND pm.id_lector = hm.id_lector 
                                     AND pm.fecha_i = hm.fecha_i
                                     AND EXTRACT(YEAR FROM pm.fecha_pago) = periodos.anio
  GROUP BY p.id_pais, p.nombre_pais, periodos.anio
)
SELECT
  s.anio,
  s.id_pais,
  s.nombre_pais,
  s.miembros_totales,
  ROUND(
    (s.miembros_totales - LAG(s.miembros_totales, 1, s.miembros_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio)) * 100 /
    NULLIF(LAG(s.miembros_totales, 1, s.miembros_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio), 0), 2
  ) AS pct_crecimiento_miembros,
  s.ingresos_totales,
  ROUND(
    (s.ingresos_totales - LAG(s.ingresos_totales, 1, s.ingresos_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio)) * 100 / 
    NULLIF(LAG(s.ingresos_totales, 1, s.ingresos_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio), 0), 2
  ) AS pct_crecimiento_ingresos
FROM stats_consolidadas s;


CREATE OR REPLACE VIEW MJV_v_obras_presentadas
  (id_club, nombre_club, id_obra_act, titulo_obra, isbn, titulo_libro,
   total_funciones, valoracion_promedio_publico, ingresos_acumulados_taquilla)
AS
SELECT
  c.id_club,
  c.nombre_club,
  oa.id_obra_act,
  oa.titulo,
  li.isbn,
  li.titulo,
  COUNT(f.id_funcion),
  ROUND(AVG(f.valoracion_obra), 2),
  -- Cálculo de taquilla acumulada: Suma de la asistencia multiplicada por el precio estático de entrada
  NVL(SUM(f.cantidad_asistencia * oa.costo_entrada), 0)
FROM MJV_obra_actuada oa
JOIN MJV_club c    ON c.id_club = oa.id_club
JOIN MJV_libro li  ON li.isbn = oa.isbn
LEFT JOIN MJV_funcion f ON f.id_obra_act = oa.id_obra_act 
                       AND f.isbn = oa.isbn 
                       AND f.id_club = oa.id_club
GROUP BY
  c.id_club,
  c.nombre_club,
  oa.id_obra_act,
  oa.titulo,
  li.isbn,
  li.titulo;


CREATE OR REPLACE VIEW MJV_v_asistencia_bimestre
  (anio, bimestre, id_lector, nombre_lector, id_club, nombre_club, id_grupo, tipo_grupo,
   reuniones_ejecutadas, inasistencias_registradas, pct_participacion, pct_inasistencia)
AS
WITH universo_reuniones AS (
  SELECT 
    cr.id_club,
    cr.id_grupo,
    cr.fecha,
    cr.isbn,
    EXTRACT(YEAR FROM cr.fecha) AS anio,
    CEIL(EXTRACT(MONTH FROM cr.fecha) / 2) AS bimestre
  FROM MJV_calendario_reunion_mes cr
  WHERE cr.realizada = 'S'
)
SELECT
  ur.anio,
  ur.bimestre,
  l.id_lector,
  INITCAP(l.p_nombre) || ' ' || INITCAP(l.p_apellido),
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  INITCAP(g.tipo_grupo),
  COUNT(DISTINCT ur.fecha || '|' || ur.isbn) AS reuniones_ejecutadas,
  COUNT(i.fecha_reunion) AS inasistencias_registradas,
  -- % de inasistencia: para auditoría de ausencias
  ROUND(
    (COUNT(i.fecha_reunion) * 100) / 
    NULLIF(COUNT(DISTINCT ur.fecha || '|' || ur.isbn), 0), 2
  ) AS pct_inasistencia,
  -- % de participación: complemento, coincide con MJV_participacion_bimestre_miembro()
  ROUND(
    100 - (COUNT(i.fecha_reunion) * 100) / 
    NULLIF(COUNT(DISTINCT ur.fecha || '|' || ur.isbn), 0), 2
  ) AS pct_participacion
FROM MJV_g_lec gl
JOIN MJV_lector l  ON l.id_lector = gl.id_lector
JOIN MJV_club c    ON c.id_club = gl.id_club
JOIN MJV_grupo g   ON g.id_grupo = gl.id_grupo AND g.id_club = gl.id_club
JOIN universo_reuniones ur ON ur.id_grupo = gl.id_grupo 
                          AND ur.id_club = gl.id_club
                          AND ur.fecha BETWEEN gl.fec_i 
                            AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'))
LEFT JOIN MJV_inasistencia i ON i.id_lector = gl.id_lector
                            AND i.id_club = gl.id_club
                            AND i.fecha_i = gl.fecha_i
                            AND i.id_grupo = gl.id_grupo
                            AND i.fec_i_g_lec = gl.fec_i
                            AND i.fecha_reunion = ur.fecha
                            AND i.isbn = ur.isbn
GROUP BY
  ur.anio,
  ur.bimestre,
  l.id_lector,
  l.p_nombre,
  l.p_apellido,
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  g.tipo_grupo;


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
/


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

    RETURN NULL;
END;
/


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


CREATE OR REPLACE PACKAGE MJV_PKG_ADMIN_CLUBES AS

    -- Inscribe un nuevo lector en un club, asignándolo al grupo por edad y
    -- registrando sus 3 preferencias de obra.
    PROCEDURE inscribir_miembro (
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
        pi_id_rep          IN NUMBER   DEFAULT NULL,
        pi_tipo_rep        IN VARCHAR2 DEFAULT NULL
    );

    -- Registra un pago de cuota anual para un lector activo en un club con cuota.
    PROCEDURE registrar_pago (
        pi_id_lector   IN NUMBER,
        pi_nombre_club IN VARCHAR2,
        pi_monto       IN NUMBER,
        pi_moneda      IN VARCHAR2,
        pi_tasa        IN NUMBER
    );

    -- Procesa el retiro voluntario o administrativo de un lector de un club.
    PROCEDURE retirar_miembro (
        pi_id_lector     IN NUMBER,
        pi_nombre_club   IN VARCHAR2,
        pi_motivo_retiro IN VARCHAR2
    );

END MJV_PKG_ADMIN_CLUBES;
/


CREATE OR REPLACE PACKAGE BODY MJV_PKG_ADMIN_CLUBES AS

    PROCEDURE inscribir_miembro (
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
        pi_id_rep          IN NUMBER   DEFAULT NULL,
        pi_tipo_rep        IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        MJV_sp_inscribir_miembro(
            pi_p_nombre        => pi_p_nombre,
            pi_p_apellido      => pi_p_apellido,
            pi_s_nombre        => pi_s_nombre,
            pi_s_apellido      => pi_s_apellido,
            pi_doc_identidad   => pi_doc_identidad,
            pi_telefono        => pi_telefono,
            pi_email           => pi_email,
            pi_genero          => pi_genero,
            pi_fecha_nac       => pi_fecha_nac,
            pi_nombre_pais_nac => pi_nombre_pais_nac,
            pi_nombre_club     => pi_nombre_club,
            pi_titulo_pref1    => pi_titulo_pref1,
            pi_titulo_pref2    => pi_titulo_pref2,
            pi_titulo_pref3    => pi_titulo_pref3,
            pi_id_rep          => pi_id_rep,
            pi_tipo_rep        => pi_tipo_rep
        );
    END inscribir_miembro;

    PROCEDURE registrar_pago (
        pi_id_lector   IN NUMBER,
        pi_nombre_club IN VARCHAR2,
        pi_monto       IN NUMBER,
        pi_moneda      IN VARCHAR2,
        pi_tasa        IN NUMBER
    ) IS
    BEGIN
        MJV_sp_registrar_pago_membresia(
            pi_id_lector   => pi_id_lector,
            pi_nombre_club => pi_nombre_club,
            pi_monto       => pi_monto,
            pi_moneda      => pi_moneda,
            pi_tasa        => pi_tasa
        );
    END registrar_pago;

    PROCEDURE retirar_miembro (
        pi_id_lector     IN NUMBER,
        pi_nombre_club   IN VARCHAR2,
        pi_motivo_retiro IN VARCHAR2
    ) IS
    BEGIN
        MJV_sp_retirar_miembro(
            pi_id_lector     => pi_id_lector,
            pi_nombre_club   => pi_nombre_club,
            pi_motivo_retiro => pi_motivo_retiro
        );
    END retirar_miembro;

END MJV_PKG_ADMIN_CLUBES;
/


CREATE OR REPLACE PACKAGE MJV_PKG_ADMIN_REUNIONES AS

    -- Agenda una reunión mensual para un grupo/libro, validando hora, moderador
    -- y conflictos de horario.
    PROCEDURE agendar_reunion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_isbn          IN VARCHAR2,
        pi_fecha_reunion IN DATE,
        pi_hora_inicio   IN DATE,
        pi_mod_id_lector IN NUMBER
    );

    -- Registra la asistencia (S) o inasistencia (N) de un miembro a una reunión.
    -- Si es inasistencia, activa la evaluación de retiro automático por bimestre.
    PROCEDURE registrar_asistencia (
        pi_id_lector     IN NUMBER,
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_asistio       IN CHAR
    );

    -- Cierra la discusión de un libro en una reunión, registrando conclusiones
    -- y valoración final (1–5). Solo aplica si la reunión ya fue realizada.
    PROCEDURE cerrar_discusion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_conclusiones  IN VARCHAR2,
        pi_valoracion    IN NUMBER
    );

END MJV_PKG_ADMIN_REUNIONES;
/


CREATE OR REPLACE PACKAGE BODY MJV_PKG_ADMIN_REUNIONES AS

    PROCEDURE agendar_reunion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_isbn          IN VARCHAR2,
        pi_fecha_reunion IN DATE,
        pi_hora_inicio   IN DATE,
        pi_mod_id_lector IN NUMBER
    ) IS
    BEGIN
        MJV_sp_agendar_reunion_mes(
            pi_id_club       => pi_id_club,
            pi_id_grupo      => pi_id_grupo,
            pi_isbn          => pi_isbn,
            pi_fecha_reunion => pi_fecha_reunion,
            pi_hora_inicio   => pi_hora_inicio,
            pi_mod_id_lector => pi_mod_id_lector
        );
    END agendar_reunion;

    PROCEDURE registrar_asistencia (
        pi_id_lector     IN NUMBER,
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_asistio       IN CHAR
    ) IS
    BEGIN
        MJV_sp_registrar_asistencia_miembro(
            pi_id_lector     => pi_id_lector,
            pi_id_club       => pi_id_club,
            pi_id_grupo      => pi_id_grupo,
            pi_fecha_reunion => pi_fecha_reunion,
            pi_isbn          => pi_isbn,
            pi_asistio       => pi_asistio
        );
    END registrar_asistencia;

    PROCEDURE cerrar_discusion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_conclusiones  IN VARCHAR2,
        pi_valoracion    IN NUMBER
    ) IS
    BEGIN
        MJV_sp_cerrar_discusion_reunion(
            pi_id_club       => pi_id_club,
            pi_id_grupo      => pi_id_grupo,
            pi_fecha_reunion => pi_fecha_reunion,
            pi_isbn          => pi_isbn,
            pi_conclusiones  => pi_conclusiones,
            pi_valoracion    => pi_valoracion
        );
    END cerrar_discusion;

END MJV_PKG_ADMIN_REUNIONES;
/


CREATE OR REPLACE VIEW MJV_vw_r1_ficha_miembro AS
SELECT
    l.id_lector,
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_completo,
    l.doc_identidad,
    l.telefono,
    l.email,
    CASE l.genero WHEN 'M' THEN 'Masculino' WHEN 'F' THEN 'Femenino' END AS genero,
    l.fecha_nac,
    -- Edad calculada en años completos al día de hoy
    TRUNC(MONTHS_BETWEEN(SYSDATE, l.fecha_nac) / 12) AS edad,
    p.nombre_pais      AS pais_nacimiento,
    p.nacionalidad
FROM
    MJV_lector l
    JOIN MJV_pais p ON p.id_pais = l.id_pais_nac;


CREATE OR REPLACE VIEW MJV_vw_r1_historial_clubes AS
SELECT
    hm.id_lector,
    c.id_club,
    c.nombre_club,
    p.nombre_pais   AS pais_club,
    ci.nombre_ciudad AS ciudad_club,
    hm.fecha_i      AS fecha_ingreso,
    hm.fecha_f      AS fecha_retiro,
    hm.estatus,
    hm.motivo_retiro
FROM
    MJV_historia_membresia hm
    JOIN MJV_club   c  ON c.id_club  = hm.id_club
    JOIN MJV_pais   p  ON p.id_pais  = c.id_pais
    JOIN MJV_ciudad ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad
ORDER BY
    hm.id_lector,
    hm.fecha_i DESC;


CREATE OR REPLACE VIEW MJV_vw_r1_preferencias AS
SELECT
    po.id_lector,
    po.prioridad,
    lb.isbn,
    lb.titulo,
    -- Autores concatenados (puede ser coautoría)
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor) AS autores,
    lb.genero,
    lb.primera_edicion
FROM
    MJV_preferencia_obra po
    JOIN MJV_libro      lb ON lb.isbn     = po.isbn
    JOIN MJV_libro_autor la ON la.isbn     = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor  = la.id_autor
GROUP BY
    po.id_lector,
    po.prioridad,
    lb.isbn,
    lb.titulo,
    lb.genero,
    lb.primera_edicion
ORDER BY
    po.id_lector,
    po.prioridad;


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


CREATE OR REPLACE VIEW MJV_vw_r2_ficha_club AS
SELECT
    c.id_club,
    c.nombre_club,
    p.nombre_pais,
    ci.nombre_ciudad,
    c.cod_postal,
    CASE c.cuota_anual WHEN 'S' THEN 'Independiente (cobra cuota)' ELSE 'Institucional (sin cuota)' END AS tipo_club,
    -- Cantidad de grupos por tipo (subconsulta escalar por tipo)
    NVL(
        (SELECT COUNT(*) FROM MJV_grupo g2
          WHERE g2.id_club = c.id_club AND g2.tipo_grupo = 'adultos'), 0
    ) AS grupos_adultos,
    NVL(
        (SELECT COUNT(*) FROM MJV_grupo g2
          WHERE g2.id_club = c.id_club AND g2.tipo_grupo = 'jovenes'), 0
    ) AS grupos_jovenes,
    NVL(
        (SELECT COUNT(*) FROM MJV_grupo g2
          WHERE g2.id_club = c.id_club AND g2.tipo_grupo = 'niños'), 0
    ) AS grupos_ninos,
    (SELECT COUNT(*) FROM MJV_grupo g2 WHERE g2.id_club = c.id_club) AS total_grupos
FROM
    MJV_club    c
    JOIN MJV_pais   p  ON p.id_pais  = c.id_pais
    JOIN MJV_ciudad ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad;


CREATE OR REPLACE VIEW MJV_vw_r2_libros_por_club AS
SELECT
    crm.id_club,
    lb.isbn,
    lb.titulo,
    -- Autores concatenados
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor)         AS autores,
    lb.genero,
    ROUND(AVG(crm.valoracion), 2)                AS valoracion_promedio_club,
    COUNT(DISTINCT crm.id_grupo)                 AS cantidad_grupos_que_lo_analizaron
FROM
    MJV_calendario_reunion_mes crm
    JOIN MJV_libro      lb ON lb.isbn     = crm.isbn
    JOIN MJV_libro_autor la ON la.isbn    = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor = la.id_autor
WHERE
    crm.ultima    = 'S'
    AND crm.valoracion IS NOT NULL
GROUP BY
    crm.id_club,
    lb.isbn,
    lb.titulo,
    lb.genero
ORDER BY
    crm.id_club,
    valoracion_promedio_club DESC;


CREATE OR REPLACE VIEW MJV_vw_r3_ficha_libro AS
SELECT
    lb.isbn,
    lb.titulo,
    lb.tipo_narrativa,
    lb.sinopsis,
    lb.genero,
    lb.primera_edicion,
    lb.total_paginas,
    p.nombre_pais          AS pais_origen,
    -- Autores concatenados (puede ser coautoría)
    LISTAGG(
        NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''),
        ', '
    ) WITHIN GROUP (ORDER BY a.id_autor) AS autores,
    -- Valoración global: promedio de TODAS las sesiones de cierre de TODOS los clubes
    ROUND(
        (SELECT AVG(crm2.valoracion)
           FROM MJV_calendario_reunion_mes crm2
          WHERE crm2.isbn   = lb.isbn
            AND crm2.ultima = 'S'
            AND crm2.valoracion IS NOT NULL),
        2
    ) AS valoracion_global
FROM
    MJV_libro      lb
    JOIN MJV_pais       p  ON p.id_pais   = lb.id_pais
    JOIN MJV_libro_autor la ON la.isbn    = lb.isbn
    JOIN MJV_autor       a  ON a.id_autor = la.id_autor
GROUP BY
    lb.isbn,
    lb.titulo,
    lb.tipo_narrativa,
    lb.sinopsis,
    lb.genero,
    lb.primera_edicion,
    lb.total_paginas,
    p.nombre_pais;


CREATE OR REPLACE VIEW MJV_vw_r3_analisis_por_grupo AS
SELECT
    crm.isbn,
    c.id_club,
    c.nombre_club,
    p.nombre_pais    AS pais_club,
    ci.nombre_ciudad AS ciudad_club,
    g.id_grupo,
    g.tipo_grupo,
    crm.valoracion,
    crm.conclusiones,
    crm.fecha        AS fecha_cierre,
    -- Moderador del cierre
    l.p_nombre || ' ' || l.p_apellido || ' ' || NVL(l.s_apellido, '') AS nombre_moderador
FROM
    MJV_calendario_reunion_mes crm
    JOIN MJV_club    c  ON c.id_club   = crm.id_club
    JOIN MJV_pais    p  ON p.id_pais   = c.id_pais
    JOIN MJV_ciudad  ci ON ci.id_pais  = c.id_pais  AND ci.id_ciudad = c.id_ciudad
    JOIN MJV_grupo   g  ON g.id_grupo  = crm.id_grupo AND g.id_club  = crm.id_club
    JOIN MJV_lector  l  ON l.id_lector = crm.mod_id_lector
WHERE
    crm.ultima     = 'S'
    AND crm.valoracion IS NOT NULL
ORDER BY
    crm.isbn,
    crm.valoracion DESC,
    crm.fecha DESC;


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


CREATE OR REPLACE VIEW MJV_vw_r2_consolidado AS
SELECT
    fc.id_club,
    fc.nombre_club,
    fc.nombre_pais,
    fc.nombre_ciudad,
    fc.cod_postal,
    fc.tipo_club,
    fc.grupos_adultos,
    fc.grupos_jovenes,
    fc.grupos_ninos,
    fc.total_grupos,
    lc.isbn,
    lc.titulo                              AS titulo_libro,
    lc.autores                             AS autores_libro,
    lc.genero                              AS genero_libro,
    lc.valoracion_promedio_club,
    lc.cantidad_grupos_que_lo_analizaron
FROM
    MJV_vw_r2_ficha_club           fc
    LEFT JOIN MJV_vw_r2_libros_por_club lc ON lc.id_club = fc.id_club
ORDER BY
    fc.id_club,
    lc.valoracion_promedio_club DESC NULLS LAST,
    lc.titulo ASC;


CREATE OR REPLACE VIEW MJV_vw_r3_consolidado AS
SELECT
    fl.isbn,
    fl.titulo,
    fl.tipo_narrativa,
    fl.sinopsis,
    fl.genero,
    fl.primera_edicion,
    fl.total_paginas,
    fl.pais_origen,
    fl.autores,
    fl.valoracion_global,
    ag.id_club,
    ag.nombre_club,
    ag.pais_club,
    ag.ciudad_club,
    ag.id_grupo,
    ag.tipo_grupo,
    ag.valoracion                          AS valoracion_grupo,
    ag.conclusiones,
    TO_CHAR(ag.fecha_cierre, 'DD/MM/YYYY') AS fecha_cierre,
    ag.nombre_moderador
FROM
    MJV_vw_r3_ficha_libro               fl
    LEFT JOIN MJV_vw_r3_analisis_por_grupo ag ON ag.isbn = fl.isbn
ORDER BY
    fl.isbn,
    ag.valoracion DESC NULLS LAST,
    ag.fecha_cierre DESC NULLS LAST;


CREATE OR REPLACE VIEW MJV_vw_r1_consolidado AS
SELECT
    fm.id_lector,
    fm.nombre_completo,
    fm.doc_identidad,
    fm.telefono,
    fm.email,
    fm.genero,
    TO_CHAR(fm.fecha_nac, 'DD/MM/YYYY')        AS fecha_nacimiento,
    fm.edad,
    fm.pais_nacimiento,
    fm.nacionalidad,
    -- Libros favoritos (subconsulta escalar, no genera filas extra)
    (SELECT pr.titulo FROM MJV_vw_r1_preferencias pr
      WHERE pr.id_lector = fm.id_lector AND pr.prioridad = 1) AS favorito_1,
    (SELECT pr.titulo FROM MJV_vw_r1_preferencias pr
      WHERE pr.id_lector = fm.id_lector AND pr.prioridad = 2) AS favorito_2,
    (SELECT pr.titulo FROM MJV_vw_r1_preferencias pr
      WHERE pr.id_lector = fm.id_lector AND pr.prioridad = 3) AS favorito_3,
    -- Membresía
    hc.id_club,
    hc.nombre_club,
    hc.pais_club,
    hc.ciudad_club,
    TO_CHAR(hc.fecha_ingreso, 'DD/MM/YYYY')    AS fecha_ingreso_club,
    TO_CHAR(hc.fecha_retiro,  'DD/MM/YYYY')    AS fecha_retiro_club,
    hc.estatus,
    hc.motivo_retiro,
    TRUNC(MONTHS_BETWEEN(NVL(hc.fecha_retiro, SYSDATE), hc.fecha_ingreso)) AS meses_antiguedad,
    -- Libro analizado (moderador en reunión de cierre del mismo club)
    la.titulo       AS libro_analizado,
    la.autores      AS autores_libro,
    la.valoracion,
    la.conclusiones,
    TO_CHAR(la.fecha_reunion, 'DD/MM/YYYY')    AS fecha_cierre_libro
FROM
    MJV_vw_r1_ficha_miembro       fm
    JOIN MJV_vw_r1_historial_clubes hc ON hc.id_lector = fm.id_lector
    LEFT JOIN MJV_vw_r1_libros_analizados la
           ON la.id_lector  = fm.id_lector
          AND la.nombre_club = hc.nombre_club
ORDER BY
    fm.id_lector,
    hc.estatus ASC,
    hc.fecha_ingreso DESC,
    la.fecha_reunion DESC;

