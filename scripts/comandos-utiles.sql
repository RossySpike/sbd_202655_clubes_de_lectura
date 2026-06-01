-- Ver tablas de usuario
SELECT table_name FROM user_tables;
-- ver todos los triggers
select trigger_name, status, table_name from user_triggers;
-- ver secuencias
SELECT sequence_name FROM user_sequences;



drop table LIBRO_AUTOR cascade constraints;

drop table LIBRO cascade constraints;

drop table GRUPO cascade constraints;

drop table ASOCIADO cascade constraints;

drop table IDIOMA_MIEMBRO cascade constraints;

drop table LECTOR cascade constraints;

drop table REPRESENTANTE cascade constraints;

drop table CLUB cascade constraints;

drop table AUTOR cascade constraints;

drop table IDIOMA cascade constraints;

drop table INSTITUCION cascade constraints;

drop table CIUDAD cascade constraints;

drop table PAIS cascade constraints;


drop trigger TGR_VALIDAR_MAYORIA_EDAD;


drop sequence SEQ_AUTOR;

drop sequence SEQ_GRUPO;

drop sequence SEQ_IDIOMA_MIEMBRO;

drop sequence SEQ_LECTOR;

drop sequence SEQ_REPRESENTANTE;

drop sequence SEQ_CLUB;

drop sequence SEQ_IDIOMA;

drop sequence SEQ_INSTITUCION;

drop sequence SEQ_CIUDAD;

drop sequence SEQ_PAIS;

