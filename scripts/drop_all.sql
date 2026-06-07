-- =============================================================================
-- SCRIPT DE ELIMINACIÓN TOTAL DE OBJETOS (TABLAS, SECUENCIAS, TRIGGERS, FUNCIONES, PROCEDIMIENTOS, ÍNDICES)
-- =============================================================================
-- EJECUTAR ESTE SCRIPT SOLO CUANDO SE DESEE BORRAR COMPLETAMENTE LA BASE DE DATOS DEL PROYECTO
-- =============================================================================

SET FEEDBACK OFF;
SET SERVEROUTPUT ON;

PROMPT Eliminando objetos de la base de datos...

-- 1. DROP TRIGGERS (primero para evitar dependencias)
PROMPT > Eliminando triggers...
BEGIN
   FOR trg IN (SELECT trigger_name FROM user_triggers WHERE trigger_name LIKE 'MJV\_%' ESCAPE '\') LOOP
      EXECUTE IMMEDIATE 'DROP TRIGGER ' || trg.trigger_name;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- 2. DROP FUNCTIONS
PROMPT > Eliminando funciones...
BEGIN
   FOR fn IN (SELECT object_name FROM user_objects WHERE object_type = 'FUNCTION' AND object_name LIKE 'MJV\_%' ESCAPE '\') LOOP
      EXECUTE IMMEDIATE 'DROP FUNCTION ' || fn.object_name;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- 3. DROP PROCEDURES
PROMPT > Eliminando procedimientos...
BEGIN
   FOR pr IN (SELECT object_name FROM user_objects WHERE object_type = 'PROCEDURE' AND object_name LIKE 'MJV\_%' ESCAPE '\') LOOP
      EXECUTE IMMEDIATE 'DROP PROCEDURE ' || pr.object_name;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- 4. DROP TABLAS (con cascade constraints)
PROMPT > Eliminando tablas...
BEGIN
   FOR tbl IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'MJV\_%' ESCAPE '\' ORDER BY table_name) LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || tbl.table_name || ' CASCADE CONSTRAINTS PURGE';
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- 5. DROP SEQUENCES
PROMPT > Eliminando secuencias...
BEGIN
   FOR seq IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'MJV\_%' ESCAPE '\') LOOP
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seq.sequence_name;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- 6. DROP ÍNDICES (opcional, porque ya se eliminan con las tablas; pero por si acaso)
PROMPT > Eliminando índices...
BEGIN
   FOR idx IN (SELECT index_name FROM user_indexes WHERE index_name LIKE 'MJV\_%' ESCAPE '\' AND table_name NOT LIKE 'MJV\_%' ESCAPE '\') LOOP
      EXECUTE IMMEDIATE 'DROP INDEX ' || idx.index_name;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

COMMIT;
PROMPT =========================================================================
PROMPT Todos los objetos han sido eliminados.
PROMPT =========================================================================

-- Verificación final
SELECT object_type, COUNT(*) FROM user_objects WHERE object_name LIKE 'MJV\_%' ESCAPE '\' GROUP BY object_type;
