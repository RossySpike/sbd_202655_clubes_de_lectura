-- NOTE: trigger para validar mayoria de edad y necesidad de representante
CREATE OR REPLACE TRIGGER tgr_validar_mayoria_edad
BEFORE INSERT OR UPDATE ON lector
FOR EACH ROW
DECLARE
  meses NUMBER;
  edad NUMBER;
BEGIN
  meses := MONTHS_BETWEEN(SYSDATE, :NEW.fecha_nac) ;
  edad := TRUNC(meses/12);
  IF edad >= 18 THEN
    IF :NEW.id_representante IS NOT NULL OR :NEW.id_representante_lector IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20001, 'Los mayores de edad no necesitan representante');
    END IF;
  ELSE
    IF :NEW.id_representante IS NULL AND :NEW.id_representante_lector IS NULL THEN
      RAISE_APPLICATION_ERROR(-20001, 'Menor de edad sin representante asignado.');
    END IF;
  END IF;
END;
/

-- HC-07: Un lector no puede tener más de una membresía activa en diferentes clubes al mismo tiempo
CREATE OR REPLACE TRIGGER tgr_un_club_activo
BEFORE INSERT OR UPDATE ON historia_membresia
FOR EACH ROW
WHEN (NEW.estatus = 'activo')
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM historia_membresia
  WHERE id_lector = :NEW.id_lector
    AND estatus   = 'activo'
    AND NOT (id_club = :NEW.id_club AND fecha_i = :NEW.fecha_i);

  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20002,
      'El lector ya tiene membresía activa en otro club.');
  END IF;
END;
/

-- HC-08: Grupos de ninos deben iniciar a las 17:00 como maximo para terminar antes de las 19:00
-- (duracion maxima de reunion = 2 horas segun enunciado)
CREATE OR REPLACE TRIGGER tgr_hora_grupo_ninos
BEFORE INSERT OR UPDATE ON grupo
FOR EACH ROW
WHEN (NEW.tipo_grupo = 'niños')
BEGIN
  IF TO_CHAR(:NEW.hora_reunion, 'HH24:MI') > '17:00' THEN
    RAISE_APPLICATION_ERROR(-20003,
      'Los grupos de niños deben iniciar a más tardar a las 17:00 para terminar antes de las 19:00.');
  END IF;
END;
/

-- HC-10: Al retirar un miembro, motivo_retiro y fecha_f son obligatorios
CREATE OR REPLACE TRIGGER tgr_retiro_completo
BEFORE INSERT OR UPDATE ON historia_membresia
FOR EACH ROW
WHEN (NEW.estatus = 'retirado')
BEGIN
  IF :NEW.motivo_retiro IS NULL THEN
    RAISE_APPLICATION_ERROR(-20004, 'El motivo de retiro es obligatorio al cambiar estatus a retirado.');
  END IF;
  IF :NEW.fecha_f IS NULL THEN
    RAISE_APPLICATION_ERROR(-20005, 'La fecha de fin es obligatoria al cambiar estatus a retirado.');
  END IF;
END;
/