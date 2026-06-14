SET SERVEROUTPUT ON;
SET VERIFY OFF;

-- Test de Actividad 2: Registrar asistencia/inasistencia (Pidiendo ID de Club)
ACCEPT p_lector_id      NUMBER PROMPT 'ID numérico del lector (ej: 21) [21]: '
ACCEPT p_id_club        NUMBER PROMPT 'ID numérico del club (ej: 1) [1]: '
ACCEPT p_grupo          CHAR   PROMPT 'Tipo de grupo [adultos]: '
ACCEPT p_titulo_libro   CHAR   PROMPT 'Título del libro [El imperio final (Nacidos de la bruma)]: '
ACCEPT p_fecha          CHAR   PROMPT 'Fecha reunion (DD/MM/YYYY) [15/07/2026]: '

DECLARE
    v_id_lector         NUMBER;
    v_id_club           NUMBER := TO_NUMBER(NVL('&p_id_club', '1'));
    v_id_grupo          NUMBER;
    v_doc_identidad     VARCHAR2(20);
    v_titulo_libro      VARCHAR2(4000) := NVL('&p_titulo_libro', 'El imperio final (Nacidos de la bruma)');
    v_isbn              VARCHAR2(20);
    v_fecha             DATE := TO_DATE(NVL('&p_fecha', '15/07/2026'), 'DD/MM/YYYY');
    v_lector_id         NUMBER := TO_NUMBER(NVL('&p_lector_id', '21'));
    v_grupo_text        VARCHAR2(100) := NVL('&p_grupo', 'adultos');
    
    -- Variable para capturar el nombre del club para el reporte de salida
    v_nombre_club       VARCHAR2(200);
BEGIN
    -- 1. Resolver los datos del Lector
    SELECT id_lector, doc_identidad 
      INTO v_id_lector, v_doc_identidad 
      FROM MJV_lector 
     WHERE id_lector = v_lector_id 
       AND ROWNUM = 1;

    -- 2. Buscar el nombre del club usando el ID ingresado para mostrarlo en la salida
    BEGIN
        SELECT nombre_club 
          INTO v_nombre_club 
          FROM MJV_club 
         WHERE id_club = v_id_club;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20090, 'Error: El ID de club ingresado (' || v_id_club || ') no existe en el sistema.');
    END;

    -- 3. Resolver el ID del grupo usando el ID del Club y el tipo descriptivo
    BEGIN
        SELECT id_grupo 
          INTO v_id_grupo 
          FROM MJV_grupo 
         WHERE id_club = v_id_club 
           AND UPPER(TRIM(tipo_grupo)) = UPPER(TRIM(v_grupo_text))
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20091, 'Error: No se encontró un grupo de tipo "' || v_grupo_text || '" en el club ' || v_nombre_club);
    END;

    -- 4. Resolver el ISBN con tu función de catálogo
    v_isbn := MJV_fn_obtener_isbn_por_titulo(v_titulo_libro);

    -- Imprimir encabezado de auditoría técnica amigable resuelta internamente
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('⚙️ [DATOS PROCESADOS INTERNAMENTE]');
    DBMS_OUTPUT.PUT_LINE(' Club / Sede:      ' || v_nombre_club || ' (ID: ' || v_id_club || ')');
    DBMS_OUTPUT.PUT_LINE(' Grupo Evaluado:   ' || UPPER(v_grupo_text) || ' (ID: ' || v_id_grupo || ')');
    DBMS_OUTPUT.PUT_LINE(' Lector Evaluado:  ID ' || v_id_lector || ' [DNI: ' || v_doc_identidad || ']');
    DBMS_OUTPUT.PUT_LINE(' Libro / Obra:     ' || v_titulo_libro || ' [ISBN: ' || v_isbn || ']');
    DBMS_OUTPUT.PUT_LINE(' Fecha de Sesión:  ' || TO_CHAR(v_fecha, 'DD-MM-YYYY'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    -- 5. Ejecutar la lógica de negocio principal pasando 'N' para simular la falta
    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_asistio       => 'N'
    );

END;
/