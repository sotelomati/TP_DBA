-- Creacion de dominios

CREATE DOMAIN dni as varchar(8)
CONSTRAINT dni_check CHECK (CAST(VALUE as INTEGER) <= 99999999);

CREATE DOMAIN cuit as varchar(13)
CONSTRAINT cuit_check CHECK (CAST(VALUE as BIGINT) <= 99999999999);


CREATE DOMAIN mesaño as varchar(7)
CONSTRAINT format_check CHECK (3 = position('-' in VALUE))
CONSTRAINT date_check CHECK ('01-01-1990' < TO_DATE('01-' || VALUE, 'DD-MM-YYYY'));

-- Creacion de tablas

CREATE TABLE tipo_operacion_contable(
id_tipo_operacion  INTEGER NOT NULL PRIMARY KEY,
descripcion varchar(50),
debito boolean, -- true:debito, false:credito
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE Localizaciones(
id_localizacion integer not null PRIMARY KEY,
provincia varchar(50) not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE Localidades(
id_localidad integer not null PRIMARY KEY,
nombre varchar(50) NOT NULL,
codigo_postal integer null,
id_provincia integer not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
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
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
FOREIGN KEY (id_localidad) REFERENCES Localidades(id_localidad)
);

CREATE TABLE Anuncios(
id_anuncio integer not null PRIMARY KEY,
titulo varchar(50) not null,
texto varchar(100) not null,
fecha date not null,
vigencia integer not null,
tipo_vigencia char not null, -- A = Año, M = Mes, D = Dias
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE Divisas(
id_divisa integer not null PRIMARY KEY,
acronimo varchar(3) not null,
descripcion varchar(50) not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE Precios(
id_precio integer not null PRIMARY KEY,
id_divisa integer not null,
monto double precision not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
FOREIGN KEY (id_divisa) REFERENCES Divisas(id_divisa)
);

CREATE TABLE TipoInmueble(
id_tipo integer not null PRIMARY KEY,
descripcion varchar(50) not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE operaciones(
id_operacion integer not null PRIMARY KEY,
descripcion varchar(50) not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE Inmuebles_Estados(
id_estado integer not null PRIMARY KEY,
descripcion varchar(50) not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

------------------------------------------------------------------------------------------------------------------

CREATE TABLE Personas (
id_persona integer UNIQUE NOT NULL,
dni dni NOT NULL,
fechaNacimiento date,
fechaInscripcion date,
nombreCompleto varchar(50),
id_direccion integer,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

PRIMARY KEY(id_persona),
CONSTRAINT FK_DIRECCION
  FOREIGN KEY (id_direccion)
    REFERENCES Direcciones(id_direccion)
);

CREATE TABLE Clientes(
id_cliente integer unique NOT NULL,
id_persona integer NOT NULL,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
	
PRIMARY KEY (id_cliente, id_persona),
CONSTRAINT FK_CLIENTE_PERSONA
  FOREIGN KEY (id_persona)
    REFERENCES Personas(id_persona)
    ON DELETE CASCADE
);


CREATE TABLE Dueños(
id_dueño integer unique NOT NULL,
id_persona integer NOT NULL,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

PRIMARY KEY (id_dueño, id_persona),
CONSTRAINT FK_DUEÑO_PERSONA
  FOREIGN KEY (id_persona)
    REFERENCES Personas(id_persona)
    ON DELETE CASCADE
);

CREATE TABLE Historial_Direcciones(
id_historial SERIAL NOT NULL PRIMARY KEY,
id_dueño integer,
id_direccion integer not null ,
id_localidad integer not null,
calle varchar(50) not null,
numero integer not null,
departamento varchar(10),
piso integer,
observaciones varchar(100),
fechaInicioVigencia date,
fechaFinVigencia date NULL,
usuario_modificacion varchar(50),
FOREIGN KEY (id_dueño) REFERENCES dueños(id_dueño),
FOREIGN KEY (id_localidad) REFERENCES Localidades(id_localidad)
);
------------------------------------------------------------------------------------------------------------------

CREATE TABLE Inmuebles(
id_inmueble integer not null PRIMARY KEY,
id_tipoInmueble integer not null,
id_estado_inmueble integer not null,
id_direccion integer not null,
id_anuncio integer not null,
id_precio integer not null,
id_dueño integer not null,
	--auditoria
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
FOREIGN KEY (id_tipoInmueble) REFERENCES TipoInmueble(id_tipo),
FOREIGN KEY (id_estado_inmueble) REFERENCES inmuebles_estados(id_estado),
FOREIGN KEY (id_direccion) REFERENCES Direcciones(id_direccion),
FOREIGN KEY (id_anuncio) REFERENCES Anuncios(id_anuncio),
FOREIGN KEY (id_precio) REFERENCES Precios(id_precio),
FOREIGN KEY (id_dueño) REFERENCES Dueños(id_dueño)
);

CREATE TABLE inmuebles_operaciones(
id_inmueble integer NOT NULL,
id_operacion integer NOT NULL,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
PRIMARY KEY (id_inmueble, id_operacion),
FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble),
FOREIGN KEY (id_operacion) REFERENCES operaciones(id_operacion)
);

CREATE TABLE PeriodoOcupacion(
id_periodo SERIAL NOT NULL PRIMARY KEY,
id_inmueble integer NOT NULL,
fechaInicio date NOT NULL,
fechaBaja date NULL,
motivoBaja varchar(100) NULL,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,
FOREIGN KEY (id_inmueble) REFERENCES Inmuebles(id_inmueble)
);

CREATE TABLE contratos_finalidades(
id_finalidad integer NOT NULL PRIMARY KEY,
descripcion varchar(50) NOT NULL,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE contratos_estados(
id_estado integer NOT NULL PRIMARY KEY,
descripcion varchar(50),
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
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
periodicidad_aumento integer DEFAULT 6,
porcentaje_aumento_periodicidad double precision DEFAULT 0.1,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

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
descripcion varchar(50) not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL
);

CREATE TABLE Garante(
dni dni not null,
id_inmueble integer not null,
id_cliente integer not null,
nombre varchar(50) not null,
fechaNacimiento date not null,
id_tipoGarantia integer not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

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
id_precioAlquiler serial not null,
id_inmueble integer not null,
id_cliente integer not null,
importe double precision not null,
fechaDefinicion date not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

PRIMARY KEY (id_inmueble, id_cliente,id_precioAlquiler),

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
mesAño mesaño not null,
id_tipo_operacion integer NOT NULL DEFAULT 2,
importePago double precision not null,
fechaPago date not null default CURRENT_DATE,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

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
id_tipo_operacion integer NOT NULL DEFAULT 1,
mesAño mesaño not null,
importe double precision,
fechaVencimiento date not null,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

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
mesAño mesaño not null,
id_tipo_operacion integer NOT NULL DEFAULT 3,
importeRecargo double precision not null,
diasVencidos integer default 0,
ultimo_usuario varchar(50) NOT NULL,
ultimo_horario timestamp NOT NULL,

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


-----------------------------------------------------------------------

CREATE TABLE EMPLEADOS(
cuit cuit NOT NULL Primary KEY,
apellido_nombre varchar(70) NULL,
fecha_ingreso date NOT NULL,
cargo varchar(150) NOT NULL,
superior cuit NULL,

FOREIGN KEY (superior) REFERENCES EMPLEADOS(cuit)
);