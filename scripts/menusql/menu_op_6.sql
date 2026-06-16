-- =============================================================================
-- menu_op_6.sql — Cerrar discusion de libro
-- =============================================================================

PROMPT
PROMPT --- CERRAR DISCUSION DE LIBRO ---
PROMPT

-- -----------------------------------------------------------------------------
-- REFERENCIA: Reuniones realizadas que aun no tienen cierre de discusion
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** REUNIONES REALIZADAS PENDIENTES DE CIERRE (sin conclusiones) ***
PROMPT

SELECT ed.id_club,
       ed.nombre_club,
       ed.id_grupo,
       ed.tipo_grupo,
       ed.isbn,
       ed.titulo,
       ed.sesiones_realizadas,
       ed.ultima_sesion,
       ed.estado_discusion
FROM   MJV_vw_estado_discusiones ed
WHERE  ed.estado_discusion = 'En curso'
ORDER  BY ed.id_club, ed.id_grupo, ed.ultima_sesion;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Historico de discusiones ya cerradas (para ver el contexto)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** HISTORICO DE DISCUSIONES YA CERRADAS ***
PROMPT

SELECT ed.id_club,
       ed.nombre_club,
       ed.id_grupo,
       ed.tipo_grupo,
       ed.isbn,
       ed.titulo,
       ed.sesiones_realizadas,
       ed.ultima_sesion,
       ed.valoracion_final,
       ed.conclusiones_finales,
       ed.estado_discusion
FROM   MJV_vw_estado_discusiones ed
WHERE  ed.estado_discusion = 'Cerrada'
ORDER  BY ed.id_club, ed.ultima_sesion DESC;

PROMPT
PROMPT *** INGRESE LOS DATOS DEL CIERRE ***
PROMPT

ACCEPT p_id_club   NUMBER PROMPT "ID club (ver tabla)                    : "
ACCEPT p_id_grupo  NUMBER PROMPT "ID grupo (ver tabla)                   : "
ACCEPT p_fec_reu   CHAR   PROMPT "Fecha reunion  DD/MM/YYYY              : "
ACCEPT p_isbn      CHAR   PROMPT "ISBN del libro (ver tabla)             : "
ACCEPT p_concl     CHAR   PROMPT "Conclusiones del grupo                 : "
ACCEPT p_valor     NUMBER PROMPT "Valoracion final  1-5                  : "

BEGIN
    MJV_PKG_ADMIN_REUNIONES.cerrar_discusion(
        pi_id_club       => &p_id_club,
        pi_id_grupo      => &p_id_grupo,
        pi_fecha_reunion => TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY'),
        pi_isbn          => TRIM('&p_isbn'),
        pi_conclusiones  => TRIM('&p_concl'),
        pi_valoracion    => &p_valor
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Cerrar Discusion] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- RESULTADO: Discusion recien cerrada con sus conclusiones y valoracion
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — DISCUSION CERRADA ***
PROMPT

SELECT ed.id_club,
       ed.nombre_club,
       ed.id_grupo,
       ed.tipo_grupo,
       ed.isbn,
       ed.titulo,
       ed.sesiones_realizadas,
       ed.ultima_sesion,
       ed.valoracion_final,
       ed.conclusiones_finales,
       ed.estado_discusion
FROM   MJV_vw_estado_discusiones ed
WHERE  ed.id_club  = &p_id_club
  AND  ed.id_grupo = &p_id_grupo
  AND  ed.isbn     = TRIM('&p_isbn');

-- -----------------------------------------------------------------------------
-- RESULTADO: Ficha completa del libro con valoracion promedio actualizada
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — FICHA DEL LIBRO (valoracion global actualizada) ***
PROMPT

SELECT fl.isbn,
       fl.titulo,
       fl.tipo_narrativa,
       fl.valoracion_promedio_global,
       fl.id_club,
       fl.nombre_club,
       fl.id_grupo,
       fl.tipo_grupo,
       fl.conclusiones_grupo
FROM   MJV_v_ficha_libro fl
WHERE  fl.isbn = TRIM('&p_isbn')
ORDER  BY fl.id_club, fl.id_grupo;

UNDEF p_id_club p_id_grupo p_fec_reu p_isbn p_concl p_valor
