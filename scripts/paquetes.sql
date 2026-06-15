-- =============================================================================
-- PROYECTO: Sistema de Gestión de Clubes de Lectura
-- ARCHIVO:  paquetes.sql
-- MOTOR:    Oracle 19c
--
-- ORDEN DE EJECUCIÓN:
--   1. script_final.sql
--   2. complemento_script_final.sql
--   3. paquetes.sql                  ← ESTE ARCHIVO
--
-- CONTIENE:
--   • MJV_PKG_ADMIN_CLUBES    — inscribir miembro, registrar pago, retirar miembro
--   • MJV_PKG_ADMIN_REUNIONES — agendar reunión, registrar asistencia, cerrar discusión
--
-- NOTA: Los paquetes reenvían la llamada a los procedures autónomos ya compilados
--       en complemento_script_final.sql. No se duplica lógica.
-- =============================================================================


-- =============================================================================
-- PAQUETE 1: MJV_PKG_ADMIN_CLUBES
-- =============================================================================

CREATE OR REPLACE PACKAGE MJV_PKG_ADMIN_CLUBES AS

    -- Inscribe un nuevo lector en un club, asignándolo al grupo por edad y
    -- registrando sus 3 preferencias de obra.
    PROCEDURE inscribir_miembro (
        pi_p_nombre        IN VARCHAR2,
        pi_p_apellido      IN VARCHAR2,
        pi_s_nombre        IN VARCHAR2 DEFAULT NULL,
        pi_s_apellido      IN VARCHAR2,
        pi_doc_identidad   IN VARCHAR2,
        pi_telefono        IN VARCHAR2,
        pi_email           IN VARCHAR2,
        pi_genero          IN VARCHAR2,
        pi_fecha_nac       IN DATE,
        pi_nombre_pais_nac IN VARCHAR2,
        pi_nombre_club     IN VARCHAR2,
        pi_titulo_pref1    IN VARCHAR2,
        pi_titulo_pref2    IN VARCHAR2,
        pi_titulo_pref3    IN VARCHAR2,
        pi_id_rep          IN NUMBER   DEFAULT NULL,
        pi_tipo_rep        IN VARCHAR2 DEFAULT NULL
    );

    -- Registra un pago de cuota anual para un lector activo en un club con cuota.
    PROCEDURE registrar_pago (
        pi_id_lector   IN NUMBER,
        pi_nombre_club IN VARCHAR2,
        pi_monto       IN NUMBER,
        pi_moneda      IN VARCHAR2,
        pi_tasa        IN NUMBER
    );

    -- Procesa el retiro voluntario o administrativo de un lector de un club.
    PROCEDURE retirar_miembro (
        pi_id_lector     IN NUMBER,
        pi_nombre_club   IN VARCHAR2,
        pi_motivo_retiro IN VARCHAR2
    );

END MJV_PKG_ADMIN_CLUBES;
/

CREATE OR REPLACE PACKAGE BODY MJV_PKG_ADMIN_CLUBES AS

    PROCEDURE inscribir_miembro (
        pi_p_nombre        IN VARCHAR2,
        pi_p_apellido      IN VARCHAR2,
        pi_s_nombre        IN VARCHAR2 DEFAULT NULL,
        pi_s_apellido      IN VARCHAR2,
        pi_doc_identidad   IN VARCHAR2,
        pi_telefono        IN VARCHAR2,
        pi_email           IN VARCHAR2,
        pi_genero          IN VARCHAR2,
        pi_fecha_nac       IN DATE,
        pi_nombre_pais_nac IN VARCHAR2,
        pi_nombre_club     IN VARCHAR2,
        pi_titulo_pref1    IN VARCHAR2,
        pi_titulo_pref2    IN VARCHAR2,
        pi_titulo_pref3    IN VARCHAR2,
        pi_id_rep          IN NUMBER   DEFAULT NULL,
        pi_tipo_rep        IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        MJV_sp_inscribir_miembro(
            pi_p_nombre        => pi_p_nombre,
            pi_p_apellido      => pi_p_apellido,
            pi_s_nombre        => pi_s_nombre,
            pi_s_apellido      => pi_s_apellido,
            pi_doc_identidad   => pi_doc_identidad,
            pi_telefono        => pi_telefono,
            pi_email           => pi_email,
            pi_genero          => pi_genero,
            pi_fecha_nac       => pi_fecha_nac,
            pi_nombre_pais_nac => pi_nombre_pais_nac,
            pi_nombre_club     => pi_nombre_club,
            pi_titulo_pref1    => pi_titulo_pref1,
            pi_titulo_pref2    => pi_titulo_pref2,
            pi_titulo_pref3    => pi_titulo_pref3,
            pi_id_rep          => pi_id_rep,
            pi_tipo_rep        => pi_tipo_rep
        );
    END inscribir_miembro;

    PROCEDURE registrar_pago (
        pi_id_lector   IN NUMBER,
        pi_nombre_club IN VARCHAR2,
        pi_monto       IN NUMBER,
        pi_moneda      IN VARCHAR2,
        pi_tasa        IN NUMBER
    ) IS
    BEGIN
        MJV_sp_registrar_pago_membresia(
            pi_id_lector   => pi_id_lector,
            pi_nombre_club => pi_nombre_club,
            pi_monto       => pi_monto,
            pi_moneda      => pi_moneda,
            pi_tasa        => pi_tasa
        );
    END registrar_pago;

    PROCEDURE retirar_miembro (
        pi_id_lector     IN NUMBER,
        pi_nombre_club   IN VARCHAR2,
        pi_motivo_retiro IN VARCHAR2
    ) IS
    BEGIN
        MJV_sp_retirar_miembro(
            pi_id_lector     => pi_id_lector,
            pi_nombre_club   => pi_nombre_club,
            pi_motivo_retiro => pi_motivo_retiro
        );
    END retirar_miembro;

END MJV_PKG_ADMIN_CLUBES;
/


-- =============================================================================
-- PAQUETE 2: MJV_PKG_ADMIN_REUNIONES
-- =============================================================================

CREATE OR REPLACE PACKAGE MJV_PKG_ADMIN_REUNIONES AS

    -- Agenda una reunión mensual para un grupo/libro, validando hora, moderador
    -- y conflictos de horario.
    PROCEDURE agendar_reunion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_isbn          IN VARCHAR2,
        pi_fecha_reunion IN DATE,
        pi_hora_inicio   IN DATE,
        pi_mod_id_lector IN NUMBER
    );

    -- Registra la asistencia (S) o inasistencia (N) de un miembro a una reunión.
    -- Si es inasistencia, activa la evaluación de retiro automático por bimestre.
    PROCEDURE registrar_asistencia (
        pi_id_lector     IN NUMBER,
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_asistio       IN CHAR
    );

    -- Cierra la discusión de un libro en una reunión, registrando conclusiones
    -- y valoración final (1–5). Solo aplica si la reunión ya fue realizada.
    PROCEDURE cerrar_discusion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_conclusiones  IN VARCHAR2,
        pi_valoracion    IN NUMBER
    );

END MJV_PKG_ADMIN_REUNIONES;
/

CREATE OR REPLACE PACKAGE BODY MJV_PKG_ADMIN_REUNIONES AS

    PROCEDURE agendar_reunion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_isbn          IN VARCHAR2,
        pi_fecha_reunion IN DATE,
        pi_hora_inicio   IN DATE,
        pi_mod_id_lector IN NUMBER
    ) IS
    BEGIN
        MJV_sp_agendar_reunion_mes(
            pi_id_club       => pi_id_club,
            pi_id_grupo      => pi_id_grupo,
            pi_isbn          => pi_isbn,
            pi_fecha_reunion => pi_fecha_reunion,
            pi_hora_inicio   => pi_hora_inicio,
            pi_mod_id_lector => pi_mod_id_lector
        );
    END agendar_reunion;

    PROCEDURE registrar_asistencia (
        pi_id_lector     IN NUMBER,
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_asistio       IN CHAR
    ) IS
    BEGIN
        MJV_sp_registrar_asistencia_miembro(
            pi_id_lector     => pi_id_lector,
            pi_id_club       => pi_id_club,
            pi_id_grupo      => pi_id_grupo,
            pi_fecha_reunion => pi_fecha_reunion,
            pi_isbn          => pi_isbn,
            pi_asistio       => pi_asistio
        );
    END registrar_asistencia;

    PROCEDURE cerrar_discusion (
        pi_id_club       IN NUMBER,
        pi_id_grupo      IN NUMBER,
        pi_fecha_reunion IN DATE,
        pi_isbn          IN VARCHAR2,
        pi_conclusiones  IN VARCHAR2,
        pi_valoracion    IN NUMBER
    ) IS
    BEGIN
        MJV_sp_cerrar_discusion_reunion(
            pi_id_club       => pi_id_club,
            pi_id_grupo      => pi_id_grupo,
            pi_fecha_reunion => pi_fecha_reunion,
            pi_isbn          => pi_isbn,
            pi_conclusiones  => pi_conclusiones,
            pi_valoracion    => pi_valoracion
        );
    END cerrar_discusion;

END MJV_PKG_ADMIN_REUNIONES;
/

-- Verificar compilación
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('MJV_PKG_ADMIN_CLUBES', 'MJV_PKG_ADMIN_REUNIONES')
 ORDER BY object_type, object_name;
