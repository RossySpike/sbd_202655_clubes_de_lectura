-- =============================================================================
-- menu_op_1.sql — Inscribir nuevo miembro
-- =============================================================================

PROMPT
PROMPT --- INSCRIBIR NUEVO MIEMBRO ---
PROMPT

-- -----------------------------------------------------------------------------
-- REFERENCIA: Lectores existentes (utiles si va a asignar un representante)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** LECTORES REGISTRADOS (para asignar representante si aplica) ***
PROMPT

SELECT l.id_lector,
       l.p_nombre || ' ' || l.p_apellido AS nombre,
       l.doc_identidad
FROM   MJV_lector l
ORDER  BY l.id_lector;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Representantes externos registrados
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** REPRESENTANTES EXTERNOS REGISTRADOS ***
PROMPT

SELECT r.id_representante,
       r.p_nombre || ' ' || r.p_apellido AS nombre,
       r.doc_identidad
FROM   MJV_representante r
ORDER  BY r.id_representante;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Clubes disponibles
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** CLUBES DISPONIBLES ***
PROMPT

SELECT c.id_club, c.nombre_club
FROM   MJV_club c
ORDER  BY c.id_club;

-- -----------------------------------------------------------------------------
-- REFERENCIA: Libros disponibles para preferencias (ISBN + Titulo)
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** CATALOGO DE LIBROS (para elegir preferencias) ***
PROMPT

SELECT li.isbn, li.titulo
FROM   MJV_libro li
ORDER  BY li.titulo;

PROMPT
PROMPT *** INGRESE LOS DATOS DEL NUEVO MIEMBRO ***
PROMPT

ACCEPT p_p_nombre   CHAR   PROMPT "Primer nombre                          : "
ACCEPT p_s_nombre   CHAR   PROMPT "Segundo nombre  (Enter si no tiene)    : "
ACCEPT p_p_apellido CHAR   PROMPT "Primer apellido                        : "
ACCEPT p_s_apellido CHAR   PROMPT "Segundo apellido                       : "
ACCEPT p_doc        CHAR   PROMPT "Documento de identidad                 : "
ACCEPT p_telefono   CHAR   PROMPT "Telefono                               : "
ACCEPT p_email      CHAR   PROMPT "Email                                  : "
ACCEPT p_genero     CHAR   PROMPT "Genero  M / F                          : "
ACCEPT p_fecha_nac  CHAR   PROMPT "Fecha nacimiento  DD/MM/YYYY           : "
ACCEPT p_pais_nac   CHAR   PROMPT "Nombre pais de nacimiento              : "
ACCEPT p_club       CHAR   PROMPT "Nombre exacto del club (ver tabla)     : "
ACCEPT p_pref1      CHAR   PROMPT "Titulo libro preferencia 1 (ver tabla) : "
ACCEPT p_pref2      CHAR   PROMPT "Titulo libro preferencia 2 (ver tabla) : "
ACCEPT p_pref3      CHAR   PROMPT "Titulo libro preferencia 3 (ver tabla) : "
ACCEPT p_id_rep     CHAR   PROMPT "ID representante  (Enter = sin rep.)   : "
ACCEPT p_tipo_rep   CHAR   PROMPT "Tipo rep.  LECTOR / EXTERNO / NULL     : "

DECLARE
    v_s_nom      VARCHAR2(20) := TRIM('&p_s_nombre');
    v_id_rep_str VARCHAR2(20) := UPPER(TRIM('&p_id_rep'));
    v_tipo_str   VARCHAR2(20) := UPPER(TRIM('&p_tipo_rep'));
    v_id_rep_num NUMBER       := NULL;
BEGIN
    IF v_id_rep_str NOT IN ('NULL','') THEN
        v_id_rep_num := TO_NUMBER(v_id_rep_str);
    END IF;

    MJV_PKG_ADMIN_CLUBES.inscribir_miembro(
        pi_p_nombre        => TRIM('&p_p_nombre'),
        pi_p_apellido      => TRIM('&p_p_apellido'),
        pi_s_nombre        => CASE WHEN UPPER(v_s_nom) IN ('NULO','NULL','') THEN NULL ELSE v_s_nom END,
        pi_s_apellido      => TRIM('&p_s_apellido'),
        pi_doc_identidad   => TRIM('&p_doc'),
        pi_telefono        => TRIM('&p_telefono'),
        pi_email           => TRIM('&p_email'),
        pi_genero          => UPPER(TRIM('&p_genero')),
        pi_fecha_nac       => TO_DATE(TRIM('&p_fecha_nac'), 'DD/MM/YYYY'),
        pi_nombre_pais_nac => TRIM('&p_pais_nac'),
        pi_nombre_club     => TRIM('&p_club'),
        pi_titulo_pref1    => TRIM('&p_pref1'),
        pi_titulo_pref2    => TRIM('&p_pref2'),
        pi_titulo_pref3    => TRIM('&p_pref3'),
        pi_id_rep          => v_id_rep_num,
        pi_tipo_rep        => CASE WHEN v_tipo_str IN ('NULL','') THEN NULL ELSE v_tipo_str END
    );
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*** ERROR [Inscribir Miembro] ***');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- RESULTADO: Ficha del miembro recien inscrito
-- -----------------------------------------------------------------------------
PROMPT
PROMPT *** RESULTADO — MIEMBRO INSCRITO ***
PROMPT

SELECT m.nombre_club,
       m.cedula,
       m.nombre_completo,
       m.fecha_ingreso,
       m.id_grupo
FROM   MJV_vw_miembros_activos m
WHERE  m.cedula = TRIM('&p_doc');

PROMPT
PROMPT *** GRUPOS ACTIVOS TRAS LA INSCRIPCION (ocupacion actualizada) ***
PROMPT

SELECT og.id_club,
       og.nombre_club,
       og.id_grupo,
       og.tipo_grupo,
       og.miembros_activos
FROM   MJV_vw_ocupacion_grupos og
WHERE  UPPER(og.nombre_club) = UPPER(TRIM('&p_club'));

UNDEF p_p_nombre p_s_nombre p_p_apellido p_s_apellido p_doc
UNDEF p_telefono p_email p_genero p_fecha_nac p_pais_nac
UNDEF p_club p_pref1 p_pref2 p_pref3 p_id_rep p_tipo_rep
