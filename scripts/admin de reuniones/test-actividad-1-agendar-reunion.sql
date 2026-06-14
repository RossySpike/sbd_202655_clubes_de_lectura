SET SERVEROUTPUT ON;
SET VERIFY OFF;

-- 1. Captura interactiva usando IDs numéricos y nombres de libros
ACCEPT p_id_club        NUMBER PROMPT 'ID numérico del club (ej: 1) [1]: '
ACCEPT p_grupo          CHAR   PROMPT 'Tipo de grupo [adultos]: '
ACCEPT p_titulo_libro   CHAR   PROMPT 'Título del libro [El imperio final (Nacidos de la bruma)]: '
ACCEPT p_lector_id      NUMBER PROMPT 'ID numérico del Lector / Moderador (ej: 21) [21]: '
ACCEPT p_fecha          CHAR   PROMPT 'Fecha de la reunión (DD/MM/YYYY) [15/07/2026]: '

DECLARE
    v_id_club        NUMBER := TO_NUMBER(NVL('&p_id_club', '1'));
    v_id_grupo       NUMBER;
    v_id_moderador   NUMBER := TO_NUMBER(NVL('&p_lector_id', '21'));
    v_titulo_libro   VARCHAR2(4000) := NVL('&p_titulo_libro', 'El imperio final (Nacidos de la bruma)');
    v_isbn           VARCHAR2(20);
    v_fecha          DATE := TO_DATE(NVL('&p_fecha', '15/07/2026'), 'DD/MM/YYYY');
    
    v_nombre_club    VARCHAR2(200);
    v_grupo_text     VARCHAR2(100) := LOWER(TRIM(NVL('&p_grupo', 'adultos')));
    v_doc_identidad  VARCHAR2(20);
    v_hora_inicio    DATE;
BEGIN
    -- 2. Resolver Nombre del Club a partir del ID ingresado
    BEGIN
        SELECT nombre_club INTO v_nombre_club FROM MJV_club WHERE id_club = v_id_club;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20090, 'Error: No se encontró un club con el ID ' || v_id_club);
    END;

    -- 3. Resolver ID de Grupo y Hora Fija asignada a partir de su tipo de grupo y ID de club
    BEGIN
        SELECT id_grupo, hora_reunion 
          INTO v_id_grupo, v_hora_inicio
          FROM MJV_grupo 
         WHERE id_club = v_id_club 
           AND LOWER(TRIM(tipo_grupo)) = v_grupo_text;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20091, 'Error: No se encontró un grupo de tipo "' || v_grupo_text || '" en el club ' || v_nombre_club);
    END;

    -- 4. Traducir Título del Libro a ISBN usando tu función de catálogo
    v_isbn := MJV_fn_obtener_isbn_por_titulo(v_titulo_libro);

    -- 5. Traducir ID del Moderador para extraer su Documento de Identidad (DNI/Cédula)
    BEGIN
        SELECT doc_identidad INTO v_doc_identidad FROM MJV_lector WHERE id_lector = v_id_moderador;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20092, 'Error: El ID de lector ' || v_id_moderador || ' no existe en el sistema.');
    END;

    -- Imprimir encabezado de auditoría técnica amigable
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('⚙️ [DATOS PROCESADOS INTERNAMENTE - AGENDAR REUNIÓN]');
    DBMS_OUTPUT.PUT_LINE(' Club / Sede:      ' || v_nombre_club || ' (ID: ' || v_id_club || ')');
    DBMS_OUTPUT.PUT_LINE(' Grupo Evaluado:   ' || UPPER(v_grupo_text) || ' (ID: ' || v_id_grupo || ')');
    DBMS_OUTPUT.PUT_LINE(' Moderador:        ID ' || v_id_moderador || ' [DNI: ' || v_doc_identidad || ']');
    DBMS_OUTPUT.PUT_LINE(' Libro / Obra:     ' || v_titulo_libro || ' [ISBN: ' || v_isbn || ']');
    DBMS_OUTPUT.PUT_LINE(' Fecha Programada: ' || TO_CHAR(v_fecha, 'DD-MM-YYYY') || ' a las ' || TO_CHAR(v_hora_inicio, 'HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    -- Invocación al procedimiento principal de la Actividad 1
    MJV_sp_agendar_reunion_mes(
        pi_id_club        => v_id_club,
        pi_id_grupo       => v_id_grupo,
        pi_isbn           => v_isbn,
        pi_fecha_reunion  => v_fecha,
        pi_hora_inicio    => v_hora_inicio,
        pi_mod_id_lector  => v_id_moderador
    );

END;
/