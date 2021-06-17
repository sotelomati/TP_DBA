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
insert into operaciones(id_operacion, descripcion) values (1, 'Venta');
insert into operaciones(id_operacion, descripcion) values (2, 'Alquiler');

-- Estados de los inmuebles
insert into inmuebles_estados(id_estado, descripcion) values (1, 'Anulado');
insert into inmuebles_estados(id_estado, descripcion) values (2, 'Disponible');
insert into inmuebles_estados(id_estado, descripcion) values (3, 'Alquilado');
insert into inmuebles_estados(id_estado, descripcion) values (4, 'Vendido');

--Ingreso de personas
insert into Personas(id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion) values (10, '41154249', '20-11-1998', '24-05-2021', 'Matias Nicolas Sotelo',1);
insert into Personas(id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion) values (11, '39717392', '16-07-1996', '01-01-2021', 'Atilio Mariano Modenutti',2);
insert into Personas(id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion) values (12, '42560204', '01-01-1995', '01-05-2021', 'Juan Ignacio Gerstner',3);

--Ingreso clientes
insert into Clientes(id_cliente, id_persona) values (1, 10);
insert into Clientes(id_cliente, id_persona) values (2, 11);
insert into Clientes(id_cliente, id_persona) values (3, 12);

--Ingreso de dueños
insert into Dueños(id_dueño, id_persona) values (2, 11);

--Inmmuebles
insert into Inmuebles(id_inmueble, id_tipoInmueble, id_estado_inmueble, 
					  id_direccion, id_anuncio, id_precio, id_dueño) 
					  values (1, 101, 1, 3, 1, 1, 2);
insert into Inmuebles(id_inmueble, id_tipoInmueble, id_estado_inmueble, 
					  id_direccion, id_anuncio, id_precio, id_dueño) 
					  values (1002, 102, 2, 1, 2, 2, 2);
insert into Inmuebles(id_inmueble, id_tipoInmueble, id_estado_inmueble, 
					  id_direccion, id_anuncio, id_precio, id_dueño) 
					  values (1003, 103, 1, 3, 3, 3, 2);
					  
--inmuebles operaciones
INSERT INTO inmuebles_operaciones(id_inmueble, id_operacion)
	VALUES  (1000, 1),
			(1002, 1),
			(1000, 2),
			(1003, 2);

--contratos finalidades
insert into contratos_finalidades(id_finalidad, descripcion) values (1, 'Vacaciones');
insert into contratos_finalidades(id_finalidad, descripcion) values (2, 'Ocupacion temporal');
insert into contratos_finalidades(id_finalidad, descripcion) values (3, 'Negocios');
insert into contratos_finalidades(id_finalidad, descripcion) values (4, 'otros');

--Estados de los contratos
insert into contratos_estados(id_estado, descripcion) values (1, 'Activo');
insert into contratos_estados(id_estado, descripcion) values (2, 'Finalizado');
insert into contratos_estados(id_estado, descripcion) values (3, 'Baja a pedido del cliente');
insert into contratos_estados(id_estado, descripcion) values (4, 'Baja a pedido del dueño');

--Contratos
insert into ContratoAlquiler(id_inmueble, id_cliente, fechacontrato, id_estado, periodo_vigencia, vencimiento_cuota, id_finalidad, precio_inicial) 
							 values (1000, 1, '20-05-2021', 1, 6, 10, 2, 1500);						 
insert into ContratoAlquiler(id_inmueble, id_cliente, fechacontrato, id_estado, periodo_vigencia, vencimiento_cuota, id_finalidad, precio_inicial) 
							 values (1002, 3, '26-05-2021', 1, 6, 10, 2, 1500);							 

--Tipos de Garantias
insert into TipoGarantia(id_garantia, descripcion) values (1, 'Recibo de Sueldo');
insert into TipoGarantia(id_garantia, descripcion) values (2, 'Titulo de propiedad');

--Tipo operaciones contables
INSERT INTO public.tipo_operacion_contable(
	id_tipo_operacion, descripcion, debito)
	VALUES (1, 'Cuota', True),
	(2,'Pago', False),
	(3, 'Recargo',True);


--Empleados
INSERT INTO public.empleados(
	cuit, apellido_nombre, fecha_ingreso, cargo, superior)
	VALUES 
	-- primer nivel
	(20111111112, 'Fernando Sato', CURRENT_DATE, 'Generente general', NULL),
	-- segundo nivel
	(20222222222, 'Sebastian Trossero', CURRENT_DATE, 'Profesor', 20111111112),
	(20333333332, 'Emanuel Orzuza', CURRENT_DATE, 'Profesor', 20111111112),
	-- tercer nivel
	(20385703132, 'Juan Gresnter', CURRENT_DATE, 'fichaje', 20222222222),
	(20444444442, 'Atilio Modenutti', CURRENT_DATE, 'Barredor', 20222222222),
	(20411542492, 'Matias Sotelo', CURRENT_DATE, 'Limpia mueble', 20333333332),

	--cuarto nivel
	(20390102222, 'Flavia Crolla', CURRENT_DATE, 'Barrendera', 20385703132),
	(58972310265, 'Gaston schonfeld', CURRENT_DATE, 'Limpia mueble', 20411542492),
	(99759067340, 'Matias Gotte', CURRENT_DATE, 'Limpia mueble', 20444444442),

	--quinto nivel
	(39640389819,'Fry, Emma M.','20-04-21','Media Relations',20390102222),
	(45734795607,'Key, Nathan L.','02-10-20','Advertising',20390102222),
	(27314651558,'Weiss, Joy S.','11-05-21','Quality Assurance',20390102222),
	(41125784684,'Le, Noble I.','07-01-22','Finances',20390102222),
	(97364273555,'Davis, Josephine O.','07-10-20','Finances',20390102222),
	(64768973192,'Santos, Troy T.','14-08-20','Customer Service',20390102222),
	(89989994799,'Aguirre, Jared S.','22-07-21','Payroll',20390102222),

	(94797992868,'Greer, Lavinia F.','17-01-21','Human Resources',58972310265),
	(59346741449,'Gaines, Xander S.','15-02-21','Media Relations',58972310265),
	(21147457876,'Boone, Rylee O.','25-07-20','Human Resources',58972310265),
	(75585928184,'Albert, Garrison Y.','24-07-21','Media Relations',58972310265),
	(52074878966,'Mccoy, Dai A.','17-08-20','Customer Service',58972310265),
	(96523788954,'Decker, Myra V.','03-05-21','Human Resources',58972310265),
	(35677116907,'Vaughn, Wanda J.','01-02-21','Accounting',58972310265),
	(33768128341,'Cooke, Aiko M.','04-01-21','Finances',58972310265),
	(14585253639,'Griffith, Ashton E.','10-01-22','Finances',58972310265),
	
	(59879378607,'Nguyen, Aubrey D.','15-06-21','Media Relations',99759067340),
	(83937642118,'Warner, Leandra M.','23-07-21','Human Resources',99759067340),
	(65174879303,'Bowers, Tanisha X.','07-04-22','Public Relations',99759067340),
	(55488439648,'Whitehead, Quinn V.','20-03-22','Sales and Marketing',99759067340),
	(62936329691,'Michael, Bianca G.','28-01-21','Research and Development',99759067340),
	(96391800095,'Dodson, Shannon E.','04-05-22','Legal Department',99759067340),
	(33792977911,'Turner, Elmo W.','15-12-20','Public Relations',99759067340),
	(61011538605,'Keller, Justin A.','12-07-20','Sales and Marketing',99759067340),
	(87517625556,'Avery, Aurelia A.','04-12-20','Customer Service',99759067340),
	(11369876835,'Malone, Hilel L.','13-01-22','Tech Support',99759067340),
	(27574034512,'Tucker, Kennan C.','12-10-21','Accounting',99759067340);







