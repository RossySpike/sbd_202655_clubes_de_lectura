-- NOTE: el NOCYCLE es para que cuando llegue a 999 no se vaya a -999
MJV_CREATE SEQUENCE seq_pais START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE pais(
  id_pais NUMBER(3) DEFAULT seq_pais.NEXTVAL PRIMARY KEY, -- 195 paises en el mundo maso
  nombre_pais VARCHAR2(100) NOT NULL,
  moneda_local VARCHAR2(3) NOT NULL, -- (Codigos ISO) USD, VES, COP, etc.
  nacionalidad VARCHAR2(100) NOT NULL UNIQUE
);


MJV_CREATE SEQUENCE seq_ciudad START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
-- NOTE: el NOT NULL es implicito por el CONSTRAINT, se pone para no ser ambiguo
MJV_CREATE TABLE ciudad(
  id_pais NUMBER(3) NOT NULL,
  id_ciudad NUMBER(3) DEFAULT seq_ciudad.NEXTVAL,
  nombre_ciudad VARCHAR2(100) NOT NULL,
  CONSTRAINT ciudad_pk PRIMARY KEY (id_pais, id_ciudad),
  CONSTRAINT ciudad_fk_pais FOREIGN KEY (id_pais) REFERENCES pais(id_pais)
);


MJV_CREATE SEQUENCE seq_institucion START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE institucion(
  id_pais NUMBER(3) NOT NULL,
  id_ciudad NUMBER(3) NOT NULL,
  id_institucion NUMBER(3) DEFAULT seq_institucion.NEXTVAL NOT NULL,
  nombre_inst VARCHAR2(100) NOT NULL,
  tipo VARCHAR2(12) NOT NULL,
  CONSTRAINT institucion_pk PRIMARY KEY (id_pais, id_ciudad, id_institucion),
  CONSTRAINT institucion_fk_ciudad FOREIGN KEY (id_pais, id_ciudad) REFERENCES ciudad(id_pais, id_ciudad),
  CONSTRAINT institucion_ck_tipo CHECK (tipo IN ('biblioteca', 'colegio', 'universidad', 'otro'))
);


MJV_CREATE SEQUENCE seq_idioma START WITH 1 MAXVALUE 999 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE idioma(
  id_idioma NUMBER(3) DEFAULT seq_idioma.NEXTVAL PRIMARY KEY,
  nombre_idioma VARCHAR2(100) NOT NULL -- NOTE: en el ER idioma no tiene el '*'
);


MJV_CREATE SEQUENCE seq_club START WITH 1 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE club(
  id_club NUMBER DEFAULT seq_club.NEXTVAL PRIMARY KEY,
  nombre_club VARCHAR2(100) NOT NULL,
  cuota_anual CHAR(1) NOT NULL, -- Con una vista se puede pasar a SiNo
  cod_postal VARCHAR2(20) NOT NULL, -- Hay paises con ceros a la izquierda o letras, maximo 11 caracteres (Iran)
-- Ciudad
  id_ciudad NUMBER(3) NOT NULL,
  id_pais NUMBER(3) NOT NULL,
  id_institucion NUMBER(3),
CONSTRAINT club_fk_ciudad FOREIGN KEY (id_pais, id_ciudad ) REFERENCES ciudad( id_pais, id_ciudad),
CONSTRAINT club_fk_institucion FOREIGN KEY (id_pais, id_ciudad, id_institucion) 
    REFERENCES institucion(id_pais, id_ciudad, id_institucion),
  CONSTRAINT club_ck_cuota CHECK (cuota_anual IN ('S', 'N'))
);

-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
MJV_CREATE TABLE asociado(
  id_club_izq NUMBER NOT NULL,
  id_club_der NUMBER NOT NULL,
  CONSTRAINT asociado_pk PRIMARY KEY (id_club_izq, id_club_der),
  CONSTRAINT asociado_fk_club_izq FOREIGN KEY (id_club_izq) REFERENCES club(id_club),
  CONSTRAINT asociado_fk_club_der FOREIGN KEY (id_club_der) REFERENCES club(id_club),
  CONSTRAINT asociado_ck_orden CHECK (id_club_izq < id_club_der) -- NOTE: esto se puede cambiar pero es para evitar duplicar (permite 1,2 pero no 2,1 sin embargo hay que mandarlo de forma ordenada) ademas que quita 1,1
);


MJV_CREATE SEQUENCE seq_representante START WITH 1 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE representante(
  id_representante NUMBER DEFAULT seq_representante.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) NOT NULL,
  p_apellido VARCHAR2(20) NOT NULL,
  doc_identidad VARCHAR2(20) NOT NULL,
  telefono VARCHAR2(20) NOT NULL
);


MJV_CREATE SEQUENCE seq_lector START WITH 1 INCREMENT BY 1 NOCYCLE;


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
MJV_CREATE TABLE lector(
  id_lector NUMBER DEFAULT seq_lector.NEXTVAL PRIMARY KEY,
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
  CONSTRAINT lector_ck_genero CHECK (genero IN ('F', 'M')),
  CONSTRAINT lector_fk_representante FOREIGN KEY (id_representante) REFERENCES representante(id_representante),
  CONSTRAINT lector_fk_representante_lector FOREIGN KEY (id_representante_lector) REFERENCES lector(id_lector),
  CONSTRAINT lector_fk_pais_nac FOREIGN KEY (id_pais_nac) REFERENCES pais(id_pais),
  CONSTRAINT lector_ck_arco CHECK (
    (id_representante IS NOT NULL AND id_representante_lector IS NULL)
    OR
    (id_representante IS NULL AND id_representante_lector IS NOT NULL)
  )
);

MJV_CREATE SEQUENCE seq_idioma_miembro START WITH 1 INCREMENT BY 1 NOCYCLE;

-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
MJV_CREATE TABLE idioma_miembro(
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


MJV_CREATE SEQUENCE seq_autor START WITH 1 INCREMENT BY 1 NOCYCLE;

-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE autor(
  id_autor NUMBER DEFAULT seq_autor.NEXTVAL PRIMARY KEY,
  p_nombre VARCHAR2(20) ,
  p_apellido VARCHAR2(20) ,
  nombre_ant_pseudonimo VARCHAR2(20)
);

-- TIPO DE ENTIDAD: Entrada (E)
MJV_CREATE TABLE libro(
  isbn VARCHAR2(20) PRIMARY KEY,  -- https:/es.wikipedia.org/wiki/ISBN#El_ISBN_de_trece_d%C3%ADgitos
  titulo VARCHAR2(100) NOT NULL,
  tipo_narrativa VARCHAR2(10) NOT NULL,
  sinopsis VARCHAR2(200) NOT NULL,
  genero VARCHAR2(20) NOT NULL,
  primera_edicion NUMBER NOT NULL, -- NOTE: Si solo guardamos el año, sino, date
  total_paginas NUMBER NOT NULL,
  id_pais NUMBER(3) NOT NULL,
  id_libro_siguiente VARCHAR2(20),
  CONSTRAINT libro_total_paginas_validas CHECK (total_paginas > 0),
  CONSTRAINT libro_tipo_narrativa_ck CHECK (tipo_narrativa IN ('novela','cuento','mito','leyenda','fabula','epopeya')),
  CONSTRAINT libro_idioma_fk_pais FOREIGN KEY ( id_pais ) REFERENCES pais(id_pais),
  CONSTRAINT libro_fk_libro_siguiente FOREIGN KEY ( id_libro_siguiente ) REFERENCES libro(isbn)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
MJV_CREATE TABLE libro_autor(
  id_autor NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  CONSTRAINT libro_autor_pk PRIMARY KEY (id_autor, isbn),
  CONSTRAINT libro_autor_fk_autor FOREIGN KEY ( id_autor ) REFERENCES autor(id_autor),
  CONSTRAINT libro_autor_fk_libro FOREIGN KEY ( isbn ) REFERENCES libro(isbn)
);


MJV_CREATE SEQUENCE seq_grupo START WITH 1 INCREMENT BY 1 NOCYCLE;

-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
MJV_CREATE TABLE grupo (
  id_grupo        NUMBER DEFAULT seq_grupo.NEXTVAL NOT NULL,
  id_club         NUMBER NOT NULL,
  tipo_grupo      VARCHAR2(10) NOT NULL,
  fecha_creacion  DATE NOT NULL,
  dia_reunion     NUMBER(1) NOT NULL, -- 1-7 Domingo, Lunes,...,Sabado
  hora_reunion    DATE NOT NULL, -- Hora militar
  CONSTRAINT grupo_pk PRIMARY KEY (id_grupo, id_club), 
  CONSTRAINT grupo_ck_tipo CHECK (tipo_grupo IN ('adultos','jovenes','niños')),
  CONSTRAINT grupo_ck_dia_permitido CHECK ((dia_reunion > 1) AND (dia_reunion<7)),
  CONSTRAINT grupo_ck_hora_reunion CHECK (TO_CHAR(hora_reunion, 'SS')='00'),
  CONSTRAINT grupo_ck_hora_permitida CHECK (TO_CHAR(hora_reunion, 'HH24:MI') BETWEEN '17:00' AND '19:00'), -- NOTE: Aqui no se si las 7 es hora maxima y ya nadie puede estar o es entre esta franja que pueden iniciar las reuniones, creo que es la ultima porque dice que los grupos de niños no pueden terminar despues de las 7
  CONSTRAINT grupo_fk_club FOREIGN KEY (id_club) REFERENCES club(id_club)
);


-- =============================================================================
-- SECUENCIAS FALTANTES (Backlog Parte 1)
-- =============================================================================

MJV_CREATE SEQUENCE seq_obra_actuada START WITH 1 INCREMENT BY 1 NOCYCLE;

MJV_CREATE SEQUENCE seq_pago_membresia START WITH 1 INCREMENT BY 1 NOCYCLE;

MJV_CREATE SEQUENCE seq_funcion START WITH 1 INCREMENT BY 1 NOCYCLE;

MJV_CREATE SEQUENCE seq_voto_publico START WITH 1 INCREMENT BY 1 NOCYCLE;


-- =============================================================================
-- TABLAS FALTANTES (Backlog Parte 2) - Orden por dependencias de FK
-- =============================================================================


-- TIPO DE ENTIDAD: Entrada (E)
-- Depende de: libro, club
MJV_CREATE TABLE obra_actuada(
  id_obra_act NUMBER DEFAULT seq_obra_actuada.NEXTVAL NOT NULL,
  titulo VARCHAR2(200) NOT NULL,
  activo CHAR(1) NOT NULL, -- 'S' = activa, 'N' = inactiva
  costo_entrada NUMBER(10, 2), -- NULL si no cobra entrada
  isbn VARCHAR2(20) NOT NULL,
  id_club NUMBER NOT NULL,
  CONSTRAINT obra_actuada_pk PRIMARY KEY (id_obra_act,isbn,id_club),
  CONSTRAINT obra_actuada_ck_activo CHECK (activo IN ('S', 'N')),
  CONSTRAINT obra_actuada_fk_libro FOREIGN KEY (isbn) REFERENCES libro(isbn),
  CONSTRAINT obra_actuada_fk_club FOREIGN KEY (id_club) REFERENCES club(id_club)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: lector, club
MJV_CREATE TABLE historia_membresia (
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  estatus VARCHAR2(8) NOT NULL, -- 'activo' o 'retirado'
  fecha_f DATE, -- NOTE: NULL mientras el miembro sigue activo
  motivo_retiro VARCHAR2(12), -- 'voluntario', 'inasistencia', 'deuda', 'otro'
  CONSTRAINT historia_membresia_pk PRIMARY KEY (id_lector, id_club, fecha_i),
  CONSTRAINT historia_membresia_fk_lec FOREIGN KEY (id_lector) REFERENCES lector(id_lector),
  CONSTRAINT historia_membresia_fk_club FOREIGN KEY (id_club) REFERENCES club(id_club),
  CONSTRAINT historia_membresia_ck_est CHECK (estatus IN ('activo', 'retirado')),
  CONSTRAINT historia_membresia_ck_mot CHECK (motivo_retiro IN ('voluntario', 'inasistencia', 'deuda', 'otro') OR motivo_retiro IS NULL)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: historia_membresia, libro
-- NOTE: cada miembro registra exactamente 3 obras preferidas al afiliarse (prioridad 1, 2, 3)
MJV_CREATE TABLE preferencia_obra(
  id_lector NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  prioridad NUMBER(1) NOT NULL, -- 1, 2 o 3
  CONSTRAINT preferencia_obra_pk PRIMARY KEY (id_lector, isbn),
-- ==============================================
-- WARNING: no esta en el (va a lector)
  -- CONSTRAINT preferencia_obra_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES historia_membresia(id_lector, id_club, fecha_i),
-- ==============================================

  CONSTRAINT preferencia_obra_fk_libro FOREIGN KEY (isbn) REFERENCES libro(isbn),
  CONSTRAINT preferencia_obra_fk_lector FOREIGN KEY (id_lector) REFERENCES lector(id_lector),
  CONSTRAINT preferencia_obra_ck_prior CHECK (prioridad IN (1, 2, 3))
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: historia_membresia, grupo
-- NOTE: un miembro solo puede estar activo en un grupo a la vez (fec_f NULL indica activo)
MJV_CREATE TABLE g_lec(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_grupo NUMBER NOT NULL,
  fec_i DATE NOT NULL, -- fecha de ingreso al grupo
  fec_f DATE, -- NOTE: NULL mientras el miembro sigue en el grupo
  CONSTRAINT g_lec_pk PRIMARY KEY (id_lector, id_club, fecha_i, id_grupo, fec_i),
  CONSTRAINT g_lec_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES historia_membresia(id_lector, id_club, fecha_i),
  CONSTRAINT g_lec_fk_grupo FOREIGN KEY (id_grupo, id_club) REFERENCES grupo(id_grupo, id_club)
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: grupo, libro, historia_membresia (moderador)
-- NOTE: el moderador es un miembro del club; para grupos de ninos debe ser de un grupo de adultos
MJV_CREATE TABLE calendario_reunion_mes(
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
  CONSTRAINT calendario_reunion_mes_pk PRIMARY KEY (id_grupo, id_club,fecha,isbn),
  CONSTRAINT calendario_reunion_mes_fk_grupo FOREIGN KEY (id_grupo,id_club) REFERENCES grupo(id_grupo, id_club),
  CONSTRAINT calendario_reunion_mes_fk_libro FOREIGN KEY (isbn) REFERENCES libro(isbn),
CONSTRAINT calendario_reunion_mes_fk_g_lec FOREIGN KEY (mod_id_lector, id_club, mod_fecha_i, id_grupo, mod_hist_fecha_i) REFERENCES g_lec( id_lector, id_club, fecha_i, id_grupo, fec_i ),
-- ==============================================
-- WARNING: no esta en el er (va para g_lec)
  -- CONSTRAINT calendario_reunion_mes_fk_mod FOREIGN KEY (mod_id_lector, mod_id_club, mod_fecha_i) REFERENCES historia_membresia(id_lector, id_club, fecha_i),
-- ==============================================
  CONSTRAINT calendario_reunion_mes_ck_realizada CHECK (realizada IN ('S', 'N')),
  CONSTRAINT calendario_reunion_mes_ck_ultima CHECK (ultima IN ('S', 'N')),
  CONSTRAINT calendario_reunion_mes_ck_val CHECK (valoracion BETWEEN 1 AND 5 OR valoracion IS NULL),
  -- HC-06: cuando ultima='S' conclusiones y valoracion son obligatorias
  CONSTRAINT calendario_ck_cierre CHECK (
    ultima = 'N'
    OR (ultima = 'S' AND conclusiones IS NOT NULL AND valoracion IS NOT NULL)
  )
);


-- TIPO DE ENTIDAD: Entrada/Salida (E/S)
-- Depende de: historia_membresia, obra_actuada
-- NOTE: pueden actuar miembros de clubes asociados, por eso la FK apunta a historia_membresia global
MJV_CREATE TABLE elenco(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  CONSTRAINT elenco_pk PRIMARY KEY (id_lector, -- PK Lector
   isbn,id_club,  id_obra_act -- PK obra_actuada
  ),
-- ==============================================
-- WARNING: no esta en el er
--  va para obra_actuada y lector no historia_membresia
  -- CONSTRAINT elenco_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES historia_membresia(id_lector, id_club, fecha_i),
-- ==============================================
CONSTRAINT elenco_fk_lector FOREIGN KEY (id_lector) REFERENCES lector(id_lector),
CONSTRAINT elenco_fk_obra  FOREIGN KEY (id_obra_act, isbn, id_club) REFERENCES obra_actuada(id_obra_act, isbn, id_club)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: historia_membresia
-- NOTE: solo aplica a clubes independientes (cuota_anual = 'S'); monto base $100 USD o equivalente local
MJV_CREATE TABLE pago_membresia(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_pago NUMBER DEFAULT seq_pago_membresia.NEXTVAL NOT NULL,
  fecha_pago DATE NOT NULL,
  monto NUMBER(10, 2) NOT NULL,
  CONSTRAINT pago_membresia_pk PRIMARY KEY (id_lector, id_club, fecha_i, id_pago),
CONSTRAINT pago_membresia_fk_lector FOREIGN KEY (id_lector) REFERENCES lector (id_lector),
  CONSTRAINT pago_membresia_fk_hm FOREIGN KEY (id_lector, id_club, fecha_i) REFERENCES historia_membresia(id_lector, id_club, fecha_i)

);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: g_lec, calendario_reunion_mes
-- NOTE: si un miembro supera el 30% de inasistencias en un bimestre es retirado del club
MJV_CREATE TABLE inasistencia(
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_grupo NUMBER NOT NULL,
  fec_i_g_lec DATE NOT NULL,
  fecha_reunion DATE NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  CONSTRAINT inasistencia_pk PRIMARY KEY (
isbn, -- PK libro
id_grupo, id_club, -- PK grupo y g_lec (historia_membresia pk compuesta)
id_lector, fecha_i, fec_i_g_lec, -- PK g_lec
fecha_reunion -- PK inasistencia
),
  CONSTRAINT inasistencia_fk_glec FOREIGN KEY (id_lector, id_club, fecha_i, id_grupo, fec_i_g_lec) REFERENCES g_lec(id_lector, id_club, fecha_i, id_grupo, fec_i),
  CONSTRAINT inasistencia_fk_cal FOREIGN KEY (id_grupo,id_club, fecha_reunion,isbn ) REFERENCES calendario_reunion_mes(id_grupo, id_club,fecha,isbn)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: obra_actuada
-- NOTE: valoracion_obra se calcula como promedio de voto_publico al cerrar la funcion
MJV_CREATE TABLE funcion(
  id_funcion NUMBER DEFAULT seq_funcion.NEXTVAL NOT NULL,
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
CONSTRAINT funcion_pk PRIMARY KEY (id_funcion, -- PK funcion
id_obra_act,isbn,id_club -- PK obra_actuada
),
  CONSTRAINT funcion_fk_obra FOREIGN KEY (id_obra_act,isbn,id_club) REFERENCES obra_actuada(id_obra_act,isbn,id_club),
  CONSTRAINT funcion_ck_valoracion CHECK (valoracion_obra BETWEEN 1 AND 5 OR valoracion_obra IS NULL)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: funcion
-- NOTE: el publico vota por el mejor actor y califica la obra; pueden haber empates en mejor actor
MJV_CREATE TABLE voto_publico(
  id_voto NUMBER DEFAULT seq_voto_publico.NEXTVAL PRIMARY KEY,
  id_funcion NUMBER NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  id_club NUMBER NOT NULL,
id_lector  NUMBER NOT NULL,
  calificacion_obra NUMBER(1) NOT NULL, -- estrellas: 1 a 5
  CONSTRAINT voto_publico_fk_funcion FOREIGN KEY (id_funcion,id_obra_act,isbn,id_club) REFERENCES funcion(id_funcion,id_obra_act,isbn,id_club),
CONSTRAINT voto_publico_fk_lector FOREIGN KEY (id_lector) REFERENCES lector(id_lector),
  CONSTRAINT voto_publico_ck_cal CHECK (calificacion_obra BETWEEN 1 AND 5)
);


-- TIPO DE ENTIDAD: Salida (S)
-- Depende de: funcion, elenco
-- NOTE: pueden existir multiples ganadores por funcion (empate permitido)
MJV_CREATE TABLE mejor_actor(
  id_funcion NUMBER NOT NULL,
  id_lector NUMBER NOT NULL,
  id_club NUMBER NOT NULL,
  fecha_i DATE NOT NULL,
  id_obra_act NUMBER NOT NULL,
  isbn VARCHAR2(20) NOT NULL,
  CONSTRAINT mejor_actor_pk PRIMARY KEY (
  id_funcion,  id_obra_act, isbn,id_club, -- PK funcion
  id_lector  -- al igual que isbn,id_club,  id_obra_act PK elenco
  ),
  CONSTRAINT mejor_actor_fk_funcion FOREIGN KEY (id_funcion, id_obra_act,isbn,id_club ) REFERENCES funcion(id_funcion, id_obra_act,isbn,id_club),
  CONSTRAINT mejor_actor_fk_elenco FOREIGN KEY (id_lector, isbn,id_club,  id_obra_act) REFERENCES elenco(id_lector, isbn,id_club,  id_obra_act )
);


-- =============================================================================
-- HC-09: INDICES DE RENDIMIENTO Y OPTIMIZACION (Backlog Tarea 3)
-- =============================================================================

-- Indices en llaves foraneas (evitan lock escalation en Oracle al hacer DELETE/UPDATE en tablas padre)
MJV_CREATE INDEX idx_asociado_der              ON asociado(id_club_der);
MJV_CREATE INDEX idx_lector_rep               ON lector(id_representante);
MJV_CREATE INDEX idx_lector_rep_lec           ON lector(id_representante_lector);
MJV_CREATE INDEX idx_lector_pais_nac          ON lector(id_pais_nac);
MJV_CREATE INDEX idx_idioma_miembro_club      ON idioma_miembro(id_club);
MJV_CREATE INDEX idx_idioma_miembro_lector    ON idioma_miembro(id_lector);
MJV_CREATE INDEX idx_libro_pais               ON libro(id_pais);
MJV_CREATE INDEX idx_libro_sig                ON libro(id_libro_siguiente);
MJV_CREATE INDEX idx_libro_autor_isbn         ON libro_autor(isbn);
MJV_CREATE INDEX idx_grupo_club               ON grupo(id_club);
MJV_CREATE INDEX idx_historia_membresia_club  ON historia_membresia(id_club);
MJV_CREATE INDEX idx_preferencia_obra_isbn    ON preferencia_obra(isbn);
MJV_CREATE INDEX idx_g_lec_grupo              ON g_lec(id_grupo);
MJV_CREATE INDEX idx_calendario_isbn          ON calendario_reunion_mes(isbn);
MJV_CREATE INDEX idx_calendario_mod           ON calendario_reunion_mes(mod_id_lector, id_club, mod_fecha_i);
MJV_CREATE INDEX idx_obra_actuada_isbn        ON obra_actuada(isbn);
MJV_CREATE INDEX idx_obra_actuada_club        ON obra_actuada(id_club);
MJV_CREATE INDEX idx_funcion_obra             ON funcion(id_obra_act);
MJV_CREATE INDEX idx_elenco_obra              ON elenco(id_obra_act);
MJV_CREATE INDEX idx_mejor_actor_elenco       ON mejor_actor(id_lector, id_club, fecha_i, id_obra_act);

-- Indices para busquedas frecuentes
MJV_CREATE INDEX idx_lector_busqueda          ON lector(p_apellido, p_nombre);
MJV_CREATE INDEX idx_libro_titulo             ON libro(titulo);
MJV_CREATE INDEX idx_club_nombre              ON club(nombre_club);


-- =============================================================================
-- Verificar que todo se creo correctamente
-- =============================================================================
SELECT object_type, COUNT(*)
FROM user_objects
WHERE object_type IN ('TABLE', 'SEQUENCE', 'TRIGGER', 'INDEX')
GROUP BY object_type;
