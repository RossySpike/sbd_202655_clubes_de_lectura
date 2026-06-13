SET SERVEROUTPUT ON;

BEGIN
    -- 1. Lector Nuevo: Carlos
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Carlos',
        pi_p_apellido      => 'Perez',
        pi_s_apellido      => 'Ruiz',
        pi_doc_identidad   => 'V-32000001',
        pi_telefono        => '04141111111',
        pi_email           => 'carlos.perez@gmail.com',
        pi_genero          => 'M',
        pi_fecha_nac       => TO_DATE('10/01/2006', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Neuromante',
        pi_titulo_pref2    => 'Juego de tronos',
        pi_titulo_pref3    => 'Un mago de Terramar'
    );

    -- 2. Lector Nuevo: Valentina
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Valentina',
        pi_p_apellido      => 'Gomez',
        pi_s_apellido      => 'Diaz',
        pi_doc_identidad   => 'V-32000002',
        pi_telefono        => '04142222222',
        pi_email           => 'valentina.gomez@gmail.com',
        pi_genero          => 'F',
        pi_fecha_nac       => TO_DATE('15/04/2007', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Momo',
        pi_titulo_pref2    => 'El juego de Ender',
        pi_titulo_pref3    => 'Snow Crash'
    );

    -- 3. Lector Nuevo: Luis
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Luis',
        pi_p_apellido      => 'Martinez',
        pi_s_apellido      => 'Silva',
        pi_doc_identidad   => 'V-32000003',
        pi_telefono        => '04143333333',
        pi_email           => 'luis.martinez@gmail.com',
        pi_genero          => 'M',
        pi_fecha_nac       => TO_DATE('20/08/2006', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Juego de tronos',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'Momo'
    );

    -- 4. Lector Nuevo: Andrea
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Andrea',
        pi_p_apellido      => 'Lopez',
        pi_s_apellido      => 'Castro',
        pi_doc_identidad   => 'V-32000004',
        pi_telefono        => '04144444444',
        pi_email           => 'andrea.lopez@gmail.com',
        pi_genero          => 'F',
        pi_fecha_nac       => TO_DATE('05/01/2008', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Un mago de Terramar',
        pi_titulo_pref2    => 'Snow Crash',
        pi_titulo_pref3    => 'El juego de Ender'
    );

    -- 5. Lector Nuevo: Diego
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Diego',
        pi_p_apellido      => 'Fernandez',
        pi_s_apellido      => 'Rojas',
        pi_doc_identidad   => 'V-32000005',
        pi_telefono        => '04145555555',
        pi_email           => 'diego.fernandez@gmail.com',
        pi_genero          => 'M',
        pi_fecha_nac       => TO_DATE('12/02/2007', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Snow Crash',
        pi_titulo_pref2    => 'Neuromante',
        pi_titulo_pref3    => 'Juego de tronos'
    );

    -- 6. Lector Nuevo: Sofia
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Sofia',
        pi_p_apellido      => 'Rodriguez',
        pi_s_apellido      => 'Mendoza',
        pi_doc_identidad   => 'V-32000006',
        pi_telefono        => '04146666666',
        pi_email           => 'sofia.rodriguez@gmail.com',
        pi_genero          => 'F',
        pi_fecha_nac       => TO_DATE('30/01/2008', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Momo',
        pi_titulo_pref2    => 'Un mago de Terramar',
        pi_titulo_pref3    => 'El juego de Ender'
    );

    -- 7. Lector Nuevo: Miguel
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Miguel',
        pi_p_apellido      => 'Hernandez',
        pi_s_apellido      => 'Vargas',
        pi_doc_identidad   => 'V-32000007',
        pi_telefono        => '04147777777',
        pi_email           => 'miguel.hernandez@gmail.com',
        pi_genero          => 'M',
        pi_fecha_nac       => TO_DATE('25/12/2006', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'El juego de Ender',
        pi_titulo_pref2    => 'Snow Crash',
        pi_titulo_pref3    => 'Neuromante'
    );

    -- 8. Lector Nuevo: Camila
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Camila',
        pi_p_apellido      => 'Garcia',
        pi_s_apellido      => 'Pinto',
        pi_doc_identidad   => 'V-32000008',
        pi_telefono        => '04148888888',
        pi_email           => 'camila.garcia@gmail.com',
        pi_genero          => 'F',
        pi_fecha_nac       => TO_DATE('18/07/2007', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Un mago de Terramar',
        pi_titulo_pref2    => 'Juego de tronos',
        pi_titulo_pref3    => 'Momo'
    );

    -- 9. Lector Nuevo: Alejandro
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Alejandro',
        pi_p_apellido      => 'Torres',
        pi_s_apellido      => 'Navarro',
        pi_doc_identidad   => 'V-32000009',
        pi_telefono        => '04149999999',
        pi_email           => 'alejandro.torres@gmail.com',
        pi_genero          => 'M',
        pi_fecha_nac       => TO_DATE('03/03/2008', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'Juego de tronos',
        pi_titulo_pref2    => 'El juego de Ender',
        pi_titulo_pref3    => 'Snow Crash'
    );

    -- 10. Lector Nuevo: Daniela (¡La que rompe el límite y fuerza el SPLIT!)
    MJV_sp_inscribir_miembro(
        pi_p_nombre        => 'Daniela',
        pi_p_apellido      => 'Blanco',
        pi_s_apellido      => 'Rios',
        pi_doc_identidad   => 'V-32000010',
        pi_telefono        => '04140000000',
        pi_email           => 'daniela.blanco@gmail.com',
        pi_genero          => 'F',
        pi_fecha_nac       => TO_DATE('11/11/2007', 'DD/MM/YYYY'),
        pi_nombre_pais_nac => 'Venezuela',
        pi_nombre_club     => 'Refugio Literario del Sur',
        pi_titulo_pref1    => 'El juego de Ender',
        pi_titulo_pref2    => 'Momo',
        pi_titulo_pref3    => 'Neuromante'
    );
END;