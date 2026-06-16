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

SELECT cr.id_club,
       cr.nombre_club,
       cr.id_grupo,
       cr.tipo_grupo,
       cr.fecha_reunion,
       cr.isbn,
       cr.titulo_libro,
       cr.es_ultima
FROM   MJV_vw_reuniones_mes cr
WHERE  cr.realizada = 'Realizada'
  AND  NOT EXISTS (
           SELECT 1
           FROM   MJV_vw_historico_discusiones hd
           WHERE  hd.id_club  = cr.id_club
             AND  hd.id_grupo = cr.id_grupo
             AND  hd.fecha    = cr.fecha_reunion
             AND  hd.isbn     = cr.isbn
             AND  hd.conclusiones IS NOT NULL
       )
ORDER  BY cr.id_club, cr.id_grupo, cr.fecha_reunion;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Historico de discusiones ya cerradas (para ver el contexto)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** HISTORICO DE DISCUSIONES YA CERRADAS ***
PROMPT

SELECT hd.id_club,
       hd.id_grupo,
       hd.fecha,
       hd.isbn,
       hd.titulo,
       hd.valoracion,
       hd.conclusiones
FROM   MJV_vw_historico_discusiones hd
ORDER  BY hd.id_club, hd.fecha DESC;

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

SELECT hd.id_club,
       hd.id_grupo,
       hd.fecha,
       hd.isbn,
       hd.titulo,
       hd.valoracion,
       hd.conclusiones
FROM   MJV_vw_historico_discusiones hd
WHERE  hd.id_club  = &p_id_club
  AND  hd.id_grupo = &p_id_grupo
  AND  hd.fecha    = TO_DATE(TRIM('&p_fec_reu'), 'DD/MM/YYYY')
  AND  hd.isbn     = TRIM('&p_isbn');

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
