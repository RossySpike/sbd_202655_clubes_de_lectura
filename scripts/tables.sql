-- NOTE: el NOCYCLE es para que cuando llegue a 999 no se vaya a -999
CREATE SEQUENCE seq_pais START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


CREATE TABLE pais(
  id_pais NUMBER(3) DEFAULT seq_pais.NEXTVAL PRIMARY KEY, -- 195 paises en el mundo maso
  nombre_pais VARCHAR2(100) NOT NULL,
  moneda_local VARCHAR2(3) NOT NULL, -- (Codigos ISO) USD, VES, COP, etc.
  nacionalidad VARCHAR2(100) NOT NULL UNIQUE
);


CREATE SEQUENCE seq_ciudad START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- NOTE: el NOT NULL es implicito por el CONSTRAINT, se pone para no ser ambiguo
CREATE TABLE ciudad(
  id_pais NUMBER(3) NOT NULL,
  id_ciudad NUMBER(3) DEFAULT seq_ciudad.NEXTVAL,
  nombre_ciudad VARCHAR2(100) NOT NULL,
  CONSTRAINT ciudad_pk PRIMARY KEY (id_pais, id_ciudad),
  CONSTRAINT ciudad_fk_pais FOREIGN KEY (id_pais) REFERENCES pais(id_pais)
);


CREATE SEQUENCE seq_institucion START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


CREATE TABLE institucion(
  id_pais NUMBER(3) NOT NULL,
  id_ciudad NUMBER(3) NOT NULL,
  id_institucion NUMBER(3) DEFAULT seq_institucion.NEXTVAL,
  nombre_inst VARCHAR2(100) NOT NULL,
  tipo VARCHAR2(12) NOT NULL,
  CONSTRAINT institucion_pk PRIMARY KEY (id_pais, id_ciudad, id_institucion),
  CONSTRAINT institucion_fk_ciudad FOREIGN KEY (id_pais, id_ciudad) REFERENCES ciudad(id_pais, id_ciudad),
  CONSTRAINT institucion_ck_tipo CHECK (tipo IN ('biblioteca', 'colegio', 'universidad', 'otro'))
);


CREATE SEQUENCE seq_idioma START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


CREATE TABLE idioma(
  id_idioma NUMBER(3) DEFAULT seq_idioma.NEXTVAL PRIMARY KEY,
  nombre_idioma VARCHAR2(100) NOT NULL -- NOTE: en el ER idioma no tiene el '*'
);


CREATE SEQUENCE seq_club START WITH 1 INCREMENT BY 1 NOCYCLE;


CREATE TABLE club(
  id_club NUMBER DEFAULT seq_club.NEXTVAL PRIMARY KEY,
  nombre_club VARCHAR2(100) NOT NULL,
  cuota_anual CHAR(1) NOT NULL, -- Con una vista se puede pasar a SiNo
  cod_postal VARCHAR2(20) NOT NULL, -- Hay paises con ceros a la izquierda o letras, maximo 11 caracteres (Iran)
  CONSTRAINT club_ck_cuota CHECK (cuota_anual IN ('S', 'N'))
);

CREATE TABLE asociado(
  id_club_izq NUMBER NOT NULL,
  id_club_der NUMBER NOT NULL,
  CONSTRAINT asociado_pk PRIMARY KEY (id_club_izq, id_club_der),
  CONSTRAINT asociado_fk_club_izq FOREIGN KEY (id_club_izq) REFERENCES club(id_club),
  CONSTRAINT asociado_fk_club_der FOREIGN KEY (id_club_der) REFERENCES club(id_club),
  CONSTRAINT asociado_ck_orden CHECK (id_club_izq < id_club_der) -- NOTE: esto se puede cambiar pero es para evitar duplicar (permite 1,2 pero no 2,1 sin embargo hay que mandarlo de forma ordenada) ademas que quita 1,1
);


CREATE SEQUENCE seq_representante START WITH 1 INCREMENT BY 1 NOCYCLE;


CREATE TABLE representante(
  id_representante NUMBER DEFAULT seq_representante.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) NOT NULL,
  p_apellido VARCHAR2(20) NOT NULL,
  doc_identidad VARCHAR2(20) NOT NULL,
  telefono VARCHAR2(20) NOT NULL
);


CREATE SEQUENCE seq_lector START WITH 1 INCREMENT BY 1 NOCYCLE;


CREATE TABLE lector(
  id_lector NUMBER DEFAULT seq_lector.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) NOT NULL,
  p_apellido VARCHAR2(20) NOT NULL,
  s_apellido VARCHAR2(20) NOT NULL,
  doc_identidad VARCHAR2(20) NOT NULL,
  telefono VARCHAR2(20) NOT NULL,
  email VARCHAR2(100) NOT NULL,
  genero CHAR(1) NOT NULL,
  fecha_nac DATE NOT NULL,
  s_nombre VARCHAR2(20),
  id_representante NUMBER,
  id_representante_lector NUMBER,
  CONSTRAINT lector_ck_genero CHECK (genero IN ('F', 'M')),
  CONSTRAINT lector_fk_representante FOREIGN KEY (id_representante) REFERENCES representante(id_representante),
  CONSTRAINT lector_fk_representante_lector FOREIGN KEY (id_representante_lector) REFERENCES lector(id_lector),
  CONSTRAINT lector_ck_arco CHECK (
    (id_representante IS NOT NULL AND id_representante_lector IS NULL)
    OR
    (id_representante IS NULL AND id_representante_lector IS NOT NULL)
  )
);


-- NOTE: trigger para validar mayoria de edad y necesidad de representante
CREATE OR REPLACE TRIGGER tgr_validar_mayoria_edad
BEFORE INSERT ON lector
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

CREATE SEQUENCE seq_idioma_miembro START WITH 1 INCREMENT BY 1 NOCYCLE;


CREATE TABLE idioma_miembro(
  id_idioma NUMBER(3) NOT NULL,
  id_idioma_miembro NUMBER DEFAULT seq_idioma_miembro.NEXTVAL NOT NULL,
  tipo CHAR(1) NOT NULL, -- 'L' = Lector, 'C' = Club
  id_club NUMBER,
  id_lector NUMBER,
  CONSTRAINT idioma_miembro_pk PRIMARY KEY (id_idioma, id_idioma_miembro),
  CONSTRAINT idioma_miembro_fk_idioma FOREIGN KEY (id_idioma) REFERENCES idioma(id_idioma),
  CONSTRAINT idioma_miembro_ck_tipo CHECK (tipo IN ('L', 'C')),
  CONSTRAINT idioma_miembro_fk_club FOREIGN KEY (id_club) REFERENCES club(id_club),
  CONSTRAINT idioma_miembro_fk_lector FOREIGN KEY (id_lector) REFERENCES lector(id_lector),
  CONSTRAINT idioma_miembro_ck_arco CHECK (
    (tipo = 'L' AND id_lector IS NOT NULL AND id_club IS NULL)
    OR
    (tipo = 'C' AND id_club IS NOT NULL AND id_lector IS NULL)
  )
);


CREATE SEQUENCE seq_autor START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE TABLE autor(
  id_autor NUMBER DEFAULT seq_autor.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) ,
  p_apellido VARCHAR2(20) ,
  nombre_ant_pseudonimo VARCHAR2(20)
);

CREATE TABLE libro(
  isbn VARCHAR2(20) PRIMARY KEY,  -- https:/es.wikipedia.org/wiki/ISBN#El_ISBN_de_trece_d%C3%ADgitos
  titulo VARCHAR2(100) NOT NULL,
  tipo_narrativa VARCHAR2(10) NOT NULL,
  sinopsis VARCHAR2(200) NOT NULL,
  genero VARCHAR2(20) NOT NULL,
  primera_edicion NUMBER NOT NULL, -- NOTE: Si solo guardamos el año, sino, date
  total_paginas NUMBER NOT NULL,
  id_pais NUMBER(3) NOT NULL,
  id_libro_siguiente VARCHAR2(20),
  CONSTRAINT libro_tipo_narrativa_ck CHECK (tipo_narrativa IN ('novela','cuento','mito','leyenda','fabula','epopeya')),
  CONSTRAINT libro_idioma_fk_pais FOREIGN KEY ( id_pais ) REFERENCES pais(id_pais),
  CONSTRAINT libro_fk_libro_siguiente FOREIGN KEY ( id_libro_siguiente ) REFERENCES libro(isbn)
);


CREATE TABLE libro_autor(
id_autor NUMBER NOT NULL,
isbn VARCHAR2(20) NOT NULL,
CONSTRAINT libro_autor_pk PRIMARY KEY (id_autor, isbn),
CONSTRAINT libro_autor_fk_autor FOREIGN KEY ( id_autor ) REFERENCES autor(id_autor),
CONSTRAINT libro_autor_fk_libro FOREIGN KEY ( isbn ) REFERENCES libro(isbn)
);


CREATE SEQUENCE seq_grupo START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE TABLE grupo (
  id_grupo NUMBER DEFAULT seq_grupo.NEXTVAL PRIMARY KEY,
  tipo_grupo VARCHAR2(10) NOT NULL,
  fecha_creacion DATE NOT NULL,
  dia_reunion NUMBER(1) NOT NULL, -- 1-7 Domingo, Lunes,...,Sabado
  hora_reunion DATE NOT NULL, -- Hora militar
  CONSTRAINT grupo_ck_tipo CHECK (tipo_grupo IN ('adultos','jovenes','niños')),
  CONSTRAINT grupo_ck_dia_permitido CHECK ((dia_reunion > 1) AND (dia_reunion<7)),
  CONSTRAINT grupo_ck_hora_reunion CHECK (TO_CHAR(hora_reunion, 'SS')='00'),
  CONSTRAINT grupo_ck_hora_permitida CHECK (TO_CHAR(hora_reunion, 'HH24:MI') BETWEEN '17:00' AND '19:00') -- NOTE: Aqui no se si las 7 es hora maxima y ya nadie puede estar o es entre esta franja que pueden iniciar las reuniones, creo que es la ultima porque dice que los grupos de niños no pueden terminar despues de las 7
);

/

-- Verificar que todo se creo correctamente
SELECT object_type, COUNT(*) 
FROM user_objects 
WHERE object_type IN ('TABLE', 'SEQUENCE', 'TRIGGER')
GROUP BY object_type;
