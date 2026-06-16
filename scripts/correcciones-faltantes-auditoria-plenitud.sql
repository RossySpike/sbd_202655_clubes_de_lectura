-- =============================================================================
-- 1. SOLUCIÓN AC-F1: Vista de Historial de Pagos
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
-- 2. SOLUCIÓN AC-P1: Función para asignación Round-Robin (Equitativa)
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
-- 3. SOLUCIÓN AC-P1 (Integración): Parche al SP de Inscripción
-- Reemplaza tu MJV_sp_inscribir_miembro actual con este.
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
    v_id_lector     NUMBER; v_age NUMBER; v_tipo_grupo VARCHAR2(10);
    v_id_grupo      NUMBER; v_id_club NUMBER; v_id_pais_nac NUMBER;
    v_isbn1         VARCHAR2(20); v_isbn2 VARCHAR2(20); v_isbn3 VARCHAR2(20);
    v_tiene_deuda   NUMBER; v_vetado NUMBER;
BEGIN
    v_id_club := MJV_fn_obtener_id_club_por_nombre(pi_nombre_club);
    SELECT id_pais INTO v_id_pais_nac FROM MJV_pais WHERE UPPER(TRIM(nombre_pais)) = UPPER(TRIM(pi_nombre_pais_nac)) AND ROWNUM = 1;
    v_isbn1 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref1);
    v_isbn2 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref2);
    v_isbn3 := MJV_fn_obtener_isbn_por_titulo(pi_titulo_pref3);

    INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) 
    VALUES (pi_p_nombre, pi_p_apellido, pi_s_apellido, pi_doc_identidad, pi_telefono, pi_email, pi_genero, pi_fecha_nac, v_id_pais_nac, pi_s_nombre, CASE WHEN UPPER(TRIM(pi_tipo_rep)) = 'EXTERNO' THEN pi_id_rep ELSE NULL END, CASE WHEN UPPER(TRIM(pi_tipo_rep)) = 'LECTOR' THEN pi_id_rep ELSE NULL END)
    RETURNING id_lector INTO v_id_lector;

    v_age := MJV_edad_miembro(v_id_lector);
    v_tiene_deuda := MJV_fn_tiene_deuda_historica(v_id_lector);
    IF v_tiene_deuda = 1 THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20054, 'Deudas pendientes.'); END IF;
    
    v_vetado := MJV_fn_vetado_por_inasistencia(v_id_lector, v_id_club);
    IF v_vetado = 1 THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20055, 'Vetado por inasistencia.'); END IF;

    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn1, 1);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn2, 2);
    INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES (v_id_lector, v_isbn3, 3);
    INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, fecha_f, estatus) VALUES (v_id_lector, v_id_club, SYSDATE, NULL, 'activo');

    IF v_age BETWEEN 6 AND 12 THEN v_tipo_grupo := 'niños'; ELSIF v_age BETWEEN 13 AND 25 THEN v_tipo_grupo := 'jovenes'; ELSIF v_age > 25 THEN v_tipo_grupo := 'adultos'; ELSE RAISE_APPLICATION_ERROR(-20003, 'Edad mínima 6 años.'); END IF;

    -- AQUÍ SE INTEGRA LA FUNCIÓN ROUND-ROBIN
    v_id_grupo := MJV_fn_grupo_menos_lleno(v_id_club, v_tipo_grupo);
    IF v_id_grupo IS NULL THEN
        INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES (v_id_club, v_tipo_grupo, SYSDATE, 2, TO_DATE('17:00:00', 'HH24:MI:SS')) RETURNING id_grupo INTO v_id_grupo;
    END IF;

    INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES (v_id_lector, v_id_club, SYSDATE, v_id_grupo, SYSDATE, NULL);
    COMMIT;
END MJV_sp_inscribir_miembro;
/

-- =============================================================================
-- 4. SOLUCIÓN AC-P6: Evitar cierre de discusión de reunión no realizada
-- =============================================================================
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
    IF v_conclusiones_norm IS NULL THEN RAISE_APPLICATION_ERROR(-20080, 'Conclusiones vacías.'); END IF;
    IF pi_valoracion NOT BETWEEN 1 AND 5 THEN RAISE_APPLICATION_ERROR(-20081, 'Valoración entre 1 y 5.'); END IF;

    SELECT realizada, ultima INTO v_reunion_realizada, v_ultima_actual FROM MJV_calendario_reunion_mes
     WHERE id_club = pi_id_club AND id_grupo = pi_id_grupo AND fecha = TRUNC(pi_fecha_reunion) AND isbn = TRIM(pi_isbn);

    -- NUEVA VALIDACIÓN: No cerrar si no se ha realizado
    IF v_reunion_realizada = 'N' THEN
        RAISE_APPLICATION_ERROR(-20084, 'ERROR: No se puede cerrar una reunión que aún no ha sido realizada. Registre la asistencia primero.');
    END IF;

    IF v_ultima_actual = 'S' THEN RAISE_APPLICATION_ERROR(-20082, 'La reunión ya está cerrada.'); END IF;

    UPDATE MJV_calendario_reunion_mes SET ultima = 'N' WHERE id_club = pi_id_club AND id_grupo = pi_id_grupo AND isbn = TRIM(pi_isbn) AND fecha != TRUNC(pi_fecha_reunion) AND ultima = 'S';
    UPDATE MJV_calendario_reunion_mes SET realizada = 'S', ultima = 'S', conclusiones = v_conclusiones_norm, valoracion = pi_valoracion WHERE id_club = pi_id_club AND id_grupo = pi_id_grupo AND fecha = TRUNC(pi_fecha_reunion) AND isbn = TRIM(pi_isbn);
    COMMIT;
END MJV_sp_cerrar_discusion_reunion;
/

-- =============================================================================
-- 5. SOLUCIÓN REPORTES: Vistas 1 y 4 Corregidas
-- =============================================================================
CREATE OR REPLACE VIEW MJV_vw_r1_libros_analizados AS
SELECT DISTINCT
    gl.id_lector, lb.isbn, lb.titulo,
    LISTAGG(NVL(a.p_nombre, a.nombre_ant_pseudonimo) || ' ' || NVL(a.p_apellido, ''), ', ') WITHIN GROUP (ORDER BY a.id_autor) AS autores,
    crm.valoracion, crm.conclusiones, c.id_club, c.nombre_club, g.tipo_grupo, crm.fecha AS fecha_cierre
FROM MJV_g_lec gl
    JOIN MJV_grupo g ON g.id_grupo = gl.id_grupo AND g.id_club = gl.id_club
    JOIN MJV_club c ON c.id_club = gl.id_club
    JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = gl.id_grupo AND crm.id_club = gl.id_club AND crm.ultima = 'S' AND crm.valoracion IS NOT NULL AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, DATE '9999-12-31')
    JOIN MJV_libro lb ON lb.isbn = crm.isbn
    JOIN MJV_libro_autor la ON la.isbn = lb.isbn
    JOIN MJV_autor a ON a.id_autor = la.id_autor
GROUP BY gl.id_lector, lb.isbn, lb.titulo, crm.valoracion, crm.conclusiones, c.id_club, c.nombre_club, g.tipo_grupo, crm.fecha;
/

CREATE OR REPLACE VIEW MJV_vw_r4_crecimiento_anual AS
WITH miembros_por_anio AS (SELECT hm.id_club, EXTRACT(YEAR FROM hm.fecha_i) AS anio, COUNT(*) AS nuevos_miembros FROM MJV_historia_membresia hm GROUP BY hm.id_club, EXTRACT(YEAR FROM hm.fecha_i)),
ingresos_por_anio AS (SELECT pm.id_club, EXTRACT(YEAR FROM pm.fecha_pago) AS anio, SUM(pm.monto) AS ingresos_usd FROM MJV_pago_membresia pm JOIN MJV_club c ON c.id_club = pm.id_club WHERE c.cuota_anual = 'S' GROUP BY pm.id_club, EXTRACT(YEAR FROM pm.fecha_pago)),
anios_por_club AS (SELECT id_club, anio FROM miembros_por_anio UNION SELECT id_club, anio FROM ingresos_por_anio),
consolidado AS (SELECT ac.id_club, ac.anio, NVL(m.nuevos_miembros, 0) AS nuevos_miembros, NVL(i.ingresos_usd, 0) AS ingresos_usd, LAG(NVL(m.nuevos_miembros, 0)) OVER (PARTITION BY ac.id_club ORDER BY ac.anio) AS miembros_anio_anterior, LAG(NVL(i.ingresos_usd, 0)) OVER (PARTITION BY ac.id_club ORDER BY ac.anio) AS ingresos_anio_anterior FROM anios_por_club ac LEFT JOIN miembros_por_anio m ON m.id_club = ac.id_club AND m.anio = ac.anio LEFT JOIN ingresos_por_anio i ON i.id_club = ac.id_club AND i.anio = ac.anio)
SELECT c.id_club, c.nombre_club, p.nombre_pais, ci.nombre_ciudad, CASE c.cuota_anual WHEN 'S' THEN 'Independiente' ELSE 'Institucional' END AS tipo_club, co.anio, co.nuevos_miembros, co.ingresos_usd, co.miembros_anio_anterior, co.ingresos_anio_anterior, ROUND(((co.nuevos_miembros - co.miembros_anio_anterior) / NULLIF(co.miembros_anio_anterior, 0)) * 100, 2) AS pct_crecimiento_miembros, ROUND(((co.ingresos_usd - co.ingresos_anio_anterior) / NULLIF(co.ingresos_anio_anterior, 0)) * 100, 2) AS pct_crecimiento_economico
FROM consolidado co JOIN MJV_club c ON c.id_club = co.id_club JOIN MJV_pais p ON p.id_pais = c.id_pais JOIN MJV_ciudad ci ON ci.id_pais = c.id_pais AND ci.id_ciudad = c.id_ciudad
ORDER BY p.nombre_pais ASC, co.anio DESC, pct_crecimiento_miembros DESC NULLS LAST, pct_crecimiento_economico DESC NULLS LAST;
/
