----------- Test funciones con textbox -------

-- Conversion Monetaria --

-- USD a VES (tasa referencial)
-- 1. Conversion Monetaria
SELECT MJV_conversion_monetaria(
  &monto, 
  '&moneda_origen', 
  '&moneda_destino', 
  &tasa_cambio
) AS monto_destino 
FROM DUAL;
-- Resultado esperado: 3650

-- Misma moneda (caso borde)
SELECT MJV_conversion_monetaria(100, 'USD', 'USD', 1) AS mismo FROM DUAL;
-- Resultado esperado: 100

-- Moneda inventada (debe lanzar error -20102)
SELECT MJV_conversion_monetaria(100, 'XYZ', 'USD', 1) FROM DUAL;

---------------------------------------------------------------------------------
-- Edad Miembro --

SELECT 
  doc_identidad,
  fecha_nac,
  MJV_edad_miembro(id_lector) AS edad_actual 
FROM MJV_lector 
WHERE doc_identidad = '&documento_identidad';

---------------------------------------------------------------------------------
-- Antiguedad de miembro en club --
-- Antigüedad de todos los miembros activos del Refugio Literario del Sur

SELECT
  l.doc_identidad,
  l.p_nombre || ' ' || l.p_apellido AS nombre,
  MJV_antiguedad_en_club_miembro(l.id_lector,
    (SELECT id_club FROM MJV_club WHERE nombre_club = '&nombre_del_club')
  ) AS anios_en_club
FROM MJV_lector l
JOIN MJV_historia_membresia hm ON hm.id_lector = l.id_lector
WHERE hm.id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = '&nombre_del_club')
  AND hm.estatus = 'activo'
ORDER BY l.doc_identidad;


---------------------------------------------------------------------------------
-- Prom mensual de participacio por grupo --

SELECT 
  id_club,
  nombre_club,
  tipo_grupo,
  mes,
  anio,
  total_inasistencias,
  total_reuniones,
  pct_participacion
FROM MJV_v_participacion_mensual_tipo_grupo
WHERE nombre_club = '&nombre_del_club'
  AND mes = &mes_numero 
  AND anio = &anio_numero;

-- Nombre CLub: Refugio Literario del sur
-- mes: 1
-- anio: 2026
-- Matemática: 4 miembros × 2 reuniones = 8 esperadas. 4 faltas. (8-4)/8*100 = 50

-- Forma demostracion con vista dedicada --
SELECT * FROM MJV_v_participacion_mensual_tipo_grupo
WHERE nombre_club = '&nombre_del_club'
  AND mes = &numero_mes AND anio = &anio_numero;
  

---------------------------------------------------------------------------------
-- Participacion Bisemestre Miembro --
-- 5. Participacion Bimestre Miembro (Evaluando la función para un lector específico)
SELECT
  l.doc_identidad,
  l.p_nombre || ' ' || l.p_apellido AS nombre,
  MJV_participacion_bimestre_miembro(
    l.id_lector,
    (SELECT id_club FROM MJV_club WHERE nombre_club = '&nombre_del_club'),
    &numero_bimestre,
    &anio_numero
  ) AS pct_asistencia
FROM MJV_lector l
WHERE l.doc_identidad = '&documento_identidad';

---------------------------------------------------------------------------------

-- Forma demostración con vista dedicada (Muestra todos los miembros del club)
SELECT * FROM MJV_v_asistencia_bimestre
WHERE nombre_club = '&nombre_del_club'
  AND bimestre = &numero_bimestre 
  AND anio = &anio_numero;