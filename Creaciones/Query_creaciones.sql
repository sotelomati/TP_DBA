--CREACION DE BASE DE DATOS

CREATE DATABASE "TP_DBA"
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;

COMMENT ON DATABASE "TP_DBA"
    IS 'Trabajo Practico de Base de datos Activas
';

-- Creacion de dominios

CREATE DOMAIN dni as varchar(8)
CONSTRAINT dni_check CHECK (CAST(VALUE as INTEGER) <= 99999999);

-- Creacion de tablas
CREATE TABLE auditoria(
	ultimo_usuario varchar(50) NOT NULL,
	ultimo_horario timestamp NOT NULL
);

CREATE TABLE tipo_operacion_contable(
 id_tipo_operacion  INTEGER NOT NULL PRIMARY KEY,
 descripcion varchar(50),
 debito boolean -- true:debito, false:credito
);

CREATE TABLE Localizaciones(
id_localizacion integer not null PRIMARY KEY,
provincia varchar(50) not null
);

CREATE TABLE Localidades(
id_localidad integer not null PRIMARY KEY,
nombre varchar(50) NOT NULL,
codigo_postal integer null,
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


CREATE TABLE Inmuebles_Estados(
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
id_tipoOperacion integer not null,
id_estado_inmueble integer not null,
id_direccion integer not null,
id_anuncio integer not null,
id_precio integer not null,
id_dueño integer not null,
FOREIGN KEY (id_tipoInmueble) REFERENCES TipoInmueble(id_tipo),
FOREIGN KEY (id_tipoOperacion) REFERENCES TipoOperacion(id_operacion),
FOREIGN KEY (id_estado_inmueble) REFERENCES imueble_estados(id_estado),
FOREIGN KEY (id_direccion) REFERENCES Direcciones(id_direccion),
FOREIGN KEY (id_anuncio) REFERENCES Anuncios(id_anuncio),
FOREIGN KEY (id_precio) REFERENCES Precios(id_precio),
FOREIGN KEY (id_dueño) REFERENCES Dueños(id_dueño)
)INHERITS(auditoria);


CREATE TABLE PeriodoOcupacion(
id_periodo integer not null PRIMARY KEY,
id_inmueble integer not null,
fechaInicio date not null,
fechaBaja date not null,
motivoBaja varchar(100),
FOREIGN KEY (id_inmueble) REFERENCES Inmuebles(id_inmueble)
);

CREATE TABLE contratos_finalidades(
id_finalidad integer NOT NULL PRIMARY KEY,
descripcion varchar(50) NOT NULL
);

CREATE TABLE contratos_estados(
id_estado integer NOT NULL PRIMARY KEY,
descripcion varchar(50)
);

CREATE TABLE ContratoAlquiler(
id_inmueble integer not null,
id_cliente integer not null,
fechaContrato date not null DEFAULT current_date,
id_estado integer NOT NULL DEFAULT 1, --1 es el estado 'Activo'
periodo_vigencia integer NOT NULL,--seran meses
vencimiento_cuota integer NOT NULL DEFAULT 10, --default dia 10 de cada mes
id_finalidad integer NULL,
precio_inicial double precision NOT NULL,

	
PRIMARY KEY (id_inmueble, id_cliente),
CONSTRAINT FK_CONTRATO_INMUEBLE
  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

CONSTRAINT FK_CONTRATO_CLIENTE
  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE,

FOREIGN KEY (id_finalidad) REFERENCES contratos_finalidades(id_finalidad),
FOREIGN KEY (id_estado) REFERENCES contratos_estados(id_estado)
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
id_tipo_operacion integer NOT NULL,
importeCuota double precision not null,
fechaPago date not null,

PRIMARY KEY (id_inmueble, id_cliente, mesAño),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE,
  
   FOREIGN KEY (id_tipo_operacion)
    REFERENCES tipo_operacion_contable(id_tipo_operacion)
);


CREATE TABLE Cuotas(
id_inmueble integer not null,
id_cliente integer not null,
id_tipo_operacion integer NOT NULL,
mesAño date not null,
importe double precision,
fechaVencimiento date not null,

PRIMARY KEY (id_inmueble, id_cliente, mesAño),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE,

  FOREIGN KEY (id_tipo_operacion)
    REFERENCES tipo_operacion_contable(id_tipo_operacion)
);


CREATE TABLE Recargos(
id_inmueble integer not null,
id_cliente integer not null,
mesAño date not null,
id_tipo_operacion integer NOT NULL,
importeRecargo double precision not null,
diasVencidos integer default 0,

PRIMARY KEY (id_inmueble, id_cliente, mesAño),

  FOREIGN KEY (id_inmueble)
    REFERENCES Inmuebles(id_inmueble)
    ON DELETE CASCADE,

  FOREIGN KEY (id_cliente)
    REFERENCES Clientes(id_cliente)
    ON DELETE CASCADE,

FOREIGN KEY (id_tipo_operacion)
REFERENCES tipo_operacion_contable(id_tipo_operacion)
);


