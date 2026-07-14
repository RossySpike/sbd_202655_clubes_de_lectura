-- =============================================================================
-- SEGURIDAD DISCRECIONAL - CLUBES DE LECTURA (Oracle 19c)
-- Usuarios finales: Miembro_Lector, Moderador_Grupo, Administrador_Club,
-- Administrador_Obras, Coordinador_Datos. Se asume MJV_DEV (dueño del
-- esquema) ya existe. Orden: script_final.sql -> complemento_script_final.sql
-- -> este archivo.
-- =============================================================================


-- PARTE 1: PERFILES (como DBA)
CREATE PROFILE MJV_perfil_admin_club LIMIT
    SESSIONS_PER_USER          2
    CPU_PER_SESSION            15000
    CPU_PER_CALL               3000
    CONNECT_TIME               480
    IDLE_TIME                  30
    FAILED_LOGIN_ATTEMPTS       5
    PASSWORD_LIFE_TIME         60
    PASSWORD_GRACE_TIME        7
    PASSWORD_REUSE_TIME        365
    PASSWORD_REUSE_MAX         5
    PASSWORD_LOCK_TIME         1
    PASSWORD_VERIFY_FUNCTION   ORA12C_VERIFY_FUNCTION;

CREATE PROFILE MJV_perfil_moderador LIMIT
    SESSIONS_PER_USER          1
    CPU_PER_SESSION            8000
    CPU_PER_CALL               2000
    CONNECT_TIME               240
    IDLE_TIME                  20
    FAILED_LOGIN_ATTEMPTS       5
    PASSWORD_LIFE_TIME         60
    PASSWORD_GRACE_TIME        7
    PASSWORD_REUSE_TIME        365
    PASSWORD_REUSE_MAX         5
    PASSWORD_LOCK_TIME         1
    PASSWORD_VERIFY_FUNCTION   ORA12C_VERIFY_FUNCTION;

CREATE PROFILE MJV_perfil_admin_obras LIMIT
    SESSIONS_PER_USER          2
    CPU_PER_SESSION            12000
    CPU_PER_CALL               3000
    CONNECT_TIME               360
    IDLE_TIME                  30
    FAILED_LOGIN_ATTEMPTS       5
    PASSWORD_LIFE_TIME         60
    PASSWORD_GRACE_TIME        7
    PASSWORD_REUSE_TIME        365
    PASSWORD_REUSE_MAX         5
    PASSWORD_LOCK_TIME         1
    PASSWORD_VERIFY_FUNCTION   ORA12C_VERIFY_FUNCTION;

CREATE PROFILE MJV_perfil_coordinador LIMIT
    SESSIONS_PER_USER          2
    CPU_PER_SESSION            12000
    CPU_PER_CALL               3000
    CONNECT_TIME               360
    IDLE_TIME                  30
    FAILED_LOGIN_ATTEMPTS       5
    PASSWORD_LIFE_TIME         60
    PASSWORD_GRACE_TIME        7
    PASSWORD_REUSE_TIME        365
    PASSWORD_REUSE_MAX         5
    PASSWORD_LOCK_TIME         1
    PASSWORD_VERIFY_FUNCTION   ORA12C_VERIFY_FUNCTION;

CREATE PROFILE MJV_perfil_lector LIMIT
    SESSIONS_PER_USER          1
    CPU_PER_SESSION            5000
    CPU_PER_CALL               1000
    CONNECT_TIME               120
    IDLE_TIME                  15
    FAILED_LOGIN_ATTEMPTS       3
    PASSWORD_LIFE_TIME         60
    PASSWORD_GRACE_TIME        5
    PASSWORD_REUSE_TIME        365
    PASSWORD_REUSE_MAX         5
    PASSWORD_LOCK_TIME         1
    PASSWORD_VERIFY_FUNCTION   ORA12C_VERIFY_FUNCTION;


-- PARTE 2: CUENTAS DE USUARIO FINAL (como DBA) - unico priv. de sistema: CREATE SESSION
-- QUOTA 0: correcto, los INSERT de usuarios finales caen en tablas propiedad
-- de MJV_DEV, la cuota se descuenta del dueño de la tabla, no de quien inserta.
CREATE USER MJV_LECTOR_DEMO IDENTIFIED BY "CambiarClaveLector#2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE MJV_perfil_lector
    QUOTA 0 ON USERS;

CREATE USER MJV_MODERADOR_DEMO IDENTIFIED BY "CambiarClaveModerador#2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE MJV_perfil_moderador
    QUOTA 0 ON USERS;

CREATE USER MJV_ADMINCLUB_DEMO IDENTIFIED BY "CambiarClaveAdminClub#2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE MJV_perfil_admin_club
    QUOTA 0 ON USERS;

CREATE USER MJV_ADMINOBRAS_DEMO IDENTIFIED BY "CambiarClaveAdminObras#2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE MJV_perfil_admin_obras
    QUOTA 0 ON USERS;

CREATE USER MJV_COORDINADOR_DEMO IDENTIFIED BY "CambiarClaveCoordinador#2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE MJV_perfil_coordinador
    QUOTA 0 ON USERS;

GRANT CREATE SESSION TO MJV_LECTOR_DEMO;
GRANT CREATE SESSION TO MJV_MODERADOR_DEMO;
GRANT CREATE SESSION TO MJV_ADMINCLUB_DEMO;
GRANT CREATE SESSION TO MJV_ADMINOBRAS_DEMO;
GRANT CREATE SESSION TO MJV_COORDINADOR_DEMO;


-- PARTE 3: ROLES (como DBA). Admin_Obras y Coordinador son hermanos de
-- Admin_Club, ninguno desciende de otro (todos heredan solo de Lector).
CREATE ROLE MJV_rol_miembro_lector  NOT IDENTIFIED;
CREATE ROLE MJV_rol_moderador_grupo NOT IDENTIFIED;
CREATE ROLE MJV_rol_admin_club      NOT IDENTIFIED;
CREATE ROLE MJV_rol_admin_obras     NOT IDENTIFIED;
CREATE ROLE MJV_rol_coordinador     NOT IDENTIFIED;

GRANT MJV_rol_miembro_lector  TO MJV_rol_moderador_grupo;
GRANT MJV_rol_moderador_grupo TO MJV_rol_admin_club;
GRANT MJV_rol_miembro_lector  TO MJV_rol_admin_obras;
GRANT MJV_rol_miembro_lector  TO MJV_rol_coordinador;


-- PARTE 4: PRIVILEGIOS DE OBJETO (como MJV_DEV, dueño de los objetos)
-- CONNECT MJV_DEV/<clave_de_MJV_DEV>

-- 4.1 MJV_rol_miembro_lector: consulta general + votacion en obras teatrales
GRANT SELECT ON MJV_v_catalogo_libros              TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_v_ficha_lector                 TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_v_ficha_club                   TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_v_ficha_libro                  TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_v_reuniones_mes                TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_v_obras_presentadas             TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_vw_miembros_activos             TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_vw_ocupacion_grupos             TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_vw_reuniones_calendario_activo  TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_vw_estado_discusiones           TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_vw_historico_discusiones        TO MJV_rol_miembro_lector;

GRANT SELECT, INSERT ON MJV_voto_publico   TO MJV_rol_miembro_lector;
GRANT SELECT, INSERT ON MJV_mejor_actor    TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_obra_actuada           TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_funcion                TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_elenco                 TO MJV_rol_miembro_lector;

-- Secuencia usada por el DEFAULT de MJV_voto_publico.id_voto
GRANT SELECT ON MJV_seq_voto_publico TO MJV_rol_miembro_lector;

-- 4.2 MJV_rol_moderador_grupo: agenda/asistencia/cierre de discusion de su grupo
GRANT EXECUTE ON MJV_sp_registrar_asistencia_miembro TO MJV_rol_moderador_grupo;
GRANT EXECUTE ON MJV_sp_cerrar_discusion_reunion     TO MJV_rol_moderador_grupo;
GRANT EXECUTE ON MJV_sp_agendar_reunion_mes          TO MJV_rol_moderador_grupo;

GRANT SELECT ON MJV_vw_inasistencias_bimestre           TO MJV_rol_moderador_grupo;
GRANT SELECT ON MJV_vw_moderadores_activos              TO MJV_rol_moderador_grupo;
GRANT SELECT ON MJV_v_asistencia_bimestre               TO MJV_rol_moderador_grupo;
GRANT SELECT ON MJV_v_participacion_mensual_tipo_grupo  TO MJV_rol_moderador_grupo;

-- 4.3 MJV_rol_admin_club: inscripcion, splits, pagos, metricas y reportes de club
GRANT EXECUTE ON MJV_sp_inscribir_miembro        TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_sp_retirar_miembro          TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_sp_split_grupo              TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_sp_registrar_pago_membresia TO MJV_rol_admin_club;

GRANT EXECUTE ON MJV_conversion_monetaria                 TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_promedio_part_mensual_tipo_grupo     TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_participacion_bimestre_miembro       TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_antiguedad_en_club_miembro           TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_edad_miembro                         TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_fn_validar_solvencia_retiro          TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_fn_tiene_deuda_historica             TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_fn_vetado_por_inasistencia           TO MJV_rol_admin_club;

GRANT SELECT ON MJV_v_crecimiento_clubes         TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_reporte_solvencia         TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_historial_retiros         TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_historial_pagos_membresia TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r1_consolidado            TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r2_consolidado            TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r3_consolidado            TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r4_consolidado            TO MJV_rol_admin_club;

-- 4.4 MJV_rol_admin_obras: logistica teatral (elenco, funciones, votos, taquilla)
GRANT SELECT, INSERT, UPDATE, DELETE ON MJV_obra_actuada TO MJV_rol_admin_obras;
GRANT SELECT, INSERT, UPDATE, DELETE ON MJV_elenco       TO MJV_rol_admin_obras;
GRANT SELECT, INSERT, UPDATE, DELETE ON MJV_funcion      TO MJV_rol_admin_obras;
GRANT SELECT, UPDATE, DELETE ON MJV_voto_publico         TO MJV_rol_admin_obras;
GRANT SELECT, UPDATE, DELETE ON MJV_mejor_actor          TO MJV_rol_admin_obras;

-- Secuencias usadas por MJV_obra_actuada.id_obra_act y MJV_funcion.id_funcion
GRANT SELECT ON MJV_seq_obra_actuada TO MJV_rol_admin_obras;
GRANT SELECT ON MJV_seq_funcion      TO MJV_rol_admin_obras;

GRANT EXECUTE ON MJV_conversion_monetaria TO MJV_rol_admin_obras;

GRANT SELECT ON MJV_v_obras_presentadas TO MJV_rol_admin_obras;

-- 4.5 MJV_rol_coordinador: catalogo maestro (paises, ciudades, instituciones, clubes, libros)
GRANT SELECT, INSERT, UPDATE ON MJV_pais        TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_ciudad      TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_institucion TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_club        TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_asociado    TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_libro       TO MJV_rol_coordinador;

-- Secuencias usadas por pais/ciudad/institucion/club (libro y asociado no usan secuencia)
GRANT SELECT ON MJV_seq_pais        TO MJV_rol_coordinador;
GRANT SELECT ON MJV_seq_ciudad      TO MJV_rol_coordinador;
GRANT SELECT ON MJV_seq_institucion TO MJV_rol_coordinador;

GRANT SELECT ON MJV_v_catalogo_libros TO MJV_rol_coordinador;
GRANT SELECT ON MJV_v_ficha_club      TO MJV_rol_coordinador;


-- PARTE 5: ASIGNACION DE ROLES A CUENTAS (como DBA)
GRANT MJV_rol_miembro_lector  TO MJV_LECTOR_DEMO;
GRANT MJV_rol_moderador_grupo TO MJV_MODERADOR_DEMO;
GRANT MJV_rol_admin_club      TO MJV_ADMINCLUB_DEMO;
GRANT MJV_rol_admin_obras     TO MJV_ADMINOBRAS_DEMO;
GRANT MJV_rol_coordinador     TO MJV_COORDINADOR_DEMO;

ALTER USER MJV_LECTOR_DEMO      DEFAULT ROLE MJV_rol_miembro_lector;
ALTER USER MJV_MODERADOR_DEMO   DEFAULT ROLE MJV_rol_moderador_grupo;
ALTER USER MJV_ADMINCLUB_DEMO   DEFAULT ROLE MJV_rol_admin_club;
ALTER USER MJV_ADMINOBRAS_DEMO  DEFAULT ROLE MJV_rol_admin_obras;
ALTER USER MJV_COORDINADOR_DEMO DEFAULT ROLE MJV_rol_coordinador;

-- Cuenta con doble responsabilidad (Admin_Club + Admin_Obras): otorgar ambos roles.
--   GRANT MJV_rol_admin_club  TO MJV_ADMINCLUB_DEMO;
--   GRANT MJV_rol_admin_obras TO MJV_ADMINCLUB_DEMO;
--   ALTER USER MJV_ADMINCLUB_DEMO DEFAULT ROLE ALL;


-- PARTE 6: AUDITORIA TEMPORAL SOBRE DML/EXECUTE CRITICOS (como DBA)
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_pago_membresia BY ACCESS;
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_historia_membresia BY ACCESS;
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_g_lec BY ACCESS;
AUDIT UPDATE ON MJV_DEV.MJV_calendario_reunion_mes BY ACCESS;

AUDIT EXECUTE ON MJV_DEV.MJV_sp_split_grupo              BY ACCESS;
AUDIT EXECUTE ON MJV_DEV.MJV_sp_registrar_pago_membresia  BY ACCESS;
AUDIT EXECUTE ON MJV_DEV.MJV_sp_retirar_miembro           BY ACCESS;

AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_obra_actuada BY ACCESS;
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_funcion      BY ACCESS;

AUDIT INSERT, UPDATE ON MJV_DEV.MJV_club        BY ACCESS;
AUDIT INSERT, UPDATE ON MJV_DEV.MJV_institucion BY ACCESS;

AUDIT ROLE WHENEVER SUCCESSFUL;

-- Verificacion de auditoria activa:
-- SELECT * FROM DBA_AUDIT_TRAIL   WHERE OWNER = 'MJV_DEV' ORDER BY TIMESTAMP DESC;
-- SELECT * FROM DBA_STMT_AUDIT_OPTS;
-- SELECT * FROM DBA_OBJ_AUDIT_OPTS WHERE OWNER = 'MJV_DEV';
-- SELECT * FROM DBA_AUDIT_TRAIL   WHERE DB_USER LIKE 'MJV_%_DEMO';


-- PARTE 7: REVERSION (no ejecutar junto con lo anterior; solo para desmontar)
/*
NOAUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_pago_membresia;
NOAUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_historia_membresia;
NOAUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_g_lec;
NOAUDIT UPDATE ON MJV_DEV.MJV_calendario_reunion_mes;
NOAUDIT EXECUTE ON MJV_DEV.MJV_sp_split_grupo;
NOAUDIT EXECUTE ON MJV_DEV.MJV_sp_registrar_pago_membresia;
NOAUDIT EXECUTE ON MJV_DEV.MJV_sp_retirar_miembro;
NOAUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_obra_actuada;
NOAUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_funcion;
NOAUDIT INSERT, UPDATE ON MJV_DEV.MJV_club;
NOAUDIT INSERT, UPDATE ON MJV_DEV.MJV_institucion;
NOAUDIT ROLE;

REVOKE MJV_rol_miembro_lector  FROM MJV_LECTOR_DEMO;
REVOKE MJV_rol_moderador_grupo FROM MJV_MODERADOR_DEMO;
REVOKE MJV_rol_admin_club      FROM MJV_ADMINCLUB_DEMO;
REVOKE MJV_rol_admin_obras     FROM MJV_ADMINOBRAS_DEMO;
REVOKE MJV_rol_coordinador     FROM MJV_COORDINADOR_DEMO;

DROP ROLE MJV_rol_admin_obras;
DROP ROLE MJV_rol_coordinador;
DROP ROLE MJV_rol_admin_club;
DROP ROLE MJV_rol_moderador_grupo;
DROP ROLE MJV_rol_miembro_lector;

DROP USER MJV_LECTOR_DEMO CASCADE;
DROP USER MJV_MODERADOR_DEMO CASCADE;
DROP USER MJV_ADMINCLUB_DEMO CASCADE;
DROP USER MJV_ADMINOBRAS_DEMO CASCADE;
DROP USER MJV_COORDINADOR_DEMO CASCADE;

DROP PROFILE MJV_perfil_lector CASCADE;
DROP PROFILE MJV_perfil_moderador CASCADE;
DROP PROFILE MJV_perfil_admin_club CASCADE;
DROP PROFILE MJV_perfil_admin_obras CASCADE;
DROP PROFILE MJV_perfil_coordinador CASCADE;
*/


-- PARTE 8: VERIFICACION CONTRA EL DICCIONARIO DE DATOS
-- SELECT * FROM ROLE_ROLE_PRIVS WHERE ROLE LIKE 'MJV_ROL%';
-- SELECT * FROM ROLE_TAB_PRIVS WHERE ROLE LIKE 'MJV_ROL%' ORDER BY ROLE, TABLE_NAME;
-- SELECT * FROM ROLE_TAB_PRIVS WHERE ROLE LIKE 'MJV_ROL%' AND COLUMN_NAME IS NOT NULL;
-- SELECT GRANTEE, GRANTED_ROLE, DEFAULT_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE LIKE 'MJV_%_DEMO';
-- SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE LIKE 'MJV_%_DEMO';
