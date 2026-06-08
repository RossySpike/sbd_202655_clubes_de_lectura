-- NOTE: el NOCYCLE es para que cuando llegue a 999 no se vaya a -999
CREATE SEQUENCE MJV_seq_pais START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_pais(
  id_pais NUMBER(3) DEFAULT MJV_seq_pais.NEXTVAL PRIMARY KEY, -- 195 paises en el mundo maso
  nombre_pais VARCHAR2(100) NOT NULL,
  moneda_local VARCHAR2(3) NOT NULL, -- (Codigos ISO) USD, VES, COP, etc.
  nacionalidad VARCHAR2(100) NOT NULL UNIQUE
);


CREATE SEQUENCE MJV_seq_ciudad START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
-- NOTE: el NOT NULL es implicito por el CONSTRAINT, se pone para no ser ambiguo
CREATE TABLE MJV_ciudad(
  id_pais NUMBER(3) NOT NULL,
  id_ciudad NUMBER(3) DEFAULT MJV_seq_ciudad.NEXTVAL,
  nombre_ciudad VARCHAR2(100) NOT NULL,
 CONSTRAINT MJV_ciudad_pk PRIMARY KEY (id_pais, id_ciudad),
 CONSTRAINT MJV_ciudad_fk_pais FOREIGN KEY (id_pais) REFERENCES MJV_pais(id_pais)
);


CREATE SEQUENCE MJV_seq_institucion START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_institucion(
  id_pais NUMBER(3) NOT NULL,
  id_ciudad NUMBER(3) NOT NULL,
  id_institucion NUMBER(3) DEFAULT MJV_seq_institucion.NEXTVAL NOT NULL,
  nombre_inst VARCHAR2(100) NOT NULL,
  tipo VARCHAR2(12) NOT NULL,
 CONSTRAINT MJV_institucion_pk PRIMARY KEY (id_pais, id_ciudad, id_institucion),
 CONSTRAINT MJV_institucion_fk_ciudad FOREIGN KEY (id_pais, id_ciudad) REFERENCES MJV_ciudad(id_pais, id_ciudad),
 CONSTRAINT MJV_institucion_ck_tipo CHECK (tipo IN ('biblioteca', 'colegio', 'universidad', 'otro'))
);


CREATE SEQUENCE MJV_seq_idioma START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_idioma(
  id_idioma NUMBER(3) DEFAULT MJV_seq_idioma.NEXTVAL PRIMARY KEY,
  nombre_idioma VARCHAR2(100) NOT NULL -- NOTE: en el ER idioma no tiene el '*'
);


CREATE SEQUENCE MJV_seq_club START WITH 1 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_club(
  id_club NUMBER DEFAULT MJV_seq_club.NEXTVAL PRIMARY KEY,
  nombre_club VARCHAR2(100) NOT NULL,
  cuota_anual CHAR(1) NOT NULL, -- Con una vista se puede pasar a SiNo
  cod_postal VARCHAR2(20) NOT NULL, -- Hay paises con ceros a la izquierda o letras, maximo 11 caracteres (Iran)
-- Ciudad
  id_ciudad NUMBER(3) NOT NULL,
  id_pais NUMBER(3) NOT NULL,
  id_institucion NUMBER(3),
CONSTRAINT MJV_club_fk_ciudad FOREIGN KEY (id_pais, id_ciudad ) REFERENCES MJV_ciudad( id_pais, id_ciudad),
CONSTRAINT MJV_club_fk_institucion FOREIGN KEY (id_pais, id_ciudad, id_institucion) 
    REFERENCES MJV_institucion(id_pais, id_ciudad, id_institucion),
 CONSTRAINT MJV_club_ck_cuota CHECK (cuota_anual IN ('S', 'N'))
);

-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
CREATE TABLE MJV_asociado(
  id_club_izq NUMBER NOT NULL,
  id_club_der NUMBER NOT NULL,
 CONSTRAINT MJV_asociado_pk PRIMARY KEY (id_club_izq, id_club_der),
 CONSTRAINT MJV_asociado_fk_club_izq FOREIGN KEY (id_club_izq) REFERENCES MJV_club(id_club),
 CONSTRAINT MJV_asociado_fk_club_der FOREIGN KEY (id_club_der) REFERENCES MJV_club(id_club),
 CONSTRAINT MJV_asociado_ck_orden CHECK (id_club_izq < id_club_der) -- NOTE: esto se puede cambiar pero es para evitar duplicar (permite 1,2 pero no 2,1 sin embargo hay que mandarlo de forma ordenada) ademas que quita 1,1
);


CREATE SEQUENCE MJV_seq_representante START WITH 1 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_representante(
  id_representante NUMBER DEFAULT MJV_seq_representante.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) NOT NULL,
  p_apellido VARCHAR2(20) NOT NULL,
  doc_identidad VARCHAR2(20) NOT NULL,
  telefono VARCHAR2(20) NOT NULL
);


CREATE SEQUENCE MJV_seq_lector START WITH 1 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
CREATE TABLE MJV_lector(
  id_lector NUMBER DEFAULT MJV_seq_lector.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) NOT NULL,
  p_apellido VARCHAR2(20) NOT NULL,
  s_apellido VARCHAR2(20) NOT NULL,
  doc_identidad VARCHAR2(20) NOT NULL,
  telefono VARCHAR2(20) NOT NULL,
  email VARCHAR2(100) NOT NULL,
  genero CHAR(1) NOT NULL,
  fecha_nac DATE NOT NULL,
  id_pais_nac NUMBER(3) NOT NULL,
  s_nombre VARCHAR2(20),
  id_representante NUMBER,
  id_representante_lector NUMBER,
 CONSTRAINT MJV_lector_ck_genero CHECK (genero IN ('F', 'M')),
 CONSTRAINT MJV_lector_fk_representante FOREIGN KEY (id_representante) REFERENCES MJV_representante(id_representante),
 CONSTRAINT MJV_lector_fk_representante_lector FOREIGN KEY (id_representante_lector) REFERENCES MJV_lector(id_lector),
 CONSTRAINT MJV_lector_fk_pais_nac FOREIGN KEY (id_pais_nac) REFERENCES MJV_pais(id_pais),
CONSTRAINT MJV_LECTOR_CK_ARCO CHECK (
    (id_representante IS NOT NULL AND id_representante_lector IS NULL)  -- Representante externo
    OR
    (id_representante IS NULL AND id_representante_lector IS NOT NULL)  -- Representante lector
    OR
    (id_representante IS NULL AND id_representante_lector IS NULL)      -- Mayor de edad
)
);

CREATE SEQUENCE MJV_seq_idioma_miembro START WITH 1 INCREMENT BY 1 NOCYCLE;

-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
CREATE TABLE MJV_idioma_miembro(
  id_idioma NUMBER(3) NOT NULL,
  id_idioma_miembro NUMBER DEFAULT MJV_seq_idioma_miembro.NEXTVAL NOT NULL,
  tipo CHAR(1) NOT NULL, -- 'L' = Lector, 'C' = Club
  id_club NUMBER,
  id_lector NUMBER,
 CONSTRAINT MJV_idioma_miembro_pk PRIMARY KEY (id_idioma, id_idioma_miembro),
 CONSTRAINT MJV_idioma_miembro_fk_idioma FOREIGN KEY (id_idioma) REFERENCES MJV_idioma(id_idioma),
 CONSTRAINT MJV_idioma_miembro_ck_tipo CHECK (tipo IN ('L', 'C')),
 CONSTRAINT MJV_idioma_miembro_fk_club FOREIGN KEY (id_club) REFERENCES MJV_club(id_club),
 CONSTRAINT MJV_idioma_miembro_fk_lector FOREIGN KEY (id_lector) REFERENCES MJV_lector(id_lector),
 CONSTRAINT MJV_idioma_miembro_ck_arco CHECK (
    (tipo = 'L' AND id_lector IS NOT NULL AND id_club IS NULL)
    OR
    (tipo = 'C' AND id_club IS NOT NULL AND id_lector IS NULL)
  )
);


CREATE SEQUENCE MJV_seq_autor START WITH 1 INCREMENT BY 1 NOCYCLE;

-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_autor(
  id_autor NUMBER DEFAULT MJV_seq_autor.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) ,
  p_apellido VARCHAR2(20) ,
  nombre_ant_pseudonimo VARCHAR2(20)
);

-- TIPO DE ENTIDAD: Entrada (E)
CREATE TABLE MJV_libro(
  isbn VARCHAR2(20) PRIMARY KEY,  -- https:/es.wikipedia.org/wiki/ISBN#El_ISBN_de_trece_d%C3%ADgitos
  titulo VARCHAR2(100) NOT NULL,
  tipo_narrativa VARCHAR2(10) NOT NULL,
  sinopsis VARCHAR2(200) NOT NULL,
  genero VARCHAR2(20) NOT NULL,
  primera_edicion NUMBER NOT NULL, -- NOTE: Si solo guardamos el año, sino, date
  total_paginas NUMBER NOT NULL,
  id_pais NUMBER(3) NOT NULL,
  id_libro_siguiente VARCHAR2(20),
 CONSTRAINT MJV_libro_total_paginas_validas CHECK (total_paginas > 0),
 CONSTRAINT MJV_libro_tipo_narrativa_ck CHECK (tipo_narrativa IN ('novela','cuento','mito','leyenda','fabula','epopeya')),
 CONSTRAINT MJV_libro_idioma_fk_pais FOREIGN KEY ( id_pais ) REFERENCES MJV_pais(id_pais),
 CONSTRAINT MJV_libro_fk_libro_siguiente FOREIGN KEY ( id_libro_siguiente ) REFERENCES MJV_libro(isbn)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
CREATE TABLE MJV_libro_autor(
  id_autor NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
 CONSTRAINT MJV_libro_autor_pk PRIMARY KEY (id_autor, isbn),
 CONSTRAINT MJV_libro_autor_fk_autor FOREIGN KEY ( id_autor ) REFERENCES MJV_autor(id_autor),
 CONSTRAINT MJV_libro_autor_fk_libro FOREIGN KEY ( isbn ) REFERENCES MJV_libro(isbn)
);


CREATE SEQUENCE MJV_seq_grupo START WITH 1 INCREMENT BY 1 NOCYCLE;

-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
CREATE TABLE MJV_grupo (
  id_grupo        NUMBER DEFAULT MJV_seq_grupo.NEXTVAL NOT NULL,
  id_club         NUMBER NOT NULL,
  tipo_grupo      VARCHAR2(10) NOT NULL,
  fecha_creacion  DATE NOT NULL,
  dia_reunion     NUMBER(1) NOT NULL, -- 1-7 Domingo, Lunes,...,Sabado
  hora_reunion    DATE NOT NULL, -- Hora militar
 CONSTRAINT MJV_grupo_pk PRIMARY KEY (id_grupo, id_club), 
 CONSTRAINT MJV_grupo_ck_tipo CHECK (tipo_grupo IN ('adultos','jovenes','niños')),
 CONSTRAINT MJV_grupo_ck_dia_permitido CHECK ((dia_reunion > 1) AND (dia_reunion<7)),
 CONSTRAINT MJV_grupo_ck_hora_reunion CHECK (TO_CHAR(hora_reunion, 'SS')='00'),
 CONSTRAINT MJV_grupo_ck_hora_permitida CHECK (TO_CHAR(hora_reunion, 'HH24:MI') BETWEEN '17:00' AND '19:00'), -- NOTE: Aqui no se si las 7 es hora maxima y ya nadie puede estar o es entre esta franja que pueden iniciar las reuniones, creo que es la ultima porque dice que los grupos de niños no pueden terminar despues de las 7
 CONSTRAINT MJV_grupo_fk_club FOREIGN KEY (id_club) REFERENCES MJV_club(id_club)
);


-- =============================================================================
-- SECUENCIAS FALTANTES (Backlog Parte 1)
-- =============================================================================

CREATE SEQUENCE MJV_seq_obra_actuada START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE SEQUENCE MJV_seq_pago_membresia START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE SEQUENCE MJV_seq_funcion START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE SEQUENCE MJV_seq_voto_publico START WITH 1 INCREMENT BY 1 NOCYCLE;


-- =============================================================================
-- TABLAS FALTANTES (Backlog Parte 2) - Orden por dependencias de FK
-- =============================================================================


-- TIPO DE ENTIDAD: Entrada (E)
-- Depende de: libro, club
CREATE TABLE MJV_obra_actuada(
  id_obra_act NUMBER DEFAULT MJV_seq_obra_actuada.NEXTVAL NOT NULL,
  titulo VARCHAR2(200) NOT NULL,
  activo CHAR(1) NOT NULL, -- 'S' = activa, 'N' = inactiva
  costo_entrada NUMBER(10, 2), -- NULL si no cobra entrada
  isbn VARCHAR2(20) NOT NULL,
  id_club NUMBER NOT NULL,
 CONSTRAINT MJV_obra_actuada_pk PRIMARY KEY (id_obra_act,isbn,id_club),
 CONSTRAINT MJV_obra_actuada_ck_activo CHECK (activo IN ('S', 'N')),
 CONSTRAINT MJV_obra_actuada_fk_libro FOREIGN KEY (isbn) REFERENCES MJV_libro(isbn),
 CONSTRAINT MJV_obra_actuada_fk_club FOREIGN KEY (id_club) REFERENCES MJV_club(id_club)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: lector, club
CREATE TABLE MJV_historia_membresia (
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  estatus VARCHAR2(8) NOT NULL, -- 'activo' o 'retirado'
  fecha_f DATE, -- NOTE: NULL mientras el miembro sigue activo
  motivo_retiro VARCHAR2(12), -- 'voluntario', 'inasistencia', 'deuda', 'otro'
 CONSTRAINT MJV_historia_membresia_pk PRIMARY KEY (id_lector, id_club, fecha_i),
 CONSTRAINT MJV_historia_membresia_fk_lec FOREIGN KEY (id_lector) REFERENCES MJV_lector(id_lector),
 CONSTRAINT MJV_historia_membresia_fk_club FOREIGN KEY (id_club) REFERENCES MJV_club(id_club),
 CONSTRAINT MJV_historia_membresia_ck_est CHECK (estatus IN ('activo', 'retirado')),
 CONSTRAINT MJV_historia_membresia_ck_mot CHECK (motivo_retiro IN ('voluntario', 'inasistencia', 'deuda', 'otro') OR motivo_retiro IS NULL)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: historia_membresia, libro
-- NOTE: cada miembro registra exactamente 3 obras preferidas al afiliarse (prioridad 1, 2, 3)
CREATE TABLE MJV_preferencia_obra(
  id_lector NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  prioridad NUMBER(1) NOT NULL, -- 1, 2 o 3
  CONSTRAINT MJV_preferencia_obra_pk PRIMARY KEY (id_lector, isbn),
  CONSTRAINT MJV_preferencia_obra_fk_libro FOREIGN KEY (isbn) REFERENCES MJV_libro(isbn),
  CONSTRAINT MJV_preferencia_obra_fk_lector FOREIGN KEY (id_lector) REFERENCES MJV_lector(id_lector),
  CONSTRAINT MJV_preferencia_obra_ck_prior CHECK (prioridad IN (1, 2, 3))
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: historia_membresia, grupo
-- NOTE: un miembro solo puede estar activo en un grupo a la vez (fec_f NULL indica activo)
CREATE TABLE MJV_g_lec(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_grupo NUMBER NOT NULL,
  fec_i DATE NOT NULL, -- fecha de ingreso al grupo
  fec_f DATE, -- NOTE: NULL mientras el miembro sigue en el grupo
  CONSTRAINT MJV_g_lec_pk PRIMARY KEY (id_lector, id_club, fecha_i, id_grupo, fec_i),
  CONSTRAINT MJV_g_lec_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES MJV_historia_membresia(id_lector, id_club, fecha_i),
  CONSTRAINT MJV_g_lec_fk_grupo FOREIGN KEY (id_grupo, id_club) REFERENCES MJV_grupo(id_grupo, id_club)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: grupo, libro, historia_membresia (moderador)
-- NOTE: el moderador es un miembro del club; para grupos de ninos debe ser de un grupo de adultos
CREATE TABLE MJV_calendario_reunion_mes(
  id_club NUMBER NOT NULL,
  id_grupo NUMBER NOT NULL,
  fecha DATE NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
-- G_LEC
  mod_id_lector NUMBER NOT NULL,
  mod_fecha_i DATE NOT NULL,
  mod_hist_fecha_i DATE NOT NULL,
  -- NOTE: Oracle SQL no tiene tipo BOOLEAN; se usa CHAR(1) con CHECK 'S'/'N'
  realizada CHAR(1) NOT NULL,
  ultima CHAR(1) NOT NULL,
  conclusiones VARCHAR2(4000),
  valoracion NUMBER(1), -- 1-5; acordado entre todos al cierre del libro
 CONSTRAINT MJV_calendario_reunion_mes_pk PRIMARY KEY (id_grupo, id_club,fecha,isbn),
 CONSTRAINT MJV_calendario_reunion_mes_fk_grupo FOREIGN KEY (id_grupo,id_club) REFERENCES MJV_grupo(id_grupo, id_club),
 CONSTRAINT MJV_calendario_reunion_mes_fk_libro FOREIGN KEY (isbn) REFERENCES MJV_libro(isbn),
  CONSTRAINT MJV_calendario_reunion_mes_fk_g_lec FOREIGN KEY (mod_id_lector, id_club, mod_fecha_i, id_grupo, mod_hist_fecha_i) REFERENCES MJV_g_lec( id_lector, id_club, fecha_i, id_grupo, fec_i ),
 CONSTRAINT MJV_calendario_reunion_mes_ck_realizada CHECK (realizada IN ('S', 'N')),
 CONSTRAINT MJV_calendario_reunion_mes_ck_ultima CHECK (ultima IN ('S', 'N')),
 CONSTRAINT MJV_calendario_reunion_mes_ck_val CHECK (valoracion BETWEEN 1 AND 5 OR valoracion IS NULL),
  -- HC-06: cuando ultima='S' conclusiones y valoracion son obligatorias
 CONSTRAINT MJV_calendario_ck_cierre CHECK (
    ultima = 'N'
    OR (ultima = 'S' AND conclusiones IS NOT NULL AND valoracion IS NOT NULL)
  )
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: historia_membresia, obra_actuada
-- NOTE: pueden actuar miembros de clubes asociados, por eso la FK apunta a historia_membresia global
CREATE TABLE MJV_elenco(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
 CONSTRAINT MJV_elenco_pk PRIMARY KEY (id_lector, -- PK Lector
   isbn,id_club,  id_obra_act -- PK obra_actuada
  ),
 CONSTRAINT MJV_elenco_fk_lector FOREIGN KEY (id_lector) REFERENCES MJV_lector(id_lector),
 CONSTRAINT MJV_elenco_fk_obra  FOREIGN KEY (id_obra_act, isbn, id_club) REFERENCES MJV_obra_actuada(id_obra_act, isbn, id_club)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: historia_membresia
-- NOTE: solo aplica a clubes independientes (cuota_anual = 'S'); monto base $100 USD o equivalente local
CREATE TABLE MJV_pago_membresia(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_pago NUMBER DEFAULT MJV_seq_pago_membresia.NEXTVAL NOT NULL,
  fecha_pago DATE NOT NULL,
  monto NUMBER(10, 2) NOT NULL,
 CONSTRAINT MJV_pago_membresia_pk PRIMARY KEY (id_lector, id_club, fecha_i, id_pago),
 CONSTRAINT MJV_pago_membresia_fk_lector FOREIGN KEY (id_lector) REFERENCES MJV_lector (id_lector),
 CONSTRAINT MJV_pago_membresia_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES MJV_historia_membresia (id_lector, id_club, fecha_i)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: g_lec, calendario_reunion_mes
-- NOTE: si un miembro supera el 30% de inasistencias en un bimestre es retirado del club
CREATE TABLE MJV_inasistencia(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_grupo NUMBER NOT NULL,
  fec_i_g_lec DATE NOT NULL,
  fecha_reunion DATE NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
 CONSTRAINT MJV_inasistencia_pk PRIMARY KEY (
isbn, -- PK libro
id_grupo, id_club, -- PK grupo y g_lec (historia_membresia pk compuesta)
id_lector, fecha_i, fec_i_g_lec, -- PK g_lec
fecha_reunion -- PK inasistencia
),
 CONSTRAINT MJV_inasistencia_fk_glec FOREIGN KEY (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec) REFERENCES MJV_g_lec(id_lector, id_club, fecha_i, id_grupo, fec_i),
 CONSTRAINT MJV_inasistencia_fk_cal FOREIGN KEY (id_grupo,id_club, fecha_reunion,isbn ) REFERENCES MJV_calendario_reunion_mes(id_grupo, id_club,fecha,isbn)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: obra_actuada
-- NOTE: valoracion_obra se calcula como promedio de voto_publico al cerrar la funcion
CREATE TABLE MJV_funcion(
  id_funcion NUMBER DEFAULT MJV_seq_funcion.NEXTVAL NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_funcion DATE NOT NULL,
  valoracion_obra NUMBER(3, 2), -- promedio de calificaciones del publico (1-5)
  cantidad_asistencia NUMBER NOT NULL,
 CONSTRAINT MJV_funcion_pk PRIMARY KEY (id_funcion, -- PK funcion
id_obra_act,isbn,id_club -- PK obra_actuada
),
 CONSTRAINT MJV_funcion_fk_obra FOREIGN KEY (id_obra_act,isbn,id_club) REFERENCES MJV_obra_actuada(id_obra_act,isbn,id_club),
 CONSTRAINT MJV_funcion_ck_valoracion CHECK (valoracion_obra BETWEEN 1 AND 5 OR valoracion_obra IS NULL)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: funcion
-- NOTE: el publico vota por el mejor actor y califica la obra; pueden haber empates en mejor actor
CREATE TABLE MJV_voto_publico(
  id_voto NUMBER DEFAULT MJV_seq_voto_publico.NEXTVAL PRIMARY KEY,
  id_funcion NUMBER NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  id_club NUMBER NOT NULL,
id_lector  NUMBER NOT NULL,
  calificacion_obra NUMBER(1) NOT NULL, -- estrellas: 1 a 5
 CONSTRAINT MJV_voto_publico_fk_funcion FOREIGN KEY (id_funcion,id_obra_act,isbn,id_club) REFERENCES MJV_funcion(id_funcion,id_obra_act,isbn,id_club),
 CONSTRAINT MJV_voto_publico_fk_lector FOREIGN KEY (id_lector) REFERENCES MJV_lector(id_lector),
 CONSTRAINT MJV_voto_publico_ck_cal CHECK (calificacion_obra BETWEEN 1 AND 5)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: funcion, elenco
-- NOTE: pueden existir multiples ganadores por funcion (empate permitido)
CREATE TABLE MJV_mejor_actor(
  id_funcion NUMBER NOT NULL,
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
 CONSTRAINT MJV_mejor_actor_pk PRIMARY KEY (
  id_funcion,  id_obra_act, isbn,id_club, -- PK funcion
  id_lector  -- al igual que isbn,id_club,  id_obra_act PK elenco
  ),
 CONSTRAINT MJV_mejor_actor_fk_funcion FOREIGN KEY (id_funcion, id_obra_act,isbn,id_club ) REFERENCES MJV_funcion(id_funcion, id_obra_act,isbn,id_club),
 CONSTRAINT MJV_mejor_actor_fk_elenco FOREIGN KEY (id_lector, isbn,id_club,  id_obra_act) REFERENCES MJV_elenco(id_lector, isbn,id_club,  id_obra_act )
);


-- =============================================================================
-- HC-09: INDICES DE RENDIMIENTO Y OPTIMIZACION (Backlog Tarea 3)
-- =============================================================================

-- Indices en llaves foraneas (evitan lock escalation en Oracle al hacer DELETE/UPDATE en tablas padre)
CREATE INDEX MJV_idx_asociado_der              ON MJV_asociado(id_club_der);
CREATE INDEX MJV_idx_lector_rep               ON MJV_lector(id_representante);
CREATE INDEX MJV_idx_lector_rep_lec           ON MJV_lector(id_representante_lector);
CREATE INDEX MJV_idx_lector_pais_nac          ON MJV_lector(id_pais_nac);
CREATE INDEX MJV_idx_idioma_miembro_club      ON MJV_idioma_miembro(id_club);
CREATE INDEX MJV_idx_idioma_miembro_lector    ON MJV_idioma_miembro(id_lector);
CREATE INDEX MJV_idx_libro_pais               ON MJV_libro(id_pais);
CREATE INDEX MJV_idx_libro_sig                ON MJV_libro(id_libro_siguiente);
CREATE INDEX MJV_idx_libro_autor_isbn         ON MJV_libro_autor(isbn);
CREATE INDEX MJV_idx_grupo_club               ON MJV_grupo(id_club);
CREATE INDEX MJV_idx_historia_membresia_club  ON MJV_historia_membresia(id_club);
CREATE INDEX MJV_idx_preferencia_obra_isbn    ON MJV_preferencia_obra(isbn);
CREATE INDEX MJV_idx_g_lec_grupo              ON MJV_g_lec(id_grupo);
CREATE INDEX MJV_idx_calendario_isbn          ON MJV_calendario_reunion_mes(isbn);
CREATE INDEX MJV_idx_calendario_mod           ON MJV_calendario_reunion_mes(mod_id_lector, id_club, mod_fecha_i);
CREATE INDEX MJV_idx_obra_actuada_isbn        ON MJV_obra_actuada(isbn);
CREATE INDEX MJV_idx_obra_actuada_club        ON MJV_obra_actuada(id_club);
CREATE INDEX MJV_idx_funcion_obra             ON MJV_funcion(id_obra_act);
CREATE INDEX MJV_idx_elenco_obra              ON MJV_elenco(id_obra_act);
CREATE INDEX MJV_idx_mejor_actor_elenco       ON MJV_mejor_actor(id_lector, id_club, fecha_i, id_obra_act);

-- Indices para busquedas frecuentes
CREATE INDEX MJV_idx_lector_busqueda          ON MJV_lector(p_apellido, p_nombre);
CREATE INDEX MJV_idx_libro_titulo             ON MJV_libro(titulo);
CREATE INDEX MJV_idx_club_nombre              ON MJV_club(nombre_club);


-- =============================================================================
-- Verificar que todo se creo correctamente
-- =============================================================================
SELECT object_type, COUNT(*)
FROM user_objects
WHERE object_type IN ('TABLE', 'SEQUENCE', 'TRIGGER', 'INDEX')
GROUP BY object_type;
-- =============================================================================
-- INSERTS: TABLAS DE ENTRADA (E) USANDO SECUENCIAS (DEFAULT) Y SUBCONSULTAS
-- =============================================================================

-- 1. PAÍSES (Omitimos id_pais, se autogenera con MJV_seq_pais.NEXTVAL)
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Estados Unidos', 'USD', 'Estadounidense');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('China', 'CNY', 'China');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Canadá', 'CAD', 'Canadiense');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Reino Unido', 'GBP', 'Británica');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Alemania', 'EUR', 'Alemana');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Chile', 'CLP', 'Chilena');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Colombia', 'COP', 'Colombiana');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('México', 'MXN', 'Mexicana');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Perú', 'PEN', 'Peruana');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Uruguay', 'UYU', 'Uruguaya');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Argentina', 'ARS', 'Argentina');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Costa Rica', 'CRC', 'Costarricense');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('España', 'EUR', 'Española');
INSERT INTO MJV_pais (nombre_pais, moneda_local, nacionalidad) VALUES ('Venezuela', 'VES', 'Venezolana');

-- 2. CIUDADES (Omitimos id_ciudad, buscamos el id_pais dinámicamente)
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), 'Santiago');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), 'Bogotá');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), 'Ciudad de México');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), 'Lima');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), 'Montevideo');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), 'Buenos Aires');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), 'San José');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), 'Madrid');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), 'Caracas');

-- 3. INSTITUCIONES (Omitimos id_institucion)
INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Santiago'), 'Biblioteca Nacional de Chile', 'biblioteca');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Ciudad de México'), 'UNAM', 'universidad');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Caracas'), 'Universidad Católica Andrés Bello', 'universidad');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Caracas'), 'Biblioteca Central UCV', 'biblioteca');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Caracas'), 'Colegio San Ignacio', 'colegio');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Bogotá'), 'Universidad de los Andes', 'universidad');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Bogotá'), 'Biblioteca Luis Ángel Arango', 'biblioteca');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Madrid'), 'Instituto Cervantes', 'otro');

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Lima'), 'Colegio Markham', 'colegio');

-- 4. IDIOMAS (Omitimos id_idioma)
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Español');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Inglés');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Chino Mandarín');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Alemán');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Francés');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Italiano');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Portugués');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Ruso');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Japonés');

-- 5. REPRESENTANTES (Omitimos id_representante)
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Carlos', 'Gómez', 'V-12345678', '+584141234567');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('María', 'Fernández', 'V-87654321', '+584241234567');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Luis', 'Pérez', 'V-11223344', '+584121112233');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Ana', 'Martínez', 'V-22334455', '+584142223344');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Jorge', 'Rodríguez', 'V-33445566', '+584163334455');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Elena', 'Díaz', 'V-44556677', '+584244445566');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Miguel', 'Torres', 'V-55667788', '+584125556677');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Lucía', 'Ramírez', 'V-66778899', '+584146667788');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Andrés', 'Silva', 'V-77889900', '+584167778899');

-- 6. AUTORES (Omitimos id_autor)
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Brandon', 'Sanderson', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Cixin', 'Liu', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('William', 'Gibson', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('George R. R.', 'Martin', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Ursula K.', 'Le Guin', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Terry', 'Pratchett', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Neil', 'Gaiman', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Michael', 'Ende', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Orson Scott', 'Card', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Robert', 'Jordan', 'James O. Rigney');
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Neal', 'Stephenson', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Patrick', 'Rothfuss', NULL);
INSERT INTO MJV_autor (p_nombre, p_apellido, nombre_ant_pseudonimo) VALUES ('Ken', 'Follett', NULL);

-- 7. CLUBES DE LECTURA (Omitimos id_club, asignamos FKs dinámicamente)
INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Refugio Literario del Sur', 'S', '8320000', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Santiago'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), (SELECT id_institucion FROM MJV_institucion WHERE nombre_inst = 'Biblioteca Nacional de Chile'));

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('El Café de los Capítulos', 'N', '110011', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Bogotá'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Tertulia de Sabios y Letras', 'S', '01000', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Ciudad de México'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), (SELECT id_institucion FROM MJV_institucion WHERE nombre_inst = 'UNAM'));

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Mentes de Papiro', 'S', '15001', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Lima'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('La Alianza de la Tinta', 'N', '11000', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Montevideo'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Lectores de la Madrugada', 'S', 'C1000', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Buenos Aires'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Ecos del Pergamino', 'N', '10101', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'San José'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Horizonte de Palabras', 'S', '28001', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Madrid'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Club de Lectura Guayana', 'S', '1000', (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Caracas'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), (SELECT id_institucion FROM MJV_institucion WHERE nombre_inst = 'Universidad Católica Andrés Bello'));


-- 8. LIBROS (El ISBN no tiene secuencia, se inserta directo. Buscamos el país dinámicamente)
INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788466631174', 'El imperio final (Nacidos de la bruma)', 'novela', 'Un mundo de cenizas donde ladrones intentan derrocar al Lord Legislador.', 'Fantasía', 2006, 688, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788466659734', 'El problema de los tres cuerpos', 'novela', 'La humanidad hace contacto con una civilización alienígena.', 'Ciencia Ficción', 2008, 416, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788445076620', 'Neuromante', 'novela', 'Un vaquero de consola hackea el sistema más peligroso.', 'Cyberpunk', 1984, 320, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788496208919', 'Juego de tronos', 'novela', 'Familias nobles luchan por el control del Trono de Hierro.', 'Fantasía Épica', 1996, 800, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788445077535', 'Un mago de Terramar', 'novela', 'Juventud y madurez del mago Ged en Terramar.', 'Fantasía', 1968, 256, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788445077467', 'La mano izquierda de la oscuridad', 'novela', 'Un embajador visita un planeta de habitantes sin género fijo.', 'Ciencia Ficción', 1969, 320, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788448005399', 'Buenos presagios', 'novela', 'Un ángel y un demonio se alían para evitar el apocalipsis.', 'Fantasía Cómica', 1990, 432, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788497596794', 'El color de la magia (Mundodisco)', 'novela', 'Aventuras del mago Rincewind y el primer turista.', 'Fantasía Cómica', 1983, 288, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788420471549', 'La historia interminable', 'novela', 'Un niño lee un libro y se adentra en Fantasía.', 'Fantasía', 1979, 416, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788420464978', 'Momo', 'novela', 'Una niña debe enfrentarse a los ladrones del tiempo.', 'Fantasía', 1973, 256, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788466653848', 'El juego de Ender', 'novela', 'Niños son entrenados en el espacio contra extraterrestres.', 'Ciencia Ficción', 1985, 368, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788448033873', 'El ojo del mundo (La rueda del tiempo)', 'novela', 'Jóvenes descubren un destino ligado al Dragón Renacido.', 'Fantasía Épica', 1990, 832, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788416502011', 'American Gods', 'novela', 'Antiguos dioses se enfrentan a los nuevos en EEUU.', 'Fantasía Urbana', 2001, 560, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788417347345', 'Snow Crash', 'novela', 'Un hacker descubre un virus letal en un mundo corporativo.', 'Cyberpunk', 1992, 448, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788401337208', 'El nombre del viento', 'novela', 'Kvothe cuenta cómo se convirtió en el mago más temido.', 'Fantasía Épica', 2007, 880, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL);

INSERT INTO MJV_libro (isbn, titulo, tipo_narrativa, sinopsis, genero, primera_edicion, total_paginas, id_pais, id_libro_siguiente) 
VALUES ('9788401336560', 'Un mundo sin fin', 'novela', 'La historia continúa siglos después de Los pilares de la Tierra.', 'Ficción Histórica', 2007, 1184, (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL);

-- 9. OBRA ACTUADA (Omitimos id_obra_act)
INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Juego de Tronos: La Puesta en Escena', 'S', 15.50, '9788496208919', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Ender en el Espacio (Monólogo)', 'S', NULL, '9788466653848', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Neuromante: El Despertar', 'S', 20.00, '9788445076620', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Invierno en Gethen', 'S', 10.00, '9788445077467', (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Buenos Presagios: El Fin del Mundo', 'S', 18.00, '9788448005399', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('El Color de la Magia Teatral', 'S', NULL, '9788497596794', (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Momo y los Hombres Grises', 'S', 12.00, '9788420464978', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('American Gods: La Tormenta', 'S', 25.00, '9788416502011', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'));

INSERT INTO MJV_obra_actuada (titulo, activo, costo_entrada, isbn, id_club) 
VALUES ('Snow Crash: El Metaverso', 'S', NULL, '9788417347345', (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'));

-- =============================================================================
-- 10. LIBRO_AUTOR (Buscamos al autor dinámicamente)
-- =============================================================================
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Sanderson'), '9788466631174');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Liu'), '9788466659734');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Gibson'), '9788445076620');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Martin'), '9788496208919');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Le Guin' AND p_nombre = 'Ursula K.'), '9788445077535');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Le Guin' AND p_nombre = 'Ursula K.'), '9788445077467');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Pratchett'), '9788448005399');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Gaiman'), '9788448005399');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Pratchett'), '9788497596794');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Ende'), '9788420471549');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Ende'), '9788420464978');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Card'), '9788466653848');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Jordan'), '9788448033873');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Gaiman'), '9788416502011');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Stephenson'), '9788417347345');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Rothfuss'), '9788401337208');
INSERT INTO MJV_libro_autor (id_autor, isbn) VALUES ((SELECT id_autor FROM MJV_autor WHERE p_apellido = 'Follett'), '9788401336560');

-- =============================================================================
-- 11. GRUPOS DE CLUBES (MJV_grupo) - 27 registros
-- =============================================================================
-- Club: Refugio Literario del Sur
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: El Café de los Capítulos
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Tertulia de Sabios y Letras
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Mentes de Papiro
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: La Alianza de la Tinta
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Lectores de la Madrugada
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Ecos del Pergamino
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Horizonte de Palabras
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Club de Lectura Guayana
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), 'adultos', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), 'jovenes', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), 'niños', TO_DATE('01/01/2026', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));

-- =============================================================================
-- 12. LECTORES (MJV_lector) - 108 registros (36 adultos, 36 jóvenes, 36 niños)
-- =============================================================================
-- --- ADULTOS (36) ---
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Alejandro', 'García', 'Club1A', 'V-ADU01', '+584240000001', 'alejandros.v-adu01@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Beatriz', 'Rodríguez', 'Club1A', 'V-ADU02', '+584240000002', 'beatrizs.v-adu02@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Carlos', 'López', 'Club1A', 'V-ADU03', '+584240000003', 'carloss.v-adu03@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Diana', 'Martínez', 'Club1A', 'V-ADU04', '+584240000004', 'dianas.v-adu04@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Eduardo', 'González', 'Club2A', 'V-ADU05', '+584240000005', 'eduardos.v-adu05@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fernando', 'Pérez', 'Club2A', 'V-ADU06', '+584240000006', 'fernandos.v-adu06@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gabriela', 'Sánchez', 'Club2A', 'V-ADU07', '+584240000007', 'gabrielas.v-adu07@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Hugo', 'Ramírez', 'Club2A', 'V-ADU08', '+584240000008', 'hugos.v-adu08@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Isabel', 'Cruz', 'Club3A', 'V-ADU09', '+584240000009', 'isabels.v-adu09@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Javier', 'Flores', 'Club3A', 'V-ADU10', '+584240000010', 'javiers.v-adu10@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Karla', 'Gómez', 'Club3A', 'V-ADU11', '+584240000011', 'karlas.v-adu11@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Luis', 'Díaz', 'Club3A', 'V-ADU12', '+584240000012', 'luiss.v-adu12@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Mónica', 'Morales', 'Club4A', 'V-ADU13', '+584240000013', 'monicas.v-adu13@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Néstor', 'Reyes', 'Club4A', 'V-ADU14', '+584240000014', 'nestors.v-adu14@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Olga', 'Ortiz', 'Club4A', 'V-ADU15', '+584240000015', 'olgas.v-adu15@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Patricia', 'Castillo', 'Club4A', 'V-ADU16', '+584240000016', 'patricias.v-adu16@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Quique', 'Ramos', 'Club5A', 'V-ADU17', '+584240000017', 'quiques.v-adu17@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Rosa', 'Ruiz', 'Club5A', 'V-ADU18', '+584240000018', 'rosas.v-adu18@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Silvia', 'Rivera', 'Club5A', 'V-ADU19', '+584240000019', 'silvias.v-adu19@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Tomás', 'Álvarez', 'Club5A', 'V-ADU20', '+584240000020', 'tomass.v-adu20@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Úrsula', 'Méndez', 'Club6A', 'V-ADU21', '+584240000021', 'ursulas.v-adu21@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Víctor', 'Chávez', 'Club6A', 'V-ADU22', '+584240000022', 'victors.v-adu22@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Walter', 'Vásquez', 'Club6A', 'V-ADU23', '+584240000023', 'walters.v-adu23@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ximena', 'Guzmán', 'Club6A', 'V-ADU24', '+584240000024', 'ximenas.v-adu24@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Yolanda', 'Fernández', 'Club7A', 'V-ADU25', '+584240000025', 'yolandas.v-adu25@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Zoilo', 'Salazar', 'Club7A', 'V-ADU26', '+584240000026', 'zoilos.v-adu26@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Alberto', 'Medina', 'Club7A', 'V-ADU27', '+584240000027', 'albertos.v-adu27@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Brenda', 'Herrera', 'Club7A', 'V-ADU28', '+584240000028', 'brendas.v-adu28@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('César', 'Castro', 'Club8A', 'V-ADU29', '+584240000029', 'cesars.v-adu29@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Daniel', 'Vargas', 'Club8A', 'V-ADU30', '+584240000030', 'daniels.v-adu30@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Estela', 'Rojas', 'Club8A', 'V-ADU31', '+584240000031', 'estelas.v-adu31@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Felipe', 'Muñoz', 'Club8A', 'V-ADU32', '+584240000032', 'felipes.v-adu32@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gloria', 'Silva', 'Club9A', 'V-ADU33', '+584240000033', 'glorias.v-adu33@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Héctor', 'Suárez', 'Club9A', 'V-ADU34', '+584240000034', 'hectors.v-adu34@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Irene', 'Delgado', 'Club9A', 'V-ADU35', '+584240000035', 'irenes.v-adu35@email.com', 'F', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('José', 'Peña', 'Club9A', 'V-ADU36', '+584240000036', 'joses.v-adu36@email.com', 'M', TO_DATE('15/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);

-- --- JÓVENES (36) ---
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Alan', 'García', 'Club1J', 'V-JOV01', '+584140000001', 'alans.v-jov01@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Bruno', 'Rodríguez', 'Club1J', 'V-JOV02', '+584140000002', 'brunos.v-jov02@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Camila', 'López', 'Club1J', 'V-JOV03', '+584140000003', 'camilas.v-jov03@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('David', 'Martínez', 'Club1J', 'V-JOV04', '+584140000004', 'davids.v-jov04@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Elena', 'González', 'Club2J', 'V-JOV05', '+584140000005', 'elenas.v-jov05@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fabio', 'Pérez', 'Club2J', 'V-JOV06', '+584140000006', 'fabios.v-jov06@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gisela', 'Sánchez', 'Club2J', 'V-JOV07', '+584140000007', 'giselas.v-jov07@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Hernán', 'Ramírez', 'Club2J', 'V-JOV08', '+584140000008', 'hernans.v-jov08@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Inés', 'Cruz', 'Club3J', 'V-JOV09', '+584140000009', 'iness.v-jov09@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Jorge', 'Flores', 'Club3J', 'V-JOV10', '+584140000010', 'jorges.v-jov10@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Kevin', 'Gómez', 'Club3J', 'V-JOV11', '+584140000011', 'kevins.v-jov11@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Laura', 'Díaz', 'Club3J', 'V-JOV12', '+584140000012', 'lauras.v-jov12@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Mateo', 'Morales', 'Club4J', 'V-JOV13', '+584140000013', 'mateos.v-jov13@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Natalia', 'Reyes', 'Club4J', 'V-JOV14', '+584140000014', 'natalias.v-jov14@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Oscar', 'Ortiz', 'Club4J', 'V-JOV15', '+584140000015', 'oscars.v-jov15@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Paola', 'Castillo', 'Club4J', 'V-JOV16', '+584140000016', 'paolas.v-jov16@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Raúl', 'Ramos', 'Club5J', 'V-JOV17', '+584140000017', 'rauls.v-jov17@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Sofía', 'Ruiz', 'Club5J', 'V-JOV18', '+584140000018', 'sofias.v-jov18@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Teresa', 'Rivera', 'Club5J', 'V-JOV19', '+584140000019', 'teresas.v-jov19@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ulises', 'Álvarez', 'Club5J', 'V-JOV20', '+584140000020', 'ulisess.v-jov20@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Valeria', 'Méndez', 'Club6J', 'V-JOV21', '+584140000021', 'valerias.v-jov21@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Wendy', 'Chávez', 'Club6J', 'V-JOV22', '+584140000022', 'wendys.v-jov22@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Xavier', 'Vásquez', 'Club6J', 'V-JOV23', '+584140000023', 'xaviers.v-jov23@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Yuri', 'Guzmán', 'Club6J', 'V-JOV24', '+584140000024', 'yuris.v-jov24@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Zulma', 'Fernández', 'Club7J', 'V-JOV25', '+584140000025', 'zulmas.v-jov25@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Adrián', 'Salazar', 'Club7J', 'V-JOV26', '+584140000026', 'adrians.v-jov26@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Belén', 'Medina', 'Club7J', 'V-JOV27', '+584140000027', 'belens.v-jov27@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Cristian', 'Herrera', 'Club7J', 'V-JOV28', '+584140000028', 'cristians.v-jov28@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Daniela', 'Castro', 'Club8J', 'V-JOV29', '+584140000029', 'danielas.v-jov29@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Emilio', 'Vargas', 'Club8J', 'V-JOV30', '+584140000030', 'emilios.v-jov30@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fabiola', 'Rojas', 'Club8J', 'V-JOV31', '+584140000031', 'fabiolas.v-jov31@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gonzalo', 'Muñoz', 'Club8J', 'V-JOV32', '+584140000032', 'gonzalos.v-jov32@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Hilda', 'Silva', 'Club9J', 'V-JOV33', '+584140000033', 'hildas.v-jov33@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Iván', 'Suárez', 'Club9J', 'V-JOV34', '+584140000034', 'ivans.v-jov34@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Julia', 'Delgado', 'Club9J', 'V-JOV35', '+584140000035', 'julias.v-jov35@email.com', 'F', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Karim', 'Peña', 'Club9J', 'V-JOV36', '+584140000036', 'karims.v-jov36@email.com', 'M', TO_DATE('15/06/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);

-- --- NIÑOS (36) ---
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Andrés', 'García', 'Club1N', 'V-NIN01', '+584120000001', 'andress.v-nin01@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Blanca', 'Rodríguez', 'Club1N', 'V-NIN02', '+584120000002', 'blancas.v-nin02@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Claudio', 'López', 'Club1N', 'V-NIN03', '+584120000003', 'claudios.v-nin03@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Diego', 'Martínez', 'Club1N', 'V-NIN04', '+584120000004', 'diegos.v-nin04@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Elisa', 'González', 'Club2N', 'V-NIN05', '+584120000005', 'elisas.v-nin05@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Francisco', 'Pérez', 'Club2N', 'V-NIN06', '+584120000006', 'franciscos.v-nin06@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gaby', 'Sánchez', 'Club2N', 'V-NIN07', '+584120000007', 'gabys.v-nin07@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Humberto', 'Ramírez', 'Club2N', 'V-NIN08', '+584120000008', 'humbertos.v-nin08@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ignacio', 'Cruz', 'Club3N', 'V-NIN09', '+584120000009', 'ignacios.v-nin09@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Juan', 'Flores', 'Club3N', 'V-NIN10', '+584120000010', 'juans.v-nin10@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Katia', 'Gómez', 'Club3N', 'V-NIN11', '+584120000011', 'katias.v-nin11@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Lucas', 'Díaz', 'Club3N', 'V-NIN12', '+584120000012', 'lucass.v-nin12@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Mario', 'Morales', 'Club4N', 'V-NIN13', '+584120000013', 'marios.v-nin13@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Nuria', 'Reyes', 'Club4N', 'V-NIN14', '+584120000014', 'nurias.v-nin14@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Omar', 'Ortiz', 'Club4N', 'V-NIN15', '+584120000015', 'omars.v-nin15@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Pablo', 'Castillo', 'Club4N', 'V-NIN16', '+584120000016', 'pablos.v-nin16@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Rocío', 'Ramos', 'Club5N', 'V-NIN17', '+584120000017', 'rocios.v-nin17@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Samuel', 'Ruiz', 'Club5N', 'V-NIN18', '+584120000018', 'samuels.v-nin18@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Tania', 'Rivera', 'Club5N', 'V-NIN19', '+584120000019', 'tanias.v-nin19@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Uriel', 'Álvarez', 'Club5N', 'V-NIN20', '+584120000020', 'uriels.v-nin20@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Valentina', 'Méndez', 'Club6N', 'V-NIN21', '+584120000021', 'valentinas.v-nin21@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('William', 'Chávez', 'Club6N', 'V-NIN22', '+584120000022', 'williams.v-nin22@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Xander', 'Vásquez', 'Club6N', 'V-NIN23', '+584120000023', 'xanders.v-nin23@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Yago', 'Guzmán', 'Club6N', 'V-NIN24', '+584120000024', 'yagos.v-nin24@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Zoraida', 'Fernández', 'Club7N', 'V-NIN25', '+584120000025', 'zoraidas.v-nin25@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ángel', 'Salazar', 'Club7N', 'V-NIN26', '+584120000026', 'angels.v-nin26@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Boris', 'Medina', 'Club7N', 'V-NIN27', '+584120000027', 'boriss.v-nin27@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Clara', 'Herrera', 'Club7N', 'V-NIN28', '+584120000028', 'claras.v-nin28@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Damián', 'Castro', 'Club8N', 'V-NIN29', '+584120000029', 'damians.v-nin29@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Eva', 'Vargas', 'Club8N', 'V-NIN30', '+584120000030', 'evas.v-nin30@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fede', 'Rojas', 'Club8N', 'V-NIN31', '+584120000031', 'fedes.v-nin31@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gema', 'Muñoz', 'Club8N', 'V-NIN32', '+584120000032', 'gemas.v-nin32@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Íñigo', 'Silva', 'Club9N', 'V-NIN33', '+584120000033', 'inigos.v-nin33@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Inma', 'Suárez', 'Club9N', 'V-NIN34', '+584120000034', 'inmas.v-nin34@email.com', 'F', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Jaime', 'Delgado', 'Club9N', 'V-NIN35', '+584120000035', 'jaimes.v-nin35@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Kiko', 'Peña', 'Club9N', 'V-NIN36', '+584120000036', 'kikos.v-nin36@email.com', 'M', TO_DATE('15/06/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);

-- =============================================================================
-- 13. HISTORIA DE MEMBRESÍA (MJV_historia_membresia) - 108 registros
-- =============================================================================
-- Miembros de Refugio Literario del Sur
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de El Café de los Capítulos
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Tertulia de Sabios y Letras
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Mentes de Papiro
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de La Alianza de la Tinta
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Lectores de la Madrugada
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Ecos del Pergamino
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Horizonte de Palabras
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Club de Lectura Guayana
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), 'activo', NULL, NULL);

-- =============================================================================
-- 14. MIEMBROS POR GRUPO (MJV_g_lec) - 108 registros
-- =============================================================================
-- Asignaciones de grupo para Refugio Literario del Sur
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para El Café de los Capítulos
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Tertulia de Sabios y Letras
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Mentes de Papiro
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para La Alianza de la Tinta
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Lectores de la Madrugada
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Ecos del Pergamino
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Horizonte de Palabras
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Club de Lectura Guayana
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('01/01/2026', 'DD/MM/YYYY'), NULL);

-- =============================================================================
-- 15. PREFERENCIAS DE OBRA (MJV_preferencia_obra) - 324 registros (3 por lector)
-- =============================================================================
-- Preferencias para lectores ADU
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), '9788445076620', 3);

-- Preferencias para lectores JOV
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), '9788445076620', 3);

-- Preferencias para lectores NIN
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), '9788445076620', 3);

INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), '9788466631174', 1);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), '9788466659734', 2);
INSERT INTO MJV_preferencia_obra (id_lector, isbn, prioridad) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), '9788445076620', 3);



-- =============================================================================
-- 16. CLUBES ASOCIADOS (MJV_asociado) - 9 registros
-- =============================================================================
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'))
);
INSERT INTO MJV_asociado (id_club_izq, id_club_der) VALUES (
  LEAST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur')),
  GREATEST((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'))
);

-- =============================================================================
-- 17. IDIOMAS DE CLUBES (MJV_idioma_miembro) - 9 registros
-- =============================================================================
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), NULL
);
INSERT INTO MJV_idioma_miembro (id_idioma, tipo, id_club, id_lector) VALUES (
  (SELECT id_idioma FROM MJV_idioma WHERE nombre_idioma = 'Español'), 'C',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), NULL
);

-- =============================================================================
-- 18. CALENDARIO DE REUNIONES (MJV_calendario_reunion_mes) - 9 registros
-- =============================================================================
-- Reunión para el grupo de adultos de: Refugio Literario del Sur (Moderador: V-ADU01)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: El Café de los Capítulos (Moderador: V-ADU05)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: Tertulia de Sabios y Letras (Moderador: V-ADU09)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: Mentes de Papiro (Moderador: V-ADU13)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: La Alianza de la Tinta (Moderador: V-ADU17)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: Lectores de la Madrugada (Moderador: V-ADU21)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: Ecos del Pergamino (Moderador: V-ADU25)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: Horizonte de Palabras (Moderador: V-ADU29)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);
-- Reunión para el grupo de adultos de: Club de Lectura Guayana (Moderador: V-ADU33)
INSERT INTO MJV_calendario_reunion_mes (
  id_club, id_grupo, fecha, isbn,
  mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
  realizada, ultima, conclusiones, valoracion
) VALUES (
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'),
  (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'),
  TO_DATE('15/01/2026', 'DD/MM/YYYY'),
  '9788466631174',
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  TO_DATE('01/01/2026', 'DD/MM/YYYY'),
  'N', 'N', NULL, NULL
);

-- =============================================================================
-- 19. ELENCO DE OBRAS TEATRALES (MJV_elenco) - 9 registros
-- =============================================================================
-- Elenco para: Juego de Tronos: La Puesta en Escena en Refugio Literario del Sur (Actor: V-ADU01)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'),
  '9788496208919',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Juego de Tronos: La Puesta en Escena' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'))
);
-- Elenco para: Invierno en Gethen en El Café de los Capítulos (Actor: V-ADU05)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'),
  '9788445077467',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Invierno en Gethen' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'))
);
-- Elenco para: Ender en el Espacio (Monólogo) en Tertulia de Sabios y Letras (Actor: V-ADU09)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'),
  '9788466653848',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Ender en el Espacio (Monólogo)' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'))
);
-- Elenco para: Neuromante: El Despertar en Mentes de Papiro (Actor: V-ADU13)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'),
  '9788445076620',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Neuromante: El Despertar' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'))
);
-- Elenco para: El Color de la Magia Teatral en La Alianza de la Tinta (Actor: V-ADU17)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'),
  '9788497596794',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'El Color de la Magia Teatral' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'))
);
-- Elenco para: Momo y los Hombres Grises en Lectores de la Madrugada (Actor: V-ADU21)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'),
  '9788420464978',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Momo y los Hombres Grises' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'))
);
-- Elenco para: American Gods: La Tormenta en Ecos del Pergamino (Actor: V-ADU25)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'),
  '9788416502011',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'American Gods: La Tormenta' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'))
);
-- Elenco para: Buenos Presagios: El Fin del Mundo en Horizonte de Palabras (Actor: V-ADU29)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'),
  '9788448005399',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Buenos Presagios: El Fin del Mundo' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'))
);
-- Elenco para: Snow Crash: El Metaverso en Club de Lectura Guayana (Actor: V-ADU33)
INSERT INTO MJV_elenco (id_lector, isbn, id_club, id_obra_act) VALUES (
  (SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'),
  '9788417347345',
  (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'),
  (SELECT id_obra_act FROM MJV_obra_actuada WHERE titulo = 'Snow Crash: El Metaverso' AND id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'))
);

COMMIT;
-- TIPO: SIMPLE (una sola tabla, sin GROUP BY, sin ORDER BY)
-- Directorio publico de lectores: datos de contacto sin doc_identidad (informacion sensible).
-- Traduce genero F/M a texto legible con DECODE.
CREATE OR REPLACE VIEW MJV_v_directorio_lector
  (id_lector, nombre_completo, genero, fecha_nac, telefono, email)
AS
SELECT
  l.id_lector,
  INITCAP(l.p_nombre) || ' ' || INITCAP(l.p_apellido) || ' ' || INITCAP(l.s_apellido),
  DECODE(l.genero, 'F', 'Femenino', 'M', 'Masculino'),
  l.fecha_nac,
  l.telefono,
  l.email
FROM MJV_lector l;


-- TIPO: SIMPLE (una sola tabla, sin GROUP BY, sin ORDER BY)
-- Catalogo editorial basico de libros: isbn, titulo, tipo, genero, edicion y paginas.
-- Excluye sinopsis (texto largo) y campo de secuencia para mantenerla liviana.
CREATE OR REPLACE VIEW MJV_v_catalogo_libros
  (isbn, titulo, tipo_narrativa, genero, primera_edicion, total_paginas)
AS
SELECT
  li.isbn,
  li.titulo,
  INITCAP(li.tipo_narrativa),
  INITCAP(li.genero),
  li.primera_edicion,
  li.total_paginas
FROM MJV_libro li;


-- TIPO: COMPLEJA (JOINs entre 5 tablas + DECODE + TO_CHAR)
-- Calendario mensual de debates: nombre del club, tipo de grupo, fecha y hora de reunion,
-- libro en discusion, nombre del moderador y estado (Realizada / Pendiente).
-- Soporte operativo del modulo de Administracion de Reuniones (Rubrica 2-II).
CREATE OR REPLACE VIEW MJV_v_reuniones_mes
  (id_club, nombre_club, id_grupo, tipo_grupo, fecha_reunion,
   hora_grupo, isbn, titulo_libro, nombre_moderador, realizada, es_ultima)
AS
SELECT
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  INITCAP(g.tipo_grupo),
  cr.fecha,
  TO_CHAR(g.hora_reunion, 'HH24:MI'),
  li.isbn,
  li.titulo,
  INITCAP(lm.p_nombre) || ' ' || INITCAP(lm.p_apellido) || ' ' || INITCAP(lm.s_apellido),
  DECODE(cr.realizada, 'S', 'Realizada', 'N', 'Pendiente'),
  DECODE(cr.ultima,    'S', 'Si',        'N', 'No')
FROM  MJV_calendario_reunion_mes cr
JOIN  MJV_grupo                  g  ON  g.id_grupo = cr.id_grupo
                                    AND g.id_club  = cr.id_club
JOIN  MJV_club                   c  ON  c.id_club  = cr.id_club
JOIN  MJV_libro                  li ON  li.isbn    = cr.isbn
JOIN  MJV_lector                 lm ON  lm.id_lector = cr.mod_id_lector;


-- TIPO: COMPLEJA (JOINs entre 5 tablas + GROUP BY + COUNT + ROUND + EXTRACT + NULLIF)
-- Agrega por (club, tipo de grupo, mes, anio):
--   total_reuniones    : reuniones realizadas en el mes
--   total_inasistencias: faltas registradas en el mes
--   pct_participacion  : porcentaje promedio de asistencia (0.00 a 100.00)
-- Base de calculo de la funcion MJV_promedio_part_mensual_tipo_grupo().
CREATE OR REPLACE VIEW MJV_v_participacion_mensual_tipo_grupo
  (id_club, nombre_club, tipo_grupo, mes, anio,
   total_reuniones, total_inasistencias, pct_participacion)
AS
SELECT
  c.id_club,
  c.nombre_club,
  INITCAP(g.tipo_grupo),
  EXTRACT(MONTH FROM cr.fecha),
  EXTRACT(YEAR  FROM cr.fecha),
  COUNT(DISTINCT cr.fecha || '|' || cr.id_grupo),
  COUNT(i.fecha_reunion),
  ROUND(
    100 - (
      COUNT(i.fecha_reunion) * 100
      /
      NULLIF(
        COUNT(DISTINCT gl.id_lector) * COUNT(DISTINCT cr.fecha || '|' || cr.id_grupo),
        0
      )
    ),
  2)
FROM  MJV_calendario_reunion_mes  cr
JOIN  MJV_grupo                   g  ON  g.id_grupo = cr.id_grupo
                                     AND g.id_club  = cr.id_club
JOIN  MJV_club                    c  ON  c.id_club  = cr.id_club
JOIN  MJV_g_lec                   gl ON  gl.id_grupo = cr.id_grupo
                                     AND gl.id_club  = cr.id_club
                                     AND gl.fec_f IS NULL
LEFT JOIN MJV_inasistencia        i  ON  i.id_grupo     = cr.id_grupo
                                     AND i.id_club      = cr.id_club
                                     AND i.fecha_reunion = cr.fecha
                                     AND i.isbn         = cr.isbn
                                     AND i.id_lector    = gl.id_lector
WHERE cr.realizada = 'S'
GROUP BY
  c.id_club,
  c.nombre_club,
  g.tipo_grupo,
  EXTRACT(MONTH FROM cr.fecha),
  EXTRACT(YEAR  FROM cr.fecha);


-- TIPO: COMPLEJA (JOINs entre 6 tablas + DECODE + TRUNC + MONTHS_BETWEEN)
-- Ficha completa de un miembro: datos personales, historial de membresias,
-- grupo asignado por periodo y catalogo de libros analizados con valoracion y conclusiones.
-- Una fila por (lector, entrada en g_lec, libro analizado durante ese periodo).
-- Backlog: v_ficha_lector. Reporte 1 exigido en enunciado pag. 10.
CREATE OR REPLACE VIEW MJV_v_ficha_lector
  (id_lector, nombre_completo, edad, nacionalidad, genero, telefono, email,
   id_club, nombre_club, fecha_ingreso, fecha_retiro, estatus, motivo_retiro,
   tipo_grupo, id_grupo, fecha_ingreso_grupo, fecha_retiro_grupo,
   isbn_analizado, titulo_analizado, valoracion_grupo, conclusiones)
AS
SELECT
  l.id_lector,
  INITCAP(l.p_nombre) || ' ' || INITCAP(l.p_apellido) || ' ' || INITCAP(l.s_apellido),
  TRUNC(MONTHS_BETWEEN(SYSDATE, l.fecha_nac) / 12),
  pa.nacionalidad,
  DECODE(l.genero, 'F', 'Femenino', 'M', 'Masculino'),
  l.telefono,
  l.email,
  c.id_club,
  c.nombre_club,
  hm.fecha_i,
  hm.fecha_f,
  INITCAP(hm.estatus),
  INITCAP(hm.motivo_retiro),
  INITCAP(g.tipo_grupo),
  g.id_grupo,
  gl.fec_i,
  gl.fec_f,
  li.isbn,
  li.titulo,
  crm.valoracion,
  crm.conclusiones
FROM MJV_lector l
JOIN MJV_pais pa               ON pa.id_pais   = l.id_pais_nac
JOIN MJV_historia_membresia hm ON hm.id_lector = l.id_lector
JOIN MJV_club c                ON c.id_club    = hm.id_club
JOIN MJV_g_lec gl              ON gl.id_lector = hm.id_lector
                               AND gl.id_club  = hm.id_club
                               AND gl.fecha_i  = hm.fecha_i
JOIN MJV_grupo g               ON g.id_grupo   = gl.id_grupo
                               AND g.id_club   = gl.id_club
LEFT JOIN MJV_calendario_reunion_mes crm
                               ON crm.id_grupo  = gl.id_grupo
                               AND crm.id_club  = gl.id_club
                               AND crm.ultima   = 'S'
                               AND crm.realizada = 'S'
                               AND crm.fecha BETWEEN gl.fec_i
                                 AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'))
LEFT JOIN MJV_libro li         ON li.isbn = crm.isbn;


-- TIPO: COMPLEJA (subconsulta en FROM + JOINs + GROUP BY + COUNT + AVG + ORDER BY)
-- Ficha del club: datos generales, cantidad de grupos por tipo (adultos/jovenes/ninos)
-- y catalogo historico de libros analizados con valoracion promedio entre grupos,
-- ordenado de mayor a menor valoracion. Backlog: v_ficha_club. Reporte 2 exigido pag. 10.
-- La subconsulta en el FROM es eficiente: se mantiene en memoria (prof. pag. 8 SQLsubconsultas).
CREATE OR REPLACE VIEW MJV_v_ficha_club
  (id_club, nombre_club, nombre_ciudad, nombre_pais, cod_postal, cuota_anual,
   grupos_adultos, grupos_jovenes, grupos_ninos,
   isbn, titulo_libro, tipo_narrativa, valoracion_promedio)
AS
SELECT
  c.id_club,
  c.nombre_club,
  ci.nombre_ciudad,
  pa.nombre_pais,
  c.cod_postal,
  DECODE(c.cuota_anual, 'S', 'Si', 'N', 'No'),
  gc.grupos_adultos,
  gc.grupos_jovenes,
  gc.grupos_ninos,
  li.isbn,
  li.titulo,
  INITCAP(li.tipo_narrativa),
  ROUND(AVG(crm.valoracion), 2)
FROM MJV_club c
JOIN MJV_ciudad ci ON ci.id_ciudad = c.id_ciudad
                  AND ci.id_pais   = c.id_pais
JOIN MJV_pais pa   ON pa.id_pais   = c.id_pais
JOIN (
  SELECT
    id_club,
    COUNT(CASE WHEN tipo_grupo = 'adultos' THEN 1 END) AS grupos_adultos,
    COUNT(CASE WHEN tipo_grupo = 'jovenes' THEN 1 END) AS grupos_jovenes,
    COUNT(CASE WHEN tipo_grupo = 'ninos'   THEN 1 END) AS grupos_ninos
  FROM MJV_grupo
  GROUP BY id_club
) gc ON gc.id_club = c.id_club
JOIN MJV_calendario_reunion_mes crm ON crm.id_club   = c.id_club
                                   AND crm.ultima    = 'S'
                                   AND crm.realizada = 'S'
JOIN MJV_libro li ON li.isbn = crm.isbn
GROUP BY
  c.id_club, c.nombre_club, ci.nombre_ciudad, pa.nombre_pais,
  c.cod_postal, c.cuota_anual,
  gc.grupos_adultos, gc.grupos_jovenes, gc.grupos_ninos,
  li.isbn, li.titulo, li.tipo_narrativa
ORDER BY c.id_club, ROUND(AVG(crm.valoracion), 2) DESC;

-- TIPO: COMPLEJA (JOINs múltiples + Subconsulta correlacionada para agregación + DECODE)
-- Ficha técnica detallada del libro: atributos editoriales, país de origen, valoración 
-- promedio global e histórico de los grupos y clubes que lo analizaron con sus conclusiones.
CREATE OR REPLACE VIEW MJV_v_ficha_libro
  (isbn, titulo, tipo_narrativa, genero, primera_edicion, total_paginas, pais_origen,
   valoracion_promedio_global, id_club, nombre_club, id_grupo, tipo_grupo, conclusiones_grupo)
AS
SELECT
  li.isbn,
  li.titulo,
  INITCAP(li.tipo_narrativa),
  INITCAP(li.genero),
  li.primera_edicion,
  li.total_paginas,
  pa.nombre_pais,
  -- Subconsulta correlacionada para computar el promedio histórico global del libro 
  -- sin alterar el grano de la vista (que incluye el detalle por cada grupo)
  ROUND((SELECT AVG(crm2.valoracion) 
         FROM MJV_calendario_reunion_mes crm2 
         WHERE crm2.isbn = li.isbn AND crm2.ultima = 'S' AND crm2.realizada = 'S'), 2),
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  INITCAP(g.tipo_grupo),
  crm.conclusiones
FROM MJV_libro li
JOIN MJV_pais pa ON pa.id_pais = li.id_pais
LEFT JOIN MJV_calendario_reunion_mes crm ON crm.isbn = li.isbn 
                                        AND crm.ultima = 'S' 
                                        AND crm.realizada = 'S'
LEFT JOIN MJV_grupo g  ON g.id_grupo = crm.id_grupo AND g.id_club = crm.id_club
LEFT JOIN MJV_club c   ON c.id_club = crm.id_club;

-- TIPO: COMPLEJA (Subconsultas CTE + Funciones Analíticas LAG + EXTRACT + NULLIF)
-- Análisis macro de crecimiento anual por país: calcula el porcentaje de incremento 
-- neto de miembros activos y la evolución de los ingresos percibidos por membresías.
CREATE OR REPLACE VIEW MJV_v_crecimiento_clubes
  (anio, id_pais, nombre_pais, total_miembros, pct_crecimiento_miembros, 
   ingresos_membresias, pct_crecimiento_ingresos)
AS
WITH stats_consolidadas AS (
  -- Paso 1: Agrupar la totalidad de los datos crudos por Año y País
  SELECT 
    p.id_pais,
    p.nombre_pais,
    periodos.anio,
    -- Conteo inequívoco de lectores que poseían estatus vigente durante el año en curso
    COUNT(DISTINCT hm.id_lector) AS miembros_totales,
    -- Sumarización de los montos efectivamente pagados en ese año calendario
    NVL(SUM(pm.monto), 0) AS ingresos_totales
  FROM MJV_pais p
  JOIN MJV_club c ON c.id_pais = p.id_pais
  -- Generación dinámica de la matriz de años disponibles en los registros históricos
  CROSS JOIN (
    SELECT DISTINCT EXTRACT(YEAR FROM fecha_i) AS anio FROM MJV_historia_membresia
    UNION
    SELECT DISTINCT EXTRACT(YEAR FROM fecha_pago) AS anio FROM MJV_pago_membresia
  ) periodos
  LEFT JOIN MJV_historia_membresia hm ON hm.id_club = c.id_club 
                                     AND EXTRACT(YEAR FROM hm.fecha_i) <= periodos.anio
                                     AND (hm.fecha_f IS NULL OR EXTRACT(YEAR FROM hm.fecha_f) >= periodos.anio)
  LEFT JOIN MJV_pago_membresia pm     ON pm.id_club = c.id_club 
                                     AND pm.id_lector = hm.id_lector 
                                     AND pm.fecha_i = hm.fecha_i
                                     AND EXTRACT(YEAR FROM pm.fecha_pago) = periodos.anio
  GROUP BY p.id_pais, p.nombre_pais, periodos.anio
)
-- Paso 2: Calcular los porcentajes delta relativos al año anterior mediante funciones de ventana
SELECT
  s.anio,
  s.id_pais,
  s.nombre_pais,
  s.miembros_totales,
  ROUND(
    (s.miembros_totales - LAG(s.miembros_totales, 1, s.miembros_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio)) * 100
    / NULLIF(LAG(s.miembros_totales, 1, s.miembros_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio), 0), 2
  ) AS pct_crecimiento_miembros,
  s.ingresos_totales,
  ROUND(
    (s.ingresos_totales - LAG(s.ingresos_totales, 1, s.ingresos_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio)) * 100
    / NULLIF(LAG(s.ingresos_totales, 1, s.ingresos_totales) OVER (PARTITION BY s.id_pais ORDER BY s.anio), 0), 2
  ) AS pct_crecimiento_ingresos
FROM stats_consolidadas s;

-- TIPO: COMPLEJA (JOINs de tablas operativas + Agregaciones complejas + SUM / AVG)
-- Histórico de obras teatrales escenificadas por club: reporta la cantidad de funciones,
-- la puntuación media otorgada por el público asistente y los ingresos acumulados en taquilla.
CREATE OR REPLACE VIEW MJV_v_obras_presentadas
  (id_club, nombre_club, id_obra_act, titulo_obra, isbn, titulo_libro,
   total_funciones, valoracion_promedio_publico, ingresos_acumulados_taquilla)
AS
SELECT
  c.id_club,
  c.nombre_club,
  oa.id_obra_act,
  oa.titulo,
  li.isbn,
  li.titulo,
  COUNT(f.id_funcion),
  ROUND(AVG(f.valoracion_obra), 2),
  -- Cálculo de taquilla acumulada: Suma de la asistencia multiplicada por el precio estático de entrada
  NVL(SUM(f.cantidad_asistencia * oa.costo_entrada), 0)
FROM MJV_obra_actuada oa
JOIN MJV_club c    ON c.id_club = oa.id_club
JOIN MJV_libro li  ON li.isbn = oa.isbn
LEFT JOIN MJV_funcion f ON f.id_obra_act = oa.id_obra_act 
                       AND f.isbn = oa.isbn 
                       AND f.id_club = oa.id_club
GROUP BY
  c.id_club,
  c.nombre_club,
  oa.id_obra_act,
  oa.titulo,
  li.isbn,
  li.titulo;

  -- TIPO: COMPLEJA (CTE + Agrupaciones Temporales Bimestrales + Funciones Matemáticas + LEFT JOIN)
-- Auditoría operativa de ausencias: calcula el porcentaje neto de inasistencias por bimestre 
-- calendario de cada lector según el grupo al que pertenecía durante la ejecución de las reuniones.
CREATE OR REPLACE VIEW MJV_v_asistencia_bimestre
  (anio, bimestre, id_lector, nombre_lector, id_club, nombre_club, id_grupo, tipo_grupo,
   reuniones_ejecutadas, inasistencias_registradas, pct_inasistencia)
AS
WITH universo_reuniones AS (
  -- Subconsulta estructural: Catalogar cada reunión en su respectivo año y bimestre natural
  SELECT 
    cr.id_club,
    cr.id_grupo,
    cr.fecha,
    cr.isbn,
    EXTRACT(YEAR FROM cr.fecha) AS anio,
    CEIL(EXTRACT(MONTH FROM cr.fecha) / 2) AS bimestre
  FROM MJV_calendario_reunion_mes cr
  WHERE cr.realizada = 'S'
)
SELECT
  ur.anio,
  ur.bimestre,
  l.id_lector,
  INITCAP(l.p_nombre) || ' ' || INITCAP(l.p_apellido),
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  INITCAP(g.tipo_grupo),
  -- Totalizador de reuniones mandatorias a las que el lector debió asistir en el periodo
  COUNT(DISTINCT ur.fecha || '|' || ur.isbn) AS reuniones_ejecutadas,
  -- Totalizador de las ausencias punibles penalizadas al lector
  COUNT(i.fecha_reunion) AS inasistencias_registradas,
  -- Porcentaje de deserción / inasistencia
  ROUND(
    (COUNT(i.fecha_reunion) * 100) 
    / 
    NULLIF(COUNT(DISTINCT ur.fecha || '|' || ur.isbn), 0), 2
  ) AS pct_inasistencia
FROM MJV_g_lec gl
JOIN MJV_lector l  ON l.id_lector = gl.id_lector
JOIN MJV_club c    ON c.id_club = gl.id_club
JOIN MJV_grupo g   ON g.id_grupo = gl.id_grupo AND g.id_club = gl.id_club
-- Restricción del cruce: Las reuniones debieron ocurrir en el intervalo donde el lector formaba parte activa del grupo
JOIN universo_reuniones ur ON ur.id_grupo = gl.id_grupo 
                          AND ur.id_club = gl.id_club
                          AND ur.fecha BETWEEN gl.fec_i 
                            AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'))
-- LEFT JOIN para asegurar reflejar a aquellos lectores ejemplares con asistencia perfecta (0% inasistencias)
LEFT JOIN MJV_inasistencia i ON i.id_lector = gl.id_lector
                            AND i.id_club = gl.id_club
                            AND i.fecha_i = gl.fecha_i
                            AND i.id_grupo = gl.id_grupo
                            AND i.fec_i_g_lec = gl.fec_i
                            AND i.fecha_reunion = ur.fecha
                            AND i.isbn = ur.isbn
GROUP BY
  ur.anio,
  ur.bimestre,
  l.id_lector,
  l.p_nombre,
  l.p_apellido,
  c.id_club,
  c.nombre_club,
  g.id_grupo,
  g.tipo_grupo;

  CREATE OR REPLACE TRIGGER MJV_tgr_g_lec_validar_edad
BEFORE INSERT ON MJV_g_lec 
FOR EACH ROW
DECLARE
  v_años NUMBER;
  v_tipo_grupo VARCHAR2(10);
  v_fecha_nac DATE;
BEGIN
  SELECT tipo_grupo INTO v_tipo_grupo 
  FROM MJV_grupo 
  WHERE id_grupo = :NEW.id_grupo AND id_club = :NEW.id_club;
  
  SELECT fecha_nac INTO v_fecha_nac 
  FROM MJV_lector 
  WHERE id_lector = :NEW.id_lector;
  
  v_años := FLOOR(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);
  
  IF v_años < 13 AND v_tipo_grupo != 'niños' THEN
    RAISE_APPLICATION_ERROR(-20008, 'Tipo de grupo incorrecto.');
  END IF;
  IF v_años BETWEEN 13 AND 25 AND v_tipo_grupo != 'jovenes' THEN
    RAISE_APPLICATION_ERROR(-20008, 'Tipo de grupo incorrecto.');
  END IF;
  IF v_años > 25 AND v_tipo_grupo != 'adultos' THEN
    RAISE_APPLICATION_ERROR(-20008, 'Tipo de grupo incorrecto.');
  END IF;
END;
/
-- NOTE: trigger para validar mayoria de edad y necesidad de representante
CREATE OR REPLACE TRIGGER MJV_tgr_validar_edad
BEFORE INSERT OR UPDATE ON MJV_lector
FOR EACH ROW
DECLARE
  meses NUMBER;
  edad NUMBER;
BEGIN
  meses := MONTHS_BETWEEN(SYSDATE, :NEW.fecha_nac) ;
  edad := TRUNC(meses/12);
IF edad < 6 THEN
      RAISE_APPLICATION_ERROR(-20000, 'La edad minima es 6.');
END IF;
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
CREATE OR REPLACE TRIGGER MJV_tgr_un_club_activo
BEFORE INSERT OR UPDATE ON MJV_historia_membresia
FOR EACH ROW
WHEN (NEW.estatus = 'activo')
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM MJV_historia_membresia
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
CREATE OR REPLACE TRIGGER MJV_tgr_hora_grupo_ninos
BEFORE INSERT OR UPDATE ON MJV_grupo
FOR EACH ROW
WHEN (NEW.tipo_grupo = 'niños')
BEGIN
  IF TO_CHAR(:NEW.hora_reunion, 'HH24:MI') > '17:00' THEN -- here '>' -> '>='
    RAISE_APPLICATION_ERROR(-20003,
      'Los grupos de niños deben iniciar a más tardar a las 17:00 para terminar antes de las 19:00.');
  END IF;
END;
/

-- HC-10: Al retirar un miembro, motivo_retiro y fecha_f son obligatorios
CREATE OR REPLACE TRIGGER MJV_tgr_retiro_completo
BEFORE INSERT OR UPDATE ON MJV_historia_membresia
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
CREATE OR REPLACE FUNCTION MJV_conversion_monetaria(
  p_monto          NUMBER,
  p_moneda_origen  VARCHAR2,
  p_moneda_destino VARCHAR2,
  p_tasa           NUMBER
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
  FROM MJV_pais
  WHERE moneda_local = v_origen;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20102, 'Moneda origen no registrada: ' || v_origen);
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM MJV_pais
  WHERE moneda_local = v_destino;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20103, 'Moneda destino no registrada: ' || v_destino);
  END IF;

  RETURN ROUND(p_monto * p_tasa, 2);
END MJV_conversion_monetaria;  
/
CREATE OR REPLACE FUNCTION MJV_edad_miembro(p_id_lector NUMBER)
RETURN NUMBER
IS
  v_fecha_nac DATE;
BEGIN
  SELECT fecha_nac INTO v_fecha_nac
  FROM MJV_lector
  WHERE id_lector = p_id_lector;

  -- TRUNC elimina los decimales dejando los años exactos cumplidos
  RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nac) / 12);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20110, 'Lector no encontrado con ID: ' || p_id_lector);
END MJV_edad_miembro;  
/

CREATE OR REPLACE FUNCTION MJV_antiguedad_en_club_miembro(
  p_id_lector NUMBER,
  p_id_club   NUMBER
) RETURN NUMBER
IS
  v_fecha_i DATE;
  v_fecha_f DATE;
BEGIN
  -- Se busca el registro activo (o el último) en la historia de membresía
  SELECT fecha_i, fecha_f INTO v_fecha_i, v_fecha_f
  FROM MJV_historia_membresia
  WHERE id_lector = p_id_lector
    AND id_club   = p_id_club
    AND estatus   = 'activo';

  RETURN TRUNC(MONTHS_BETWEEN(NVL(v_fecha_f, SYSDATE), v_fecha_i) / 12);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20111,
      'No se encontró una membresía activa para el lector ' || p_id_lector || ' en el club ' || p_id_club);
END MJV_antiguedad_en_club_miembro;  
/

-- Promedio de asistencia (0-100) de los grupos de un tipo en un club, para un mes/año.
-- Por cada grupo: ((oportunidades - inasistencias) / oportunidades) * 100; luego AVG entre grupos.
-- Oportunidad = miembro activo en g_lec que debía asistir a una reunión realizada del mes.
CREATE OR REPLACE FUNCTION MJV_promedio_part_mensual_tipo_grupo(
  p_id_club    NUMBER,
  p_tipo_grupo VARCHAR2,
  p_mes        NUMBER,
  p_anio       NUMBER
) RETURN NUMBER
IS
  v_tipo     VARCHAR2(10) := LOWER(TRIM(p_tipo_grupo));
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
       FROM MJV_calendario_reunion_mes crm
       JOIN MJV_g_lec gl ON gl.id_grupo = crm.id_grupo AND gl.id_club = g.id_club
       WHERE crm.id_grupo = g.id_grupo
         AND crm.realizada = 'S'
         AND EXTRACT(MONTH FROM crm.fecha) = p_mes
         AND EXTRACT(YEAR FROM crm.fecha)  = p_anio
         AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'))
      ) AS esperadas,
      (SELECT COUNT(*)
       FROM MJV_inasistencia i
       JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = i.id_grupo AND crm.fecha = i.fecha_reunion
       WHERE i.id_grupo = g.id_grupo
         AND i.id_club  = g.id_club
         AND crm.realizada = 'S'
         AND EXTRACT(MONTH FROM crm.fecha) = p_mes
         AND EXTRACT(YEAR FROM crm.fecha)  = p_anio
      ) AS faltas
    FROM MJV_grupo g
    WHERE g.id_club = p_id_club
      AND LOWER(g.tipo_grupo) = v_tipo
  )
  WHERE esperadas > 0;

  RETURN NVL(v_promedio, 0);
END MJV_promedio_part_mensual_tipo_grupo;
/
-- Porcentaje de asistencia (0-100) de un lector en un club durante un bimestre.
-- Bimestre 1 = ene-feb, 2 = mar-abr, 3 = may-jun, 4 = jul-ago, 5 = sep-oct, 6 = nov-dic.
CREATE OR REPLACE FUNCTION MJV_participacion_bimestre_miembro(
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

  -- Reuniones totales programadas y ejecutadas a las que el lector pertenecía en ese bimestre
  SELECT COUNT(*)
  INTO v_esperadas
  FROM MJV_calendario_reunion_mes crm
  JOIN MJV_g_lec gl ON gl.id_grupo = crm.id_grupo AND gl.id_club = p_id_club
  WHERE gl.id_lector = p_id_lector
    AND gl.id_club   = p_id_club
    AND crm.realizada = 'S'
    AND EXTRACT(YEAR FROM crm.fecha) = p_anio
    AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin
    AND crm.fecha BETWEEN gl.fec_i AND NVL(gl.fec_f, TO_DATE('31/12/9999', 'DD/MM/YYYY'));

  IF v_esperadas = 0 THEN
    RETURN 100;
  END IF;

  -- Inasistencias registradas del lector en ese mismo periodo
  SELECT COUNT(*)
  INTO v_faltas
  FROM MJV_inasistencia i
  JOIN MJV_calendario_reunion_mes crm ON crm.id_grupo = i.id_grupo AND crm.fecha = i.fecha_reunion
  WHERE i.id_lector = p_id_lector
    AND i.id_club   = p_id_club
    AND crm.realizada = 'S'
    AND EXTRACT(YEAR FROM crm.fecha) = p_anio
    AND EXTRACT(MONTH FROM crm.fecha) BETWEEN v_mes_ini AND v_mes_fin;

  RETURN ROUND(((v_esperadas - v_faltas) / v_esperadas) * 100, 2);
END MJV_participacion_bimestre_miembro;  
/


-- SPLITS:      Max       Min
-- ADULTOS      30        10
-- JOVENES      15        5
-- NIÑOS        15        10
-- "no se puede incluir un nuevo integrante o realizar un split mientras se esté discutiendo un libro" PAG 3
-- "Cuando se realiza esa división o split se dejan en el grupo original los miembros más antiguos y, luego por cada nueva inscripción se van asignando los nuevos miembros de manera equitativa" PAG 3
-- NOTE: creo que no es necesario revisar por el moderador aca puesto que condicion necesaria de split es que no se este analizando un libro, osea,
-- no hay reuniones que implica que tampoco hay un moderador elegido ya que el moderador tampoco es un puesto unico
CREATE OR REPLACE PROCEDURE MJV_sp_split_grupo(
    p_id_club_original IN NUMBER,
    p_id_grupo_original IN NUMBER,
    p_tipo_grupo IN VARCHAR2,
    p_dia_reunion IN NUMBER,
    p_hora_reunion IN DATE,
    p_nuevo_grupo_id OUT NUMBER
) AS
    v_min_miem NUMBER;
BEGIN
    IF p_tipo_grupo = 'adultos' THEN
        v_min_miem := 10;
    ELSIF p_tipo_grupo = 'jovenes' THEN
        v_min_miem := 5;
    ELSE  -- niños
        v_min_miem := 10;
    END IF;
    
    -- Crear nuevo grupo
    INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion)
    VALUES (p_id_club_original, p_tipo_grupo, SYSDATE, p_dia_reunion, p_hora_reunion)
    RETURNING id_grupo INTO p_nuevo_grupo_id;
    
    -- (traspaso)
    UPDATE MJV_g_lec 
    SET id_grupo = p_nuevo_grupo_id
    WHERE id_club = p_id_club_original AND id_grupo = p_id_grupo_original 
      AND fec_f IS NULL
      AND id_lector IN (
          SELECT id_lector FROM (
              SELECT id_lector, fec_i
              FROM MJV_g_lec
              WHERE id_club = p_id_club_original AND id_grupo = p_id_grupo_original 
                AND fec_f IS NULL
              ORDER BY fec_i DESC
              FETCH FIRST v_min_miem ROWS ONLY
          )
      );
    
    COMMIT;
END;
/


CREATE OR REPLACE TRIGGER MJV_tgr_grupo_lleno
BEFORE INSERT  ON MJV_g_lec-- NOTE: fecha_i, fec_i Quiza un trigger que revise que la fecha de ingreso sea >= a la de creacion en grupo
FOR EACH ROW

DECLARE
  f_grupo MJV_grupo%ROWTYPE;
  lector_estatus VARCHAR2(8);
  num_miembros NUMBER;
  max_miem NUMBER;
  v_nuevo_grupo_id NUMBER;
  v_se_hizo_ultima CHAR(1);
BEGIN

    BEGIN
SELECT ultima INTO v_se_hizo_ultima FROM MJV_calendario_reunion_mes  WHERE id_club = :NEW.id_club AND id_grupo = :NEW.id_grupo AND realizada = 'S' ORDER BY fecha DESC FETCH FIRST 1 ROWS ONLY;

IF v_se_hizo_ultima != 'S' THEN
                  RAISE_APPLICATION_ERROR(-20006, 'No se puede agregar miembros mientras se discute un libro');

END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- No hay reuniones realizadas, se puede agregar
    END;
    SELECT * INTO f_grupo 
    FROM MJV_grupo 
    WHERE id_club = :NEW.id_club AND id_grupo = :NEW.id_grupo ;


  BEGIN
    SELECT estatus INTO lector_estatus FROM MJV_historia_membresia WHERE id_club = :NEW.id_club AND id_lector = :NEW.id_lector AND estatus = 'activo';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
                  RAISE_APPLICATION_ERROR(-20007, 'El lector no tiene una membresia activa en el club asociado al grupo.');
  END;
  SELECT COUNT(*) INTO num_miembros FROM MJV_g_lec gl WHERE gl.id_club = :NEW.id_club AND gl.id_grupo = :NEW.id_grupo AND gl.fec_f IS NULL;
    -- Validar de grupo
    IF f_grupo.tipo_grupo = 'adultos' THEN
      max_miem := 30;
    END IF;
    IF f_grupo.tipo_grupo = 'jovenes' THEN
      max_miem := 15;
    END IF;
    IF f_grupo.tipo_grupo = 'niños' THEN
      max_miem := 15;
    END IF;
    IF num_miembros >= max_miem THEN
         MJV_sp_split_grupo(
            p_id_club_original => f_grupo.id_club,
            p_id_grupo_original => f_grupo.id_grupo,
            p_tipo_grupo => f_grupo.tipo_grupo,
            p_dia_reunion => f_grupo.dia_reunion,
            p_hora_reunion => f_grupo.hora_reunion,
            p_nuevo_grupo_id => v_nuevo_grupo_id
        );
        :NEW.id_grupo := v_nuevo_grupo_id;
    END IF;
END;
/


CREATE OR REPLACE TRIGGER MJV_tgr_validar_moderador
BEFORE INSERT OR UPDATE ON MJV_calendario_reunion_mes
FOR EACH ROW
DECLARE
    v_es_miembro_club NUMBER;
    v_tipo_grupo      VARCHAR2(10);
    v_es_adulto       NUMBER;
BEGIN
    -- Validar que el moderador sea miembro activo del mismo club
    SELECT COUNT(*)
    INTO v_es_miembro_club
    FROM MJV_g_lec
    WHERE id_lector = :NEW.mod_id_lector
      AND id_club   = :NEW.id_club
      AND fec_f IS NULL;  -- Miembro activo en el club

    IF v_es_miembro_club = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 
            'El moderador debe ser un miembro activo del mismo club (no de un club asociado).');
    END IF;

    -- tipo de grupo de la reunion
    SELECT tipo_grupo
    INTO v_tipo_grupo
    FROM MJV_grupo
    WHERE id_grupo = :NEW.id_grupo
      AND id_club  = :NEW.id_club;

    IF v_tipo_grupo = 'niños' THEN
        SELECT COUNT(*)
        INTO v_es_adulto
        FROM MJV_g_lec gl
        JOIN MJV_grupo g ON gl.id_grupo = g.id_grupo AND gl.id_club = g.id_club
        WHERE gl.id_lector = :NEW.mod_id_lector
          AND gl.id_club   = :NEW.id_club
          AND gl.fec_f IS NULL
          AND g.tipo_grupo = 'adultos';

        IF v_es_adulto = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 
                'Para reuniones de grupo de niños, el moderador debe ser miembro de un grupo de adultos del mismo club.');
        END IF;
    END IF;


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'No se encontró información del grupo o club asociado a la reunión.');
END;
/
--- NOTE: IA
CREATE OR REPLACE PROCEDURE MJV_sp_insertar_reunion( -- En lugar de insert usar esto para validaciones, cuando se aplique la seguridad se hace el revoke de insert
    p_id_club IN NUMBER,
    p_id_grupo IN NUMBER,
    p_fecha IN DATE,
    p_isbn IN VARCHAR2,
    p_mod_id_lector IN NUMBER,
    p_mod_fecha_i IN DATE,
    p_mod_hist_fecha_i IN DATE,
    p_realizada IN CHAR DEFAULT 'N',
    p_ultima IN CHAR DEFAULT 'N',
    p_conclusiones IN VARCHAR2 DEFAULT NULL,
    p_valoracion IN NUMBER DEFAULT NULL
) AS
    v_activas NUMBER;
    v_reuniones NUMBER;
    v_es_miembro_club NUMBER;
    v_tipo_grupo VARCHAR2(10);
    v_es_adulto NUMBER;
BEGIN
    -- =====================================================
    -- VALIDACIÓN 1: Moderador debe ser miembro activo del club
    -- =====================================================
    SELECT COUNT(*)
    INTO v_es_miembro_club
    FROM MJV_g_lec
    WHERE id_lector = p_mod_id_lector
      AND id_club = p_id_club
      AND fec_f IS NULL;

    IF v_es_miembro_club = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 
            'El moderador debe ser un miembro activo del mismo club.');
    END IF;

    -- =====================================================
    -- VALIDACIÓN 2: Tipo de grupo y moderador adulto para niños
    -- =====================================================
    SELECT tipo_grupo INTO v_tipo_grupo
    FROM MJV_grupo
    WHERE id_grupo = p_id_grupo AND id_club = p_id_club;

    IF v_tipo_grupo = 'niños' THEN
        SELECT COUNT(*)
        INTO v_es_adulto
        FROM MJV_g_lec gl
        JOIN MJV_grupo g ON gl.id_grupo = g.id_grupo AND gl.id_club = g.id_club
        WHERE gl.id_lector = p_mod_id_lector
          AND gl.id_club = p_id_club
          AND gl.fec_f IS NULL
          AND g.tipo_grupo = 'adultos';

        IF v_es_adulto = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 
                'Para reuniones de niños, el moderador debe ser de un grupo de adultos.');
        END IF;
    END IF;

    -- =====================================================
    -- VALIDACIÓN 3: Moderador no puede tener otra discusión activa
    -- =====================================================
    SELECT COUNT(*)
    INTO v_activas
    FROM MJV_calendario_reunion_mes
    WHERE mod_id_lector = p_mod_id_lector
      AND id_club = p_id_club
      AND realizada = 'N'
      AND ultima = 'N';

    IF v_activas > 0 THEN
        RAISE_APPLICATION_ERROR(-20033,
            'El moderador ya está asignado a otra discusión activa.');
    END IF;

    -- =====================================================
    -- VALIDACIÓN 4: Máximo 3 reuniones realizadas por libro
    -- =====================================================
    IF p_realizada = 'S' THEN
        SELECT COUNT(*)
        INTO v_reuniones
        FROM MJV_calendario_reunion_mes
        WHERE id_grupo = p_id_grupo
          AND id_club = p_id_club
          AND isbn = p_isbn
          AND realizada = 'S';

        IF v_reuniones >= 3 THEN
            RAISE_APPLICATION_ERROR(-20034,
                'Ya se han realizado 3 reuniones para este libro.');
        END IF;
    END IF;

    -- =====================================================
    -- VALIDACIÓN 5: Si es última reunión, conclusiones y valoración son obligatorias
    -- =====================================================
    IF p_ultima = 'S' THEN
        IF p_conclusiones IS NULL OR p_valoracion IS NULL THEN
            RAISE_APPLICATION_ERROR(-20035,
                'Para la última reunión, conclusiones y valoración son obligatorias.');
        END IF;
        
        -- Validar rango de valoración
        IF p_valoracion < 1 OR p_valoracion > 5 THEN
            RAISE_APPLICATION_ERROR(-20036,
                'La valoración debe estar entre 1 y 5.');
        END IF;
    END IF;

    -- =====================================================
    -- INSERT (todas las validaciones pasaron)
    -- =====================================================
    INSERT INTO MJV_calendario_reunion_mes (
        id_club, id_grupo, fecha, isbn,
        mod_id_lector, mod_fecha_i, mod_hist_fecha_i,
        realizada, ultima, conclusiones, valoracion
    ) VALUES (
        p_id_club, p_id_grupo, p_fecha, p_isbn,
        p_mod_id_lector, p_mod_fecha_i, p_mod_hist_fecha_i,
        p_realizada, p_ultima, p_conclusiones, p_valoracion
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Reunión insertada correctamente.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
        RAISE;
END;
/
