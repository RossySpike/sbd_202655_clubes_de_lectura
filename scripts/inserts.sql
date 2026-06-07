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

-- 2. CIUDADES (Omitimos id_ciudad, buscamos el id_pais dinámicamente)
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), 'Santiago');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), 'Bogotá');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), 'Ciudad de México');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Perú'), 'Lima');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Uruguay'), 'Montevideo');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Argentina'), 'Buenos Aires');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Costa Rica'), 'San José');
INSERT INTO MJV_ciudad (id_pais, nombre_ciudad) VALUES ((SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'España'), 'Madrid');

-- 3. INSTITUCIONES (Omitimos id_institucion)
INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES (
  (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), 
  (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Santiago'), 
  'Biblioteca Nacional de Chile', 'biblioteca'
);

INSERT INTO MJV_institucion (id_pais, id_ciudad, nombre_inst, tipo) 
VALUES (
  (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), 
  (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Ciudad de México'), 
  'UNAM', 'universidad'
);

-- 4. IDIOMAS (Omitimos id_idioma)
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Español');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Inglés');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Chino Mandarín');
INSERT INTO MJV_idioma (nombre_idioma) VALUES ('Alemán');

-- 5. REPRESENTANTES (Omitimos id_representante)
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('Carlos', 'Gómez', 'V-12345678', '+584141234567');
INSERT INTO MJV_representante (p_nombre, p_apellido, doc_identidad, telefono) VALUES ('María', 'Fernández', 'V-87654321', '+584241234567');

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
VALUES ('Refugio Literario del Sur', 'S', '8320000', 
  (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Santiago'), 
  (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Chile'), 
  (SELECT id_institucion FROM MJV_institucion WHERE nombre_inst = 'Biblioteca Nacional de Chile')
);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('El Café de los Capítulos', 'N', '110011', 
  (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Bogotá'), 
  (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'Colombia'), 
  NULL
);

INSERT INTO MJV_club (nombre_club, cuota_anual, cod_postal, id_ciudad, id_pais, id_institucion) 
VALUES ('Tertulia de Sabios y Letras', 'S', '01000', 
  (SELECT id_ciudad FROM MJV_ciudad WHERE nombre_ciudad = 'Ciudad de México'), 
  (SELECT id_pais FROM MJV_pais WHERE nombre_pais = 'México'), 
  (SELECT id_institucion FROM MJV_institucion WHERE nombre_inst = 'UNAM')
);

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

COMMIT;