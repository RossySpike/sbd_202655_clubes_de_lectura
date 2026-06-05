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

-- Convierte un monto entre monedas usando una tasa suministrada por quien ejecuta.
-- p_tasa = unidades de p_moneda_destino por cada 1 unidad de p_moneda_origen.
-- Valida que ambas monedas existan en pais.moneda_local.
CREATE OR REPLACE FUNCTION conversion_monetaria(
  p_monto          NUMBER,
  p_moneda_origen  VARCHAR2,
  p_moneda_destino VARCHAR2,
  p_tasa           NUMBER,
  p_fecha          DATE DEFAULT SYSDATE
) RETURN NUMBER
IS
  v_origen  VARCHAR2(3) := UPPER(TRIM(p_moneda_origen));
  v_destino VARCHAR2(3) := UPPER(TRIM(p_moneda_destino));
  v_count   NUMBER;
BEGIN
  IF p_monto IS NULL OR p_tasa IS NULL THEN
    RETURN NULL;
  END IF;

  IF v_origen = v_destino THEN
    RETURN p_monto;
  END IF;

  IF p_tasa <= 0 THEN
    RAISE_APPLICATION_ERROR(-20101, 'La tasa de conversión debe ser mayor que cero.');
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM pais
  WHERE moneda_local = v_origen;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20102, 'Moneda origen no registrada: ' || v_origen);
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM pais
  WHERE moneda_local = v_destino;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20103, 'Moneda destino no registrada: ' || v_destino);
  END IF;

  RETURN ROUND(p_monto * p_tasa, 2);
END conversion_monetaria;
/

-- Retorna la edad del lector en años: ROUND((SYSDATE - fecha_nac) / 365, 0).
CREATE OR REPLACE FUNCTION edad_miembro(p_id_lector NUMBER)
RETURN NUMBER
IS
  v_fecha_nac DATE;
BEGIN
  SELECT fecha_nac
  INTO v_fecha_nac
  FROM lector
  WHERE id_lector = p_id_lector;

  RETURN ROUND((SYSDATE - v_fecha_nac) / 365, 0);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20110, 'Lector no encontrado: ' || p_id_lector);
END edad_miembro;
/

-- Retorna la antigüedad del lector en el club en años.
-- Usa la membresía activa; si fecha_f es NULL, calcula hasta SYSDATE.
CREATE OR REPLACE FUNCTION antiguedad_en_club_miembro(
  p_id_lector NUMBER,
  p_id_club   NUMBER
) RETURN NUMBER
IS
  v_fecha_i DATE;
  v_fecha_f DATE;
BEGIN
  SELECT fecha_i, fecha_f
  INTO v_fecha_i, v_fecha_f
  FROM historia_membresia
  WHERE id_lector = p_id_lector
    AND id_club   = p_id_club
    AND estatus   = 'activo';

  RETURN ROUND((NVL(v_fecha_f, SYSDATE) - v_fecha_i) / 365, 0);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20111,
      'No hay membresía activa para lector ' || p_id_lector || ' en club ' || p_id_club);
END antiguedad_en_club_miembro;
/

-- Promedio de asistencia (0-100) de los grupos de un tipo en un club, para un mes/año.
-- Por cada grupo: ((oportunidades - inasistencias) / oportunidades) * 100; luego AVG entre grupos.
-- Oportunidad = miembro activo en g_lec que debía asistir a una reunión realizada del mes.
CREATE OR REPLACE FUNCTION promedio_part_mensual_tipo_grupo(
  p_id_club    NUMBER,
  p_tipo_grupo VARCHAR2,
  p_mes        NUMBER,
  p_anio       NUMBER
) RETURN NUMBER
IS
  v_tipo     VARCHAR2(10) := TRIM(p_tipo_grupo);
  v_promedio NUMBER;
BEGIN
  IF p_mes < 1 OR p_mes > 12 THEN
    RAISE_APPLICATION_ERROR(-20120, 'El mes debe estar entre 1 y 12.');
  END IF;

  SELECT ROUND(AVG(((esperadas - faltas) / esperadas) * 100), 2)
  INTO v_promedio
  FROM (
    SELECT g.id_grupo,
      (SELECT COUNT(*)
       FROM calendario_reunion_mes crm
       JOIN g_lec gl
         ON gl.id_grupo = crm.id_grupo
        AND gl.id_club  = g.id_club
       WHERE crm.id_grupo = g.id_grupo
         AND crm.realizada = 'S'
         AND EXTRACT(MONTH FROM crm.fecha) = p_mes
         AND EXTRACT(YEAR FROM crm.fecha)  = p_anio
         AND gl.fec_i <= crm.fecha
         AND (gl.fec_f IS NULL OR gl.fec_f >= crm.fecha)
      ) AS esperadas,
      (SELECT COUNT(*)
       FROM inasistencia i
       JOIN calendario_reunion_mes crm
         ON crm.id_grupo = i.id_grupo
        AND crm.fecha    = i.fecha_reunion
       WHERE i.id_grupo = g.id_grupo
         AND i.id_club  = g.id_club
         AND crm.realizada = 'S'
         AND EXTRACT(MONTH FROM crm.fecha) = p_mes
         AND EXTRACT(YEAR FROM crm.fecha)  = p_anio
      ) AS faltas
    FROM grupo g
    WHERE g.id_club    = p_id_club
      AND g.tipo_grupo = v_tipo
  )
  WHERE esperadas > 0;

  RETURN NVL(v_promedio, 0);
END promedio_part_mensual_tipo_grupo;
/

-- Porcentaje de asistencia (0-100) de un lector en un club durante un bimestre.
-- Bimestre 1 = ene-feb, 2 = mar-abr, 3 = may-jun, 4 = jul-ago, 5 = sep-oct, 6 = nov-dic.
CREATE OR REPLACE FUNCTION participacion_bimestre_miembro(
  p_id_lector NUMBER,
  p_id_club   NUMBER,
  p_bimestre  NUMBER,
  p_anio      NUMBER
) RETURN NUMBER
IS
  v_mes_ini   NUMBER;
  v_mes_fin   NUMBER;
  v_esperadas NUMBER;
  v_faltas    NUMBER;
BEGIN
  IF p_bimestre < 1 OR p_bimestre > 6 THEN
    RAISE_APPLICATION_ERROR(-20121, 'El bimestre debe estar entre 1 y 6.');
  END IF;

  v_mes_ini := (p_bimestre - 1) * 2 + 1;
  v_mes_fin := p_bimestre * 2;

  SELECT COUNT(*)
  INTO v_esperadas
  FROM calendario_reunion_mes crm
  JOIN g_lec gl
    ON gl.id_grupo = crm.id_grupo
   AND gl.id_club  = p_id_club
  WHERE gl.id_lector = p_id_lector
    AND gl.id_club   = p_id_club
    AND crm.realizada = 'S'
    AND EXTRACT(YEAR FROM crm.fecha) = p_anio
    AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin
    AND gl.fec_i <= crm.fecha
    AND (gl.fec_f IS NULL OR gl.fec_f >= crm.fecha);

  IF v_esperadas = 0 THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*)
  INTO v_faltas
  FROM inasistencia i
  JOIN calendario_reunion_mes crm
    ON crm.id_grupo = i.id_grupo
   AND crm.fecha    = i.fecha_reunion
  WHERE i.id_lector = p_id_lector
    AND i.id_club   = p_id_club
    AND crm.realizada = 'S'
    AND EXTRACT(YEAR FROM crm.fecha) = p_anio
    AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin;

  RETURN ROUND(((v_esperadas - v_faltas) / v_esperadas) * 100, 2);
END participacion_bimestre_miembro;
/

