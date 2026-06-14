SET SERVEROUTPUT ON;
SET VERIFY OFF;

-- 1. Captura interactiva de datos amigables para el usuario
ACCEPT p_club_nombre PROMPT 'Ingrese el Nombre del Club (ej. Refugio Literario del Sur): ';
ACCEPT p_grupo_tipo  PROMPT 'Ingrese el Tipo de Grupo (adultos/jovenes/ninos): ';
ACCEPT p_libro_titulo PROMPT 'Ingrese el Título del Libro: ';
ACCEPT p_id_moderador PROMPT 'Ingrese el ID del Lector (Moderador): ';
ACCEPT p_fecha_reun   PROMPT 'Ingrese la Fecha de la Reunión (DD/MM/YYYY): ';
ACCEPT p_hora_reun    PROMPT 'Ingrese la Hora de la Reunión (HH24:MI): ';

DECLARE
    v_id_club       MJV_club_lectura.id_club%TYPE;
    v_id_grupo      MJV_grupo_lectura.id_grupo%TYPE;
    v_isbn          MJV_libro.isbn%TYPE;
    v_id_moderador  MJV_lector.id_lector%TYPE := TO_NUMBER('&p_id_moderador');
    v_fecha         DATE := TO_DATE('&p_fecha_reun', 'DD/MM/YYYY');
    v_hora_inicio   VARCHAR2(5) := '&p_hora_reun';
    v_doc_identidad MJV_lector.doc_identidad%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PROCESANDO ASIGNACIÓN DE REUNIÓN ===');

    -- Traducción 1: Nombre del Club -> ID del Club
    SELECT id_club INTO v_id_club 
    FROM MJV_club_lectura 
    WHERE UPPER(TRIM(nombre_club)) = UPPER(TRIM('&p_club_nombre'));

    -- Traducción 2: Tipo de Grupo -> ID del Grupo
    SELECT id_grupo INTO v_id_grupo 
    FROM MJV_grupo_lectura 
    WHERE UPPER(TRIM(tipo_grupo)) = UPPER(TRIM('&p_grupo_tipo'))
      AND id_club = v_id_club;

    -- Traducción 3: Título del Libro -> ISBN (Uso de tu función de catálogo)
    v_isbn := MJV_fn_obtener_isbn_por_titulo('&p_libro_titulo');

    -- Búsqueda de soporte: Obtener Cédula/DNI del Moderador para la auditoría
    SELECT doc_identidad INTO v_doc_identidad 
    FROM MJV_lector 
    WHERE id_lector = v_id_moderador;

    -- Invocación al procedimiento principal con los IDs resueltos internamente
    MJV_sp_agendar_reunion_mes(
        pi_id_club        => v_id_club,
        pi_id_grupo       => v_id_grupo,
        pi_isbn           => v_isbn,
        pi_fecha_reunion  => v_fecha,
        pi_hora_inicio    => v_hora_inicio,
        pi_mod_id_lector  => v_id_moderador
    );

    -- Salida limpia confirmando los datos técnicos que el usuario no digitó
    DBMS_OUTPUT.PUT_LINE('✔ Reunión agendada con ÉXITO.');
    DBMS_OUTPUT.PUT_LINE(' Libro procesado (ISBN): ' || v_isbn);
    DBMS_OUTPUT.PUT_LINE(' Identificación del Moderador: ' || v_doc_identidad);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: No se encontró el Club, el Grupo o el Lector con los nombres provistos.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' ERROR EN TRANSACCIÓN: ' || SQLERRM);
END;
/