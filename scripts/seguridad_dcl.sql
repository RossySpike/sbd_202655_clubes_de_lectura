-- =============================================================================
-- SEGURIDAD DISCRECIONAL - CLUBES DE LECTURA (Oracle 19c)
-- Archivo: seguridad_dcl.sql
-- Alcance: DISEÑO DE SEGURIDAD PARA USUARIOS FINALES (entrega individual,
-- Rúbrica 2 - Seguridad Lógica). NO crea cuentas DBA ni Desarrollador: se
-- asume que la cuenta MJV_DEV (dueña del esquema: tablas, vistas, secuencias,
-- procedimientos, funciones, triggers de prefijo MJV_) YA EXISTE, creada en
-- otra etapa del proyecto grupal.
--
-- ORDEN DE EJECUCION EN EL PROYECTO:
--   1. script_final.sql              (DDL + datos + triggers base + vistas base)
--   2. complemento_script_final.sql  (funciones, SPs, vistas operativas, brechas)
--   3. seguridad_dcl.sql             (ESTE ARCHIVO - modelo DAC de usuarios finales)
--
-- Quién ejecuta qué:
--   - PARTE 1 (perfiles) y PARTE 2 (cuentas + CREATE SESSION): requieren
--     privilegios de sistema (CREATE PROFILE, CREATE USER). Se ejecutan
--     conectado como DBA (p.ej. SYSTEM o la cuenta DBA del proyecto).
--   - PARTE 3 (CREATE ROLE): requiere el privilegio de sistema CREATE ROLE.
--     Se ejecuta como DBA.
--   - PARTE 4 (GRANT de privilegios de OBJETO sobre vistas/programas hacia
--     los roles): solo el DUEÑO de cada objeto puede otorgarlos. Se ejecuta
--     conectado como MJV_DEV.
--   - PARTE 5 (GRANT rol -> cuenta): requiere tener el rol con ADMIN OPTION
--     o ser DBA. Se ejecuta como DBA.
--   - PARTE 6 (AUDIT): requiere privilegio de sistema AUDIT ANY / AUDIT
--     SYSTEM. Se ejecuta como DBA.
--
-- Estructura del archivo:
--   PARTE 1: Perfiles (PROFILE) para las 5 cuentas de usuario final
--   PARTE 2: Cuentas de Usuario Final + único privilegio de sistema (CREATE SESSION)
--   PARTE 3: Roles de negocio - Miembro_Lector -> Moderador_Grupo -> Administrador_Club
--            (cadena jerárquica de club/reuniones), y Administrador_Obras y
--            Coordinador_Datos como roles hermanos independientes
--   PARTE 4: Privilegios de OBJETO otorgados por MJV_DEV (dueño) a cada rol
--   PARTE 5: Asignación de roles a las cuentas de usuario final
--   PARTE 6: Auditoría temporal sobre DML/EXECUTE críticos
--   PARTE 7: Script de reversión (REVOKE / DROP) para mantenimiento
--   PARTE 8: Notas de verificación contra el diccionario de datos
--
-- Diseño de separación de responsabilidades (5 roles = 3 procesos de negocio
-- del enunciado + el mantenimiento de catálogo maestro + el nivel base de
-- lector):
--   Miembro_Lector      -> consumo básico + votación en obras (todo lector)
--   Moderador_Grupo      -> hereda Lector + Administración de Reuniones
--   Administrador_Club   -> hereda Moderador + Administración de Clubes
--   Administrador_Obras  -> hereda Lector (rol HERMANO de Admin_Club, NO
--                            desciende de él) + Planificación/Ejecución de
--                            Obras Actuadas (Rúbrica 3). Se separa porque es
--                            un proceso de negocio propio con su propio
--                            responsable operativo (logística teatral),
--                            distinto de quien administra membresías/grupos.
--   Coordinador_Datos    -> hereda Lector (rol HERMANO de Admin_Club y
--                            Admin_Obras). Mantiene el catálogo maestro que
--                            ningún otro rol puede tocar: países, ciudades,
--                            instituciones, alta de clubes nuevos y alta de
--                            libros nuevos. Sin este rol, ninguna cuenta de
--                            usuario final podría registrar un libro o un
--                            club nuevo — solo MJV_DEV, que no debería hacer
--                            mantenimiento operativo de datos de negocio.
--   Una cuenta que deba cubrir varias responsabilidades recibe varios roles
--   con un GRANT adicional (son compatibles entre sí, todos hermanos).
-- =============================================================================


-- #############################################################################
-- PARTE 1: PERFILES (PROFILE)
-- Limitan consumo de recursos (sesiones, CPU, tiempo de conexión/ocio) y
-- fuerzan política de contraseñas (vencimiento, reintentos, complejidad).
-- Se ejecuta como DBA. Requiere el privilegio de sistema CREATE PROFILE.
-- #############################################################################

-- Perfil para el Administrador_Club: sesiones concurrentes limitadas y CPU
-- acotada, ya que ejecuta procesos de mayor peso (inscripciones, splits,
-- pagos) pero no debe monopolizar recursos de la instancia compartida.
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

-- Perfil para el Moderador_Grupo: una sola sesión activa (regla de negocio:
-- un moderador no puede liderar más de un grupo simultáneamente, por lo que
-- tampoco tiene sentido que mantenga sesiones concurrentes), consumo medio.
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

-- Perfil para el Administrador_Obras: similar en peso a Admin_Club (procesos
-- batch: planificación de funciones, cálculo de taquilla), pero con menos
-- sesiones concurrentes ya que la logística teatral es más esporádica que
-- la administración diaria de membresías.
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

-- Perfil para el Coordinador_Datos: mantiene el catálogo maestro (países,
-- ciudades, instituciones, clubes, libros). Trabajo administrativo poco
-- frecuente pero de sesiones más largas (carga de datos por lote), similar
-- en peso a Admin_Obras.
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

-- Perfil para el Miembro_Lector (nivel básico): el más restrictivo, una sola
-- sesión, CPU mínima, ideal para consultas puntuales y votaciones ocasionales.
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


-- #############################################################################
-- PARTE 2: CUENTAS DE USUARIO FINAL
-- Toda cuenta debe tener clave obligatoria (IDENTIFIED BY). El único
-- privilegio de SISTEMA que reciben es CREATE SESSION: sin él la cuenta no
-- puede ni siquiera conectarse, y con él por sí solo tampoco puede hacer
-- nada más hasta que el dueño de los objetos (MJV_DEV) le otorgue, vía rol,
-- los privilegios de OBJETO (SELECT/INSERT/UPDATE/EXECUTE) que necesite.
-- Se ejecuta como DBA.
-- #############################################################################

-- QUOTA 0 en las 4 cuentas: correcto y suficiente en este diseño. Todas las
-- filas que insertan los usuarios finales (voto_publico, obra_actuada,
-- elenco, funcion, etc.) viven en tablas propiedad de MJV_DEV; el espacio
-- ocupado por un INSERT se descuenta de la cuota del DUEÑO de la tabla, no
-- de quien ejecuta el INSERT. Los usuarios finales nunca son propietarios
-- de segmentos propios (no tienen CREATE TABLE), así que no necesitan cuota.
CREATE USER MJV_LECTOR_DEMO IDENTIFIED BY "CambiarClaveLector#2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE MJV_perfil_lector
    QUOTA 0 ON USERS;              -- no crea objetos propios

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

-- Único privilegio de SISTEMA que reciben los usuarios finales.
GRANT CREATE SESSION TO MJV_LECTOR_DEMO;
GRANT CREATE SESSION TO MJV_MODERADOR_DEMO;
GRANT CREATE SESSION TO MJV_ADMINCLUB_DEMO;
GRANT CREATE SESSION TO MJV_ADMINOBRAS_DEMO;
GRANT CREATE SESSION TO MJV_COORDINADOR_DEMO;


-- #############################################################################
-- PARTE 3: ROLES DE NEGOCIO JERARQUICOS
-- Los privilegios no se otorgan cuenta por cuenta sino agrupados por rol
-- lógico, para facilitar el mantenimiento (si cambia una regla de negocio,
-- se ajusta el rol una sola vez y todas las cuentas que lo tienen quedan
-- actualizadas automáticamente).
-- Se ejecuta como DBA. Requiere el privilegio de sistema CREATE ROLE.
-- #############################################################################

CREATE ROLE MJV_rol_miembro_lector  NOT IDENTIFIED;
CREATE ROLE MJV_rol_moderador_grupo NOT IDENTIFIED;
CREATE ROLE MJV_rol_admin_club      NOT IDENTIFIED;
CREATE ROLE MJV_rol_admin_obras     NOT IDENTIFIED;
CREATE ROLE MJV_rol_coordinador     NOT IDENTIFIED;

-- Jerarquía de negocio (Administración de Clubes / Reuniones):
-- Moderador_Grupo hereda todo lo de Miembro_Lector, y Administrador_Club
-- hereda todo lo de Moderador_Grupo (y por transitividad de Miembro_Lector).
-- Un solo GRANT rol->rol basta para propagar accesos.
GRANT MJV_rol_miembro_lector  TO MJV_rol_moderador_grupo;
GRANT MJV_rol_moderador_grupo TO MJV_rol_admin_club;

-- Administrador_Obras y Coordinador_Datos son roles HERMANOS de
-- Administrador_Club: los tres descienden de Miembro_Lector, pero ninguno
-- hereda de los otros. Administrador_Obras modela el proceso de negocio
-- independiente de "Planificación y Ejecución de Obras Actuadas" (Rúbrica
-- 3); Coordinador_Datos modela el mantenimiento del catálogo maestro
-- (países, ciudades, instituciones, clubes, libros), que no pertenece a
-- ningún proceso operativo específico sino que los precede a todos.
GRANT MJV_rol_miembro_lector  TO MJV_rol_admin_obras;
GRANT MJV_rol_miembro_lector  TO MJV_rol_coordinador;


-- #############################################################################
-- PARTE 4: PRIVILEGIOS DE OBJETO OTORGADOS POR EL DESARROLLADOR (MJV_DEV) A
-- CADA ROL. Por defecto solo el dueño de un objeto puede otorgar privilegios
-- sobre él; MJV_DEV es dueña de todas las tablas/vistas/programas MJV_*.
-- A PARTIR DE AQUI, CONECTAR COMO MJV_DEV.
-- #############################################################################

-- CONNECT MJV_DEV/<clave_de_MJV_DEV>

-- =============================================================================
-- 4.1 ROL: MJV_rol_miembro_lector  (Nivel Básico)
--   - SELECT sobre vistas de su perfil, listado de obras analizadas y clubes.
--   - INSERT/UPDATE únicamente habilitados para:
--       a) votar por actores en las obras teatrales (MJV_voto_publico,
--          MJV_mejor_actor) — el voto público de 1-5 estrellas por función
--          es exactamente MJV_voto_publico.calificacion_obra.
--       b) aportar su registro individual para la valoración final del
--          libro (1-5), la cual el enunciado indica que se "acuerda entre
--          todos los lectores del grupo" y se consolida/cierra por el
--          Moderador vía MJV_sp_cerrar_discusion_reunion (ver rol 2).
-- =============================================================================

-- --- Lectura de vistas de catálogo / perfil / clubes -----------------------
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

-- --- Votación en obras teatrales (mejor actor + calificación 1-5) ----------
GRANT SELECT, INSERT ON MJV_voto_publico   TO MJV_rol_miembro_lector;
GRANT SELECT, INSERT ON MJV_mejor_actor    TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_obra_actuada           TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_funcion                TO MJV_rol_miembro_lector;
GRANT SELECT ON MJV_elenco                 TO MJV_rol_miembro_lector;

-- --- Secuencia usada por el INSERT anterior --------------------------------
-- MJV_voto_publico.id_voto usa DEFAULT MJV_seq_voto_publico.NEXTVAL: al ser
-- un DEFAULT de columna, Oracle lo resuelve con los privilegios del DUEÑO de
-- la tabla (MJV_DEV), por lo que el rol podría insertar sin este GRANT. Se
-- otorga de todas formas por buena práctica: si la aplicación necesita leer
-- o referenciar el próximo valor explícitamente (p.ej. para mostrarlo antes
-- de confirmar el voto), el privilegio ya está disponible.
GRANT SELECT ON MJV_seq_voto_publico TO MJV_rol_miembro_lector;


-- =============================================================================
-- 4.2 ROL: MJV_rol_moderador_grupo  (Nivel Medio)
--   Hereda MJV_rol_miembro_lector (ya asignado en PARTE 3).
--   Añade permisos de escritura para:
--     a) registrar la asistencia en las reuniones que modera
--        -> EXECUTE sobre MJV_sp_registrar_asistencia_miembro
--     b) actualizar el estatus del libro a "finalizado" registrando las
--        conclusiones grupales y la valoración final acordada (1-5)
--        -> EXECUTE sobre MJV_sp_cerrar_discusion_reunion
--   (MJV_sp_agendar_reunion_mes también se otorga aquí porque el moderador
--   es quien agenda las reuniones de su grupo/libro).
-- =============================================================================

GRANT EXECUTE ON MJV_sp_registrar_asistencia_miembro TO MJV_rol_moderador_grupo;
GRANT EXECUTE ON MJV_sp_cerrar_discusion_reunion     TO MJV_rol_moderador_grupo;
GRANT EXECUTE ON MJV_sp_agendar_reunion_mes          TO MJV_rol_moderador_grupo;

-- Vistas operativas adicionales para el seguimiento de sus reuniones/grupo
GRANT SELECT ON MJV_vw_inasistencias_bimestre           TO MJV_rol_moderador_grupo;
GRANT SELECT ON MJV_vw_moderadores_activos              TO MJV_rol_moderador_grupo;
GRANT SELECT ON MJV_v_asistencia_bimestre               TO MJV_rol_moderador_grupo;
GRANT SELECT ON MJV_v_participacion_mensual_tipo_grupo  TO MJV_rol_moderador_grupo;


-- =============================================================================
-- 4.3 ROL: MJV_rol_admin_club  (Nivel Operativo Alto — Administración de Clubes)
--   Hereda MJV_rol_moderador_grupo (y transitivamente Miembro_Lector).
--   Añade:
--     a) EXECUTE sobre los procedimientos de transacciones complejas:
--        inscripción de miembros, splits automáticos de grupo, y registro
--        de pagos de membresía anual.
--     b) EXECUTE sobre funciones de cálculo de métricas financieras y de
--        crecimiento de los clubes.
--   NOTA: la logística teatral (elencos, funciones, taquilla) NO vive aquí;
--   es responsabilidad exclusiva de MJV_rol_admin_obras (sección 4.4), un
--   rol hermano independiente — ver justificación al inicio del archivo.
-- =============================================================================

-- --- Procedimientos de transacciones complejas -----------------------------
GRANT EXECUTE ON MJV_sp_inscribir_miembro        TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_sp_retirar_miembro          TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_sp_split_grupo              TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_sp_registrar_pago_membresia TO MJV_rol_admin_club;

-- --- Métricas financieras y de crecimiento (EXECUTE sobre funciones) -------
GRANT EXECUTE ON MJV_conversion_monetaria                 TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_promedio_part_mensual_tipo_grupo     TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_participacion_bimestre_miembro       TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_antiguedad_en_club_miembro           TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_edad_miembro                         TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_fn_validar_solvencia_retiro          TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_fn_tiene_deuda_historica             TO MJV_rol_admin_club;
GRANT EXECUTE ON MJV_fn_vetado_por_inasistencia           TO MJV_rol_admin_club;

-- --- Vistas de reportes financieros / crecimiento / solvencia --------------
GRANT SELECT ON MJV_v_crecimiento_clubes         TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_reporte_solvencia         TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_historial_retiros         TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_historial_pagos_membresia TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r1_consolidado            TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r2_consolidado            TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r3_consolidado            TO MJV_rol_admin_club;
GRANT SELECT ON MJV_vw_r4_consolidado            TO MJV_rol_admin_club;


-- =============================================================================
-- 4.4 ROL: MJV_rol_admin_obras  (Nivel Operativo Alto — Planificación y
--   Ejecución de Obras Actuadas, Rúbrica 3)
--   Hereda MJV_rol_miembro_lector directamente (rol HERMANO de admin_club,
--   no desciende de él ni de moderador_grupo).
--   Responsabilidades exclusivas:
--     a) SELECT/INSERT/UPDATE/DELETE sobre la logística teatral completa:
--        obras actuadas, elenco (miembros que actúan) y funciones
--        (calendario de presentaciones: fecha, hora, duración, asistencia).
--     b) Gestión del resultado de la interacción con el público:
--        MJV_voto_publico (calificación 1-5) y MJV_mejor_actor, incluyendo
--        UPDATE para cerrar/consolidar resultados de una función.
--     c) SELECT sobre el reporte consolidado de obras/valoración/taquilla.
-- =============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON MJV_obra_actuada TO MJV_rol_admin_obras;
GRANT SELECT, INSERT, UPDATE, DELETE ON MJV_elenco       TO MJV_rol_admin_obras;
GRANT SELECT, INSERT, UPDATE, DELETE ON MJV_funcion      TO MJV_rol_admin_obras;
GRANT SELECT, UPDATE, DELETE ON MJV_voto_publico         TO MJV_rol_admin_obras;
GRANT SELECT, UPDATE, DELETE ON MJV_mejor_actor          TO MJV_rol_admin_obras;

-- --- Secuencias usadas por los INSERT anteriores ---------------------------
-- MJV_obra_actuada.id_obra_act y MJV_funcion.id_funcion usan DEFAULT
-- ...NEXTVAL (resuelto con privilegios del dueño MJV_DEV, igual que en 4.1).
-- MJV_elenco y MJV_mejor_actor no usan secuencia (PK compuesta manual).
GRANT SELECT ON MJV_seq_obra_actuada TO MJV_rol_admin_obras;
GRANT SELECT ON MJV_seq_funcion      TO MJV_rol_admin_obras;

-- --- Métrica compartida con Admin_Club (conversión monetaria de taquilla) --
GRANT EXECUTE ON MJV_conversion_monetaria TO MJV_rol_admin_obras;

-- --- Vista de reporte de obras/taquilla/valoración (histórico por club) ----
-- MJV_v_obras_presentadas: cantidad de funciones, valoración promedio del
-- público e ingresos acumulados en taquilla por obra — es el reporte
-- operativo propio de este dominio (no confundir con MJV_vw_r3_consolidado,
-- que es la "Ficha de libro" del enunciado y pertenece a Admin_Club).
GRANT SELECT ON MJV_v_obras_presentadas TO MJV_rol_admin_obras;


-- =============================================================================
-- 4.5 ROL: MJV_rol_coordinador  (Mantenimiento de Catálogo Maestro)
--   Hereda MJV_rol_miembro_lector directamente (rol HERMANO de admin_club y
--   admin_obras). Sin este rol, ninguna cuenta de usuario final podría dar
--   de alta un país, ciudad, institución, club o libro nuevo — solo MJV_DEV,
--   que no debería hacer mantenimiento operativo de datos de negocio.
--   Responsabilidades exclusivas:
--     a) SELECT/INSERT/UPDATE sobre el catálogo geográfico e institucional:
--        países, ciudades, instituciones (no DELETE: estos catálogos son
--        referenciados por FK desde club/lector y no deben eliminarse en
--        operación normal, solo corregirse).
--     b) SELECT/INSERT/UPDATE sobre clubes nuevos/existentes y su relación
--        de asociación entre clubes (MJV_asociado).
--     c) SELECT/INSERT/UPDATE sobre el catálogo de libros.
--   NOTA: no incluye ninguna tabla transaccional (membresías, reuniones,
--   pagos, obras teatrales) — esas siguen siendo exclusivas de los otros
--   3 roles operativos.
-- =============================================================================

GRANT SELECT, INSERT, UPDATE ON MJV_pais        TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_ciudad      TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_institucion TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_club        TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_asociado    TO MJV_rol_coordinador;
GRANT SELECT, INSERT, UPDATE ON MJV_libro       TO MJV_rol_coordinador;

-- --- Secuencias usadas por los INSERT anteriores ---------------------------
-- MJV_pais, MJV_ciudad, MJV_institucion y MJV_club usan DEFAULT ...NEXTVAL
-- (resuelto con privilegios del dueño MJV_DEV, igual que en 4.1 y 4.4).
-- MJV_libro usa isbn como PK natural: no requiere secuencia.
-- MJV_asociado usa PK compuesta manual (id_club_izq, id_club_der): tampoco.
GRANT SELECT ON MJV_seq_pais        TO MJV_rol_coordinador;
GRANT SELECT ON MJV_seq_ciudad      TO MJV_rol_coordinador;
GRANT SELECT ON MJV_seq_institucion TO MJV_rol_coordinador;

-- --- Vistas de catálogo para verificar antes de insertar/actualizar --------
GRANT SELECT ON MJV_v_catalogo_libros TO MJV_rol_coordinador;
GRANT SELECT ON MJV_v_ficha_club      TO MJV_rol_coordinador;


-- #############################################################################
-- PARTE 5: ASIGNACION DE ROLES A LAS CUENTAS DE USUARIO FINAL
-- Se ejecuta como DBA.
-- #############################################################################

GRANT MJV_rol_miembro_lector  TO MJV_LECTOR_DEMO;
GRANT MJV_rol_moderador_grupo TO MJV_MODERADOR_DEMO;
GRANT MJV_rol_admin_club      TO MJV_ADMINCLUB_DEMO;
GRANT MJV_rol_admin_obras     TO MJV_ADMINOBRAS_DEMO;
GRANT MJV_rol_coordinador     TO MJV_COORDINADOR_DEMO;

-- Los roles no quedan activos por defecto en cada sesión salvo que se fije
-- explícitamente; se marcan como DEFAULT ROLE para que la aplicación no
-- tenga que emitir un SET ROLE manual en cada conexión.
ALTER USER MJV_LECTOR_DEMO      DEFAULT ROLE MJV_rol_miembro_lector;
ALTER USER MJV_MODERADOR_DEMO   DEFAULT ROLE MJV_rol_moderador_grupo;
ALTER USER MJV_ADMINCLUB_DEMO   DEFAULT ROLE MJV_rol_admin_club;
ALTER USER MJV_ADMINOBRAS_DEMO  DEFAULT ROLE MJV_rol_admin_obras;
ALTER USER MJV_COORDINADOR_DEMO DEFAULT ROLE MJV_rol_coordinador;

-- Ejemplo de cuenta con doble responsabilidad (Admin_Club + Admin_Obras):
-- al ser roles hermanos, basta con otorgar ambos a la misma cuenta.
--   GRANT MJV_rol_admin_club  TO MJV_ADMINCLUB_DEMO;
--   GRANT MJV_rol_admin_obras TO MJV_ADMINCLUB_DEMO;
--   ALTER USER MJV_ADMINCLUB_DEMO DEFAULT ROLE ALL;


-- #############################################################################
-- PARTE 6: AUDITORIA TEMPORAL SOBRE COMANDOS DML / EXECUTE CRITICOS
-- Habilitar solo durante ventanas de revisión/entrega; luego usar el
-- NOAUDIT correspondiente (ver PARTE 7). Requiere privilegio de sistema
-- AUDIT SYSTEM. Se ejecuta como DBA.
-- #############################################################################

-- Auditar pagos de membresía (dinero real involucrado, ver R.N. de $100/año)
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_pago_membresia BY ACCESS;

-- Auditar altas/bajas de membresía (impacto directo en reglas de unicidad
-- de un solo club activo y de solvencia previa a nueva inscripción)
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_historia_membresia BY ACCESS;

-- Auditar movimientos de grupo (altas, retiros de grupo, resultado de splits)
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_g_lec BY ACCESS;

-- Auditar cierres de discusión / valoraciones grupales del libro (1-5): no
-- deben poder alterarse fuera del procedimiento oficial de cierre
AUDIT UPDATE ON MJV_DEV.MJV_calendario_reunion_mes BY ACCESS;

-- Auditar ejecución de los procedimientos de mayor impacto transaccional
AUDIT EXECUTE ON MJV_DEV.MJV_sp_split_grupo              BY ACCESS;
AUDIT EXECUTE ON MJV_DEV.MJV_sp_registrar_pago_membresia  BY ACCESS;
AUDIT EXECUTE ON MJV_DEV.MJV_sp_retirar_miembro           BY ACCESS;

-- Auditar la logística de obras teatrales (dominio Admin_Obras): ingresos
-- por taquilla y resultados de votación pública son datos sensibles al
-- ser fuente de ingreso alternativa del club y de reconocimiento a actores.
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_obra_actuada BY ACCESS;
AUDIT INSERT, UPDATE, DELETE ON MJV_DEV.MJV_funcion      BY ACCESS;

-- Auditar el mantenimiento del catálogo maestro (dominio Coordinador_Datos):
-- altas/cambios de club e institución afectan directamente a qué cuota
-- cobra un club (cuota_anual) y a la relación de asociación entre clubes.
AUDIT INSERT, UPDATE ON MJV_DEV.MJV_club        BY ACCESS;
AUDIT INSERT, UPDATE ON MJV_DEV.MJV_institucion BY ACCESS;

-- Auditar la administración misma de los roles de usuario final (creación,
-- modificación, asignación) tal como recomienda el material teórico
-- (AUDIT ROLE WHENEVER SUCCESSFUL).
AUDIT ROLE WHENEVER SUCCESSFUL;

-- Consultas de verificación de auditoría activa:
-- SELECT * FROM DBA_AUDIT_TRAIL   WHERE OWNER = 'MJV_DEV' ORDER BY TIMESTAMP DESC;
-- SELECT * FROM DBA_STMT_AUDIT_OPTS;
-- SELECT * FROM DBA_OBJ_AUDIT_OPTS WHERE OWNER = 'MJV_DEV';
-- SELECT * FROM DBA_AUDIT_TRAIL   WHERE DB_USER LIKE 'MJV_%_DEMO';


-- #############################################################################
-- PARTE 7: SCRIPT DE REVERSION (mantenimiento / desmontaje del modelo)
-- No ejecutar junto con las partes anteriores. Usar solo para deshacer el
-- diseño completo en un entorno de pruebas.
-- #############################################################################

/*
-- --- Desactivar auditoría ---------------------------------------------
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

-- --- Quitar roles de las cuentas ----------------------------------------
REVOKE MJV_rol_miembro_lector  FROM MJV_LECTOR_DEMO;
REVOKE MJV_rol_moderador_grupo FROM MJV_MODERADOR_DEMO;
REVOKE MJV_rol_admin_club      FROM MJV_ADMINCLUB_DEMO;
REVOKE MJV_rol_admin_obras     FROM MJV_ADMINOBRAS_DEMO;
REVOKE MJV_rol_coordinador     FROM MJV_COORDINADOR_DEMO;

-- --- Eliminar roles (arrastra los GRANT de objeto internos) -------------
DROP ROLE MJV_rol_admin_obras;
DROP ROLE MJV_rol_coordinador;
DROP ROLE MJV_rol_admin_club;
DROP ROLE MJV_rol_moderador_grupo;
DROP ROLE MJV_rol_miembro_lector;

-- --- Eliminar cuentas de usuario final -----------------------------------
DROP USER MJV_LECTOR_DEMO CASCADE;
DROP USER MJV_MODERADOR_DEMO CASCADE;
DROP USER MJV_ADMINCLUB_DEMO CASCADE;
DROP USER MJV_ADMINOBRAS_DEMO CASCADE;
DROP USER MJV_COORDINADOR_DEMO CASCADE;

-- --- Eliminar perfiles ---------------------------------------------------
DROP PROFILE MJV_perfil_lector CASCADE;
DROP PROFILE MJV_perfil_moderador CASCADE;
DROP PROFILE MJV_perfil_admin_club CASCADE;
DROP PROFILE MJV_perfil_admin_obras CASCADE;
DROP PROFILE MJV_perfil_coordinador CASCADE;
*/


-- #############################################################################
-- PARTE 8: NOTAS DE VERIFICACION (diccionario de datos)
-- #############################################################################

-- Jerarquía de roles otorgados a un rol (herencia Miembro_Lector -> Moderador
-- -> Admin_Club, y Miembro_Lector -> Admin_Obras como rama hermana):
-- SELECT * FROM ROLE_ROLE_PRIVS WHERE ROLE LIKE 'MJV_ROL%';

-- Privilegios de objeto por rol (equivalente a user_tab_privs, pero para roles):
-- SELECT * FROM ROLE_TAB_PRIVS WHERE ROLE LIKE 'MJV_ROL%' ORDER BY ROLE, TABLE_NAME;

-- Privilegios de columna (UPDATE granular), equivalente a user_col_privs:
-- SELECT * FROM ROLE_TAB_PRIVS WHERE ROLE LIKE 'MJV_ROL%' AND COLUMN_NAME IS NOT NULL;

-- Roles asignados a cada cuenta de usuario final y cuál es el default:
-- SELECT GRANTEE, GRANTED_ROLE, DEFAULT_ROLE FROM DBA_ROLE_PRIVS
--  WHERE GRANTEE LIKE 'MJV_%_DEMO';

-- Verificar que los usuarios finales NO tengan privilegios de sistema
-- adicionales a CREATE SESSION (equivalente a user_sys_privs vista por el DBA):
-- SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE LIKE 'MJV_%_DEMO';
