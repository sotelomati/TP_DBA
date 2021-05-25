--Ingreso de Localizaciones
insert into Localizaciones(id_localizacion, provincia) values (10, 'Entre Rios');
insert into Localizaciones(id_localizacion, provincia) values (11, 'Cordoba');
insert into Localizaciones(id_localizacion, provincia) values (12, 'Misiones');
insert into Localizaciones(id_localizacion, provincia) values (13, 'Buenos Aires');
insert into Localizaciones(id_localizacion, provincia) values (14, 'Santa Fe');
insert into Localizaciones(id_localizacion, provincia) values (15, 'La Pampa');
insert into Localizaciones(id_localizacion, provincia) values (16, 'Jujuy');
insert into Localizaciones(id_localizacion, provincia) values (17, 'Neuquen');

--Ingreso de localidades
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (1, 'Parana', 3100, 10);
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (2, 'Cordoba', 5800, 11);
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (3, 'Misiones', 3300, 12);
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (4, 'Villa Carlos Paz', 5800, 11);
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (5, 'Santa Fe', 3000, 14);
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (6, 'Rosario', 3000, 14);
insert into Localidades(id_localidad, nombre, codigo_postal, id_provincia) values (7, 'Oro Verde', 3100, 10);

--Ingreso de direcciones
insert into Direcciones(id_direccion, id_localidad, calle, numero, departamento, piso, observaciones) values (1, 1, 'Division de los Andes', 1276, NULL ,NULL, 'Porton Negro');
insert into Direcciones(id_direccion, id_localidad, calle, numero, departamento, piso, observaciones) values (2, 1, 'Victorio Camerano', 2052, NULL ,NULL, 'Porton Azul');
insert into Direcciones(id_direccion, id_localidad, calle, numero, departamento, piso, observaciones) values (3, 7, 'Los Pinos', 111, 'B',3, 'No tiene porton');

--Anuncios
insert into Anuncios(id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia) values (1, 'Venta Casa', 'Vendo casa', '20-01-2021', 30,'D');
insert into Anuncios(id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia) values (2, 'Alquiler Dpto', 'Alquilo Dpto', '21-03-2021', 15,'D');
insert into Anuncios(id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia) values (3, 'Alquilo casa roja', 'La pinte yo', '28-02-2020', 10,'D');
insert into Anuncios(id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia) values (4, 'Alquiler dpto rosa', 'Info al DM', '04-11-2020', 5,'D');

--Divisas
insert into Divisas(id_divisa, acronimo, descripcion) values (1, 'USD', 'Dolares');
insert into Divisas(id_divisa, acronimo, descripcion) values (2, 'ARS', 'Pesos');
insert into Divisas(id_divisa, acronimo, descripcion) values (3, 'EUR', 'Euros');
insert into Divisas(id_divisa, acronimo, descripcion) values (4, 'JPY', 'Yenes');

--Precios
insert into Precios(id_precio, id_divisa, monto) values (1, 2, 5000);
insert into Precios(id_precio, id_divisa, monto) values (2, 2, 5500);
insert into Precios(id_precio, id_divisa, monto) values (3, 4, 15000);
insert into Precios(id_precio, id_divisa, monto) values (4, 1, 100);

--Tipos de inmuebles
insert into tipoInmueble(id_tipo, descripcion) values (101, 'Monoambiente');
insert into tipoInmueble(id_tipo, descripcion) values (102, 'Duplex');
insert into tipoInmueble(id_tipo, descripcion) values (103, 'Departamento');
insert into tipoInmueble(id_tipo, descripcion) values (104, 'Casa');
insert into tipoInmueble(id_tipo, descripcion) values (105, 'Cochera');
insert into tipoInmueble(id_tipo, descripcion) values (106, 'Galpon');

-- Tipos de operaciones
insert into TipoOperacion(id_operacion, descripcion) values (1, 'Venta');
insert into TipoOperacion(id_operacion, descripcion) values (2, 'Alquiler');

-- Estados de los inmuebles
insert into imueble_estados(id_estado, descripcion) values (1, 'Anulado');
insert into imueble_estados(id_estado, descripcion) values (2, 'Disponible');
insert into imueble_estados(id_estado, descripcion) values (3, 'Alquilado');
insert into imueble_estados(id_estado, descripcion) values (4, 'Vendido');

--Ingreso de personas
insert into Personas(id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion) values (10, '41154249', '20-11-1998', '24-05-2021', 'Matias Nicolas Sotelo',1);
insert into Personas(id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion) values (11, '39717392', '16-07-1996', '01-01-2021', 'Atilio Mariano Modenutti',2);
insert into Personas(id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion) values (12, '42560204', '01-01-1995', '01-05-2021', 'Juan Ignacio Gerstner',3);

--Ingreso clientes
insert into Clientes(id_cliente, id_persona) values (1, 10);
insert into Clientes(id_cliente, id_persona) values (2, 11);
insert into Clientes(id_cliente, id_persona) values (3, 12);

--Ingreso de due�os
insert into Due�os(id_due�o, id_persona) values (2, 11);