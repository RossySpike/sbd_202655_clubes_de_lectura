-- =============================================================================
-- VISTAS CENTRALIZADAS PARA ADMINISTRACIÓN DE CLUB DE LECTURA (MJV)
-- =============================================================================

-- 1. Vista de Calendario (Estado general de reuniones)
CREATE OR REPLACE VIEW MJV_vw_calendario_reuniones AS
SELECT 
    c.id_club,
    c.id_grupo,
    g.tipo_grupo,
    c.fecha,
    c.isbn,
    l.titulo AS titulo_libro,
    c.realizada,
    c.ultima,
    c.mod_id_lector,
    (SELECT p_nombre || ' ' || p_apellido FROM MJV_lector WHERE id_lector = c.mod_id_lector) AS nombre_moderador
FROM MJV_calendario_reunion_mes c
JOIN MJV_grupo g ON c.id_club = g.id_club AND c.id_grupo = g.id_grupo
JOIN MJV_libro l ON c.isbn = l.isbn;

-- 2. Vista de Reporte de Inasistencias (Para monitoreo de penalizaciones)
CREATE OR REPLACE VIEW MJV_vw_reporte_inasistencias AS
SELECT 
    i.id_lector,
    l.p_nombre || ' ' || l.p_apellido AS nombre_lector,
    i.id_club,
    i.id_grupo,
    i.fecha_reunion,
    i.isbn
FROM MJV_inasistencia i
JOIN MJV_lector l ON i.id_lector = l.id_lector;

-- 3. Vista de Histórico de Discusiones (Para consulta de conclusiones y calidad)
CREATE OR REPLACE VIEW MJV_vw_historico_discusiones AS
SELECT 
    c.id_club,
    c.id_grupo,
    c.fecha,
    c.isbn,
    l.titulo,
    c.conclusiones,
    c.valoracion
FROM MJV_calendario_reunion_mes c
JOIN MJV_libro l ON c.isbn = l.isbn
WHERE c.realizada = 'S'; -- Filtramos solo las que ya han finalizado

-- =============================================================================
-- COMENTARIOS DE USO:
-- - MJV_vw_calendario_reuniones: Útil para identificar qué reuniones siguen 
--   pendientes (realizada = 'N').
-- - MJV_vw_reporte_inasistencias: Permite auditar qué miembros están cerca 
--   de alcanzar el 30% de inasistencias por bimestre.
-- - MJV_vw_historico_discusiones: Provee el "archivo" de resultados finales 
--   para cada libro discutido.
-- =============================================================================