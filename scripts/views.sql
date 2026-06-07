-- TIPO: SIMPLE (una sola tabla, sin GROUP BY, sin ORDER BY)
-- Directorio publico de lectores: datos de contacto sin doc_identidad (informacion sensible).
-- Traduce genero F/M a texto legible con DECODE.
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


-- TIPO: SIMPLE (una sola tabla, sin GROUP BY, sin ORDER BY)
-- Catalogo editorial basico de libros: isbn, titulo, tipo, genero, edicion y paginas.
-- Excluye sinopsis (texto largo) y campo de secuencia para mantenerla liviana.
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


-- TIPO: COMPLEJA (JOINs entre 5 tablas + DECODE + TO_CHAR)
-- Calendario mensual de debates: nombre del club, tipo de grupo, fecha y hora de reunion,
-- libro en discusion, nombre del moderador y estado (Realizada / Pendiente).
-- Soporte operativo del modulo de Administracion de Reuniones (Rubrica 2-II).
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


-- TIPO: COMPLEJA (JOINs entre 5 tablas + GROUP BY + COUNT + ROUND + EXTRACT + NULLIF)
-- Agrega por (club, tipo de grupo, mes, anio):
--   total_reuniones    : reuniones realizadas en el mes
--   total_inasistencias: faltas registradas en el mes
--   pct_participacion  : porcentaje promedio de asistencia (0.00 a 100.00)
-- Base de calculo de la funcion MJV_promedio_part_mensual_tipo_grupo().
CREATE OR REPLACE VIEW MJV_v_participacion_mensual_tipo_grupo
  (id_club, nombre_club, tipo_grupo, mes, anio,
   total_reuniones, total_inasistencias, pct_participacion)
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
      COUNT(i.fecha_reunion) * 100
      /
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


-- TIPO: COMPLEJA (JOINs entre 6 tablas + DECODE + TRUNC + MONTHS_BETWEEN)
-- Ficha completa de un miembro: datos personales, historial de membresias,
-- grupo asignado por periodo y catalogo de libros analizados con valoracion y conclusiones.
-- Una fila por (lector, entrada en g_lec, libro analizado durante ese periodo).
-- Backlog: v_ficha_lector. Reporte 1 exigido en enunciado pag. 10.
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


-- TIPO: COMPLEJA (subconsulta en FROM + JOINs + GROUP BY + COUNT + AVG + ORDER BY)
-- Ficha del club: datos generales, cantidad de grupos por tipo (adultos/jovenes/ninos)
-- y catalogo historico de libros analizados con valoracion promedio entre grupos,
-- ordenado de mayor a menor valoracion. Backlog: v_ficha_club. Reporte 2 exigido pag. 10.
-- La subconsulta en el FROM es eficiente: se mantiene en memoria (prof. pag. 8 SQLsubconsultas).
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
  li.isbn, li.titulo, li.tipo_narrativa
ORDER BY c.id_club, ROUND(AVG(crm.valoracion), 2) DESC;
