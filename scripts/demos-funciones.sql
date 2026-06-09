----------- Test funciones -------

-- Conversion Monetaria --

-- USD a VES (tasa referencial)
SELECT MJV_conversion_monetaria(100, 'USD', 'VES', 36.50) AS monto_ves FROM DUAL;
-- Resultado esperado: 3650

-- Misma moneda (caso borde)
SELECT MJV_conversion_monetaria(100, 'USD', 'USD', 1) AS mismo FROM DUAL;
-- Resultado esperado: 100

-- Moneda inventada (debe lanzar error -20102)
SELECT MJV_conversion_monetaria(100, 'XYZ', 'USD', 1) FROM DUAL;

---------------------------------------------------------------------------------
-- Edad Miembro --
-- Ver edad de varios lectores con su fecha de nacimiento para verificar
SELECT
  l.doc_identidad,
  l.fecha_nac,
  MJV_edad_miembro(l.id_lector) AS edad_actual
FROM MJV_lector l
WHERE l.doc_identidad IN ('V-ADU01', 'V-JOV01', 'V-NIN01')
ORDER BY l.doc_identidad;


---------------------------------------------------------------------------------
-- Antiguedad de miembro en club --
-- Antigüedad de todos los miembros activos del Refugio Literario del Sur
SELECT
  l.doc_identidad,
  l.p_nombre || ' ' || l.p_apellido AS nombre,
  MJV_antiguedad_en_club_miembro(l.id_lector,
    (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur')
  ) AS anios_en_club
FROM MJV_lector l
JOIN MJV_historia_membresia hm ON hm.id_lector = l.id_lector
WHERE hm.id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur')
  AND hm.estatus = 'activo'
ORDER BY l.doc_identidad;


---------------------------------------------------------------------------------
-- Prom mensual de participacio por grupo --
SELECT MJV_promedio_part_mensual_tipo_grupo(
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'),
  'adultos',
  1,     -- enero
  2026
) AS pct_participacion FROM DUAL;
-- Resultado esperado: 50
-- Matemática: 4 miembros × 2 reuniones = 8 esperadas. 4 faltas. (8-4)/8*100 = 50

-- Forma demostracion con vista dedicada --
SELECT * FROM MJV_v_participacion_mensual_tipo_grupo
WHERE nombre_club = 'Refugio Literario del Sur'
  AND mes = 1 AND anio = 2026;
  

---------------------------------------------------------------------------------
-- Participacion Bisemestre Miembro --
SELECT
  l.doc_identidad,
  l.p_nombre || ' ' || l.p_apellido AS nombre,
  MJV_participacion_bimestre_miembro(
    l.id_lector,
    (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'),
    1,    -- bimestre 1: ene-feb
    2026
  ) AS pct_asistencia
FROM MJV_lector l
WHERE l.doc_identidad IN ('V-ADU01', 'V-ADU02', 'V-ADU03', 'V-ADU04')
ORDER BY l.doc_identidad;

-- Forma demostracion con vista dedicada --
SELECT * FROM MJV_v_asistencia_bimestre
WHERE nombre_club = 'Refugio Literario del Sur'
  AND bimestre = 1 AND anio = 2026;

