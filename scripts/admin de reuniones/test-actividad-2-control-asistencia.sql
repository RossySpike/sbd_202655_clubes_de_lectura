SET SERVEROUTPUT ON;

-- Test de Actividad 2: Registrar asistencia/inasistencia (solicita parámetros al usuario)
ACCEPT p_lector_id  NUMBER PROMPT 'ID numérico del lector (ej: 21) [21]: '
ACCEPT p_club       CHAR PROMPT 'Club (nombre) [Refugio Literario del Sur]: '
ACCEPT p_grupo      CHAR PROMPT 'Tipo de grupo [adultos]: '
ACCEPT p_titulo_libro  CHAR PROMPT 'Título del libro [El imperio final (Nacidos de la bruma)]: '
ACCEPT p_fecha      CHAR PROMPT 'Fecha reunion (DD/MM/YYYY) [15/07/2026]: '

DECLARE
    v_id_lector      NUMBER;
    v_id_club        NUMBER;
    v_id_grupo       NUMBER;
    v_doc_identidad  VARCHAR2(20);
    v_titulo_libro   VARCHAR2(4000) := NVL('&p_titulo_libro','El imperio final (Nacidos de la bruma)');
    v_isbn           VARCHAR2(20);
    v_fecha          DATE := TO_DATE(NVL('&p_fecha','15/07/2026'),'DD/MM/YYYY');
    v_lector_id      NUMBER := TO_NUMBER(NVL('&p_lector_id','21'));
    -- (Solo se usa un lector por ejecución)
    v_club_text      VARCHAR2(4000) := NVL('&p_club','Refugio Literario del Sur');
    v_grupo_text     VARCHAR2(100) := NVL('&p_grupo','adultos');
BEGIN
    -- Resolver IDs y datos internos
    SELECT id_lector, doc_identidad INTO v_id_lector, v_doc_identidad FROM MJV_lector WHERE id_lector = v_lector_id AND ROWNUM = 1;
    SELECT id_club INTO v_id_club FROM MJV_club WHERE nombre_club = v_club_text AND ROWNUM = 1;
    SELECT id_grupo INTO v_id_grupo FROM MJV_grupo WHERE id_club = v_id_club AND tipo_grupo = v_grupo_text AND ROWNUM = 1;
    v_isbn := MJV_fn_obtener_isbn_por_titulo(v_titulo_libro);

    DBMS_OUTPUT.PUT_LINE('Resolved: id_lector='||v_id_lector||' doc_identidad='||v_doc_identidad||' id_club='||v_id_club||' id_grupo='||v_id_grupo||' titulo='||v_titulo_libro||' isbn='||v_isbn||' fecha='||TO_CHAR(v_fecha,'DD/MM/YYYY'));

    -- Test: asistencia
    MJV_sp_registrar_asistencia_miembro(
        pi_id_lector     => v_id_lector,
        pi_id_club       => v_id_club,
        pi_id_grupo      => v_id_grupo,
        pi_fecha_reunion => v_fecha,
        pi_isbn          => v_isbn,
        pi_asistio       => 'S'
    );

    DBMS_OUTPUT.PUT_LINE('Entrada: id_lector='||v_id_lector||' | doc_identidad='||v_doc_identidad||' | titulo='||v_titulo_libro||' | isbn='||v_isbn);
    -- Si quieres probar inasistencia, ejecuta el script otra vez usando el mismo u otro id_lector
END;
/
