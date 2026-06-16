-- =============================================================================
-- menu_op_4.sql — Agendar reunion mensual
-- =============================================================================

PROMPT
PROMPT --- AGENDAR REUNION MENSUAL ---
PROMPT

-- -----------------------------------------------------------------------------
-- REFERENCIA: Clubes y grupos disponibles con su ID
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** CLUBES Y GRUPOS DISPONIBLES ***
PROMPT

SELECT og.id_club,
       og.nombre_club,
       og.id_grupo,
       og.tipo_grupo,
       og.miembros_activos
FROM   MJV_vw_ocupacion_grupos og
ORDER  BY og.id_club, og.id_grupo;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Libros disponibles (ISBN)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** CATALOGO DE LIBROS (ISBN para agendar) ***
PROMPT

SELECT li.isbn, li.titulo, li.tipo_narrativa
FROM   MJV_libro li
ORDER  BY li.titulo;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Moderadores disponibles (lectores activos con ID)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** MODERADORES DISPONIBLES (lectores activos) ***
PROMPT

SELECT l.id_lector,
       l.p_nombre || ' ' || l.p_apellido AS nombre_moderador
FROM   MJV_lector l
WHERE  EXISTS (
    SELECT 1
    FROM   MJV_historia_membresia hm
    WHERE  hm.id_lector = l.id_lector
      AND  hm.estatus   = 'activo'
)
ORDER  BY l.id_lector;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Reuniones ya agendadas (para verificar conflictos)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** CALENDARIO ACTUAL DE REUNIONES ***
PROMPT

SELECT cr.id_club,
       cr.nombre_club,
       cr.id_grupo,
       cr.tipo_grupo,
       cr.fecha_reunion,
       cr.hora_grupo,
       cr.isbn,
       cr.titulo_libro,
       cr.nombre_moderador,
       cr.realizada
FROM   MJV_v_reuniones_mes cr
ORDER  BY cr.id_club, cr.fecha_reunion;

PROMPT
PROMPT *** INGRESE LOS DATOS DE LA REUNION ***
PROMPT

ACCEPT p_id_club   NUMBER PROMPT "ID club (ver tabla)                    : "
ACCEPT p_id_grupo  NUMBER PROMPT "ID grupo (ver tabla)                   : "
ACCEPT p_isbn      CHAR   PROMPT "ISBN del libro (ver tabla)             : "
ACCEPT p_fec_reu   CHAR   PROMPT "Fecha reunion  DD/MM/YYYY              : "
ACCEPT p_hora      CHAR   PROMPT "Hora inicio  HH24:MI  (ej. 17:00)     : "
ACCEPT p_id_mod    NUMBER PROMPT "ID moderador (ver tabla)               : "

BEGIN
    MJV_PKG_ADMIN_REUNIONES.agendar_reunion(
        pi_id_club       => &p_id_club,
        pi_id_grupo      => &p_id_grupo,
        pi_isbn          => TRIM('&p_isbn'),
        pi_fecha_reunion => TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY'),
        pi_hora_inicio   => TO_DATE(TRIM('&p_hora'),    'HH24:MI'),
        pi_mod_id_lector => &p_id_mod
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Agendar Reunion] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- RESULTADO: Reunion recien agendada en el calendario
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — REUNION AGENDADA ***
PROMPT

SELECT cr.id_club,
       cr.nombre_club,
       cr.id_grupo,
       cr.tipo_grupo,
       cr.fecha_reunion,
       cr.hora_grupo,
       cr.isbn,
       cr.titulo_libro,
       cr.nombre_moderador,
       cr.realizada,
       cr.es_ultima
FROM   MJV_v_reuniones_mes cr
WHERE  cr.id_club  = &p_id_club
  AND  cr.id_grupo = &p_id_grupo
  AND  cr.fecha_reunion = TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY');

UNDEF p_id_club p_id_grupo p_isbn p_fec_reu p_hora p_id_mod
