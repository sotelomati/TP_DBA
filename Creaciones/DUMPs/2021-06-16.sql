--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.2

-- Started on 2021-06-16 18:02:39

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 699 (class 1247 OID 16511)
-- Name: cuit; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.cuit AS character varying(13)
	CONSTRAINT cuit_check CHECK (((VALUE)::bigint <= '99999999999'::bigint));


ALTER DOMAIN public.cuit OWNER TO postgres;

--
-- TOC entry 695 (class 1247 OID 16508)
-- Name: dni; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.dni AS character varying(8)
	CONSTRAINT dni_check CHECK (((VALUE)::integer <= 99999999));


ALTER DOMAIN public.dni OWNER TO postgres;

--
-- TOC entry 703 (class 1247 OID 16514)
-- Name: mesaño; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public."mesaño" AS character varying(7)
	CONSTRAINT date_check CHECK (('1990-01-01'::date < to_date(('01-'::text || (VALUE)::text), 'DD-MM-YYYY'::text)))
	CONSTRAINT format_check CHECK ((3 = "position"((VALUE)::text, '-'::text)));


ALTER DOMAIN public."mesaño" OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 16913)
-- Name: calcular_recargo(integer, integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota date) RETURNS double precision
    LANGUAGE plpgsql
    AS $$ 
DECLARE v_recargo double precision = 0;
DECLARE v_monto precios.monto%TYPE;
DECLARE porcentaje_recargo double precision = 0.01;
DECLARE diferencia_de_dias integer = 0;
DECLARE v_fecha_vencimiento date;
BEGIN
--Obtengo el monto a cobrar
select monto from precioAlquiler into v_monto
where id_inmueble = inmueble 
and id_cliente = cliente
and date_part('MONTH', age(fechaDefinicion, fehca_cuota)) <= 0 
order by date_part('MONTH', age(fechaDefinicion, fecha_cuota)) asc;

select fechaVencimiento INTO v_fecha_vencimiento from cuotas
where id_inmueble = inmueble 
and id_cliente = cliente
and mesaño = fecha_cuota;

diferencia_de_dias = date_part('DAY', age(current_date, fecha_vencimiento));
IF  diferencia_de_dias > 0 THEN
	v_recargo = diferencia_de_dias * (v_monto * porcentaje_recargo);
END IF;

RETURN v_recargo;
END;
$$;


ALTER FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota date) OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 16976)
-- Name: calcular_recargo(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota public."mesaño") RETURNS double precision
    LANGUAGE plpgsql
    AS $$ 
DECLARE v_recargo double precision = 0;
DECLARE v_monto cuotas.importe%TYPE;
DECLARE porcentaje_recargo double precision = 0.01;
DECLARE diferencia_de_dias integer = 0;
DECLARE v_fecha_vencimiento date;
BEGIN
--Obtengo el monto a cobrar
select importe INTO v_monto from cuotas 
where id_inmueble = inmueble 
and id_cliente = cliente
and mesaño LIKE fecha_cuota;

select fechaVencimiento INTO v_fecha_vencimiento from cuotas
where id_inmueble = inmueble 
and id_cliente = cliente
and mesaño LIKE fecha_cuota;

diferencia_de_dias = current_date - v_fecha_vencimiento;
IF  diferencia_de_dias > 0 THEN
	v_recargo = diferencia_de_dias * (v_monto * porcentaje_recargo);
	
END IF;

RETURN v_recargo;
END;
$$;


ALTER FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota public."mesaño") OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 16989)
-- Name: empleados_dependientes(public.cuit); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.empleados_dependientes(public.cuit) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    e record;
    e2 record;
    BEGIN
        for e in select emp.cuit, emp.apellido_nombre, emp.fecha_ingreso, emp.cargo, emp.superior as depende
                from empleados as emp
                where emp.superior = $1
            LOOP
                    for e2 in select cuit,apellido_nombre,fecha_ingreso, cargo, depende 
                        from empleados_dependientes(e.cuit) as (cuit cuit, apellido_nombre varchar(70),fecha_ingreso date, cargo varchar(15), depende cuit)
                        LOOP
                            return next e2;
                        end LOOP;
                return next e;
            end LOOP;
            return;
    end;
    $_$;


ALTER FUNCTION public.empleados_dependientes(public.cuit) OWNER TO postgres;

--
-- TOC entry 270 (class 1255 OID 16962)
-- Name: sp_actualizar_periodo_ocupacion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_actualizar_periodo_ocupacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_motivo_baja periodoOcupacion.motivoBaja%TYPE;
BEGIN
IF NEW.id_estado = OLD.id_estado THEN
	RETURN NEW;
ELSEIF NEW.id_estado <> 1 AND old.id_estado = 1 THEN --SI es 1 estaba activo
	SELECT descripcion INTO v_motivo_baja FROM contratos_estados WHERE id_estado = new.id_estado; 
	
	UPDATE periodoocupacion
	SET fechabaja=CURRENT_DATE, motivobaja=v_motivo_baja
	WHERE id_inmueble= OLD.id_inmueble and fechaInicio = OLD.fechaContrato;
	RETURN NEW;
ELSEIF NEW.id_estado = 1 AND OLD.id_estado <> 1 THEN
	IF EXISTS (select * from periodoOcupacion WHERE id_inmueble = OLD.id_inmueble 
			   AND fechaBaja IS NULL) THEN
		RAISE NOTICE 'No se permite abrir un contrato cuando ya se abrio otro posteriormente';
		RETURN NULL; -- NO Permito abrir un contrato cuando se abrio otro mas actual
	ELSE 
		UPDATE periodoocupacion
		SET fechabaja=NULL, motivobaja=NULL
		WHERE id_inmueble= OLD.id_inmueble and fechaInicio = OLD.fechaContrato;
	END IF;
END IF;

RETURN NEW;

END;
$$;


ALTER FUNCTION public.sp_actualizar_periodo_ocupacion() OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 16871)
-- Name: sp_actualizar_usuario_y_tiempo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_actualizar_usuario_y_tiempo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
NEW.ultimo_usuario = CURRENT_USER;
NEW.ultimo_horario = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_actualizar_usuario_y_tiempo() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16897)
-- Name: sp_agregar_fecha_vencimiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_agregar_fecha_vencimiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
		DECLARE
		 va_fecha_vencimiento integer;
		 va_fecha date;
		 va_ultimo_dia_fecha date;
		 
        BEGIN
				--obtenemos el dia del mes de vencimiento de la cuota segun el contrato
				SELECT ca.vencimiento_cuota INTO va_fecha_vencimiento FROM contratoalquiler AS ca
					WHERE ca.id_inmueble = new.id_inmueble AND ca.id_cliente = new.id_cliente;
				-- convertimos nuestro mes y año de la cuota en DATE	
				va_fecha := SP_convertir_mesaño_date(new.mesaño);
				-- creamos una variable con el ultimo dia del mes
				va_ultimo_dia_fecha:=  DATE((date_trunc('month', va_fecha) + interval '2 month') - interval '1 day');
				-- verificamos que el dia de vencimiento sea menor al ultimo dia del mes
				IF (cast(extract(day from va_ultimo_dia_fecha) as integer)) <= va_fecha_vencimiento THEN
					--si es mayor asignamos el ultimo dia del mes a la fecha de vencimiento de la cuota
					va_fecha_vencimiento:=cast(extract(day from va_ultimo_dia_fecha) as integer);
					
				END IF;
				-- creamos la fecha de vencimiento del mes proximo
				new.fechavencimiento := DATE( cast (va_fecha_vencimiento as varchar) || '-' || sp_convertir_date_mesaño((va_fecha + interval '1 MONTH')::date));

			RETURN new;
        END;
    $$;


ALTER FUNCTION public.sp_agregar_fecha_vencimiento() OWNER TO postgres;

--
-- TOC entry 271 (class 1255 OID 16964)
-- Name: sp_autoincremental_control(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_autoincremental_control() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_contador integer = 1; 
DECLARE v_id_valido inmuebles.id_inmueble%TYPE;
BEGIN
--chequeo si es la primera fila
IF NOT EXISTS(select * from inmuebles) THEN
	NEW.id_inmueble = 1000;

	
ELSEIF NEW.id_inmueble IS NULL THEN
	select id_inmueble+v_contador INTO v_id_valido FROM inmuebles 
	order by ultimo_horario DESC LIMIT 1;
	WHILE EXISTS ( select id_inmueble FROM inmuebles where id_inmueble = v_id_valido) LOOP
		v_contador = v_contador + 1;
		select id_inmueble+v_contador INTO v_id_valido FROM inmuebles 
		order by ultimo_horario DESC LIMIT 1;
	END LOOP;
	new.id_inmueble = v_id_valido;

--En este caso no viene nulo y no es la primera fila
ELSEIF EXISTS (select id_inmueble from inmuebles where id_inmueble = NEW.id_inmueble) THEN
		RETURN NULL;

END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_autoincremental_control() OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 16899)
-- Name: sp_cargarprecioalquiler(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_cargarprecioalquiler() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
        BEGIN
            INSERT INTO public.precioalquiler(id_inmueble, id_cliente, importe, fechadefinicion)
				VALUES (NEW.id_inmueble,NEW.id_cliente,NEW.precio_inicial,CURRENT_DATE);
            RETURN NULL;
        END;
    $$;


ALTER FUNCTION public.sp_cargarprecioalquiler() OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 16978)
-- Name: sp_check_facturacion_contrato(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_check_facturacion_contrato(inmueble integer, cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE v_mes_pendiente_facturacion mesaño;
BEGIN
	IF NOT(SP_contrato_isActivo(inmueble, cliente)) THEN
		RAISE NOTICE 'El contrato no esta activo';
		RETURN FALSE;
	ELSE
		--este if verifica si la anterior esta paga
		IF (sp_esta_paga_bool(inmueble, cliente, sp_operacion_resta_mes_año(v_mesaño, 1))) THEN
				--chequeo que el mes esta en el contrato
				IF SP_esta_en_rango_contrato(inmueble, cliente, v_mesaño) THEN
					--Chequeo que sea el mes actual o el proximo
					IF 	(SP_es_mayor_mesaño(SP_convertir_date_mesaño(CURRENT_DATE), v_mesaño) 
						 OR
						(SP_convertir_date_mesaño(CURRENT_DATE) LIKE v_mesaño) 
						 OR
						(sp_operacion_suma_mes_año(SP_convertir_date_mesaño(CURRENT_DATE), 1) LIKE v_mesaño))
						THEN
						--se generara la cuota
						
						IF SP_crear_cuota(inmueble, cliente, v_mesaño) THEN
						RAISE NOTICE 'Se creo la cuota correspondiente a %', v_mesaño;
						RETURN TRUE;
						ELSE
						RAISE NOTICE 'No se pudo crear la cuota correspondiente a %', v_mesaño;
						RETURN FALSE;
						END IF;
					ELSE
						RAISE NOTICE 'El mes % es posterior al que se debe pagar', v_mesaño;
						RETURN FALSE;
					END IF;
				ELSE
					RAISE NOTICE 'El mes que se quiere abonar no esta en el rango del contrato';
					RETURN FALSE;
				END IF;
		ELSE
			RAISE NOTICE 'La cuota anterior no esta paga';
			RETURN FALSE;
		END IF;
			
	END IF;
END;
$$;


ALTER FUNCTION public.sp_check_facturacion_contrato(inmueble integer, cliente integer, "v_mesaño" public."mesaño") OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 16977)
-- Name: sp_contrato_isactivo(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_contrato_isactivo(v_inmueble integer, v_cliente integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE estado integer;
BEGIN
	select id_estado INTO estado FROM contratoAlquiler 
	where id_cliente = v_cliente AND id_inmueble = v_inmueble;
	IF estado = 1 THEN -- 1=activo
		RETURN TRUE;
	ELSE RETURN False;
	END IF;
END;
$$;


ALTER FUNCTION public.sp_contrato_isactivo(v_inmueble integer, v_cliente integer) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 16917)
-- Name: sp_convertir_date_mesaño(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_convertir_date_mesaño"(fecha date) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN right(to_char(fecha, 'DD-MM-YYYY'), 7);
END;
$$;


ALTER FUNCTION public."sp_convertir_date_mesaño"(fecha date) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16918)
-- Name: sp_convertir_mesaño_date(public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño") RETURNS date
    LANGUAGE plpgsql
    AS $$
	BEGIN
	
		RETURN '01-' || v_mesaño; 
	END;
$$;


ALTER FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño") OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16919)
-- Name: sp_crear_cuota(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_crear_cuota(v_inmueble integer, v_cliente integer, fechacrear public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NOT SP_existe_cuota(v_inmueble, v_cliente, fechaCrear) THEN
		IF SP_esta_en_rango_contrato(v_inmueble, v_cliente, fechaCrear) THEN
			INSERT INTO public.cuotas(id_inmueble, id_cliente, "mesaño")
			VALUES (v_inmueble, v_cliente, fechaCrear);
			RETURN TRUE;
		ELSE
			RAISE NOTICE 'La cuota no corresponde al contrato';
			RETURN FALSE;
		END IF;
	ELSE
		RAISE NOTICE 'La cuota para el mes año % ya existe', fechaCrear;
		RETURN TRUE;
	END IF;
END;
$$;


ALTER FUNCTION public.sp_crear_cuota(v_inmueble integer, v_cliente integer, fechacrear public."mesaño") OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 16901)
-- Name: sp_crear_fecha_vencimiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_crear_fecha_vencimiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.vencimiento_cuota = extract ('day' from new.fechaContrato);
RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_crear_fecha_vencimiento() OWNER TO postgres;

--
-- TOC entry 269 (class 1255 OID 16960)
-- Name: sp_crear_periodo_ocupacion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_crear_periodo_ocupacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO periodoocupacion(id_inmueble, fechainicio, fechabaja, motivobaja)
	VALUES (NEW.id_inmueble, NEW.fechaContrato, NULL, NULL);
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_crear_periodo_ocupacion() OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 16903)
-- Name: sp_dias_vencidos_recargo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_dias_vencidos_recargo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_fechavencimiento DATE;
BEGIN
	select fechaVencimiento INTO v_fechavencimiento FROM cuotas
	WHERE id_inmueble = NEW.id_inmueble AND id_cliente = NEW.id_cliente AND mesaño = NEW.mesaño;
	
	NEW.diasVencidos = CURRENT_DATE - v_fechavencimiento;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_dias_vencidos_recargo() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 16916)
-- Name: sp_es_igual_mesaño(public."mesaño", public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño) = SP_convertir_mesaño_date(comparar);

END;
$$;


ALTER FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16920)
-- Name: sp_es_mayor_mesaño(public."mesaño", public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño)>SP_convertir_mesaño_date(comparar);

END;
$$;


ALTER FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") OWNER TO postgres;

--
-- TOC entry 268 (class 1255 OID 16921)
-- Name: sp_esta_en_rango_contrato(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE rango_inferior DATE;
DECLARE rango_superior DATE;
DECLARE v_vigencia INTEGER;
BEGIN

SELECT fechacontrato, periodo_vigencia INTO rango_inferior, v_vigencia FROM contratoalquiler
WHERE id_inmueble = v_inmueble AND id_cliente = v_cliente AND id_estado = 1;

rango_superior = rango_inferior + (CAST(v_vigencia AS varchar) || ' MONTH')::interval;

	IF (SP_es_mayor_mesaño(v_mesaño, SP_convertir_date_mesaño(rango_inferior)) 
		AND (SP_es_mayor_mesaño(SP_convertir_date_mesaño(rango_superior), v_mesaño) 
			 OR SP_es_igual_mesaño(SP_convertir_date_mesaño(rango_superior), v_mesaño)))
		THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$;


ALTER FUNCTION public.sp_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") OWNER TO postgres;

--
-- TOC entry 263 (class 1255 OID 16908)
-- Name: sp_esta_paga(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_esta_paga(v_cliente integer, v_inmueble integer, "v_mesaño" public."mesaño") RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE v_vencimiento date;
BEGIN
	
	SELECT fechavencimiento INTO v_vencimiento FROM Cuotas
	WHERE v_cliente = Cuotas.id_cliente
	AND v_inmueble = Cuotas.id_inmueble
	AND v_mesaño = Cuotas.mesaño;
	
	IF EXISTS (SELECT * FROM pagos
	WHERE v_cliente = pagos.id_cliente
	AND v_inmueble = pagos.id_inmueble
	AND v_mesaño = pagos.mesaño)
	THEN
		RETURN 'Pagada';
	ELSE
		IF (v_vencimiento < CURRENT_DATE) THEN
			RETURN 'Vencida';
		ELSE
			RETURN 'Impaga';
		END IF;
	END IF;

RETURN 'No existe la cuota.';
END;
$$;


ALTER FUNCTION public.sp_esta_paga(v_cliente integer, v_inmueble integer, "v_mesaño" public."mesaño") OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16907)
-- Name: sp_esta_paga_bool(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_esta_paga_bool(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE v_vencimiento date;
BEGIN
	IF ((SP_es_igual_mesaño(SP_obtener_mesaño_contrato(v_inmueble, v_cliente, 1), v_mesaño))
	   	AND 
	    NOT EXISTS (SELECT v_mesaño FROM pagos
		WHERE v_cliente = pagos.id_cliente
		AND v_inmueble = pagos.id_inmueble
		AND v_mesaño LIKE pagos.mesaño))
		THEN
		RAISE NOTICE 'La cuota % no esta paga', v_mesaño;
		RETURN FALSE;
	ELSEIF EXISTS (SELECT v_mesaño FROM pagos
		WHERE v_cliente = pagos.id_cliente
		AND v_inmueble = pagos.id_inmueble
		AND v_mesaño LIKE pagos.mesaño)
		THEN
			RETURN True;
	ELSEIF NOT SP_esta_en_rango_contrato(v_inmueble, v_cliente, v_mesaño) THEN
		RETURN TRUE;
	END IF;
RETURN False;
END;
$$;


ALTER FUNCTION public.sp_esta_paga_bool(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 16909)
-- Name: sp_existe_cuota(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_existe_cuota(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF EXISTS (SELECT * from CUOTAS
			  WHERE id_inmueble = v_inmueble
			  AND id_cliente = v_cliente
			  AND mesaño = v_mesaño)
	THEN RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$;


ALTER FUNCTION public.sp_existe_cuota(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 16970)
-- Name: sp_historial_direcciones_dueño(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_historial_direcciones_dueño"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE 
        v_dueño integer;
        v_nuevo_id_historial integer;
    BEGIN
        IF EXISTS(select dueños.id_dueño from dueños
                    inner join personas on dueños.id_persona = personas.id_persona
                    where  personas.id_direccion=OLD.id_direccion)
            THEN
            UPDATE historial_direcciones SET fechaFinVigencia = CURRENT_DATE
            WHERE id_direccion = OLD.id_direccion AND fechaFinVigencia IS NULL;
			IF (tg_op = 'UPDATE') THEN
            --obtengo nuevo ID
            select COUNT(id_historial)+1 INTO v_nuevo_id_historial
                FROM Historial_Direcciones;
            select dueños.id_dueño INTO v_dueño from dueños
                inner join personas on personas.id_direccion = OLD.id_direccion 
                where  dueños.id_persona = personas.id_persona;
            INSERT INTO Historial_Direcciones(
                id_historial,id_dueño,id_direccion,
                id_localidad ,calle,numero,
                departamento,piso,observaciones,
                fechaInicioVigencia,fechaFinVigencia,
                usuario_modificacion
            ) values (
                v_nuevo_id_historial,v_dueño,
                NEW.id_direccion,NEW.id_localidad ,
                NEW.calle,NEW.numero,
                NEW.departamento,NEW.piso,
                NEW.observaciones,CURRENT_DATE,
                NULL,CURRENT_USER
            );
            END IF;
        END IF;
		return new;
    END;
	
    $$;


ALTER FUNCTION public."sp_historial_direcciones_dueño"() OWNER TO postgres;

--
-- TOC entry 278 (class 1255 OID 16974)
-- Name: sp_importepago(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_importepago() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_recargo recargos.importerecargo%TYPE;
DECLARE v_importeCuota cuotas.importe%TYPE;
BEGIN
	v_recargo = calcular_recargo(NEW.id_inmueble, NEW.id_cliente, NEW.mesaño);
	select importe INTO v_importeCuota FROM CUOTAS
	WHERE id_inmueble = NEW.id_inmueble AND id_cliente = NEW.id_cliente AND mesaño = NEW.mesaño;
	IF(NEW.importepago IS NULL) THEN
		NEW.importepago = v_recargo + v_importeCuota;
		RAISE NOTICE 'Su pago se genero correctamente %', NEW.importepago;
		RETURN NEW;
	ELSEIF (NEW.importepago < (v_recargo + v_importeCuota)) THEN
		RAISE NOTICE 'No se admiten pagos parciales, debe cubrir el importe total %', (v_recargo + v_importeCuota);
		RETURN NULL;
	ELSE
		RAISE NOTICE 'El pago se ingreso correctamente, su vuelto es: %', (NEW.importepago - (v_recargo + v_importeCuota));
		NEW.importePago = v_recargo + v_importeCuota;
		RETURN NEW;										   	
	END IF;
	
	RETURN NULL;
END;
$$;


ALTER FUNCTION public.sp_importepago() OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 16990)
-- Name: sp_mi_propio_jefe(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_mi_propio_jefe() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.CUIT = NEW.superior THEN
		RAISE NOTICE 'No puedes ser tu propio jefe en esta piramide';
		RETURN NULL;
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_mi_propio_jefe() OWNER TO postgres;

--
-- TOC entry 272 (class 1255 OID 16966)
-- Name: sp_modificar_nombre_cliente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_modificar_nombre_cliente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	UPDATE Personas SET nombreCompleto = new.nombreCompleto
	FROM Clientes
	WHERE clientes.id_persona = personas.id_persona and clientes.id_cliente = old.id_cliente;

RETURN new;
END;
$$;


ALTER FUNCTION public.sp_modificar_nombre_cliente() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16905)
-- Name: sp_obtener_importe_cuota(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_obtener_importe_cuota() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_cantidad_cuotas integer = 0;
BEGIN

	IF NOT EXISTS (select importe from precioAlquiler 
			where id_inmueble = NEW.id_inmueble and id_cliente = NEW.id_cliente)
		THEN
			RAISE NOTICE 'No se puede determinar el importe para la cuota ya que no hay ningun precio para el contrato';
			RETURN NULL;
	ELSE
		SELECT COUNT(mesaño) INTO v_cantidad_cuotas FROM CUOTAS 
		where id_inmueble = NEW.id_inmueble 
		and id_cliente = NEW.id_cliente;
		
		IF (v_cantidad_cuotas = 0) THEN
			--solo existe el precio inicial, no aplico logica de definicion de importe
			select importe INTO NEW.importe from precioAlquiler 
			where id_inmueble = NEW.id_inmueble 
			and id_cliente = NEW.id_cliente
			order by fechadefinicion ASC;
		ELSE--aca existen varios prebios, aplico logica
			NEW.importe = SP_obtener_importe_cuota(NEW.id_inmueble, NEW.id_cliente, NEW.mesaño);
		END IF;
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.sp_obtener_importe_cuota() OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 16910)
-- Name: sp_obtener_importe_cuota(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño") RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE v_importe double precision = 0;
BEGIN
	select importe INTO v_importe from precioAlquiler 
	where id_inmueble =  v_inmueble
	and id_cliente = v_cliente
	and SP_es_mayor_mesaño(fechaContable, SP_convertir_date_mesaño(fechaDefinicion)) 
	order by fechadefinicion DESC
	LIMIT 1;
	
	RETURN v_importe;
END;
$$;


ALTER FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño") OWNER TO postgres;

--
-- TOC entry 267 (class 1255 OID 16912)
-- Name: sp_obtener_importe_por_tipo(integer, integer, public."mesaño", integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE resultado double precision = 0.00;
DECLARE tipo_operacion integer;
BEGIN

IF operacion = 1 THEN
	select importe INTO resultado from cuotas
	where id_inmueble = inmueble AND id_cliente = cliente AND mesaño LIKE mes_año;
	select id_tipo_operacion INTO tipo_operacion FROM cuotas;
	
ELSEIF operacion = 2 THEN
	select importeCuota INTO resultado from pagos
	where id_inmueble = inmueble AND id_cliente = cliente AND mesaño LIKE mes_año;
	select id_tipo_operacion INTO tipo_operacion FROM pagos;
	
ELSEIF operacion = 3 THEN
	select importeRecargo INTO resultado from recargos
	where id_inmueble = inmueble AND id_cliente = cliente AND mesaño LIKE mes_año;
	select id_tipo_operacion INTO tipo_operacion FROM recargos;
END IF;

IF tipo_operacion = 1 THEN
	--Es Debito
	resultado = resultado * -1;
END IF;

RETURN resultado;
END;
$$;


ALTER FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer) OWNER TO postgres;

--
-- TOC entry 266 (class 1255 OID 16911)
-- Name: sp_obtener_mesaño_contrato(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE v_rango_inferior DATE;
DECLARE v_rango_superior DATE;
DECLARE v_vigencia integer;
DECLARE v_mesaño mesaño;
BEGIN
	SELECT fechacontrato, periodo_vigencia INTO v_rango_inferior, v_vigencia FROM contratoalquiler
	WHERE id_inmueble = v_inmueble AND id_cliente = v_cliente AND id_estado = 1;
	
	v_rango_superior = v_rango_inferior + (CAST(v_vigencia AS varchar) || ' MONTH')::interval;

	IF   (SP_esta_en_rango_contrato(v_inmueble, v_cliente, sp_operacion_suma_mes_año
		(SP_convertir_date_mesaño(v_rango_inferior), mes))) 
	THEN
		v_mesaño = sp_operacion_suma_mes_año(SP_convertir_date_mesaño(v_rango_inferior), mes);
		RETURN v_mesaño;
	ELSE
		RAISE NOTICE 'El mes que solicita no esta dentro del contrato, el rango superior es: %', 
			SP_convertir_date_mesaño(v_rango_superior);
		RETURN NULL;
	END IF;
END;
$$;


ALTER FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16914)
-- Name: sp_operacion_resta_mes_año(public."mesaño", integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) - (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;


ALTER FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 16915)
-- Name: sp_operacion_suma_mes_año(public."mesaño", integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) + (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;


ALTER FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer) OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 16973)
-- Name: sp_pagar_cuota(integer, integer, public."mesaño"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_pagar_cuota(v_inmueble integer, v_cliente integer, v_cuota public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE v_recargo recargos.importerecargo%TYPE;
BEGIN

	IF NOT (sp_esta_paga_bool(v_inmueble, v_cliente, v_cuota)) THEN
		v_recargo = calcular_recargo(v_inmueble, v_cliente, v_cuota);
		IF v_recargo > 0 THEN
			INSERT INTO public.recargos(
			id_inmueble, id_cliente, "mesaño", importerecargo)
			VALUES (v_inmueble, v_cliente, v_cuota, v_recargo);
		END IF;
		
		INSERT INTO public.pagos(
		id_inmueble, id_cliente, "mesaño", fechapago)
		VALUES (v_inmueble, v_cliente, v_cuota, CURRENT_DATE);
		
		RAISE NOTICE 'El pago se creo correctamente';
		RETURN TRUE;
	END IF;
	
RAISE NOTICE 'La cuota de % esta paga', v_cuota; 
RETURN FALSE;

END;
$$;


ALTER FUNCTION public.sp_pagar_cuota(v_inmueble integer, v_cliente integer, v_cuota public."mesaño") OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 16987)
-- Name: sp_verificar_jefe_maximo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_verificar_jefe_maximo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF NEW.superior IS NULL AND EXISTS (SELECT * FROM empleados where superior IS NULL) THEN
		--Solo puede haber un empleado sin jefe
		RAISE NOTICE 'Solo puede existir un empleado sin jefe';
		RETURN NULL;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.sp_verificar_jefe_maximo() OWNER TO postgres;

--
-- TOC entry 275 (class 1255 OID 16968)
-- Name: tg_iniciar_historial_dueños(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."tg_iniciar_historial_dueños"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE v_nuevo_id_historial INTEGER;
    BEGIN
        --obtengo nuevo ID
        select COUNT(id_historial)+1 INTO v_nuevo_id_historial FROM Historial_Direcciones;

        --inicio el historial de dueño
        INSERT INTO Historial_Direcciones
            (
                select v_nuevo_id_historial,NEW.id_dueño,
                direcciones.id_direccion, id_localidad, calle, 
                numero, departamento, piso, observaciones, CURRENT_DATE, NULL, CURRENT_USER
                FROM direcciones
                INNER JOIN Personas on personas.id_direccion = direcciones.id_direccion
                WHERE personas.id_persona = new.id_persona
            );
        RETURN NULL;

    END;
$$;


ALTER FUNCTION public."tg_iniciar_historial_dueños"() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 204 (class 1259 OID 16547)
-- Name: anuncios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.anuncios (
    id_anuncio integer NOT NULL,
    titulo character varying(50) NOT NULL,
    texto character varying(100) NOT NULL,
    fecha date NOT NULL,
    vigencia integer NOT NULL,
    tipo_vigencia character(1) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.anuncios OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16595)
-- Name: clientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientes (
    id_cliente integer NOT NULL,
    id_persona integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.clientes OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16710)
-- Name: contratoalquiler; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contratoalquiler (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    fechacontrato date DEFAULT CURRENT_DATE NOT NULL,
    id_estado integer DEFAULT 1 NOT NULL,
    periodo_vigencia integer NOT NULL,
    vencimiento_cuota integer DEFAULT 10 NOT NULL,
    id_finalidad integer,
    precio_inicial double precision NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.contratoalquiler OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16705)
-- Name: contratos_estados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contratos_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.contratos_estados OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16700)
-- Name: contratos_finalidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contratos_finalidades (
    id_finalidad integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.contratos_finalidades OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16809)
-- Name: cuotas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuotas (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    id_tipo_operacion integer DEFAULT 1 NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    importe double precision,
    fechavencimiento date NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.cuotas OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16582)
-- Name: personas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas (
    id_persona integer NOT NULL,
    dni public.dni NOT NULL,
    fechanacimiento date,
    fechainscripcion date,
    nombrecompleto character varying(50),
    id_direccion integer,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.personas OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 16517)
-- Name: tipo_operacion_contable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_operacion_contable (
    id_tipo_operacion integer NOT NULL,
    descripcion character varying(50),
    debito boolean,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.tipo_operacion_contable OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16922)
-- Name: cuota_cta_cte; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.cuota_cta_cte AS
 SELECT cuotas.id_cliente,
    personas.nombrecompleto,
    cuotas."mesaño",
    tipo_operacion_contable.descripcion,
    public.sp_obtener_importe_por_tipo(cuotas.id_inmueble, cuotas.id_cliente, cuotas."mesaño", 1) AS importe
   FROM (((public.cuotas
     JOIN public.tipo_operacion_contable ON ((cuotas.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion)))
     JOIN public.clientes ON ((clientes.id_cliente = cuotas.id_cliente)))
     JOIN public.personas ON ((clientes.id_persona = personas.id_persona)));


ALTER TABLE public.cuota_cta_cte OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16784)
-- Name: pagos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagos (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    id_tipo_operacion integer DEFAULT 2 NOT NULL,
    importepago double precision NOT NULL,
    fechapago date DEFAULT CURRENT_DATE NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.pagos OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16927)
-- Name: pago_cta_cte; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pago_cta_cte AS
 SELECT pagos.id_cliente,
    personas.nombrecompleto,
    pagos."mesaño",
    tipo_operacion_contable.descripcion,
    public.sp_obtener_importe_por_tipo(pagos.id_inmueble, pagos.id_cliente, pagos."mesaño", 2) AS importe
   FROM (((public.pagos
     JOIN public.tipo_operacion_contable ON ((pagos.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion)))
     JOIN public.clientes ON ((clientes.id_cliente = pagos.id_cliente)))
     JOIN public.personas ON ((clientes.id_persona = personas.id_persona)));


ALTER TABLE public.pago_cta_cte OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16833)
-- Name: recargos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recargos (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    id_tipo_operacion integer DEFAULT 3 NOT NULL,
    importerecargo double precision NOT NULL,
    diasvencidos integer DEFAULT 0,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.recargos OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16932)
-- Name: recargo_cta_cte; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.recargo_cta_cte AS
 SELECT recargos.id_cliente,
    personas.nombrecompleto,
    recargos."mesaño",
    tipo_operacion_contable.descripcion,
    public.sp_obtener_importe_por_tipo(recargos.id_inmueble, recargos.id_cliente, recargos."mesaño", 3) AS importe
   FROM (((public.recargos
     JOIN public.tipo_operacion_contable ON ((recargos.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion)))
     JOIN public.clientes ON ((clientes.id_cliente = recargos.id_cliente)))
     JOIN public.personas ON ((clientes.id_persona = personas.id_persona)));


ALTER TABLE public.recargo_cta_cte OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16937)
-- Name: cta_cte_cliente; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.cta_cte_cliente AS
 SELECT cta_cte.id_cliente,
    cta_cte.nombrecompleto,
    cta_cte."mesaño",
    cta_cte.descripcion,
    cta_cte.importe
   FROM ( SELECT cuota_cta_cte.id_cliente,
            cuota_cta_cte.nombrecompleto,
            cuota_cta_cte."mesaño",
            cuota_cta_cte.descripcion,
            cuota_cta_cte.importe
           FROM public.cuota_cta_cte
        UNION
         SELECT pago_cta_cte.id_cliente,
            pago_cta_cte.nombrecompleto,
            pago_cta_cte."mesaño",
            pago_cta_cte.descripcion,
            pago_cta_cte.importe
           FROM public.pago_cta_cte
        UNION
         SELECT recargo_cta_cte.id_cliente,
            recargo_cta_cte.nombrecompleto,
            recargo_cta_cte."mesaño",
            recargo_cta_cte.descripcion,
            recargo_cta_cte.importe
           FROM public.recargo_cta_cte) cta_cte
  ORDER BY cta_cte.id_cliente;


ALTER TABLE public.cta_cte_cliente OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 16537)
-- Name: direcciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.direcciones (
    id_direccion integer NOT NULL,
    id_localidad integer NOT NULL,
    calle character varying(50) NOT NULL,
    numero integer NOT NULL,
    departamento character varying(10),
    piso integer,
    observaciones character varying(100),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.direcciones OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16527)
-- Name: localidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localidades (
    id_localidad integer NOT NULL,
    nombre character varying(50) NOT NULL,
    codigo_postal integer,
    id_provincia integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.localidades OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 16522)
-- Name: localizaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localizaciones (
    id_localizacion integer NOT NULL,
    provincia character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.localizaciones OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16941)
-- Name: direccion_completa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.direccion_completa AS
 SELECT d.id_direccion,
    d.calle,
    d.numero,
    d.departamento,
    d.piso,
    d.observaciones,
    l.nombre,
    l.codigo_postal,
    loca.provincia
   FROM ((public.direcciones d
     JOIN public.localidades l ON ((d.id_localidad = l.id_localidad)))
     JOIN public.localizaciones loca ON ((l.id_provincia = loca.id_localizacion)));


ALTER TABLE public.direccion_completa OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16552)
-- Name: divisas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.divisas (
    id_divisa integer NOT NULL,
    acronimo character varying(3) NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.divisas OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 16607)
-- Name: dueños; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."dueños" (
    "id_dueño" integer NOT NULL,
    id_persona integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public."dueños" OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16858)
-- Name: empleados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empleados (
    cuit public.cuit NOT NULL,
    apellido_nombre character varying(70),
    fecha_ingreso date NOT NULL,
    cargo character varying(15) NOT NULL,
    superior public.cuit
);


ALTER TABLE public.empleados OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16743)
-- Name: garante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.garante (
    dni public.dni NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    nombre character varying(50) NOT NULL,
    fechanacimiento date NOT NULL,
    id_tipogarantia integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.garante OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16621)
-- Name: historial_direcciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historial_direcciones (
    id_historial integer NOT NULL,
    "id_dueño" integer,
    id_direccion integer NOT NULL,
    id_localidad integer NOT NULL,
    calle character varying(50) NOT NULL,
    numero integer NOT NULL,
    departamento character varying(10),
    piso integer,
    observaciones character varying(100),
    fechainiciovigencia date,
    fechafinvigencia date,
    usuario_modificacion character varying(50)
);


ALTER TABLE public.historial_direcciones OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16619)
-- Name: historial_direcciones_id_historial_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historial_direcciones_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.historial_direcciones_id_historial_seq OWNER TO postgres;

--
-- TOC entry 3360 (class 0 OID 0)
-- Dependencies: 213
-- Name: historial_direcciones_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historial_direcciones_id_historial_seq OWNED BY public.historial_direcciones.id_historial;


--
-- TOC entry 215 (class 1259 OID 16637)
-- Name: inmuebles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inmuebles (
    id_inmueble integer NOT NULL,
    id_tipoinmueble integer NOT NULL,
    id_estado_inmueble integer NOT NULL,
    id_direccion integer NOT NULL,
    id_anuncio integer NOT NULL,
    id_precio integer NOT NULL,
    "id_dueño" integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.inmuebles OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16672)
-- Name: inmuebles_operaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inmuebles_operaciones (
    id_inmueble integer NOT NULL,
    id_operacion integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.inmuebles_operaciones OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16689)
-- Name: periodoocupacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.periodoocupacion (
    id_periodo integer NOT NULL,
    id_inmueble integer NOT NULL,
    fechainicio date NOT NULL,
    fechabaja date,
    motivobaja character varying(100),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.periodoocupacion OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16557)
-- Name: precios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.precios (
    id_precio integer NOT NULL,
    id_divisa integer NOT NULL,
    monto double precision NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.precios OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16946)
-- Name: precio_inmueble; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.precio_inmueble AS
 SELECT p.id_precio,
    p.monto,
    d.acronimo
   FROM (public.precios p
     JOIN public.divisas d ON ((p.id_divisa = d.id_divisa)));


ALTER TABLE public.precio_inmueble OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16567)
-- Name: tipoinmueble; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipoinmueble (
    id_tipo integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.tipoinmueble OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16950)
-- Name: info_inmuebles_completa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.info_inmuebles_completa AS
 SELECT inmuebles.id_inmueble,
    tipo.descripcion,
    anu.titulo,
    pre.monto,
    pre.acronimo,
    per.nombrecompleto,
        CASE
            WHEN (1 = ( SELECT inmuebles_operaciones.id_operacion
               FROM public.inmuebles_operaciones
              WHERE ((inmuebles_operaciones.id_inmueble = inmuebles.id_inmueble) AND (inmuebles_operaciones.id_operacion = 1)))) THEN 'SI'::text
            ELSE 'NO'::text
        END AS se_vende,
        CASE
            WHEN (2 = ( SELECT inmuebles_operaciones.id_operacion
               FROM public.inmuebles_operaciones
              WHERE ((inmuebles_operaciones.id_inmueble = inmuebles.id_inmueble) AND (inmuebles_operaciones.id_operacion = 2)))) THEN 'SI'::text
            ELSE 'NO'::text
        END AS se_alquila,
        CASE
            WHEN ((2 = ( SELECT inmuebles_operaciones.id_operacion
               FROM public.inmuebles_operaciones
              WHERE ((inmuebles_operaciones.id_inmueble = inmuebles.id_inmueble) AND (inmuebles_operaciones.id_operacion = 2)))) AND (( SELECT periodoocupacion.fechabaja
               FROM public.periodoocupacion) <> NULL::date)) THEN 'OCUPADO'::text
            ELSE 'LIBRE'::text
        END AS estado_alquiler,
        CASE
            WHEN ((2 = ( SELECT inmuebles_operaciones.id_operacion
               FROM public.inmuebles_operaciones
              WHERE ((inmuebles_operaciones.id_inmueble = inmuebles.id_inmueble) AND (inmuebles_operaciones.id_operacion = 2)))) AND (( SELECT periodoocupacion.fechabaja
               FROM public.periodoocupacion) <> NULL::date)) THEN ( SELECT periodoocupacion.fechabaja
               FROM public.periodoocupacion
              WHERE (periodoocupacion.id_inmueble = inmuebles.id_inmueble))
            ELSE NULL::date
        END AS fecha_desocupacion,
    direc.id_direccion,
    direc.calle,
    direc.numero,
    direc.departamento,
    direc.piso,
    direc.observaciones,
    direc.nombre,
    direc.codigo_postal,
    direc.provincia
   FROM ((((((public.inmuebles
     JOIN public.direccion_completa direc ON ((direc.id_direccion = inmuebles.id_direccion)))
     JOIN public."dueños" due ON ((due."id_dueño" = inmuebles."id_dueño")))
     JOIN public.personas per ON ((per.id_persona = due.id_persona)))
     JOIN public.anuncios anu ON ((anu.id_anuncio = inmuebles.id_anuncio)))
     JOIN public.precio_inmueble pre ON ((pre.id_precio = inmuebles.id_precio)))
     JOIN public.tipoinmueble tipo ON ((tipo.id_tipo = inmuebles.id_tipoinmueble)));


ALTER TABLE public.info_inmuebles_completa OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16955)
-- Name: informacion_cuotas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.informacion_cuotas AS
 SELECT per.id_persona,
    per.dni,
    per.fechanacimiento,
    per.fechainscripcion,
    per.nombrecompleto,
    per.id_direccion,
    per.ultimo_usuario,
    per.ultimo_horario,
    cuo."mesaño",
    public.sp_esta_paga(ca.id_cliente, ca.id_inmueble, cuo."mesaño") AS sp_esta_paga
   FROM ((((public.contratoalquiler ca
     JOIN public.info_inmuebles_completa iic ON ((iic.id_inmueble = ca.id_inmueble)))
     JOIN public.clientes cli ON ((cli.id_cliente = ca.id_cliente)))
     JOIN public.personas per ON ((per.id_persona = cli.id_persona)))
     JOIN public.cuotas cuo ON (((cuo.id_inmueble = iic.id_inmueble) AND (cuo.id_cliente = ca.id_cliente))))
  WHERE (ca.id_estado = 1);


ALTER TABLE public.informacion_cuotas OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16577)
-- Name: inmuebles_estados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inmuebles_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.inmuebles_estados OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16572)
-- Name: operaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operaciones (
    id_operacion integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.operaciones OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16687)
-- Name: periodoocupacion_id_periodo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.periodoocupacion_id_periodo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.periodoocupacion_id_periodo_seq OWNER TO postgres;

--
-- TOC entry 3361 (class 0 OID 0)
-- Dependencies: 217
-- Name: periodoocupacion_id_periodo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.periodoocupacion_id_periodo_seq OWNED BY public.periodoocupacion.id_periodo;


--
-- TOC entry 224 (class 1259 OID 16768)
-- Name: precioalquiler; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.precioalquiler (
    id_precioalquiler integer NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    importe double precision NOT NULL,
    fechadefinicion date NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.precioalquiler OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16766)
-- Name: precioalquiler_id_precioalquiler_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.precioalquiler_id_precioalquiler_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.precioalquiler_id_precioalquiler_seq OWNER TO postgres;

--
-- TOC entry 3362 (class 0 OID 0)
-- Dependencies: 223
-- Name: precioalquiler_id_precioalquiler_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.precioalquiler_id_precioalquiler_seq OWNED BY public.precioalquiler.id_precioalquiler;


--
-- TOC entry 237 (class 1259 OID 16979)
-- Name: tipogarantia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipogarantia (
    id_garantia integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);


ALTER TABLE public.tipogarantia OWNER TO postgres;

--
-- TOC entry 3044 (class 2604 OID 16624)
-- Name: historial_direcciones id_historial; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_direcciones ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_direcciones_id_historial_seq'::regclass);


--
-- TOC entry 3045 (class 2604 OID 16692)
-- Name: periodoocupacion id_periodo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.periodoocupacion ALTER COLUMN id_periodo SET DEFAULT nextval('public.periodoocupacion_id_periodo_seq'::regclass);


--
-- TOC entry 3049 (class 2604 OID 16771)
-- Name: precioalquiler id_precioalquiler; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precioalquiler ALTER COLUMN id_precioalquiler SET DEFAULT nextval('public.precioalquiler_id_precioalquiler_seq'::regclass);


--
-- TOC entry 3329 (class 0 OID 16547)
-- Dependencies: 204
-- Data for Name: anuncios; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.anuncios (id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia, ultimo_usuario, ultimo_horario) VALUES (1, 'Venta Casa', 'Vendo casa', '2021-01-20', 30, 'D', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.anuncios (id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia, ultimo_usuario, ultimo_horario) VALUES (2, 'Alquiler Dpto', 'Alquilo Dpto', '2021-03-21', 15, 'D', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.anuncios (id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia, ultimo_usuario, ultimo_horario) VALUES (3, 'Alquilo casa roja', 'La pinte yo', '2020-02-28', 10, 'D', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.anuncios (id_anuncio, titulo, texto, fecha, vigencia, tipo_vigencia, ultimo_usuario, ultimo_horario) VALUES (4, 'Alquiler dpto rosa', 'Info al DM', '2020-11-04', 5, 'D', 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3336 (class 0 OID 16595)
-- Dependencies: 211
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.clientes (id_cliente, id_persona, ultimo_usuario, ultimo_horario) VALUES (1, 10, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.clientes (id_cliente, id_persona, ultimo_usuario, ultimo_horario) VALUES (2, 11, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.clientes (id_cliente, id_persona, ultimo_usuario, ultimo_horario) VALUES (3, 12, 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3346 (class 0 OID 16710)
-- Dependencies: 221
-- Data for Name: contratoalquiler; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.contratoalquiler (id_inmueble, id_cliente, fechacontrato, id_estado, periodo_vigencia, vencimiento_cuota, id_finalidad, precio_inicial, ultimo_usuario, ultimo_horario) VALUES (1002, 3, '2021-05-26', 1, 6, 26, 2, 1500, 'postgres', '2021-06-13 17:01:24.279656');
INSERT INTO public.contratoalquiler (id_inmueble, id_cliente, fechacontrato, id_estado, periodo_vigencia, vencimiento_cuota, id_finalidad, precio_inicial, ultimo_usuario, ultimo_horario) VALUES (1000, 1, '2021-02-20', 1, 6, 20, 2, 1500, 'postgres', '2021-06-13 17:33:53.899225');


--
-- TOC entry 3345 (class 0 OID 16705)
-- Dependencies: 220
-- Data for Name: contratos_estados; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.contratos_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (1, 'Activo', 'postgres', '2021-06-13 17:01:21.669113');
INSERT INTO public.contratos_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (2, 'Finalizado', 'postgres', '2021-06-13 17:01:21.669113');
INSERT INTO public.contratos_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (3, 'Baja a pedido del cliente', 'postgres', '2021-06-13 17:01:21.669113');
INSERT INTO public.contratos_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (4, 'Baja a pedido del dueño', 'postgres', '2021-06-13 17:01:21.669113');


--
-- TOC entry 3344 (class 0 OID 16700)
-- Dependencies: 219
-- Data for Name: contratos_finalidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.contratos_finalidades (id_finalidad, descripcion, ultimo_usuario, ultimo_horario) VALUES (1, 'Vacaciones', 'postgres', '2021-06-13 17:01:17.944486');
INSERT INTO public.contratos_finalidades (id_finalidad, descripcion, ultimo_usuario, ultimo_horario) VALUES (2, 'Ocupacion temporal', 'postgres', '2021-06-13 17:01:17.944486');
INSERT INTO public.contratos_finalidades (id_finalidad, descripcion, ultimo_usuario, ultimo_horario) VALUES (3, 'Negocios', 'postgres', '2021-06-13 17:01:17.944486');
INSERT INTO public.contratos_finalidades (id_finalidad, descripcion, ultimo_usuario, ultimo_horario) VALUES (4, 'otros', 'postgres', '2021-06-13 17:01:17.944486');


--
-- TOC entry 3351 (class 0 OID 16809)
-- Dependencies: 226
-- Data for Name: cuotas; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cuotas (id_inmueble, id_cliente, id_tipo_operacion, "mesaño", importe, fechavencimiento, ultimo_usuario, ultimo_horario) VALUES (1000, 1, 1, '03-2021', 1500, '2021-04-20', 'postgres', '2021-06-13 17:36:17.345426');


--
-- TOC entry 3328 (class 0 OID 16537)
-- Dependencies: 203
-- Data for Name: direcciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.direcciones (id_direccion, id_localidad, calle, numero, departamento, piso, observaciones, ultimo_usuario, ultimo_horario) VALUES (1, 1, 'Division de los Andes', 1276, NULL, NULL, 'Porton Negro', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.direcciones (id_direccion, id_localidad, calle, numero, departamento, piso, observaciones, ultimo_usuario, ultimo_horario) VALUES (2, 1, 'Victorio Camerano', 2052, NULL, NULL, 'Porton Azul', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.direcciones (id_direccion, id_localidad, calle, numero, departamento, piso, observaciones, ultimo_usuario, ultimo_horario) VALUES (3, 7, 'Las Napias 2', 111, 'B', 3, 'No tiene porton', 'postgres', '2021-06-13 17:30:02.303467');


--
-- TOC entry 3330 (class 0 OID 16552)
-- Dependencies: 205
-- Data for Name: divisas; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.divisas (id_divisa, acronimo, descripcion, ultimo_usuario, ultimo_horario) VALUES (1, 'USD', 'Dolares', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.divisas (id_divisa, acronimo, descripcion, ultimo_usuario, ultimo_horario) VALUES (2, 'ARS', 'Pesos', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.divisas (id_divisa, acronimo, descripcion, ultimo_usuario, ultimo_horario) VALUES (3, 'EUR', 'Euros', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.divisas (id_divisa, acronimo, descripcion, ultimo_usuario, ultimo_horario) VALUES (4, 'JPY', 'Yenes', 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3337 (class 0 OID 16607)
-- Dependencies: 212
-- Data for Name: dueños; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."dueños" ("id_dueño", id_persona, ultimo_usuario, ultimo_horario) VALUES (2, 11, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public."dueños" ("id_dueño", id_persona, ultimo_usuario, ultimo_horario) VALUES (3, 12, 'postgres', '2021-06-13 17:29:40.670634');


--
-- TOC entry 3353 (class 0 OID 16858)
-- Dependencies: 228
-- Data for Name: empleados; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.empleados (cuit, apellido_nombre, fecha_ingreso, cargo, superior) VALUES ('11111111', 'Juan Perez', '2021-06-16', 'Barredor', NULL);
INSERT INTO public.empleados (cuit, apellido_nombre, fecha_ingreso, cargo, superior) VALUES ('22222222', 'Atilio Modenitti', '2021-06-16', 'Panadero', '11111111');
INSERT INTO public.empleados (cuit, apellido_nombre, fecha_ingreso, cargo, superior) VALUES ('33333333', 'Juan K', '2021-06-16', 'fichaje', '22222222');
INSERT INTO public.empleados (cuit, apellido_nombre, fecha_ingreso, cargo, superior) VALUES ('11115555', 'Juan Peres', '2021-06-16', 'Barredor', '33333333');
INSERT INTO public.empleados (cuit, apellido_nombre, fecha_ingreso, cargo, superior) VALUES ('41154249', 'Matias Sotelo', '2021-06-16', 'Limpia mueble', '33333333');
INSERT INTO public.empleados (cuit, apellido_nombre, fecha_ingreso, cargo, superior) VALUES ('99999999', 'Juan Perez', '2021-06-16', 'Barredor', '99999999');


--
-- TOC entry 3347 (class 0 OID 16743)
-- Dependencies: 222
-- Data for Name: garante; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3339 (class 0 OID 16621)
-- Dependencies: 214
-- Data for Name: historial_direcciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.historial_direcciones (id_historial, "id_dueño", id_direccion, id_localidad, calle, numero, departamento, piso, observaciones, fechainiciovigencia, fechafinvigencia, usuario_modificacion) VALUES (1, 3, 3, 7, 'Las Napias', 111, 'B', 3, 'No tiene porton', '2021-06-13', '2021-06-13', 'postgres');
INSERT INTO public.historial_direcciones (id_historial, "id_dueño", id_direccion, id_localidad, calle, numero, departamento, piso, observaciones, fechainiciovigencia, fechafinvigencia, usuario_modificacion) VALUES (2, 3, 3, 7, 'Las Napias 2', 111, 'B', 3, 'No tiene porton', '2021-06-13', NULL, 'postgres');


--
-- TOC entry 3340 (class 0 OID 16637)
-- Dependencies: 215
-- Data for Name: inmuebles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.inmuebles (id_inmueble, id_tipoinmueble, id_estado_inmueble, id_direccion, id_anuncio, id_precio, "id_dueño", ultimo_usuario, ultimo_horario) VALUES (1000, 101, 1, 3, 1, 1, 2, 'postgres', '2021-06-13 17:01:11.479623');
INSERT INTO public.inmuebles (id_inmueble, id_tipoinmueble, id_estado_inmueble, id_direccion, id_anuncio, id_precio, "id_dueño", ultimo_usuario, ultimo_horario) VALUES (1002, 102, 2, 1, 2, 2, 2, 'postgres', '2021-06-13 17:01:11.479623');
INSERT INTO public.inmuebles (id_inmueble, id_tipoinmueble, id_estado_inmueble, id_direccion, id_anuncio, id_precio, "id_dueño", ultimo_usuario, ultimo_horario) VALUES (1003, 103, 1, 3, 3, 3, 2, 'postgres', '2021-06-13 17:01:11.479623');


--
-- TOC entry 3334 (class 0 OID 16577)
-- Dependencies: 209
-- Data for Name: inmuebles_estados; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.inmuebles_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (1, 'Anulado', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.inmuebles_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (2, 'Disponible', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.inmuebles_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (3, 'Alquilado', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.inmuebles_estados (id_estado, descripcion, ultimo_usuario, ultimo_horario) VALUES (4, 'Vendido', 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3341 (class 0 OID 16672)
-- Dependencies: 216
-- Data for Name: inmuebles_operaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.inmuebles_operaciones (id_inmueble, id_operacion, ultimo_usuario, ultimo_horario) VALUES (1000, 1, 'postgres', '2021-06-13 17:01:15.312246');
INSERT INTO public.inmuebles_operaciones (id_inmueble, id_operacion, ultimo_usuario, ultimo_horario) VALUES (1002, 1, 'postgres', '2021-06-13 17:01:15.312246');
INSERT INTO public.inmuebles_operaciones (id_inmueble, id_operacion, ultimo_usuario, ultimo_horario) VALUES (1000, 2, 'postgres', '2021-06-13 17:01:15.312246');
INSERT INTO public.inmuebles_operaciones (id_inmueble, id_operacion, ultimo_usuario, ultimo_horario) VALUES (1003, 2, 'postgres', '2021-06-13 17:01:15.312246');


--
-- TOC entry 3327 (class 0 OID 16527)
-- Dependencies: 202
-- Data for Name: localidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (1, 'Parana', 3100, 10, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (2, 'Cordoba', 5800, 11, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (3, 'Misiones', 3300, 12, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (4, 'Villa Carlos Paz', 5800, 11, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (5, 'Santa Fe', 3000, 14, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (6, 'Rosario', 3000, 14, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localidades (id_localidad, nombre, codigo_postal, id_provincia, ultimo_usuario, ultimo_horario) VALUES (7, 'Oro Verde', 3100, 10, 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3326 (class 0 OID 16522)
-- Dependencies: 201
-- Data for Name: localizaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (10, 'Entre Rios', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (11, 'Cordoba', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (12, 'Misiones', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (13, 'Buenos Aires', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (14, 'Santa Fe', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (15, 'La Pampa', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (16, 'Jujuy', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.localizaciones (id_localizacion, provincia, ultimo_usuario, ultimo_horario) VALUES (17, 'Neuquen', 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3333 (class 0 OID 16572)
-- Dependencies: 208
-- Data for Name: operaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.operaciones (id_operacion, descripcion, ultimo_usuario, ultimo_horario) VALUES (1, 'Venta', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.operaciones (id_operacion, descripcion, ultimo_usuario, ultimo_horario) VALUES (2, 'Alquiler', 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3350 (class 0 OID 16784)
-- Dependencies: 225
-- Data for Name: pagos; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pagos (id_inmueble, id_cliente, "mesaño", id_tipo_operacion, importepago, fechapago, ultimo_usuario, ultimo_horario) VALUES (1000, 1, '03-2021', 2, 2310, '2021-06-13', 'postgres', '2021-06-13 17:56:36.037955');


--
-- TOC entry 3343 (class 0 OID 16689)
-- Dependencies: 218
-- Data for Name: periodoocupacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.periodoocupacion (id_periodo, id_inmueble, fechainicio, fechabaja, motivobaja, ultimo_usuario, ultimo_horario) VALUES (3, 1000, '2021-05-20', NULL, NULL, 'postgres', '2021-06-13 17:01:24.279656');
INSERT INTO public.periodoocupacion (id_periodo, id_inmueble, fechainicio, fechabaja, motivobaja, ultimo_usuario, ultimo_horario) VALUES (4, 1002, '2021-05-26', NULL, NULL, 'postgres', '2021-06-13 17:01:24.279656');


--
-- TOC entry 3335 (class 0 OID 16582)
-- Dependencies: 210
-- Data for Name: personas; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.personas (id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion, ultimo_usuario, ultimo_horario) VALUES (10, '41154249', '1998-11-20', '2021-05-24', 'Matias Nicolas Sotelo', 1, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.personas (id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion, ultimo_usuario, ultimo_horario) VALUES (11, '39717392', '1996-07-16', '2021-01-01', 'Atilio Mariano Modenutti', 2, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.personas (id_persona, dni, fechanacimiento, fechainscripcion, nombrecompleto, id_direccion, ultimo_usuario, ultimo_horario) VALUES (12, '42560204', '1995-01-01', '2021-05-01', 'Juan Ignacio Gerstner', 3, 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3349 (class 0 OID 16768)
-- Dependencies: 224
-- Data for Name: precioalquiler; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.precioalquiler (id_precioalquiler, id_inmueble, id_cliente, importe, fechadefinicion, ultimo_usuario, ultimo_horario) VALUES (3, 1000, 1, 1500, '2021-06-13', 'postgres', '2021-06-13 17:01:24.279656');
INSERT INTO public.precioalquiler (id_precioalquiler, id_inmueble, id_cliente, importe, fechadefinicion, ultimo_usuario, ultimo_horario) VALUES (4, 1002, 3, 1500, '2021-06-13', 'postgres', '2021-06-13 17:01:24.279656');


--
-- TOC entry 3331 (class 0 OID 16557)
-- Dependencies: 206
-- Data for Name: precios; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.precios (id_precio, id_divisa, monto, ultimo_usuario, ultimo_horario) VALUES (1, 2, 5000, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.precios (id_precio, id_divisa, monto, ultimo_usuario, ultimo_horario) VALUES (2, 2, 5500, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.precios (id_precio, id_divisa, monto, ultimo_usuario, ultimo_horario) VALUES (3, 4, 15000, 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.precios (id_precio, id_divisa, monto, ultimo_usuario, ultimo_horario) VALUES (4, 1, 100, 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3352 (class 0 OID 16833)
-- Dependencies: 227
-- Data for Name: recargos; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.recargos (id_inmueble, id_cliente, "mesaño", id_tipo_operacion, importerecargo, diasvencidos, ultimo_usuario, ultimo_horario) VALUES (1000, 1, '03-2021', 3, 810, 54, 'postgres', '2021-06-13 17:56:36.037955');


--
-- TOC entry 3325 (class 0 OID 16517)
-- Dependencies: 200
-- Data for Name: tipo_operacion_contable; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_operacion_contable (id_tipo_operacion, descripcion, debito, ultimo_usuario, ultimo_horario) VALUES (1, 'Cuota', true, 'postgres', '2021-06-13 17:04:15.374758');
INSERT INTO public.tipo_operacion_contable (id_tipo_operacion, descripcion, debito, ultimo_usuario, ultimo_horario) VALUES (2, 'Pago', false, 'postgres', '2021-06-13 17:04:15.374758');
INSERT INTO public.tipo_operacion_contable (id_tipo_operacion, descripcion, debito, ultimo_usuario, ultimo_horario) VALUES (3, 'Recargo', true, 'postgres', '2021-06-13 17:04:15.374758');


--
-- TOC entry 3354 (class 0 OID 16979)
-- Dependencies: 237
-- Data for Name: tipogarantia; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipogarantia (id_garantia, descripcion, ultimo_usuario, ultimo_horario) VALUES (1, 'Recibo de Sueldo', 'postgres', '2021-06-13 17:04:09.984491');
INSERT INTO public.tipogarantia (id_garantia, descripcion, ultimo_usuario, ultimo_horario) VALUES (2, 'Titulo de propiedad', 'postgres', '2021-06-13 17:04:09.984491');


--
-- TOC entry 3332 (class 0 OID 16567)
-- Dependencies: 207
-- Data for Name: tipoinmueble; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipoinmueble (id_tipo, descripcion, ultimo_usuario, ultimo_horario) VALUES (101, 'Monoambiente', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.tipoinmueble (id_tipo, descripcion, ultimo_usuario, ultimo_horario) VALUES (102, 'Duplex', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.tipoinmueble (id_tipo, descripcion, ultimo_usuario, ultimo_horario) VALUES (103, 'Departamento', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.tipoinmueble (id_tipo, descripcion, ultimo_usuario, ultimo_horario) VALUES (104, 'Casa', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.tipoinmueble (id_tipo, descripcion, ultimo_usuario, ultimo_horario) VALUES (105, 'Cochera', 'postgres', '2021-06-13 16:58:49.985349');
INSERT INTO public.tipoinmueble (id_tipo, descripcion, ultimo_usuario, ultimo_horario) VALUES (106, 'Galpon', 'postgres', '2021-06-13 16:58:49.985349');


--
-- TOC entry 3363 (class 0 OID 0)
-- Dependencies: 213
-- Name: historial_direcciones_id_historial_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.historial_direcciones_id_historial_seq', 1, false);


--
-- TOC entry 3364 (class 0 OID 0)
-- Dependencies: 217
-- Name: periodoocupacion_id_periodo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.periodoocupacion_id_periodo_seq', 4, true);


--
-- TOC entry 3365 (class 0 OID 0)
-- Dependencies: 223
-- Name: precioalquiler_id_precioalquiler_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.precioalquiler_id_precioalquiler_seq', 4, true);


--
-- TOC entry 3064 (class 2606 OID 16551)
-- Name: anuncios anuncios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anuncios
    ADD CONSTRAINT anuncios_pkey PRIMARY KEY (id_anuncio);


--
-- TOC entry 3078 (class 2606 OID 16601)
-- Name: clientes clientes_id_cliente_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_cliente_key UNIQUE (id_cliente);


--
-- TOC entry 3080 (class 2606 OID 16599)
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id_cliente, id_persona);


--
-- TOC entry 3098 (class 2606 OID 16717)
-- Name: contratoalquiler contratoalquiler_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente);


--
-- TOC entry 3096 (class 2606 OID 16709)
-- Name: contratos_estados contratos_estados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratos_estados
    ADD CONSTRAINT contratos_estados_pkey PRIMARY KEY (id_estado);


--
-- TOC entry 3094 (class 2606 OID 16704)
-- Name: contratos_finalidades contratos_finalidades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratos_finalidades
    ADD CONSTRAINT contratos_finalidades_pkey PRIMARY KEY (id_finalidad);


--
-- TOC entry 3106 (class 2606 OID 16817)
-- Name: cuotas cuotas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");


--
-- TOC entry 3062 (class 2606 OID 16541)
-- Name: direcciones direcciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_pkey PRIMARY KEY (id_direccion);


--
-- TOC entry 3066 (class 2606 OID 16556)
-- Name: divisas divisas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.divisas
    ADD CONSTRAINT divisas_pkey PRIMARY KEY (id_divisa);


--
-- TOC entry 3082 (class 2606 OID 16613)
-- Name: dueños dueños_id_dueño_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_id_dueño_key" UNIQUE ("id_dueño");


--
-- TOC entry 3084 (class 2606 OID 16611)
-- Name: dueños dueños_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_pkey" PRIMARY KEY ("id_dueño", id_persona);


--
-- TOC entry 3110 (class 2606 OID 16865)
-- Name: empleados empleados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_pkey PRIMARY KEY (cuit);


--
-- TOC entry 3100 (class 2606 OID 16750)
-- Name: garante garante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.garante
    ADD CONSTRAINT garante_pkey PRIMARY KEY (id_inmueble, id_cliente, dni);


--
-- TOC entry 3086 (class 2606 OID 16626)
-- Name: historial_direcciones historial_direcciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT historial_direcciones_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 3074 (class 2606 OID 16581)
-- Name: inmuebles_estados inmuebles_estados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles_estados
    ADD CONSTRAINT inmuebles_estados_pkey PRIMARY KEY (id_estado);


--
-- TOC entry 3090 (class 2606 OID 16676)
-- Name: inmuebles_operaciones inmuebles_operaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_pkey PRIMARY KEY (id_inmueble, id_operacion);


--
-- TOC entry 3088 (class 2606 OID 16641)
-- Name: inmuebles inmuebles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_pkey PRIMARY KEY (id_inmueble);


--
-- TOC entry 3060 (class 2606 OID 16531)
-- Name: localidades localidades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_pkey PRIMARY KEY (id_localidad);


--
-- TOC entry 3058 (class 2606 OID 16526)
-- Name: localizaciones localizaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizaciones
    ADD CONSTRAINT localizaciones_pkey PRIMARY KEY (id_localizacion);


--
-- TOC entry 3072 (class 2606 OID 16576)
-- Name: operaciones operaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_pkey PRIMARY KEY (id_operacion);


--
-- TOC entry 3104 (class 2606 OID 16793)
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");


--
-- TOC entry 3092 (class 2606 OID 16694)
-- Name: periodoocupacion periodoocupacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_pkey PRIMARY KEY (id_periodo);


--
-- TOC entry 3076 (class 2606 OID 16589)
-- Name: personas personas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (id_persona);


--
-- TOC entry 3102 (class 2606 OID 16773)
-- Name: precioalquiler precioalquiler_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente, id_precioalquiler);


--
-- TOC entry 3068 (class 2606 OID 16561)
-- Name: precios precios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_pkey PRIMARY KEY (id_precio);


--
-- TOC entry 3108 (class 2606 OID 16842)
-- Name: recargos recargos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");


--
-- TOC entry 3056 (class 2606 OID 16521)
-- Name: tipo_operacion_contable tipo_operacion_contable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_operacion_contable
    ADD CONSTRAINT tipo_operacion_contable_pkey PRIMARY KEY (id_tipo_operacion);


--
-- TOC entry 3112 (class 2606 OID 16983)
-- Name: tipogarantia tipogarantia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipogarantia
    ADD CONSTRAINT tipogarantia_pkey PRIMARY KEY (id_garantia);


--
-- TOC entry 3070 (class 2606 OID 16571)
-- Name: tipoinmueble tipoinmueble_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipoinmueble
    ADD CONSTRAINT tipoinmueble_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3173 (class 2620 OID 16963)
-- Name: contratoalquiler tg_actualizar_periodo_ocupacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_actualizar_periodo_ocupacion BEFORE UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_periodo_ocupacion();


--
-- TOC entry 3179 (class 2620 OID 16898)
-- Name: cuotas tg_agregar_fecha_vencimiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_agregar_fecha_vencimiento BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_agregar_fecha_vencimiento();


--
-- TOC entry 3153 (class 2620 OID 16877)
-- Name: anuncios tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.anuncios FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3160 (class 2620 OID 16884)
-- Name: clientes tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3169 (class 2620 OID 16890)
-- Name: contratoalquiler tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3168 (class 2620 OID 16889)
-- Name: contratos_estados tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratos_estados FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3167 (class 2620 OID 16888)
-- Name: contratos_finalidades tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratos_finalidades FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3178 (class 2620 OID 16895)
-- Name: cuotas tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3151 (class 2620 OID 16873)
-- Name: direcciones tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3154 (class 2620 OID 16878)
-- Name: divisas tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.divisas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3161 (class 2620 OID 16885)
-- Name: dueños tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public."dueños" FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3174 (class 2620 OID 16892)
-- Name: garante tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.garante FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3163 (class 2620 OID 16872)
-- Name: inmuebles tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3158 (class 2620 OID 16882)
-- Name: inmuebles_estados tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles_estados FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3165 (class 2620 OID 16886)
-- Name: inmuebles_operaciones tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles_operaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3150 (class 2620 OID 16876)
-- Name: localidades tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.localidades FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3149 (class 2620 OID 16875)
-- Name: localizaciones tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.localizaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3157 (class 2620 OID 16881)
-- Name: operaciones tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.operaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3176 (class 2620 OID 16894)
-- Name: pagos tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3166 (class 2620 OID 16887)
-- Name: periodoocupacion tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.periodoocupacion FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3159 (class 2620 OID 16883)
-- Name: personas tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.personas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3175 (class 2620 OID 16893)
-- Name: precioalquiler tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.precioalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3155 (class 2620 OID 16879)
-- Name: precios tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.precios FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3181 (class 2620 OID 16896)
-- Name: recargos tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.recargos FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3148 (class 2620 OID 16874)
-- Name: tipo_operacion_contable tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipo_operacion_contable FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3186 (class 2620 OID 16984)
-- Name: tipogarantia tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipogarantia FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3156 (class 2620 OID 16880)
-- Name: tipoinmueble tg_auditorio_modificacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipoinmueble FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();


--
-- TOC entry 3164 (class 2620 OID 16965)
-- Name: inmuebles tg_autoincremental_control; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_autoincremental_control BEFORE INSERT ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_autoincremental_control();


--
-- TOC entry 3170 (class 2620 OID 16900)
-- Name: contratoalquiler tg_cargarprecioalquiler; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_cargarprecioalquiler AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_cargarprecioalquiler();


--
-- TOC entry 3171 (class 2620 OID 16902)
-- Name: contratoalquiler tg_crear_fecha_vencimiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_crear_fecha_vencimiento BEFORE INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_fecha_vencimiento();


--
-- TOC entry 3172 (class 2620 OID 16961)
-- Name: contratoalquiler tg_crear_periodo_ocupacion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_crear_periodo_ocupacion AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_periodo_ocupacion();


--
-- TOC entry 3182 (class 2620 OID 16985)
-- Name: recargos tg_dias_vencidos_recargo; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_dias_vencidos_recargo BEFORE INSERT ON public.recargos FOR EACH ROW EXECUTE FUNCTION public.sp_dias_vencidos_recargo();


--
-- TOC entry 3152 (class 2620 OID 16971)
-- Name: direcciones tg_historial_direcciones_dueño; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "tg_historial_direcciones_dueño" BEFORE DELETE OR UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public."sp_historial_direcciones_dueño"();


--
-- TOC entry 3177 (class 2620 OID 16975)
-- Name: pagos tg_importepago; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_importepago BEFORE INSERT ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.sp_importepago();


--
-- TOC entry 3162 (class 2620 OID 16969)
-- Name: dueños tg_iniciar_historial_dueños; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "tg_iniciar_historial_dueños" AFTER INSERT ON public."dueños" FOR EACH ROW EXECUTE FUNCTION public."tg_iniciar_historial_dueños"();


--
-- TOC entry 3184 (class 2620 OID 16991)
-- Name: empleados tg_mi_propio_jefe; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_mi_propio_jefe BEFORE INSERT OR UPDATE ON public.empleados FOR EACH ROW EXECUTE FUNCTION public.sp_mi_propio_jefe();


--
-- TOC entry 3185 (class 2620 OID 16967)
-- Name: cta_cte_cliente tg_modificar_nombre_cliente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_modificar_nombre_cliente INSTEAD OF UPDATE ON public.cta_cte_cliente FOR EACH ROW EXECUTE FUNCTION public.sp_modificar_nombre_cliente();


--
-- TOC entry 3180 (class 2620 OID 16906)
-- Name: cuotas tg_obtener_importe_cuota; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_obtener_importe_cuota BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_obtener_importe_cuota();


--
-- TOC entry 3183 (class 2620 OID 16988)
-- Name: empleados tg_verificar_jefe_maximo; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_verificar_jefe_maximo BEFORE INSERT OR UPDATE ON public.empleados FOR EACH ROW EXECUTE FUNCTION public.sp_verificar_jefe_maximo();


--
-- TOC entry 3133 (class 2606 OID 16733)
-- Name: contratoalquiler contratoalquiler_id_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.contratos_estados(id_estado);


--
-- TOC entry 3132 (class 2606 OID 16728)
-- Name: contratoalquiler contratoalquiler_id_finalidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_finalidad_fkey FOREIGN KEY (id_finalidad) REFERENCES public.contratos_finalidades(id_finalidad);


--
-- TOC entry 3142 (class 2606 OID 16823)
-- Name: cuotas cuotas_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- TOC entry 3141 (class 2606 OID 16818)
-- Name: cuotas cuotas_id_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;


--
-- TOC entry 3143 (class 2606 OID 16828)
-- Name: cuotas cuotas_id_tipo_operacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);


--
-- TOC entry 3114 (class 2606 OID 16542)
-- Name: direcciones direcciones_id_localidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);


--
-- TOC entry 3147 (class 2606 OID 16866)
-- Name: empleados empleados_superior_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_superior_fkey FOREIGN KEY (superior) REFERENCES public.empleados(cuit);


--
-- TOC entry 3117 (class 2606 OID 16602)
-- Name: clientes fk_cliente_persona; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;


--
-- TOC entry 3131 (class 2606 OID 16723)
-- Name: contratoalquiler fk_contrato_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- TOC entry 3130 (class 2606 OID 16718)
-- Name: contratoalquiler fk_contrato_inmueble; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;


--
-- TOC entry 3116 (class 2606 OID 16590)
-- Name: personas fk_direccion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_direccion FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);


--
-- TOC entry 3118 (class 2606 OID 16614)
-- Name: dueños fk_dueÑo_persona; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "fk_dueÑo_persona" FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;


--
-- TOC entry 3135 (class 2606 OID 16756)
-- Name: garante fk_garante_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- TOC entry 3134 (class 2606 OID 16751)
-- Name: garante fk_garante_inmueble; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;


--
-- TOC entry 3119 (class 2606 OID 16627)
-- Name: historial_direcciones historial_direcciones_id_dueño_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT "historial_direcciones_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");


--
-- TOC entry 3120 (class 2606 OID 16632)
-- Name: historial_direcciones historial_direcciones_id_localidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT historial_direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);


--
-- TOC entry 3124 (class 2606 OID 16657)
-- Name: inmuebles inmuebles_id_anuncio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_anuncio_fkey FOREIGN KEY (id_anuncio) REFERENCES public.anuncios(id_anuncio);


--
-- TOC entry 3123 (class 2606 OID 16652)
-- Name: inmuebles inmuebles_id_direccion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);


--
-- TOC entry 3126 (class 2606 OID 16667)
-- Name: inmuebles inmuebles_id_dueño_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT "inmuebles_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");


--
-- TOC entry 3122 (class 2606 OID 16647)
-- Name: inmuebles inmuebles_id_estado_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_estado_inmueble_fkey FOREIGN KEY (id_estado_inmueble) REFERENCES public.inmuebles_estados(id_estado);


--
-- TOC entry 3125 (class 2606 OID 16662)
-- Name: inmuebles inmuebles_id_precio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_precio_fkey FOREIGN KEY (id_precio) REFERENCES public.precios(id_precio);


--
-- TOC entry 3121 (class 2606 OID 16642)
-- Name: inmuebles inmuebles_id_tipoinmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_tipoinmueble_fkey FOREIGN KEY (id_tipoinmueble) REFERENCES public.tipoinmueble(id_tipo);


--
-- TOC entry 3127 (class 2606 OID 16677)
-- Name: inmuebles_operaciones inmuebles_operaciones_id_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);


--
-- TOC entry 3128 (class 2606 OID 16682)
-- Name: inmuebles_operaciones inmuebles_operaciones_id_operacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_operacion_fkey FOREIGN KEY (id_operacion) REFERENCES public.operaciones(id_operacion);


--
-- TOC entry 3113 (class 2606 OID 16532)
-- Name: localidades localidades_id_provincia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_id_provincia_fkey FOREIGN KEY (id_provincia) REFERENCES public.localizaciones(id_localizacion);


--
-- TOC entry 3139 (class 2606 OID 16799)
-- Name: pagos pagos_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- TOC entry 3138 (class 2606 OID 16794)
-- Name: pagos pagos_id_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;


--
-- TOC entry 3140 (class 2606 OID 16804)
-- Name: pagos pagos_id_tipo_operacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);


--
-- TOC entry 3129 (class 2606 OID 16695)
-- Name: periodoocupacion periodoocupacion_id_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);


--
-- TOC entry 3137 (class 2606 OID 16779)
-- Name: precioalquiler precioalquiler_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- TOC entry 3136 (class 2606 OID 16774)
-- Name: precioalquiler precioalquiler_id_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;


--
-- TOC entry 3115 (class 2606 OID 16562)
-- Name: precios precios_id_divisa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_id_divisa_fkey FOREIGN KEY (id_divisa) REFERENCES public.divisas(id_divisa);


--
-- TOC entry 3145 (class 2606 OID 16848)
-- Name: recargos recargos_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- TOC entry 3144 (class 2606 OID 16843)
-- Name: recargos recargos_id_inmueble_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;


--
-- TOC entry 3146 (class 2606 OID 16853)
-- Name: recargos recargos_id_tipo_operacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);


-- Completed on 2021-06-16 18:02:39

--
-- PostgreSQL database dump complete
--

