-- =============================================================================
-- PROYECTO: Sistema de Gestión de Clubes de Lectura — MJV
-- ARCHIVO:  menu.sql  (script principal)
-- MOTOR:    Oracle 19c / SQL Developer
--
-- Ejecutar con F5 (Run Script).
-- Segun la opcion elegida, invoca dinamicamente el archivo hijo:
--   menu_op_1.sql, menu_op_2.sql, ... menu_op_6.sql
-- Cada archivo hijo pide solo sus propios parametros y ejecuta su procedure.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET PAGESIZE     1000
SET VERIFY       OFF
SET FEEDBACK     OFF

PROMPT
PROMPT ============================================================
PROMPT  SISTEMA DE GESTION DE CLUBES DE LECTURA  -  MJV
PROMPT ============================================================
PROMPT
PROMPT  ADMINISTRACION DE CLUBES
PROMPT    1. Inscribir nuevo miembro
PROMPT    2. Registrar pago de membresia
PROMPT    3. Retirar miembro
PROMPT
PROMPT  ADMINISTRACION DE REUNIONES
PROMPT    4. Agendar reunion mensual
PROMPT    5. Registrar asistencia de miembro
PROMPT    6. Cerrar discusion de libro
PROMPT
PROMPT ============================================================
PROMPT

ACCEPT g_opcion NUMBER PROMPT ">> Elija una opcion (1-6): "

@@menu_op_&g_opcion..sql
