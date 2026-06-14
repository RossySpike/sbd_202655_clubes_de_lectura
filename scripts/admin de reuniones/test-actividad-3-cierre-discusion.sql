SET SERVEROUTPUT ON;
SET VERIFY OFF;

ACCEPT p_club_nombre  PROMPT 'Ingrese el Nombre del Club: ';
ACCEPT p_grupo_tipo   PROMPT 'Ingrese el Tipo de Grupo (adultos/jovenes/ninos): ';
ACCEPT p_libro_titulo PROMPT 'Ingrese el Título del Libro a cerrar: ';
ACCEPT p_fecha_reun   PROMPT 'Ingrese la Fecha de la Reunión (DD/MM/YYYY): ';
ACCEPT p_conclusiones PROMPT 'Ingrese las conclusiones de la discusión: ';
ACCEPT p_valoracion   PROMPT 'Defina la valoración final del libro (1 al 5): ';

DECLARE
    -- CORREGIDO: Tipos mapeados uno a uno con script_final.sql
    v_id_club        MJV_club.id_club%TYPE;
    v_id_grupo       MJV_grupo.id_grupo%TYPE;
    v_isbn           MJV_Libro.isbn%TYPE;
    v_fecha_reunion  DATE := TO_DATE('&p_fecha_reun', 'DD/MM/YYYY');
    v_valoracion     NUMBER := TO_NUMBER('&p_valoracion');
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PROCESANDO CIERRE DE CICLO DE LECTURA ===');

    -- CORREGIDO: Mapeos exactos sobre tablas maestras
    SELECT id_club INTO v_id_club 
    FROM MJV_club 
    WHERE UPPER(TRIM(nombre_club)) = UPPER(TRIM('&p_club_nombre'))
      AND ROWNUM = 1;
    
    SELECT id_grupo INTO v_id_grupo 
    FROM MJV_grupo 
    WHERE UPPER(TRIM(tipo_grupo)) = UPPER(TRIM('&p_grupo_tipo')) 
      AND id_club = v_id_club
      AND ROWNUM = 1;
    
    v_isbn := MJV_fn_obtener_isbn_por_titulo('&p_libro_titulo');

    -- Ejecución del procedimiento corregido
    MJV_sp_cerrar_discusion_reunion(
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha_reunion,
        pi_isbn          => v_isbn,
        pi_conclusiones  => '&p_conclusiones',
        pi_valoracion    => v_valoracion
    );

    DBMS_OUTPUT.PUT_LINE('✔ Ciclo de lectura cerrado exitosamente para el ISBN: ' || v_isbn);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERROR AL CERRAR LA DISCUSIÓN: ' || SQLERRM);
END;
/