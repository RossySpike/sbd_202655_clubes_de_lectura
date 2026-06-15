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
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), 'adultos', TO_DATE('30/06/2024', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), 'jovenes', TO_DATE('27/04/2023', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), 'niños', TO_DATE('13/07/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: El Café de los Capítulos
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), 'adultos', TO_DATE('26/03/2025', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), 'jovenes', TO_DATE('05/03/2025', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), 'niños', TO_DATE('04/11/2024', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Tertulia de Sabios y Letras
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), 'adultos', TO_DATE('06/05/2025', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), 'jovenes', TO_DATE('04/04/2025', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), 'niños', TO_DATE('02/08/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Mentes de Papiro
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), 'adultos', TO_DATE('12/11/2024', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), 'jovenes', TO_DATE('22/04/2024', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), 'niños', TO_DATE('06/07/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: La Alianza de la Tinta
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), 'adultos', TO_DATE('07/06/2023', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), 'jovenes', TO_DATE('30/06/2023', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), 'niños', TO_DATE('26/07/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Lectores de la Madrugada
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), 'adultos', TO_DATE('29/12/2023', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), 'jovenes', TO_DATE('26/08/2023', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), 'niños', TO_DATE('29/08/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Ecos del Pergamino
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), 'adultos', TO_DATE('23/04/2024', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), 'jovenes', TO_DATE('28/07/2023', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), 'niños', TO_DATE('29/09/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Horizonte de Palabras
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), 'adultos', TO_DATE('25/09/2024', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), 'jovenes', TO_DATE('21/01/2024', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), 'niños', TO_DATE('28/04/2025', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));
-- Club: Club de Lectura Guayana
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), 'adultos', TO_DATE('24/07/2024', 'DD/MM/YYYY'), 2, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), 'jovenes', TO_DATE('26/05/2025', 'DD/MM/YYYY'), 3, TO_DATE('18:00:00', 'HH24:MI:SS'));
INSERT INTO MJV_grupo (id_club, tipo_grupo, fecha_creacion, dia_reunion, hora_reunion) VALUES ((SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), 'niños', TO_DATE('26/10/2023', 'DD/MM/YYYY'), 4, TO_DATE('17:00:00', 'HH24:MI:SS'));

-- =============================================================================
-- 12. LECTORES (MJV_lector) - 108 registros (36 adultos, 36 jóvenes, 36 niños)
-- =============================================================================
-- --- ADULTOS (36) ---
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Alejandro', 'García', 'Club1A', 'V-ADU01', '+584240000001', 'alejandros.v-adu01@email.com', 'M', TO_DATE('22/07/1985', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Beatriz', 'Rodríguez', 'Club1A', 'V-ADU02', '+584240000002', 'beatrizs.v-adu02@email.com', 'F', TO_DATE('05/04/1979', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Carlos', 'López', 'Club1A', 'V-ADU03', '+584240000003', 'carloss.v-adu03@email.com', 'M', TO_DATE('24/03/1990', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Diana', 'Martínez', 'Club1A', 'V-ADU04', '+584240000004', 'dianas.v-adu04@email.com', 'F', TO_DATE('05/05/1982', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Eduardo', 'González', 'Club2A', 'V-ADU05', '+584240000005', 'eduardos.v-adu05@email.com', 'M', TO_DATE('05/06/2004', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fernando', 'Pérez', 'Club2A', 'V-ADU06', '+584240000006', 'fernandos.v-adu06@email.com', 'M', TO_DATE('01/04/1977', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gabriela', 'Sánchez', 'Club2A', 'V-ADU07', '+584240000007', 'gabrielas.v-adu07@email.com', 'F', TO_DATE('26/06/1996', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Hugo', 'Ramírez', 'Club2A', 'V-ADU08', '+584240000008', 'hugos.v-adu08@email.com', 'M', TO_DATE('27/11/1986', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Isabel', 'Cruz', 'Club3A', 'V-ADU09', '+584240000009', 'isabels.v-adu09@email.com', 'F', TO_DATE('02/07/1974', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Javier', 'Flores', 'Club3A', 'V-ADU10', '+584240000010', 'javiers.v-adu10@email.com', 'M', TO_DATE('09/04/2000', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Karla', 'Gómez', 'Club3A', 'V-ADU11', '+584240000011', 'karlas.v-adu11@email.com', 'F', TO_DATE('21/02/1976', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Luis', 'Díaz', 'Club3A', 'V-ADU12', '+584240000012', 'luiss.v-adu12@email.com', 'M', TO_DATE('19/02/1989', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Mónica', 'Morales', 'Club4A', 'V-ADU13', '+584240000013', 'monicas.v-adu13@email.com', 'F', TO_DATE('15/09/1983', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Néstor', 'Reyes', 'Club4A', 'V-ADU14', '+584240000014', 'nestors.v-adu14@email.com', 'M', TO_DATE('29/11/1990', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Olga', 'Ortiz', 'Club4A', 'V-ADU15', '+584240000015', 'olgas.v-adu15@email.com', 'F', TO_DATE('26/11/1991', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Patricia', 'Castillo', 'Club4A', 'V-ADU16', '+584240000016', 'patricias.v-adu16@email.com', 'F', TO_DATE('08/02/1989', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Quique', 'Ramos', 'Club5A', 'V-ADU17', '+584240000017', 'quiques.v-adu17@email.com', 'M', TO_DATE('01/12/1991', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Rosa', 'Ruiz', 'Club5A', 'V-ADU18', '+584240000018', 'rosas.v-adu18@email.com', 'F', TO_DATE('25/04/1991', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Silvia', 'Rivera', 'Club5A', 'V-ADU19', '+584240000019', 'silvias.v-adu19@email.com', 'F', TO_DATE('29/07/1992', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Tomás', 'Álvarez', 'Club5A', 'V-ADU20', '+584240000020', 'tomass.v-adu20@email.com', 'M', TO_DATE('23/08/1990', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Úrsula', 'Méndez', 'Club6A', 'V-ADU21', '+584240000021', 'ursulas.v-adu21@email.com', 'F', TO_DATE('21/12/1997', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Víctor', 'Chávez', 'Club6A', 'V-ADU22', '+584240000022', 'victors.v-adu22@email.com', 'M', TO_DATE('27/02/1978', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Walter', 'Vásquez', 'Club6A', 'V-ADU23', '+584240000023', 'walters.v-adu23@email.com', 'M', TO_DATE('17/02/1982', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ximena', 'Guzmán', 'Club6A', 'V-ADU24', '+584240000024', 'ximenas.v-adu24@email.com', 'F', TO_DATE('08/09/1975', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Yolanda', 'Fernández', 'Club7A', 'V-ADU25', '+584240000025', 'yolandas.v-adu25@email.com', 'F', TO_DATE('25/09/1990', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Zoilo', 'Salazar', 'Club7A', 'V-ADU26', '+584240000026', 'zoilos.v-adu26@email.com', 'M', TO_DATE('16/05/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Alberto', 'Medina', 'Club7A', 'V-ADU27', '+584240000027', 'albertos.v-adu27@email.com', 'M', TO_DATE('18/11/1991', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Brenda', 'Herrera', 'Club7A', 'V-ADU28', '+584240000028', 'brendas.v-adu28@email.com', 'F', TO_DATE('01/12/1993', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('César', 'Castro', 'Club8A', 'V-ADU29', '+584240000029', 'cesars.v-adu29@email.com', 'M', TO_DATE('29/04/1984', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Daniel', 'Vargas', 'Club8A', 'V-ADU30', '+584240000030', 'daniels.v-adu30@email.com', 'M', TO_DATE('21/12/1987', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Estela', 'Rojas', 'Club8A', 'V-ADU31', '+584240000031', 'estelas.v-adu31@email.com', 'F', TO_DATE('09/05/2003', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Felipe', 'Muñoz', 'Club8A', 'V-ADU32', '+584240000032', 'felipes.v-adu32@email.com', 'M', TO_DATE('21/02/1984', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gloria', 'Silva', 'Club9A', 'V-ADU33', '+584240000033', 'glorias.v-adu33@email.com', 'F', TO_DATE('23/04/2003', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Héctor', 'Suárez', 'Club9A', 'V-ADU34', '+584240000034', 'hectors.v-adu34@email.com', 'M', TO_DATE('18/04/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Irene', 'Delgado', 'Club9A', 'V-ADU35', '+584240000035', 'irenes.v-adu35@email.com', 'F', TO_DATE('08/12/1987', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('José', 'Peña', 'Club9A', 'V-ADU36', '+584240000036', 'joses.v-adu36@email.com', 'M', TO_DATE('29/09/1978', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);

-- --- JÓVENES (36) ---
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Alan', 'García', 'Club1J', 'V-JOV01', '+584140000001', 'alans.v-jov01@email.com', 'M', TO_DATE('09/07/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Bruno', 'Rodríguez', 'Club1J', 'V-JOV02', '+584140000002', 'brunos.v-jov02@email.com', 'M', TO_DATE('14/06/2008', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Camila', 'López', 'Club1J', 'V-JOV03', '+584140000003', 'camilas.v-jov03@email.com', 'F', TO_DATE('19/10/2008', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('David', 'Martínez', 'Club1J', 'V-JOV04', '+584140000004', 'davids.v-jov04@email.com', 'M', TO_DATE('21/04/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Elena', 'González', 'Club2J', 'V-JOV05', '+584140000005', 'elenas.v-jov05@email.com', 'F', TO_DATE('28/04/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fabio', 'Pérez', 'Club2J', 'V-JOV06', '+584140000006', 'fabios.v-jov06@email.com', 'M', TO_DATE('30/11/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gisela', 'Sánchez', 'Club2J', 'V-JOV07', '+584140000007', 'giselas.v-jov07@email.com', 'F', TO_DATE('25/11/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Hernán', 'Ramírez', 'Club2J', 'V-JOV08', '+584140000008', 'hernans.v-jov08@email.com', 'M', TO_DATE('29/11/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Inés', 'Cruz', 'Club3J', 'V-JOV09', '+584140000009', 'iness.v-jov09@email.com', 'F', TO_DATE('21/09/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Jorge', 'Flores', 'Club3J', 'V-JOV10', '+584140000010', 'jorges.v-jov10@email.com', 'M', TO_DATE('15/11/2008', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Kevin', 'Gómez', 'Club3J', 'V-JOV11', '+584140000011', 'kevins.v-jov11@email.com', 'M', TO_DATE('13/10/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Laura', 'Díaz', 'Club3J', 'V-JOV12', '+584140000012', 'lauras.v-jov12@email.com', 'F', TO_DATE('23/08/2011', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Mateo', 'Morales', 'Club4J', 'V-JOV13', '+584140000013', 'mateos.v-jov13@email.com', 'M', TO_DATE('15/04/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Natalia', 'Reyes', 'Club4J', 'V-JOV14', '+584140000014', 'natalias.v-jov14@email.com', 'F', TO_DATE('06/08/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Oscar', 'Ortiz', 'Club4J', 'V-JOV15', '+584140000015', 'oscars.v-jov15@email.com', 'M', TO_DATE('09/05/2011', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Paola', 'Castillo', 'Club4J', 'V-JOV16', '+584140000016', 'paolas.v-jov16@email.com', 'F', TO_DATE('25/12/2011', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Raúl', 'Ramos', 'Club5J', 'V-JOV17', '+584140000017', 'rauls.v-jov17@email.com', 'M', TO_DATE('06/06/2007', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Sofía', 'Ruiz', 'Club5J', 'V-JOV18', '+584140000018', 'sofias.v-jov18@email.com', 'F', TO_DATE('17/11/2008', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Teresa', 'Rivera', 'Club5J', 'V-JOV19', '+584140000019', 'teresas.v-jov19@email.com', 'F', TO_DATE('01/11/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ulises', 'Álvarez', 'Club5J', 'V-JOV20', '+584140000020', 'ulisess.v-jov20@email.com', 'M', TO_DATE('06/04/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Valeria', 'Méndez', 'Club6J', 'V-JOV21', '+584140000021', 'valerias.v-jov21@email.com', 'F', TO_DATE('04/08/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Wendy', 'Chávez', 'Club6J', 'V-JOV22', '+584140000022', 'wendys.v-jov22@email.com', 'F', TO_DATE('07/11/2012', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Xavier', 'Vásquez', 'Club6J', 'V-JOV23', '+584140000023', 'xaviers.v-jov23@email.com', 'M', TO_DATE('15/10/2007', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Yuri', 'Guzmán', 'Club6J', 'V-JOV24', '+584140000024', 'yuris.v-jov24@email.com', 'F', TO_DATE('02/03/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Zulma', 'Fernández', 'Club7J', 'V-JOV25', '+584140000025', 'zulmas.v-jov25@email.com', 'F', TO_DATE('02/04/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Adrián', 'Salazar', 'Club7J', 'V-JOV26', '+584140000026', 'adrians.v-jov26@email.com', 'M', TO_DATE('11/10/2012', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Belén', 'Medina', 'Club7J', 'V-JOV27', '+584140000027', 'belens.v-jov27@email.com', 'F', TO_DATE('09/12/2012', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Cristian', 'Herrera', 'Club7J', 'V-JOV28', '+584140000028', 'cristians.v-jov28@email.com', 'M', TO_DATE('08/12/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Daniela', 'Castro', 'Club8J', 'V-JOV29', '+584140000029', 'danielas.v-jov29@email.com', 'F', TO_DATE('07/03/2008', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Emilio', 'Vargas', 'Club8J', 'V-JOV30', '+584140000030', 'emilios.v-jov30@email.com', 'M', TO_DATE('05/04/2010', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fabiola', 'Rojas', 'Club8J', 'V-JOV31', '+584140000031', 'fabiolas.v-jov31@email.com', 'F', TO_DATE('11/10/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gonzalo', 'Muñoz', 'Club8J', 'V-JOV32', '+584140000032', 'gonzalos.v-jov32@email.com', 'M', TO_DATE('20/03/2008', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Hilda', 'Silva', 'Club9J', 'V-JOV33', '+584140000033', 'hildas.v-jov33@email.com', 'F', TO_DATE('15/11/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Iván', 'Suárez', 'Club9J', 'V-JOV34', '+584140000034', 'ivans.v-jov34@email.com', 'M', TO_DATE('18/01/2006', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Julia', 'Delgado', 'Club9J', 'V-JOV35', '+584140000035', 'julias.v-jov35@email.com', 'F', TO_DATE('26/12/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, NULL, NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Karim', 'Peña', 'Club9J', 'V-JOV36', '+584140000036', 'karims.v-jov36@email.com', 'M', TO_DATE('24/04/2009', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, NULL, NULL);

-- --- NIÑOS (36) ---
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Andrés', 'García', 'Club1N', 'V-NIN01', '+584120000001', 'andress.v-nin01@email.com', 'M', TO_DATE('02/03/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Blanca', 'Rodríguez', 'Club1N', 'V-NIN02', '+584120000002', 'blancas.v-nin02@email.com', 'F', TO_DATE('05/12/2015', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Claudio', 'López', 'Club1N', 'V-NIN03', '+584120000003', 'claudios.v-nin03@email.com', 'M', TO_DATE('04/12/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Diego', 'Martínez', 'Club1N', 'V-NIN04', '+584120000004', 'diegos.v-nin04@email.com', 'M', TO_DATE('03/09/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Elisa', 'González', 'Club2N', 'V-NIN05', '+584120000005', 'elisas.v-nin05@email.com', 'F', TO_DATE('05/08/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Francisco', 'Pérez', 'Club2N', 'V-NIN06', '+584120000006', 'franciscos.v-nin06@email.com', 'M', TO_DATE('31/07/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gaby', 'Sánchez', 'Club2N', 'V-NIN07', '+584120000007', 'gabys.v-nin07@email.com', 'F', TO_DATE('16/11/2017', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Humberto', 'Ramírez', 'Club2N', 'V-NIN08', '+584120000008', 'humbertos.v-nin08@email.com', 'M', TO_DATE('26/06/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ignacio', 'Cruz', 'Club3N', 'V-NIN09', '+584120000009', 'ignacios.v-nin09@email.com', 'M', TO_DATE('15/01/2014', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Juan', 'Flores', 'Club3N', 'V-NIN10', '+584120000010', 'juans.v-nin10@email.com', 'M', TO_DATE('06/04/2015', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Katia', 'Gómez', 'Club3N', 'V-NIN11', '+584120000011', 'katias.v-nin11@email.com', 'F', TO_DATE('17/08/2019', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Lucas', 'Díaz', 'Club3N', 'V-NIN12', '+584120000012', 'lucass.v-nin12@email.com', 'M', TO_DATE('19/12/2019', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Mario', 'Morales', 'Club4N', 'V-NIN13', '+584120000013', 'marios.v-nin13@email.com', 'M', TO_DATE('09/04/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Nuria', 'Reyes', 'Club4N', 'V-NIN14', '+584120000014', 'nurias.v-nin14@email.com', 'F', TO_DATE('06/01/2014', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Omar', 'Ortiz', 'Club4N', 'V-NIN15', '+584120000015', 'omars.v-nin15@email.com', 'M', TO_DATE('09/11/2019', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Pablo', 'Castillo', 'Club4N', 'V-NIN16', '+584120000016', 'pablos.v-nin16@email.com', 'M', TO_DATE('25/06/2017', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Rocío', 'Ramos', 'Club5N', 'V-NIN17', '+584120000017', 'rocios.v-nin17@email.com', 'F', TO_DATE('17/11/2015', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Samuel', 'Ruiz', 'Club5N', 'V-NIN18', '+584120000018', 'samuels.v-nin18@email.com', 'M', TO_DATE('25/09/2019', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Tania', 'Rivera', 'Club5N', 'V-NIN19', '+584120000019', 'tanias.v-nin19@email.com', 'F', TO_DATE('25/12/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Uriel', 'Álvarez', 'Club5N', 'V-NIN20', '+584120000020', 'uriels.v-nin20@email.com', 'M', TO_DATE('20/04/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Valentina', 'Méndez', 'Club6N', 'V-NIN21', '+584120000021', 'valentinas.v-nin21@email.com', 'F', TO_DATE('16/12/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('William', 'Chávez', 'Club6N', 'V-NIN22', '+584120000022', 'williams.v-nin22@email.com', 'M', TO_DATE('04/09/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Xander', 'Vásquez', 'Club6N', 'V-NIN23', '+584120000023', 'xanders.v-nin23@email.com', 'M', TO_DATE('02/04/2019', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Yago', 'Guzmán', 'Club6N', 'V-NIN24', '+584120000024', 'yagos.v-nin24@email.com', 'M', TO_DATE('16/12/2019', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Zoraida', 'Fernández', 'Club7N', 'V-NIN25', '+584120000025', 'zoraidas.v-nin25@email.com', 'F', TO_DATE('23/03/2017', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Ángel', 'Salazar', 'Club7N', 'V-NIN26', '+584120000026', 'angels.v-nin26@email.com', 'M', TO_DATE('31/03/2016', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Boris', 'Medina', 'Club7N', 'V-NIN27', '+584120000027', 'boriss.v-nin27@email.com', 'M', TO_DATE('26/03/2014', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Clara', 'Herrera', 'Club7N', 'V-NIN28', '+584120000028', 'claras.v-nin28@email.com', 'F', TO_DATE('07/03/2015', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Venezuela'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Damián', 'Castro', 'Club8N', 'V-NIN29', '+584120000029', 'damians.v-nin29@email.com', 'M', TO_DATE('13/06/2017', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Estados Unidos'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Eva', 'Vargas', 'Club8N', 'V-NIN30', '+584120000030', 'evas.v-nin30@email.com', 'F', TO_DATE('06/11/2014', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'China'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Fede', 'Rojas', 'Club8N', 'V-NIN31', '+584120000031', 'fedes.v-nin31@email.com', 'M', TO_DATE('11/05/2014', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Canadá'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Gema', 'Muñoz', 'Club8N', 'V-NIN32', '+584120000032', 'gemas.v-nin32@email.com', 'F', TO_DATE('27/08/2014', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Reino Unido'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Íñigo', 'Silva', 'Club9N', 'V-NIN33', '+584120000033', 'inigos.v-nin33@email.com', 'M', TO_DATE('04/09/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Alemania'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Inma', 'Suárez', 'Club9N', 'V-NIN34', '+584120000034', 'inmas.v-nin34@email.com', 'F', TO_DATE('12/05/2017', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Jaime', 'Delgado', 'Club9N', 'V-NIN35', '+584120000035', 'jaimes.v-nin35@email.com', 'M', TO_DATE('21/02/2018', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);
INSERT INTO MJV_lector (p_nombre, p_apellido, s_apellido, doc_identidad, telefono, email, genero, fecha_nac, id_pais_nac, s_nombre, id_representante, id_representante_lector) VALUES ('Kiko', 'Peña', 'Club9N', 'V-NIN36', '+584120000036', 'kikos.v-nin36@email.com', 'M', TO_DATE('24/04/2017', 'DD/MM/YYYY'), (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), NULL, (SELECT MIN(id_representante) FROM MJV_representante), NULL);

-- =============================================================================
-- 13. HISTORIA DE MEMBRESÍA (MJV_historia_membresia) - 108 registros
-- =============================================================================
-- Miembros de Refugio Literario del Sur
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('18/07/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('24/06/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('22/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('03/02/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('22/01/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('10/02/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('15/10/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('18/07/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('28/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('13/02/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('16/06/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de El Café de los Capítulos
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('27/06/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('25/11/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/05/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('18/05/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('03/12/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('31/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('28/02/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('14/10/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('22/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('05/08/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('09/06/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('17/02/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Tertulia de Sabios y Letras
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('23/01/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('08/01/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('20/08/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('16/08/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('17/06/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('02/07/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('29/04/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('04/01/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('03/11/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('15/09/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('07/04/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Mentes de Papiro
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('12/05/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('24/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('03/06/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('23/11/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('24/04/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('02/08/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('29/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('23/09/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('19/04/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('17/07/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('14/07/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de La Alianza de la Tinta
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('02/03/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('23/12/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('08/06/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('09/08/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('26/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('06/06/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('29/11/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('22/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('16/09/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('13/11/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('20/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('10/02/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Lectores de la Madrugada
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('16/09/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('23/07/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/06/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('11/10/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('08/01/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('02/06/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('12/11/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('05/07/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('19/08/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('26/08/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('30/01/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('29/11/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Ecos del Pergamino
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('28/10/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('07/04/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('28/11/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('08/07/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('21/09/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('24/06/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('23/11/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('28/09/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/05/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('03/08/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('23/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('09/08/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Horizonte de Palabras
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('09/03/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('28/08/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('25/10/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('13/04/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('22/02/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('06/06/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('25/06/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('03/05/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('18/10/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('17/11/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('20/07/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('23/12/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
-- Miembros de Club de Lectura Guayana
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('15/08/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('27/07/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('17/03/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('03/01/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('27/08/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('19/02/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('10/12/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('18/07/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('22/07/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('08/10/2023', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('28/05/2024', 'DD/MM/YYYY'), 'activo', NULL, NULL);
INSERT INTO MJV_historia_membresia (id_lector, id_club, fecha_i, estatus, fecha_f, motivo_retiro) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('12/05/2025', 'DD/MM/YYYY'), 'activo', NULL, NULL);

-- =============================================================================
-- 14. MIEMBROS POR GRUPO (MJV_g_lec) - 108 registros
-- =============================================================================
-- Asignaciones de grupo para Refugio Literario del Sur
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('18/07/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('18/07/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('24/06/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('24/06/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('22/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('22/12/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('03/02/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'adultos'), TO_DATE('03/02/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('01/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('01/12/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('22/01/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('22/01/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('10/02/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('10/02/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('15/10/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'jovenes'), TO_DATE('15/10/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN01'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('18/07/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('18/07/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN02'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('28/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('28/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN03'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('13/02/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('13/02/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN04'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur'), TO_DATE('16/06/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Refugio Literario del Sur') AND tipo_grupo = 'niños'), TO_DATE('16/06/2025', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para El Café de los Capítulos
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('27/06/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('27/06/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('25/11/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('25/11/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('01/05/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('01/05/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('18/05/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'adultos'), TO_DATE('18/05/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('03/12/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('03/12/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('31/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('31/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('28/02/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('28/02/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('14/10/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'jovenes'), TO_DATE('14/10/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN05'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('22/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('22/12/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN06'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('05/08/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('05/08/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN07'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('09/06/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('09/06/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN08'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos'), TO_DATE('17/02/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'El Café de los Capítulos') AND tipo_grupo = 'niños'), TO_DATE('17/02/2025', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Tertulia de Sabios y Letras
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('23/01/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('23/01/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('08/01/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('08/01/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('20/08/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('20/08/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('16/08/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'adultos'), TO_DATE('16/08/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('17/06/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('17/06/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('02/07/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('02/07/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('29/04/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('29/04/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('04/01/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'jovenes'), TO_DATE('04/01/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN09'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('03/11/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('03/11/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN10'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('15/09/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('15/09/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN11'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('07/04/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('07/04/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN12'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras'), TO_DATE('01/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Tertulia de Sabios y Letras') AND tipo_grupo = 'niños'), TO_DATE('01/12/2023', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Mentes de Papiro
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('01/01/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('01/01/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('12/05/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('12/05/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('24/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('24/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('03/06/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'adultos'), TO_DATE('03/06/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('23/11/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('23/11/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('24/04/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('24/04/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('02/08/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('02/08/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('29/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'jovenes'), TO_DATE('29/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN13'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('23/09/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('23/09/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN14'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('19/04/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('19/04/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN15'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('17/07/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('17/07/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN16'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro'), TO_DATE('14/07/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Mentes de Papiro') AND tipo_grupo = 'niños'), TO_DATE('14/07/2023', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para La Alianza de la Tinta
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('02/03/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('02/03/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('23/12/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('23/12/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('08/06/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('08/06/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('09/08/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'adultos'), TO_DATE('09/08/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('26/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('26/12/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('06/06/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('06/06/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('29/11/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('29/11/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('22/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'jovenes'), TO_DATE('22/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN17'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('16/09/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('16/09/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN18'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('13/11/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('13/11/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN19'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('20/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('20/12/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN20'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta'), TO_DATE('10/02/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'La Alianza de la Tinta') AND tipo_grupo = 'niños'), TO_DATE('10/02/2025', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Lectores de la Madrugada
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('16/09/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('16/09/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('23/07/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('23/07/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('01/06/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('01/06/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('11/10/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'adultos'), TO_DATE('11/10/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('08/01/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('08/01/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('02/06/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('02/06/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('12/11/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('12/11/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('05/07/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'jovenes'), TO_DATE('05/07/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN21'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('19/08/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('19/08/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN22'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('26/08/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('26/08/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN23'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('30/01/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('30/01/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN24'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada'), TO_DATE('29/11/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Lectores de la Madrugada') AND tipo_grupo = 'niños'), TO_DATE('29/11/2023', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Ecos del Pergamino
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('28/10/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('28/10/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('07/04/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('07/04/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('28/11/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('28/11/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('08/07/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'adultos'), TO_DATE('08/07/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('21/09/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('21/09/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('24/06/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('24/06/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('23/11/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('23/11/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('28/09/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'jovenes'), TO_DATE('28/09/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN25'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('01/05/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('01/05/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN26'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('03/08/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('03/08/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN27'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('23/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('23/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN28'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino'), TO_DATE('09/08/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Ecos del Pergamino') AND tipo_grupo = 'niños'), TO_DATE('09/08/2024', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Horizonte de Palabras
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('09/03/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('09/03/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('28/08/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('28/08/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('25/10/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('25/10/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('13/04/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'adultos'), TO_DATE('13/04/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('22/02/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('22/02/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('06/06/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('06/06/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('25/06/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('25/06/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('03/05/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'jovenes'), TO_DATE('03/05/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN29'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('18/10/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('18/10/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN30'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('17/11/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('17/11/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN31'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('20/07/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('20/07/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN32'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras'), TO_DATE('23/12/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Horizonte de Palabras') AND tipo_grupo = 'niños'), TO_DATE('23/12/2023', 'DD/MM/YYYY'), NULL);
-- Asignaciones de grupo para Club de Lectura Guayana
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('15/08/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('15/08/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('27/07/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('27/07/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('17/03/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('17/03/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-ADU36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('03/01/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'adultos'), TO_DATE('03/01/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('27/08/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('27/08/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('19/02/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('19/02/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('10/12/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('10/12/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-JOV36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('18/07/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'jovenes'), TO_DATE('18/07/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN33'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('22/07/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('22/07/2025', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN34'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('08/10/2023', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('08/10/2023', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN35'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('28/05/2024', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('28/05/2024', 'DD/MM/YYYY'), NULL);
INSERT INTO MJV_g_lec (id_lector, id_club, fecha_i, id_grupo, fec_i, fec_f) VALUES ((SELECT id_lector FROM MJV_lector WHERE doc_identidad = 'V-NIN36'), (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana'), TO_DATE('12/05/2025', 'DD/MM/YYYY'), (SELECT id_grupo FROM MJV_grupo WHERE id_club = (SELECT id_club FROM MJV_club WHERE nombre_club = 'Club de Lectura Guayana') AND tipo_grupo = 'niños'), TO_DATE('12/05/2025', 'DD/MM/YYYY'), NULL);

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
  TO_DATE('18/07/2024', 'DD/MM/YYYY'),
  TO_DATE('18/07/2024', 'DD/MM/YYYY'),
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
  TO_DATE('27/06/2024', 'DD/MM/YYYY'),
  TO_DATE('27/06/2024', 'DD/MM/YYYY'),
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
  TO_DATE('23/01/2025', 'DD/MM/YYYY'),
  TO_DATE('23/01/2025', 'DD/MM/YYYY'),
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
  TO_DATE('01/01/2025', 'DD/MM/YYYY'),
  TO_DATE('01/01/2025', 'DD/MM/YYYY'),
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
  TO_DATE('02/03/2024', 'DD/MM/YYYY'),
  TO_DATE('02/03/2024', 'DD/MM/YYYY'),
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
  TO_DATE('16/09/2024', 'DD/MM/YYYY'),
  TO_DATE('16/09/2024', 'DD/MM/YYYY'),
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
  TO_DATE('28/10/2024', 'DD/MM/YYYY'),
  TO_DATE('28/10/2024', 'DD/MM/YYYY'),
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
  TO_DATE('09/03/2025', 'DD/MM/YYYY'),
  TO_DATE('09/03/2025', 'DD/MM/YYYY'),
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
  TO_DATE('15/08/2025', 'DD/MM/YYYY'),
  TO_DATE('15/08/2025', 'DD/MM/YYYY'),
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

--==================================
-- AJUSTES COMPLEMENTARIOS: LECTORES INACTIVOS / RETIRADOS
-- =====================================================================
-- Forzar retiro de un lector de perfil Adulto del Club 1
UPDATE MJV_historia_membresia 
SET estatus = 'retirado', 
    fecha_f = TO_DATE('2026-02-15', 'YYYY-MM-DD'), 
    motivo_retiro = 'otro' 
WHERE id_lector = (SELECT MIN(id_lector) FROM MJV_lector WHERE s_apellido LIKE '%Club1A%');

-- Forzar retiro de un lector de perfil Joven del Club 2
UPDATE MJV_historia_membresia 
SET estatus = 'retirado', 
    fecha_f = TO_DATE('2026-04-10', 'YYYY-MM-DD'), 
    motivo_retiro = 'otro' 
WHERE id_lector = (SELECT MIN(id_lector) FROM MJV_lector WHERE s_apellido LIKE '%Club2J%');

-- Forzar retiro de un lector de perfil Adulto del Club 3
UPDATE MJV_historia_membresia 
SET estatus = 'retirado', 
    fecha_f = TO_DATE('2026-05-20', 'YYYY-MM-DD'), 
    motivo_retiro = 'voluntario' 
WHERE id_lector = (SELECT MAX(id_lector) FROM MJV_lector WHERE s_apellido LIKE '%Club3A%');
-- REGISTRO DE REPRESENTANTES LEGALES
-- (Papás, Mamás o Tutores independientes con pocos menores a cargo)
-- =====================================================================

INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono, email, id_pais_res, id_ciudad_res) 
VALUES ('Carlos', 'Gómez', 'V-REP01', '+584141112233', 'carlos.gomez@email.com', 1, 1);

INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono, email, id_pais_res, id_ciudad_res) 
VALUES ('María', 'Rodríguez', 'V-REP02', '+584124445566', 'maria.rod@email.com', 1, 1);

INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono, email, id_pais_res, id_ciudad_res) 
VALUES ('Andrés', 'Fernández', 'V-REP03', '+584167778899', 'andres.fer@email.com', 1, 1);

INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono, email, id_pais_res, id_ciudad_res) 
VALUES ('Laura', 'Martínez', 'V-REP04', '+584249990011', 'laura.mar@email.com', 1, 1);

INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono, email, id_pais_res, id_ciudad_res) 
VALUES ('Jorge', 'Álvarez', 'V-REP05', '+584142223344', 'jorge.alv@email.com', 1, 1);


-- =====================================================================
 --ASIGNACIÓN INDIVIDUAL POR NÚCLEO FAMILIAR--

-- =====================================================================

-- Familia 1: Carlos Gómez (V-REP01) representa a dos hermanos en el Club 1
UPDATE MJV_lector 
SET id_representante = (SELECT id_representante FROM MJV_representante WHERE doc_identidad = 'V-REP01')
WHERE doc_identidad IN ('V-NIN01', 'V-NIN02');

-- Familia 2: María Rodríguez (V-REP02) representa a tres niños en el Club 1 y 2
UPDATE MJV_lector 
SET id_representante = (SELECT id_representante FROM MJV_representante WHERE doc_identidad = 'V-REP02')
WHERE doc_identidad IN ('V-NIN03', 'V-NIN04', 'V-NIN05');

-- Familia 3: Andrés Fernández (V-REP03) representa a un hijo único en el Club 2
UPDATE MJV_lector 
SET id_representante = (SELECT id_representante FROM MJV_representante WHERE doc_identidad = 'V-REP03')
WHERE doc_identidad IN ('V-NIN06');

-- Familia 4: Laura Martínez (V-REP04) representa a dos niños en el Club 3
UPDATE MJV_lector 
SET id_representante = (SELECT id_representante FROM MJV_representante WHERE doc_identidad = 'V-REP04')
WHERE doc_identidad IN ('V-NIN07', 'V-NIN08');

-- Familia 5: Jorge Álvarez (V-REP05) representa a dos hermanos en el Club 4
UPDATE MJV_lector 
SET id_representante = (SELECT id_representante FROM MJV_representante WHERE doc_identidad = 'V-REP05')
WHERE doc_identidad IN ('V-NIN13', 'V-NIN14');

COMMIT;