PGDMP     .                    y            TP_DBA    13.2    13.2 ?    ?           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            ?           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ?           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            ?           1262    18331    TP_DBA    DATABASE     d   CREATE DATABASE "TP_DBA" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Spanish_Spain.1252';
    DROP DATABASE "TP_DBA";
                postgres    false            ?           1247    18333    dni    DOMAIN     o   CREATE DOMAIN public.dni AS character varying(8)
	CONSTRAINT dni_check CHECK (((VALUE)::integer <= 99999999));
    DROP DOMAIN public.dni;
       public          postgres    false            ?           1247    18336    mesaño    DOMAIN     ?   CREATE DOMAIN public."mesaño" AS character varying(7)
	CONSTRAINT date_check CHECK (('1990-01-01'::date < to_date(('01-'::text || (VALUE)::text), 'DD-MM-YYYY'::text)))
	CONSTRAINT format_check CHECK ((3 = "position"((VALUE)::text, '-'::text)));
    DROP DOMAIN public."mesaño";
       public          postgres    false            ?            1255    18660 (   calcular_recargo(integer, integer, date)    FUNCTION     ?  CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota date) RETURNS double precision
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
 \   DROP FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota date);
       public          postgres    false                       1255    18671 !   sp_actualizar_periodo_ocupacion()    FUNCTION     5  CREATE FUNCTION public.sp_actualizar_periodo_ocupacion() RETURNS trigger
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
 8   DROP FUNCTION public.sp_actualizar_periodo_ocupacion();
       public          postgres    false            ?            1255    18661     sp_actualizar_usuario_y_tiempo()    FUNCTION     ?   CREATE FUNCTION public.sp_actualizar_usuario_y_tiempo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
NEW.ultimo_usuario = CURRENT_USER;
NEW.ultimo_horario = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$;
 7   DROP FUNCTION public.sp_actualizar_usuario_y_tiempo();
       public          postgres    false            	           1255    18745    sp_agregar_fecha_vencimiento()    FUNCTION     0  CREATE FUNCTION public.sp_agregar_fecha_vencimiento() RETURNS trigger
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
 5   DROP FUNCTION public.sp_agregar_fecha_vencimiento();
       public          postgres    false            ?            1255    18723    sp_agregar_importe_cuota()    FUNCTION     ?   CREATE FUNCTION public.sp_agregar_importe_cuota() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	NEW.importe = SP_obtener_importe_cuota(NEW.id_inmueble, NEW.id_cliente, NEW.mesaño);
	RETURN NEW;
END;
$$;
 1   DROP FUNCTION public.sp_agregar_importe_cuota();
       public          postgres    false            ?            1255    18664    sp_autoincremental_control()    FUNCTION     v  CREATE FUNCTION public.sp_autoincremental_control() RETURNS trigger
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
 3   DROP FUNCTION public.sp_autoincremental_control();
       public          postgres    false                       1255    18751 A   sp_check_facturacion_contrato(integer, integer, public."mesaño")    FUNCTION       CREATE FUNCTION public.sp_check_facturacion_contrato(inmueble integer, cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
 u   DROP FUNCTION public.sp_check_facturacion_contrato(inmueble integer, cliente integer, "v_mesaño" public."mesaño");
       public          postgres    false    687                       1255    18750 &   sp_contrato_isactivo(integer, integer)    FUNCTION     f  CREATE FUNCTION public.sp_contrato_isactivo(v_inmueble integer, v_cliente integer) RETURNS boolean
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
 R   DROP FUNCTION public.sp_contrato_isactivo(v_inmueble integer, v_cliente integer);
       public          postgres    false            ?            1255    18702    sp_convertir_date_mesaño(date)    FUNCTION     ?   CREATE FUNCTION public."sp_convertir_date_mesaño"(fecha date) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN right(to_char(fecha, 'DD-MM-YYYY'), 7);
END;
$$;
 >   DROP FUNCTION public."sp_convertir_date_mesaño"(fecha date);
       public          postgres    false    687            ?            1255    18713 +   sp_convertir_mesaño_date(public."mesaño")    FUNCTION     ?   CREATE FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño") RETURNS date
    LANGUAGE plpgsql
    AS $$
	BEGIN
	
		RETURN '01-' || v_mesaño; 
	END;
$$;
 P   DROP FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño");
       public          postgres    false    687                       1255    18747 2   sp_crear_cuota(integer, integer, public."mesaño")    FUNCTION     j  CREATE FUNCTION public.sp_crear_cuota(v_inmueble integer, v_cliente integer, fechacrear public."mesaño") RETURNS boolean
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
 i   DROP FUNCTION public.sp_crear_cuota(v_inmueble integer, v_cliente integer, fechacrear public."mesaño");
       public          postgres    false    687                        1255    18669    sp_crear_periodo_ocupacion()    FUNCTION       CREATE FUNCTION public.sp_crear_periodo_ocupacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO periodoocupacion(id_inmueble, fechainicio, fechabaja, motivobaja)
	VALUES (NEW.id_inmueble, NEW.fechaContrato, NULL, NULL);
	RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.sp_crear_periodo_ocupacion();
       public          postgres    false                       1255    18753 7   sp_es_igual_mesaño(public."mesaño", public."mesaño")    FUNCTION     ?   CREATE FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño) = SP_convertir_mesaño_date(comparar);

END;
$$;
 e   DROP FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño");
       public          postgres    false    687    687                       1255    18744 7   sp_es_mayor_mesaño(public."mesaño", public."mesaño")    FUNCTION     ?   CREATE FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño)>SP_convertir_mesaño_date(comparar);

END;
$$;
 e   DROP FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño");
       public          postgres    false    687    687                       1255    18721 =   sp_esta_en_rango_contrato(integer, integer, public."mesaño")    FUNCTION     8  CREATE FUNCTION public.sp_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
 u   DROP FUNCTION public.sp_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño");
       public          postgres    false    687            ?            1255    18658 0   sp_esta_paga(integer, integer, public."mesaño")    FUNCTION     ?  CREATE FUNCTION public.sp_esta_paga(v_cliente integer, v_inmueble integer, "v_mesaño" public."mesaño") RETURNS character varying
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
 h   DROP FUNCTION public.sp_esta_paga(v_cliente integer, v_inmueble integer, "v_mesaño" public."mesaño");
       public          postgres    false    687                       1255    18752 5   sp_esta_paga_bool(integer, integer, public."mesaño")    FUNCTION     ;  CREATE FUNCTION public.sp_esta_paga_bool(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
 m   DROP FUNCTION public.sp_esta_paga_bool(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño");
       public          postgres    false    687                       1255    18714 3   sp_existe_cuota(integer, integer, public."mesaño")    FUNCTION     X  CREATE FUNCTION public.sp_existe_cuota(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
 k   DROP FUNCTION public.sp_existe_cuota(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño");
       public          postgres    false    687            ?            1255    18668    sp_modificar_nombre_cliente()    FUNCTION     %  CREATE FUNCTION public.sp_modificar_nombre_cliente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	UPDATE Personas SET nombreCompleto = new.nombreCompleto
	FROM Clientes
	WHERE clientes.id_persona = personas.id_persona and clientes.id_cliente = old.id_cliente;

RETURN new;
END;
$$;
 4   DROP FUNCTION public.sp_modificar_nombre_cliente();
       public          postgres    false                       1255    18710    sp_obtener_importe_cuota()    FUNCTION     ?  CREATE FUNCTION public.sp_obtener_importe_cuota() RETURNS trigger
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
 1   DROP FUNCTION public.sp_obtener_importe_cuota();
       public          postgres    false                       1255    18704 <   sp_obtener_importe_cuota(integer, integer, public."mesaño")    FUNCTION     ?  CREATE FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño") RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE v_importe double precision = 0;
BEGIN
	select importe INTO v_importe from precioAlquiler 
	where id_inmueble =1000
	and id_cliente = 1
	and SP_es_mayor_mesaño(fechaContable, SP_convertir_date_mesaño(fechaDefinicion)) 
	order by fechadefinicion DESC
	LIMIT 1;
	
	RETURN v_importe;
END;
$$;
 v   DROP FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño");
       public          postgres    false    687            ?            1255    18659 H   sp_obtener_importe_por_tipo(integer, integer, public."mesaño", integer)    FUNCTION       CREATE FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer) RETURNS double precision
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
 ?   DROP FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer);
       public          postgres    false    687                       1255    18759 6   sp_obtener_mesaño_contrato(integer, integer, integer)    FUNCTION       CREATE FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer) RETURNS public."mesaño"
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
	raise notice 'error %', v_rango_superior;
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
 h   DROP FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer);
       public          postgres    false    687            
           1255    18715 6   sp_operacion_resta_mes_año(public."mesaño", integer)    FUNCTION     u  CREATE FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) - (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;
 c   DROP FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer);
       public          postgres    false    687    687                       1255    18716 5   sp_operacion_suma_mes_año(public."mesaño", integer)    FUNCTION     t  CREATE FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) + (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;
 b   DROP FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer);
       public          postgres    false    687    687            ?            1259    18372    anuncios    TABLE     ?   CREATE TABLE public.anuncios (
    id_anuncio integer NOT NULL,
    titulo character varying(50) NOT NULL,
    texto character varying(100) NOT NULL,
    fecha date NOT NULL,
    vigencia integer NOT NULL,
    tipo_vigencia character(1) NOT NULL
);
    DROP TABLE public.anuncios;
       public         heap    postgres    false            ?            1259    18420    clientes    TABLE     c   CREATE TABLE public.clientes (
    id_cliente integer NOT NULL,
    id_persona integer NOT NULL
);
    DROP TABLE public.clientes;
       public         heap    postgres    false            ?            1259    18507    contratoalquiler    TABLE     n  CREATE TABLE public.contratoalquiler (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    fechacontrato date DEFAULT CURRENT_DATE NOT NULL,
    id_estado integer DEFAULT 1 NOT NULL,
    periodo_vigencia integer NOT NULL,
    vencimiento_cuota integer DEFAULT 10 NOT NULL,
    id_finalidad integer,
    precio_inicial double precision NOT NULL
);
 $   DROP TABLE public.contratoalquiler;
       public         heap    postgres    false            ?            1259    18502    contratos_estados    TABLE     q   CREATE TABLE public.contratos_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50)
);
 %   DROP TABLE public.contratos_estados;
       public         heap    postgres    false            ?            1259    18497    contratos_finalidades    TABLE     ?   CREATE TABLE public.contratos_finalidades (
    id_finalidad integer NOT NULL,
    descripcion character varying(50) NOT NULL
);
 )   DROP TABLE public.contratos_finalidades;
       public         heap    postgres    false            ?            1259    18602    cuotas    TABLE     ?   CREATE TABLE public.cuotas (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    id_tipo_operacion integer DEFAULT 1 NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    importe double precision,
    fechavencimiento date NOT NULL
);
    DROP TABLE public.cuotas;
       public         heap    postgres    false    687            ?            1259    18407    personas    TABLE     ?   CREATE TABLE public.personas (
    id_persona integer NOT NULL,
    dni public.dni NOT NULL,
    fechanacimiento date,
    fechainscripcion date,
    nombrecompleto character varying(50),
    id_direccion integer
);
    DROP TABLE public.personas;
       public         heap    postgres    false    683            ?            1259    18342    tipo_operacion_contable    TABLE     ?   CREATE TABLE public.tipo_operacion_contable (
    id_tipo_operacion integer NOT NULL,
    descripcion character varying(50),
    debito boolean
);
 +   DROP TABLE public.tipo_operacion_contable;
       public         heap    postgres    false            ?            1259    18683    cuota_cta_cte    VIEW     /  CREATE VIEW public.cuota_cta_cte AS
 SELECT cuotas.id_cliente,
    personas.nombrecompleto,
    cuotas."mesaño",
    tipo_operacion_contable.descripcion,
    public.sp_obtener_importe_por_tipo(cuotas.id_inmueble, cuotas.id_cliente, cuotas."mesaño", 1) AS importe
   FROM (((public.cuotas
     JOIN public.tipo_operacion_contable ON ((cuotas.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion)))
     JOIN public.clientes ON ((clientes.id_cliente = cuotas.id_cliente)))
     JOIN public.personas ON ((clientes.id_persona = personas.id_persona)));
     DROP VIEW public.cuota_cta_cte;
       public          postgres    false    200    238    222    222    222    222    211    211    210    210    200    687            ?            1259    18578    pagos    TABLE       CREATE TABLE public.pagos (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    id_tipo_operacion integer DEFAULT 2 NOT NULL,
    importecuota double precision NOT NULL,
    fechapago date DEFAULT CURRENT_DATE NOT NULL
);
    DROP TABLE public.pagos;
       public         heap    postgres    false    687            ?            1259    18688    pago_cta_cte    VIEW     &  CREATE VIEW public.pago_cta_cte AS
 SELECT pagos.id_cliente,
    personas.nombrecompleto,
    pagos."mesaño",
    tipo_operacion_contable.descripcion,
    public.sp_obtener_importe_por_tipo(pagos.id_inmueble, pagos.id_cliente, pagos."mesaño", 2) AS importe
   FROM (((public.pagos
     JOIN public.tipo_operacion_contable ON ((pagos.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion)))
     JOIN public.clientes ON ((clientes.id_cliente = pagos.id_cliente)))
     JOIN public.personas ON ((clientes.id_persona = personas.id_persona)));
    DROP VIEW public.pago_cta_cte;
       public          postgres    false    221    238    221    221    221    211    211    210    210    200    200    687            ?            1259    18625    recargos    TABLE       CREATE TABLE public.recargos (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    id_tipo_operacion integer DEFAULT 3 NOT NULL,
    importerecargo double precision NOT NULL,
    diasvencidos integer DEFAULT 0
);
    DROP TABLE public.recargos;
       public         heap    postgres    false    687            ?            1259    18693    recargo_cta_cte    VIEW     A  CREATE VIEW public.recargo_cta_cte AS
 SELECT recargos.id_cliente,
    personas.nombrecompleto,
    recargos."mesaño",
    tipo_operacion_contable.descripcion,
    public.sp_obtener_importe_por_tipo(recargos.id_inmueble, recargos.id_cliente, recargos."mesaño", 3) AS importe
   FROM (((public.recargos
     JOIN public.tipo_operacion_contable ON ((recargos.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion)))
     JOIN public.clientes ON ((clientes.id_cliente = recargos.id_cliente)))
     JOIN public.personas ON ((clientes.id_persona = personas.id_persona)));
 "   DROP VIEW public.recargo_cta_cte;
       public          postgres    false    210    238    223    223    223    223    211    211    210    200    200    687            ?            1259    18698    cta_cte_cliente    VIEW     ?  CREATE VIEW public.cta_cte_cliente AS
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
 "   DROP VIEW public.cta_cte_cliente;
       public          postgres    false    228    228    228    228    228    230    230    230    230    230    229    229    229    229    229    687            ?            1259    18362    direcciones    TABLE       CREATE TABLE public.direcciones (
    id_direccion integer NOT NULL,
    id_localidad integer NOT NULL,
    calle character varying(50) NOT NULL,
    numero integer NOT NULL,
    departamento character varying(10),
    piso integer,
    observaciones character varying(100)
);
    DROP TABLE public.direcciones;
       public         heap    postgres    false            ?            1259    18352    localidades    TABLE     ?   CREATE TABLE public.localidades (
    id_localidad integer NOT NULL,
    nombre character varying(50) NOT NULL,
    codigo_postal integer,
    id_provincia integer NOT NULL
);
    DROP TABLE public.localidades;
       public         heap    postgres    false            ?            1259    18347    localizaciones    TABLE     {   CREATE TABLE public.localizaciones (
    id_localizacion integer NOT NULL,
    provincia character varying(50) NOT NULL
);
 "   DROP TABLE public.localizaciones;
       public         heap    postgres    false            ?            1259    18650    direccion_completa    VIEW     ?  CREATE VIEW public.direccion_completa AS
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
 %   DROP VIEW public.direccion_completa;
       public          postgres    false    203    203    203    203    203    203    201    201    202    202    202    202    203            ?            1259    18377    divisas    TABLE     ?   CREATE TABLE public.divisas (
    id_divisa integer NOT NULL,
    acronimo character varying(3) NOT NULL,
    descripcion character varying(50) NOT NULL
);
    DROP TABLE public.divisas;
       public         heap    postgres    false            ?            1259    18432    dueños    TABLE     e   CREATE TABLE public."dueños" (
    "id_dueño" integer NOT NULL,
    id_persona integer NOT NULL
);
    DROP TABLE public."dueños";
       public         heap    postgres    false            ?            1259    18540    garante    TABLE     ?   CREATE TABLE public.garante (
    dni public.dni NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    nombre character varying(50) NOT NULL,
    fechanacimiento date NOT NULL,
    id_tipogarantia integer NOT NULL
);
    DROP TABLE public.garante;
       public         heap    postgres    false    683            ?            1259    18444 	   inmuebles    TABLE     ?  CREATE TABLE public.inmuebles (
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
    DROP TABLE public.inmuebles;
       public         heap    postgres    false            ?            1259    18486    periodoocupacion    TABLE     ?   CREATE TABLE public.periodoocupacion (
    id_periodo integer NOT NULL,
    id_inmueble integer NOT NULL,
    fechainicio date NOT NULL,
    fechabaja date,
    motivobaja character varying(100)
);
 $   DROP TABLE public.periodoocupacion;
       public         heap    postgres    false            ?            1259    18382    precios    TABLE     ?   CREATE TABLE public.precios (
    id_precio integer NOT NULL,
    id_divisa integer NOT NULL,
    monto double precision NOT NULL
);
    DROP TABLE public.precios;
       public         heap    postgres    false            ?            1259    18654    precio_inmueble    VIEW     ?   CREATE VIEW public.precio_inmueble AS
 SELECT p.id_precio,
    p.monto,
    d.acronimo
   FROM (public.precios p
     JOIN public.divisas d ON ((p.id_divisa = d.id_divisa)));
 "   DROP VIEW public.precio_inmueble;
       public          postgres    false    205    205    206    206    206            ?            1259    18392    tipoinmueble    TABLE     s   CREATE TABLE public.tipoinmueble (
    id_tipo integer NOT NULL,
    descripcion character varying(50) NOT NULL
);
     DROP TABLE public.tipoinmueble;
       public         heap    postgres    false            ?            1259    18397    tipooperacion    TABLE     y   CREATE TABLE public.tipooperacion (
    id_operacion integer NOT NULL,
    descripcion character varying(50) NOT NULL
);
 !   DROP TABLE public.tipooperacion;
       public         heap    postgres    false            ?            1259    18673    info_inmuebles_completa    VIEW     m	  CREATE VIEW public.info_inmuebles_completa AS
 SELECT inmuebles.id_inmueble,
    tipo.descripcion,
    anu.titulo,
    pre.monto,
    pre.acronimo,
    per.nombrecompleto,
        CASE
            WHEN (1 = ( SELECT tipooperacion.id_operacion
               FROM public.tipooperacion
              WHERE ((inmuebles.id_inmueble = inmuebles.id_inmueble) AND (tipooperacion.id_operacion = 1)))) THEN 'SI'::text
            ELSE 'NO'::text
        END AS se_vende,
        CASE
            WHEN (2 = ( SELECT tipooperacion.id_operacion
               FROM public.tipooperacion
              WHERE ((inmuebles.id_inmueble = inmuebles.id_inmueble) AND (tipooperacion.id_operacion = 2)))) THEN 'SI'::text
            ELSE 'NO'::text
        END AS se_alquila,
        CASE
            WHEN ((2 = ( SELECT tipooperacion.id_operacion
               FROM public.tipooperacion
              WHERE ((inmuebles.id_inmueble = inmuebles.id_inmueble) AND (tipooperacion.id_operacion = 2)))) AND (( SELECT periodoocupacion.fechabaja
               FROM public.periodoocupacion) <> NULL::date)) THEN 'OCUPADO'::text
            ELSE 'LIBRE'::text
        END AS estado_alquiler,
        CASE
            WHEN ((2 = ( SELECT tipooperacion.id_operacion
               FROM public.tipooperacion
              WHERE ((inmuebles.id_inmueble = inmuebles.id_inmueble) AND (tipooperacion.id_operacion = 2)))) AND (( SELECT periodoocupacion.fechabaja
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
 *   DROP VIEW public.info_inmuebles_completa;
       public          postgres    false    204    204    207    207    208    210    210    212    212    213    213    213    213    213    213    215    215    224    224    224    224    224    224    224    224    224    225    225    225            ?            1259    18678    informacion_cuotas    VIEW     ?  CREATE VIEW public.informacion_cuotas AS
 SELECT per.id_persona,
    per.dni,
    per.fechanacimiento,
    per.fechainscripcion,
    per.nombrecompleto,
    per.id_direccion,
    cuo."mesaño",
    public.sp_esta_paga(ca.id_cliente, ca.id_inmueble, cuo."mesaño") AS sp_esta_paga
   FROM ((((public.contratoalquiler ca
     JOIN public.info_inmuebles_completa iic ON ((iic.id_inmueble = ca.id_inmueble)))
     JOIN public.clientes cli ON ((cli.id_cliente = ca.id_cliente)))
     JOIN public.personas per ON ((per.id_persona = cli.id_persona)))
     JOIN public.cuotas cuo ON (((cuo.id_inmueble = iic.id_inmueble) AND (cuo.id_cliente = ca.id_cliente))))
  WHERE (ca.id_estado = 1);
 %   DROP VIEW public.informacion_cuotas;
       public          postgres    false    222    222    218    237    226    211    211    210    210    210    210    210    210    218    218    222    683    687            ?            1259    18402    inmuebles_estados    TABLE     z   CREATE TABLE public.inmuebles_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50) NOT NULL
);
 %   DROP TABLE public.inmuebles_estados;
       public         heap    postgres    false            ?            1259    18775    inmuebles_operaciones    TABLE     s   CREATE TABLE public.inmuebles_operaciones (
    id_inmueble integer NOT NULL,
    id_operacion integer NOT NULL
);
 )   DROP TABLE public.inmuebles_operaciones;
       public         heap    postgres    false            ?            1259    18770    operaciones    TABLE     w   CREATE TABLE public.operaciones (
    id_operacion integer NOT NULL,
    descripcion character varying(50) NOT NULL
);
    DROP TABLE public.operaciones;
       public         heap    postgres    false            ?            1259    18484    periodoocupacion_id_periodo_seq    SEQUENCE     ?   CREATE SEQUENCE public.periodoocupacion_id_periodo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.periodoocupacion_id_periodo_seq;
       public          postgres    false    215            ?           0    0    periodoocupacion_id_periodo_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.periodoocupacion_id_periodo_seq OWNED BY public.periodoocupacion.id_periodo;
          public          postgres    false    214            ?            1259    18727    precioalquiler    TABLE     ?   CREATE TABLE public.precioalquiler (
    id_precioalquiler integer NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    importe double precision NOT NULL,
    fechadefinicion date NOT NULL
);
 "   DROP TABLE public.precioalquiler;
       public         heap    postgres    false            ?            1259    18725 $   precioalquiler_id_precioalquiler_seq    SEQUENCE     ?   CREATE SEQUENCE public.precioalquiler_id_precioalquiler_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.precioalquiler_id_precioalquiler_seq;
       public          postgres    false    233            ?           0    0 $   precioalquiler_id_precioalquiler_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.precioalquiler_id_precioalquiler_seq OWNED BY public.precioalquiler.id_precioalquiler;
          public          postgres    false    232            ?            1259    18535    tipogarantia    TABLE     w   CREATE TABLE public.tipogarantia (
    id_garantia integer NOT NULL,
    descripcion character varying(50) NOT NULL
);
     DROP TABLE public.tipogarantia;
       public         heap    postgres    false            ?           2604    18489    periodoocupacion id_periodo    DEFAULT     ?   ALTER TABLE ONLY public.periodoocupacion ALTER COLUMN id_periodo SET DEFAULT nextval('public.periodoocupacion_id_periodo_seq'::regclass);
 J   ALTER TABLE public.periodoocupacion ALTER COLUMN id_periodo DROP DEFAULT;
       public          postgres    false    215    214    215            ?           2604    18730     precioalquiler id_precioalquiler    DEFAULT     ?   ALTER TABLE ONLY public.precioalquiler ALTER COLUMN id_precioalquiler SET DEFAULT nextval('public.precioalquiler_id_precioalquiler_seq'::regclass);
 O   ALTER TABLE public.precioalquiler ALTER COLUMN id_precioalquiler DROP DEFAULT;
       public          postgres    false    232    233    233            ?          0    18372    anuncios 
   TABLE DATA                 public          postgres    false    204   s!      ?          0    18420    clientes 
   TABLE DATA                 public          postgres    false    211   `"      ?          0    18507    contratoalquiler 
   TABLE DATA                 public          postgres    false    218   ?"      ?          0    18502    contratos_estados 
   TABLE DATA                 public          postgres    false    217   ?"      ?          0    18497    contratos_finalidades 
   TABLE DATA                 public          postgres    false    216   ?#      ?          0    18602    cuotas 
   TABLE DATA                 public          postgres    false    222    $      ?          0    18362    direcciones 
   TABLE DATA                 public          postgres    false    203   :$      ?          0    18377    divisas 
   TABLE DATA                 public          postgres    false    205   (%      ?          0    18432    dueños 
   TABLE DATA                 public          postgres    false    212   ?%      ?          0    18540    garante 
   TABLE DATA                 public          postgres    false    220   !&      ?          0    18444 	   inmuebles 
   TABLE DATA                 public          postgres    false    213   ;&      ?          0    18402    inmuebles_estados 
   TABLE DATA                 public          postgres    false    209   '      ?          0    18775    inmuebles_operaciones 
   TABLE DATA                 public          postgres    false    235   ?'      ?          0    18352    localidades 
   TABLE DATA                 public          postgres    false    202   (      ?          0    18347    localizaciones 
   TABLE DATA                 public          postgres    false    201   ?(      ?          0    18770    operaciones 
   TABLE DATA                 public          postgres    false    234   ?)      ?          0    18578    pagos 
   TABLE DATA                 public          postgres    false    221   -*      ?          0    18486    periodoocupacion 
   TABLE DATA                 public          postgres    false    215   G*      ?          0    18407    personas 
   TABLE DATA                 public          postgres    false    210   a*      ?          0    18727    precioalquiler 
   TABLE DATA                 public          postgres    false    233   j+      ?          0    18382    precios 
   TABLE DATA                 public          postgres    false    206   ?+      ?          0    18625    recargos 
   TABLE DATA                 public          postgres    false    223    ,      ?          0    18342    tipo_operacion_contable 
   TABLE DATA                 public          postgres    false    200   ,      ?          0    18535    tipogarantia 
   TABLE DATA                 public          postgres    false    219   ?,      ?          0    18392    tipoinmueble 
   TABLE DATA                 public          postgres    false    207   6-      ?          0    18397    tipooperacion 
   TABLE DATA                 public          postgres    false    208   ?-      ?           0    0    periodoocupacion_id_periodo_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.periodoocupacion_id_periodo_seq', 12, true);
          public          postgres    false    214            ?           0    0 $   precioalquiler_id_precioalquiler_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.precioalquiler_id_precioalquiler_seq', 6, true);
          public          postgres    false    232            ?           2606    18376    anuncios anuncios_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.anuncios
    ADD CONSTRAINT anuncios_pkey PRIMARY KEY (id_anuncio);
 @   ALTER TABLE ONLY public.anuncios DROP CONSTRAINT anuncios_pkey;
       public            postgres    false    204            ?           2606    18426     clientes clientes_id_cliente_key 
   CONSTRAINT     a   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_cliente_key UNIQUE (id_cliente);
 J   ALTER TABLE ONLY public.clientes DROP CONSTRAINT clientes_id_cliente_key;
       public            postgres    false    211            ?           2606    18424    clientes clientes_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id_cliente, id_persona);
 @   ALTER TABLE ONLY public.clientes DROP CONSTRAINT clientes_pkey;
       public            postgres    false    211    211                        2606    18514 &   contratoalquiler contratoalquiler_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente);
 P   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_pkey;
       public            postgres    false    218    218            ?           2606    18506 (   contratos_estados contratos_estados_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.contratos_estados
    ADD CONSTRAINT contratos_estados_pkey PRIMARY KEY (id_estado);
 R   ALTER TABLE ONLY public.contratos_estados DROP CONSTRAINT contratos_estados_pkey;
       public            postgres    false    217            ?           2606    18501 0   contratos_finalidades contratos_finalidades_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.contratos_finalidades
    ADD CONSTRAINT contratos_finalidades_pkey PRIMARY KEY (id_finalidad);
 Z   ALTER TABLE ONLY public.contratos_finalidades DROP CONSTRAINT contratos_finalidades_pkey;
       public            postgres    false    216                       2606    18609    cuotas cuotas_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 <   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_pkey;
       public            postgres    false    222    222    222            ?           2606    18366    direcciones direcciones_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_pkey PRIMARY KEY (id_direccion);
 F   ALTER TABLE ONLY public.direcciones DROP CONSTRAINT direcciones_pkey;
       public            postgres    false    203            ?           2606    18381    divisas divisas_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.divisas
    ADD CONSTRAINT divisas_pkey PRIMARY KEY (id_divisa);
 >   ALTER TABLE ONLY public.divisas DROP CONSTRAINT divisas_pkey;
       public            postgres    false    205            ?           2606    18438    dueños dueños_id_dueño_key 
   CONSTRAINT     c   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_id_dueño_key" UNIQUE ("id_dueño");
 K   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "dueños_id_dueño_key";
       public            postgres    false    212            ?           2606    18436    dueños dueños_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_pkey" PRIMARY KEY ("id_dueño", id_persona);
 B   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "dueños_pkey";
       public            postgres    false    212    212                       2606    18547    garante garante_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT garante_pkey PRIMARY KEY (id_inmueble, id_cliente, dni);
 >   ALTER TABLE ONLY public.garante DROP CONSTRAINT garante_pkey;
       public            postgres    false    220    220    220            ?           2606    18406 (   inmuebles_estados inmuebles_estados_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.inmuebles_estados
    ADD CONSTRAINT inmuebles_estados_pkey PRIMARY KEY (id_estado);
 R   ALTER TABLE ONLY public.inmuebles_estados DROP CONSTRAINT inmuebles_estados_pkey;
       public            postgres    false    209                       2606    18779 0   inmuebles_operaciones inmuebles_operaciones_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_pkey PRIMARY KEY (id_inmueble, id_operacion);
 Z   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_pkey;
       public            postgres    false    235    235            ?           2606    18448    inmuebles inmuebles_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_pkey PRIMARY KEY (id_inmueble);
 B   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_pkey;
       public            postgres    false    213            ?           2606    18356    localidades localidades_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_pkey PRIMARY KEY (id_localidad);
 F   ALTER TABLE ONLY public.localidades DROP CONSTRAINT localidades_pkey;
       public            postgres    false    202            ?           2606    18351 "   localizaciones localizaciones_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.localizaciones
    ADD CONSTRAINT localizaciones_pkey PRIMARY KEY (id_localizacion);
 L   ALTER TABLE ONLY public.localizaciones DROP CONSTRAINT localizaciones_pkey;
       public            postgres    false    201                       2606    18774    operaciones operaciones_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_pkey PRIMARY KEY (id_operacion);
 F   ALTER TABLE ONLY public.operaciones DROP CONSTRAINT operaciones_pkey;
       public            postgres    false    234                       2606    18586    pagos pagos_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 :   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_pkey;
       public            postgres    false    221    221    221            ?           2606    18491 &   periodoocupacion periodoocupacion_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_pkey PRIMARY KEY (id_periodo);
 P   ALTER TABLE ONLY public.periodoocupacion DROP CONSTRAINT periodoocupacion_pkey;
       public            postgres    false    215            ?           2606    18414    personas personas_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (id_persona);
 @   ALTER TABLE ONLY public.personas DROP CONSTRAINT personas_pkey;
       public            postgres    false    210                       2606    18732 "   precioalquiler precioalquiler_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente, id_precioalquiler);
 L   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_pkey;
       public            postgres    false    233    233    233            ?           2606    18386    precios precios_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_pkey PRIMARY KEY (id_precio);
 >   ALTER TABLE ONLY public.precios DROP CONSTRAINT precios_pkey;
       public            postgres    false    206            
           2606    18633    recargos recargos_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 @   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_pkey;
       public            postgres    false    223    223    223            ?           2606    18346 4   tipo_operacion_contable tipo_operacion_contable_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.tipo_operacion_contable
    ADD CONSTRAINT tipo_operacion_contable_pkey PRIMARY KEY (id_tipo_operacion);
 ^   ALTER TABLE ONLY public.tipo_operacion_contable DROP CONSTRAINT tipo_operacion_contable_pkey;
       public            postgres    false    200                       2606    18539    tipogarantia tipogarantia_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.tipogarantia
    ADD CONSTRAINT tipogarantia_pkey PRIMARY KEY (id_garantia);
 H   ALTER TABLE ONLY public.tipogarantia DROP CONSTRAINT tipogarantia_pkey;
       public            postgres    false    219            ?           2606    18396    tipoinmueble tipoinmueble_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.tipoinmueble
    ADD CONSTRAINT tipoinmueble_pkey PRIMARY KEY (id_tipo);
 H   ALTER TABLE ONLY public.tipoinmueble DROP CONSTRAINT tipoinmueble_pkey;
       public            postgres    false    207            ?           2606    18401     tipooperacion tipooperacion_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.tipooperacion
    ADD CONSTRAINT tipooperacion_pkey PRIMARY KEY (id_operacion);
 J   ALTER TABLE ONLY public.tipooperacion DROP CONSTRAINT tipooperacion_pkey;
       public            postgres    false    208            5           2620    18672 0   contratoalquiler tg_actualizar_periodo_ocupacion    TRIGGER     ?   CREATE TRIGGER tg_actualizar_periodo_ocupacion BEFORE UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_periodo_ocupacion();
 I   DROP TRIGGER tg_actualizar_periodo_ocupacion ON public.contratoalquiler;
       public          postgres    false    257    218            7           2620    18746 #   cuotas tg_agregar_fecha_vencimiento    TRIGGER     ?   CREATE TRIGGER tg_agregar_fecha_vencimiento BEFORE INSERT OR UPDATE ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_agregar_fecha_vencimiento();
 <   DROP TRIGGER tg_agregar_fecha_vencimiento ON public.cuotas;
       public          postgres    false    222    265            2           2620    18662 #   inmuebles tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 <   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles;
       public          postgres    false    240    213            3           2620    18665 $   inmuebles tg_autoincremental_control    TRIGGER     ?   CREATE TRIGGER tg_autoincremental_control BEFORE INSERT ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_autoincremental_control();
 =   DROP TRIGGER tg_autoincremental_control ON public.inmuebles;
       public          postgres    false    213    241            4           2620    18670 +   contratoalquiler tg_crear_periodo_ocupacion    TRIGGER     ?   CREATE TRIGGER tg_crear_periodo_ocupacion AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_periodo_ocupacion();
 D   DROP TRIGGER tg_crear_periodo_ocupacion ON public.contratoalquiler;
       public          postgres    false    256    218            6           2620    18711    cuotas tg_obtener_importe_cuota    TRIGGER     ?   CREATE TRIGGER tg_obtener_importe_cuota BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_obtener_importe_cuota();
 8   DROP TRIGGER tg_obtener_importe_cuota ON public.cuotas;
       public          postgres    false    222    261            !           2606    18530 0   contratoalquiler contratoalquiler_id_estado_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.contratos_estados(id_estado);
 Z   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_id_estado_fkey;
       public          postgres    false    3070    218    217                        2606    18525 3   contratoalquiler contratoalquiler_id_finalidad_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_finalidad_fkey FOREIGN KEY (id_finalidad) REFERENCES public.contratos_finalidades(id_finalidad);
 ]   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_id_finalidad_fkey;
       public          postgres    false    218    3068    216            )           2606    18615    cuotas cuotas_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_cliente_fkey;
       public          postgres    false    3056    211    222            (           2606    18610    cuotas cuotas_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_inmueble_fkey;
       public          postgres    false    222    3064    213            *           2606    18620 $   cuotas cuotas_id_tipo_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 N   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_tipo_operacion_fkey;
       public          postgres    false    222    3034    200                       2606    18367 )   direcciones direcciones_id_localidad_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);
 S   ALTER TABLE ONLY public.direcciones DROP CONSTRAINT direcciones_id_localidad_fkey;
       public          postgres    false    3038    202    203                       2606    18427    clientes fk_cliente_persona    FK CONSTRAINT     ?   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.clientes DROP CONSTRAINT fk_cliente_persona;
       public          postgres    false    210    3054    211                       2606    18520 $   contratoalquiler fk_contrato_cliente    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT fk_contrato_cliente;
       public          postgres    false    211    218    3056                       2606    18515 %   contratoalquiler fk_contrato_inmueble    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT fk_contrato_inmueble;
       public          postgres    false    218    213    3064                       2606    18415    personas fk_direccion    FK CONSTRAINT     ?   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_direccion FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);
 ?   ALTER TABLE ONLY public.personas DROP CONSTRAINT fk_direccion;
       public          postgres    false    3040    210    203                       2606    18439    dueños fk_dueÑo_persona    FK CONSTRAINT     ?   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "fk_dueÑo_persona" FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "fk_dueÑo_persona";
       public          postgres    false    3054    210    212            #           2606    18553    garante fk_garante_cliente    FK CONSTRAINT     ?   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_cliente;
       public          postgres    false    3056    220    211            "           2606    18548    garante fk_garante_inmueble    FK CONSTRAINT     ?   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_inmueble;
       public          postgres    false    3064    213    220            $           2606    18558    garante fk_garante_tipo    FK CONSTRAINT     ?   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_tipo FOREIGN KEY (id_tipogarantia) REFERENCES public.tipogarantia(id_garantia) ON DELETE CASCADE;
 A   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_tipo;
       public          postgres    false    220    219    3074                       2606    18469 #   inmuebles inmuebles_id_anuncio_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_anuncio_fkey FOREIGN KEY (id_anuncio) REFERENCES public.anuncios(id_anuncio);
 M   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_anuncio_fkey;
       public          postgres    false    213    204    3042                       2606    18464 %   inmuebles inmuebles_id_direccion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);
 O   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_direccion_fkey;
       public          postgres    false    3040    203    213                       2606    18479 "   inmuebles inmuebles_id_dueño_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT "inmuebles_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");
 N   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT "inmuebles_id_dueño_fkey";
       public          postgres    false    3060    213    212                       2606    18459 +   inmuebles inmuebles_id_estado_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_estado_inmueble_fkey FOREIGN KEY (id_estado_inmueble) REFERENCES public.inmuebles_estados(id_estado);
 U   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_estado_inmueble_fkey;
       public          postgres    false    3052    213    209                       2606    18474 "   inmuebles inmuebles_id_precio_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_precio_fkey FOREIGN KEY (id_precio) REFERENCES public.precios(id_precio);
 L   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_precio_fkey;
       public          postgres    false    3046    206    213                       2606    18449 (   inmuebles inmuebles_id_tipoinmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_tipoinmueble_fkey FOREIGN KEY (id_tipoinmueble) REFERENCES public.tipoinmueble(id_tipo);
 R   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_tipoinmueble_fkey;
       public          postgres    false    3048    207    213            0           2606    18780 <   inmuebles_operaciones inmuebles_operaciones_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);
 f   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_id_inmueble_fkey;
       public          postgres    false    3064    213    235            1           2606    18785 =   inmuebles_operaciones inmuebles_operaciones_id_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_operacion_fkey FOREIGN KEY (id_operacion) REFERENCES public.operaciones(id_operacion);
 g   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_id_operacion_fkey;
       public          postgres    false    3086    234    235                       2606    18357 )   localidades localidades_id_provincia_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_id_provincia_fkey FOREIGN KEY (id_provincia) REFERENCES public.localizaciones(id_localizacion);
 S   ALTER TABLE ONLY public.localidades DROP CONSTRAINT localidades_id_provincia_fkey;
       public          postgres    false    201    202    3036            &           2606    18592    pagos pagos_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_cliente_fkey;
       public          postgres    false    3056    211    221            %           2606    18587    pagos pagos_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_inmueble_fkey;
       public          postgres    false    3064    221    213            '           2606    18597 "   pagos pagos_id_tipo_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 L   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_tipo_operacion_fkey;
       public          postgres    false    200    3034    221                       2606    18492 2   periodoocupacion periodoocupacion_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);
 \   ALTER TABLE ONLY public.periodoocupacion DROP CONSTRAINT periodoocupacion_id_inmueble_fkey;
       public          postgres    false    213    3064    215            /           2606    18738 -   precioalquiler precioalquiler_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 W   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_id_cliente_fkey;
       public          postgres    false    211    3056    233            .           2606    18733 .   precioalquiler precioalquiler_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_id_inmueble_fkey;
       public          postgres    false    233    213    3064                       2606    18387    precios precios_id_divisa_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_id_divisa_fkey FOREIGN KEY (id_divisa) REFERENCES public.divisas(id_divisa);
 H   ALTER TABLE ONLY public.precios DROP CONSTRAINT precios_id_divisa_fkey;
       public          postgres    false    205    3044    206            ,           2606    18639 !   recargos recargos_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_cliente_fkey;
       public          postgres    false    211    223    3056            +           2606    18634 "   recargos recargos_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_inmueble_fkey;
       public          postgres    false    3064    213    223            -           2606    18644 (   recargos recargos_id_tipo_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 R   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_tipo_operacion_fkey;
       public          postgres    false    3034    223    200            ?   ?   x???K
?0@?=??Z??$U\???P?m%??FBR5??S???jx3?<^??*Y?!??P?{???0?ɕ?B???Bp?պ???p?2??n? ?.?{ew??v?m?,+?0W??TX???)g?2?)RDq?????X??C}????+g?na;n?"???-?Ri2?Ş^?2?2N???G	儏???|?+0????҂??:=?H]<?{?8??      ?   Y   x???v
Q???W((M??L?K??L?+I-V??L??rt???Ԣ???DM?0G?P?`CCMk.OJ1bH?!?@C???pq ?NAs      ?   
   x???          ?   ?   x???v
Q???W((M??L?K??+)J,?/?O-.IL?/V??L??uRR???2?3??4?}B]?4u??K2???5??<?b??L?̼Ĝ?*?"??k4?)1+Q!Q? 5%3%?,G!9'35?$?z֘`?&?4??F?g?? ??~?      ?   ?   x???v
Q???W((M??L?K??+)J,?/?O??K??LILI-V??LA?u?B?E?ə?y?
a?>???
?:
?a?ɉ ??buMk.Ojo4???? l?BIjnA~Qbխ1Z㗚???L????AL?? ?Ձ~      ?   
   x???          ?   ?   x?Ő=k1???ڜ?	ɕ6C?K???pC???-???ۗ???JB;e??W?Ԛ??k???0????SB??#f????k?;?[?A???x??<6{?XD?%s?1]?}??Mw??`?? ?>?BY,????1+????s躿????4?N????}
w}?>?+???]???,????~?????y?/????{????????Tb*?P#?pý?V?/???      ?   ?   x???v
Q???W((M??L?K?,?,N,V??L???u????2s?uRR???2?3??4?}B]?4u?C?]ԁ?K~NbQj???5?'U?6?2; ?8??&?t??ZZDM?M?FzD?L?L̓? ??s      ?   K   x???v
Q???W((M??L?SJ)M=?1?XIAC)3%?S?Q ?R????5?}B]?4?t5???? ?b?      ?   
   x???          ?   ?   x?ݑ?
?0??>??R?T.???C??T?k-??Ih??|1?VGG?????n?qi?OvH???=עy??\sCQ?o"??Z}?i?J}U??e)?쨐V:??v????]غ7?[c??/_|U???֛c??!ED?k⮻bB?L{i?	]f?h??)?x????8?/&?p?
?_?e^?u??(?k]?R?????;? xa???      ?      x???v
Q???W((M??L????-MM?I-?O-.IL?/V??L??uRR???2?3??4?}B]?4u??Js?*?5??<?b??P??????L?F??krlNai&u?k46,5/%b( ??sI      ?   b   x???v
Q???W((M??L????-MM?I-??/H-JL???K-V??L????( 9pIM?0G?P?`CCMk.O*kDc??5????c?? ?s       ?   ?   x????
?0??}?bvZҋU???B?K?ڭL? 1Su?ӛv!? u9p??????t??p>B??55?j?(??1???`?^[%?aI7?????Qk?E?!?Z?.?Ʊ?Q???q	??p?Ñ?'?l%ם?-z3?L??'Gl??B?M?E??Hk?5Z?
|??8?x?恰U]qԣ?aљGO???͜{?h*e??}? ? K?	?      ?   ?   x??л?@?ឧ?NH???L0???????]?D??????$?+?4/???4???ۺ?fܩ;zcCJ
>???)?^?'Ɇ0?K????h?(??P?2?`???????ҭ??%;e?@?wq????X!????[{?v?r@?	????????i?%?{{?/????\?7?????~??      ?   a   x???v
Q???W((M??L??/H-JL???K-V??L???uRR???2@M?0G?P?`C??Լ?DuMk.O??3???SX???Z2?? ??5?      ?   
   x???          ?   
   x???          ?   ?   x?ő?j?0??y
??B<l'ivꡌ?5???u???	+$??Of}??A???????~??9???\{???f?f?-v??H???????:hM??턣E?)x???4???ܣCNDw??˱???)lr??\?Ն????RB˨??J?B?<??	?8Z?9?\Ol??SR߉_1WV???*????,????????G????x??9?????;???	t??Z??
????e1??8?????w?'?/G??      ?   
   x???          ?   l   x???v
Q???W((M??L?+(JM??/V??L???u?̲̔??D?????|M?0G?P?`C#SMk.OJM3??fJӌuLt??8?Y@6?? u?_?      ?   
   x???          ?   ?   x???v
Q???W((M??L?+?,ȏ?/H-JL??ϋO??+IL?IU??L?G??QHI-N.?,?q?2K?5?}B]?4uԝK?K?uJ?JS5??<ih?к???|?mi?9Ŵ??h]Pjrb?F???? T?r?      ?   v   x???v
Q???W((M??L?+?,?OO,J?+?LT??L??qtRR???2?3??4?}B]?4uԃR?3????
???9)????\??m4:$??4ltAQ~AfjJb
?t.. ?=?      ?   ?   x???M
?0@?}O1??P???qU?H@+??V?t??4?<????->?h??сh?;X?kR??,??!??B?j"??M????[??uY@zc?r?	͂i~LĿ?ƣgg5~?p?????"G??QНGOr?Q?}?X}p???w?ڲ	\?? D,?X      ?   c   x???v
Q???W((M??L?+?,??/H-JL???S??L???tRR???2@M?0G?P?`C??Լ?DuMk.Oj?h4?1??43'?d( A7?     