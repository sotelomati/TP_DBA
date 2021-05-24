-- Database: TP1-BDA

-- DROP DATABASE "TP1-BDA";

CREATE DATABASE "TP1-BDA"
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Latin America.1252'
    LC_CTYPE = 'Spanish_Latin America.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
	
	------------------------------------------------
	
-- Creacion de dominios

CREATE DOMAIN dni as varchar(8)
CONSTRAINT dni_check CHECK (CAST(VALUE as INTEGER) <= 99999999);

-- Creacion de tablas

CREATE TABLE Localizaciones(
id_localizacion integer not null PRIMARY KEY,
provincia varchar(50) not null
);

CREATE TABLE Localidades(
id_localidad integer not null PRIMARY KEY,
codigo_postal integer not null,
id_provincia integer not null,
FOREIGN KEY (id_provincia) REFERENCES Localizaciones(id_localizacion)
);

CREATE TABLE Direcciones(
id_direccion integer not null PRIMARY KEY,
id_localidad integer not null,
calle varchar(50) not null,
numero integer not null,
departamento varchar(10),
piso integer,
observaciones varchar(100),
FOREIGN KEY (id_localidad) REFERENCES Localidades(id_localidad)
);


CREATE TABLE Anuncios(
id_anuncio integer not null PRIMARY KEY,
titulo varchar(50) not null,
texto varchar(100) not null,
fecha date not null,
vigencia integer not null,
tipo_vigencia char not null -- A = Año, M = Mes, D = Dias
);

CREATE TABLE Divisas(
id_divisa integer not null PRIMARY KEY,
acronimo varchar(3) not null,
descripcion varchar(50) not null
);

CREATE TABLE Precios(
id_precio integer not null PRIMARY KEY,
id_divisa integer not null,
monto double precision not null,
FOREIGN KEY (id_divisa) REFERENCES Divisas(id_divisa)
);



CREATE TABLE TipoInmueble(
id_tipo integer not null PRIMARY KEY,
descripcion varchar(50) not null
);


CREATE TABLE TipoOperacion(
id_operacion integer not null PRIMARY KEY,
descripcion varchar(50) not null
);


CREATE TABLE Estados(
id_estado integer not null PRIMARY KEY,
descripcion varchar(50) not null
);


------------------------------------------------------------------------------------------------------------------


CREATE TABLE Personas (
id_persona integer UNIQUE NOT NULL,
dni dni NOT NULL,
fechaNacimiento date,
fechaInscripcion date,
nombreCompleto varchar(50),
id_direccion integer,

PRIMARY KEY(id_persona),
CONSTRAINT FK_DIRECCION
  FOREIGN KEY (id_direccion)
    REFERENCES Direcciones(id_direccion)
);

CREATE TABLE Clientes(
id_cliente integer unique NOT NULL,
id_persona integer NOT NULL,
	
PRIMARY KEY (id_cliente, id_persona),
CONSTRAINT FK_CLIENTE_PERSONA
  FOREIGN KEY (id_persona)
    REFERENCES Personas(id_persona)
    ON DELETE CASCADE
);


CREATE TABLE Dueños(
id_dueño integer unique NOT NULL,
id_persona integer NOT NULL,

PRIMARY KEY (id_dueño, id_persona),
CONSTRAINT FK_DUEÑO_PERSONA
  FOREIGN KEY (id_persona)
    REFERENCES Personas(id_persona)
    ON DELETE CASCADE
);


------------------------------------------------------------------------------------------------------------------


CREATE TABLE Inmuebles(
id_inmueble integer not null PRIMARY KEY,
id_tipoInmueble integer not null,
--id_tipoOperacion integer not null,
id_estado integer not null,
id_direccion integer not null,
id_anuncio integer not null,
id_precio integer not null,
id_dueño integer not null,
FOREIGN KEY (id_tipoInmueble) REFERENCES TipoInmueble(id_tipo),
--FOREIGN KEY (id_tipoOperacion) REFERENCES TipoOperacion(id_operacion),
FOREIGN KEY (id_estado) REFERENCES Estados(id_estado),
FOREIGN KEY (id_direccion) REFERENCES Direcciones(id_direccion),
FOREIGN KEY (id_anuncio) REFERENCES Anuncios(id_anuncio),
FOREIGN KEY (id_precio) REFERENCES Precios(id_precio),
FOREIGN KEY (id_dueño) REFERENCES Dueños(id_dueño)
);

--

CREATE TABLE InmuebleOperacion(
    id_inmueble integer not null,
    id_operacion integer not null,
    PRIMARY KEY (id_inmueble,id_operacion),
    FOREIGN KEY (id_inmueble) REFERENCES Inmuebles(id_inmueble),
    FOREIGN KEY (id_operacion) REFERENCES TipoOperacion(id_operacion)

);
--


CREATE TABLE PeriodoOcupacion(
id_periodo integer not null PRIMARY KEY,
id_inmueble integer not null,
fechaInicio date not null,
fechaBaja date null ,
motivoBaja varchar(100),
FOREIGN KEY (id_inmueble) REFERENCES Inmuebles(id_inmueble)
);


CREATE TABLE ContratoAlquiler(
id_inmueble integer not null,
id_cliente integer not null,
fechaContrato date not null,
	
PRIMARY KEY (id_inmueble, id_cliente),
CONSTRAINT FK_CONTRATO_INMUEBLE
  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

CONSTRAINT FK_CONTRATO_CLIENTE
  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE
);

CREATE TABLE TipoGarantia(
id_garantia integer not null PRIMARY KEY,
descripcion varchar(50) not null
);

CREATE TABLE Garante(
dni dni not null,
id_inmueble integer not null,
id_cliente integer not null,
nombre varchar(50) not null,
fechaNacimiento date not null,
id_tipoGarantia integer not null,

PRIMARY KEY (id_inmueble, id_cliente, dni),
CONSTRAINT FK_GARANTE_INMUEBLE
  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

CONSTRAINT FK_GARANTE_CLIENTE
  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE,

CONSTRAINT FK_GARANTE_TIPO
  FOREIGN KEY (id_tipoGarantia)
    REFERENCES TipoGarantia(id_garantia)
    ON DELETE CASCADE
);

CREATE TABLE PrecioAlquiler(
id_inmueble integer not null,
id_cliente integer not null,
importe double precision not null,
fechaDefinicion date not null,

PRIMARY KEY (id_inmueble, id_cliente),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE
);


CREATE TABLE Pagos(
id_inmueble integer not null,
id_cliente integer not null,
mesAño date not null,
importeCuota double precision not null,
fechaPago date not null,

PRIMARY KEY (id_inmueble, id_cliente, mesAño),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE
);


CREATE TABLE Cuotas(
id_inmueble integer not null,
id_cliente integer not null,
mesAño date not null,
fechaVencimiento date not null,

PRIMARY KEY (id_inmueble, id_cliente, mesAño),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE
);


CREATE TABLE Recargos(
id_inmueble integer not null,
id_cliente integer not null,
mesAño date not null,
importeRecargo double precision not null,
diasVencidos integer default 0,

PRIMARY KEY (id_inmueble, id_cliente, mesAño),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE
);

-----------------CREACION DE VISTAS--------------------

/*El esquema deberá contener una vista con la información completa
de todos los inmuebles registrados, para el caso de los inmuebles 
que están en alquiler se deberá ver si está ocupado o no y en el caso
de estar ocupado la fecha de finalización de ese contrato. Tenga en cuenta
además que si el inmueble está en alquiler y en venta al mismo tiempo debe 
visualizarse en la misma fila.
*/

CREATE VIEW info_inmuebles_view AS 
	(
		SELECT id_inmueble,
				id_tipoInmueble ,
				id_tipoOperacion ,
				id_estado ,
				id_direccion ,
				id_anuncio ,
				id_precio ,
				id_dueño
		FROM Inmuebles
		IF( id_tipoInmueble = id_tipo )
	)

--alter table Inmuebles drop column id_tipoOperacion;
SELECT id_operacion FROM InmuebleOperacion where (id_inmueble = (select Inmuebles.id_inmueble from Inmuebles)) and (id_operacion = 1);




SELECT id_inmueble,
		id_tipoInmueble ,
		id_direccion ,
		id_anuncio ,
		id_precio ,
		id_dueño,
		(CASE 
			WHEN (1 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 1))
				THEN 'SI'

				ELSE 'NO'

				END  )AS SE_VENDE
		,
		(CASE 
			WHEN (2 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
				THEN 'SI'

				ELSE 'NO'

				END  )AS SE_ALQUILA
		,
		(CASE 
		 	WHEN ((2 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
				  AND 
				  ((SELECT fechaBaja FROM PeriodoOcupacion) <> NULL ))
		 		THEN 'OCUPADO'
		 		
		 		ELSE 'LIBRE'
		 		
		 END) AS ESTADO_ALQUILER
		,
		(CASE 
		 	WHEN ((2 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
				  AND 
				  ((SELECT fechaBaja FROM PeriodoOcupacion) <> NULL ))
		 		THEN (SELECT fechaBaja FROM PeriodoOcupacion WHERE id_inmueble = Inmuebles.id_inmueble )
				ELSE NULL
		 		
		 END) AS FECHA_DESOCUPACION
FROM Inmuebles