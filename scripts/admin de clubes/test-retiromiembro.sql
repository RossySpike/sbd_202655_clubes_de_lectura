
SET SERVEROUTPUT ON;

DECLARE
    v_doc    VARCHAR2(20)  := '&documento_identidad_lector';
    v_club   VARCHAR2(150) := '&nombre_exacto_del_club';
    v_motivo VARCHAR2(200) := '&motivo_retiro_voluntario_inasistencia_deuda_otro';
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => v_doc,
        pi_nombre_club   => v_club,
        pi_motivo_retiro => LOWER(TRIM(v_motivo))
    );
END;

--- Test especializados
---------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => 'V-00000000', -- Cédula inventada
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'Prueba de fantasma'
    );
END;

-------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => 'V-31066026',
        pi_nombre_club   => 'Refugio del Norte', -- Club falso
        pi_motivo_retiro => 'Prueba de club falso'
    );
END;

----------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => 'V3345454', -- Cédula de Ara (sin guion según tu imagen)
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'voluntario'
    );
END;

-------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => 'V3345454', 
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'Intento de doble retiro'
    );
END;

----------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
    MJV_sp_retirar_miembro(
        pi_doc_identidad => 'V-31066026', -- Cédula de Marco
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_motivo_retiro => 'deuda'
    );
END;

-- Test de insolvencia o aviso tardio
---- Escenario No solvente en pagos
-----------------------------------------------------------------------
SET SERVEROUTPUT ON;

BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-ADU01',
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => 105,
        pi_moneda        => 'EUR',
        pi_tasa          => 1.05
    );
END;

UPDATE MJV_historia_membresia 
   SET fecha_i = ADD_MONTHS(SYSDATE, -13) -- Hace 13 meses
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');
COMMIT;

-- 2. Intentamos retirar
BEGIN
    MJV_sp_retirar_miembro('V-ADU01', 'Refugio Literario del Sur', 'otro');
END;

--------------------------------------------------------------------------------
---- Escenario aviso tardio

SET SERVEROUTPUT ON;

-- 1. Desactivamos triggers y restricciones temporalmente
ALTER TRIGGER MJV_TGR_UN_CLUB_ACTIVO DISABLE;
ALTER TABLE MJV_g_lec DISABLE CONSTRAINT MJV_G_LEC_FK_HM;

-- 2. Limpiamos sus pagos anteriores y le insertamos su cuota del 1er año (100 USD)
DELETE FROM MJV_pago_membresia 
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

INSERT INTO MJV_pago_membresia (id_lector, id_club, fecha_i, fecha_pago, monto)
SELECT l.id_lector, c.id_club, h.fecha_i, SYSDATE, 100
  FROM MJV_lector l, MJV_clubes c, MJV_historia_membresia h
 WHERE l.doc_identidad = 'V-ADU01'
   AND c.nombre_club = 'Refugio Literario del Sur' -- ¡Cámbialo si está en otro club!
   AND h.id_lector = l.id_lector
   AND h.id_club = c.id_club;

-- 3. Restauramos a V-ADU01 para asegurarnos de que está ACTIVO
UPDATE MJV_historia_membresia
   SET estatus = 'activo', fecha_f = NULL, motivo = NULL
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

UPDATE MJV_g_lec
   SET fec_f = NULL
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

-- 4. Viajamos en el tiempo (-11 meses para forzar el aviso tardío)
UPDATE MJV_historia_membresia 
   SET fecha_i = ADD_MONTHS(SYSDATE, -11)
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

UPDATE MJV_g_lec 
   SET fecha_i = ADD_MONTHS(SYSDATE, -11) 
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

-- 5. Reactivamos todo y guardamos los cambios
ALTER TABLE MJV_g_lec ENABLE CONSTRAINT MJV_G_LEC_FK_HM;
ALTER TRIGGER MJV_TGR_UN_CLUB_ACTIVO ENABLE;
COMMIT;

-- 6. AHORA SÍ: Ejecutamos el procedimiento de retiro
BEGIN
    MJV_sp_retirar_miembro('V-ADU01', 'Refugio Literario del Sur', 'otro'); 
END;


------------------------------------------------------------------------------------------
---- Escenario feliz

SET SERVEROUTPUT ON;

BEGIN
    MJV_sp_registrar_pago_membresia(
        pi_doc_identidad => 'V-ADU01',
        pi_nombre_club   => 'Refugio Literario del Sur',
        pi_monto         => 105,
        pi_moneda        => 'EUR',
        pi_tasa          => 1.05
    );
END;

-- 1. Configuramos el escenario (Justo el aniversario, pero con pagos al día)
UPDATE MJV_historia_membresia 
   SET fecha_i = ADD_MONTHS(SYSDATE, -12)
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');
COMMIT;

-- 2. Intentamos retirar
BEGIN
    MJV_sp_retirar_miembro('V-ADU01', 'Refugio Literario del Sur', 'voluntario');
END;



-- Reactivacion de miembro por si acaso --
-- 1. Dormimos al guardia (trigger) temporalmente para que no moleste
ALTER TRIGGER MJV_TGR_UN_CLUB_ACTIVO DISABLE;

-- 2. Restauramos su estatus en el historial y borramos la huella del retiro
UPDATE MJV_historia_membresia
   SET estatus = 'activo',
       fecha_f = NULL,
       motivo_retiro  = NULL
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

-- 3. Lo volvemos a meter en su grupo de lectura activo
UPDATE MJV_g_lec
   SET fec_f = NULL
 WHERE id_lector = (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01');

COMMIT;

-- 4. Despertamos al guardia de nuevo (Opcional: Si vas a borrar el trigger por la Opción 2, no corras esta línea)
ALTER TRIGGER MJV_TGR_UN_CLUB_ACTIVO ENABLE;

DBMS_OUTPUT.PUT_LINE('¡El lector V-ADU01 ha sido restaurado con éxito!');