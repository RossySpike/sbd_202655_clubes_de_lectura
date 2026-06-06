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
 CONSTRAINT MJV_lector_ck_arco CHECK (
    (id_representante IS NOT NULL AND id_representante_lector IS NULL)
    OR
    (id_representante IS NULL AND id_representante_lector IS NOT NULL)
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
-- ==============================================
-- WARNING: no esta en el (va a lector)
  --CONSTRAINT MJV_preferencia_obra_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES MJV_historia_membresia(id_lector, id_club, fecha_i),
-- ==============================================

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
-- ==============================================
-- WARNING: no esta en el er (va para g_lec)
  --CONSTRAINT MJV_calendario_reunion_mes_fk_mod FOREIGN KEY (mod_id_lector, mod_id_club, mod_fecha_i) REFERENCES MJV_historia_membresia(id_lector, id_club, fecha_i),
-- ==============================================
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
-- ==============================================
-- WARNING: no esta en el er
--  va para obra_actuada y lector no historia_membresia
  --CONSTRAINT MJV_elenco_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES MJV_historia_membresia(id_lector, id_club, fecha_i),
-- ==============================================
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
 CONSTRAINT MJV_pago_membresia_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES MJV_historia_membresia(id_lector, id_club, fecha_i)

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
-- ==============================================
-- WARNING: no esta en el er
--  hora_funcion DATE NOT NULL, -- NOTE: se usa solo la parte de hora (HH24:MI)
--  duracion_minutos NUMBER(3) NOT NULL,
-- ==============================================
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
