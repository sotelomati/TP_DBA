PGDMP     #    	                y            TP_DBA    13.2    13.2 ?               0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    16410    TP_DBA    DATABASE     d   CREATE DATABASE "TP_DBA" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Spanish_Spain.1252';
    DROP DATABASE "TP_DBA";
                postgres    false            ?           1247    16511    cuit    DOMAIN     ~   CREATE DOMAIN public.cuit AS character varying(13)
	CONSTRAINT cuit_check CHECK (((VALUE)::bigint <= '99999999999'::bigint));
    DROP DOMAIN public.cuit;
       public          postgres    false            ?           1247    16508    dni    DOMAIN     o   CREATE DOMAIN public.dni AS character varying(8)
	CONSTRAINT dni_check CHECK (((VALUE)::integer <= 99999999));
    DROP DOMAIN public.dni;
       public          postgres    false            ?           1247    16514    mesaño    DOMAIN     ?   CREATE DOMAIN public."mesaño" AS character varying(7)
	CONSTRAINT date_check CHECK (('1990-01-01'::date < to_date(('01-'::text || (VALUE)::text), 'DD-MM-YYYY'::text)))
	CONSTRAINT format_check CHECK ((3 = "position"((VALUE)::text, '-'::text)));
    DROP DOMAIN public."mesaño";
       public          postgres    false            ?            1255    16913 (   calcular_recargo(integer, integer, date)    FUNCTION     ?  CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota date) RETURNS double precision
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
       public          postgres    false                       1255    16976 4   calcular_recargo(integer, integer, public."mesaño")    FUNCTION     x  CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota public."mesaño") RETURNS double precision
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

diferencia_de_dias = date_part('DAY', age(current_date, v_fecha_vencimiento));
IF  diferencia_de_dias > 0 THEN
	v_recargo = diferencia_de_dias * (v_monto * porcentaje_recargo);
	
END IF;

RETURN v_recargo;
END;
$$;
 h   DROP FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota public."mesaño");
       public          postgres    false    700                       1255    16962 !   sp_actualizar_periodo_ocupacion()    FUNCTION     5  CREATE FUNCTION public.sp_actualizar_periodo_ocupacion() RETURNS trigger
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
       public          postgres    false            ?            1255    16871     sp_actualizar_usuario_y_tiempo()    FUNCTION     ?   CREATE FUNCTION public.sp_actualizar_usuario_y_tiempo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
NEW.ultimo_usuario = CURRENT_USER;
NEW.ultimo_horario = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$;
 7   DROP FUNCTION public.sp_actualizar_usuario_y_tiempo();
       public          postgres    false            ?            1255    16897    sp_agregar_fecha_vencimiento()    FUNCTION     0  CREATE FUNCTION public.sp_agregar_fecha_vencimiento() RETURNS trigger
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
       public          postgres    false                       1255    16964    sp_autoincremental_control()    FUNCTION     v  CREATE FUNCTION public.sp_autoincremental_control() RETURNS trigger
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
       public          postgres    false            ?            1255    16899    sp_cargarprecioalquiler()    FUNCTION     Z  CREATE FUNCTION public.sp_cargarprecioalquiler() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
        BEGIN
            INSERT INTO public.precioalquiler(id_inmueble, id_cliente, importe, fechadefinicion)
				VALUES (NEW.id_inmueble,NEW.id_cliente,NEW.precio_inicial,CURRENT_DATE);
            RETURN NULL;
        END;
    $$;
 0   DROP FUNCTION public.sp_cargarprecioalquiler();
       public          postgres    false                       1255    16978 A   sp_check_facturacion_contrato(integer, integer, public."mesaño")    FUNCTION       CREATE FUNCTION public.sp_check_facturacion_contrato(inmueble integer, cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    700                       1255    16977 &   sp_contrato_isactivo(integer, integer)    FUNCTION     f  CREATE FUNCTION public.sp_contrato_isactivo(v_inmueble integer, v_cliente integer) RETURNS boolean
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
       public          postgres    false            ?            1255    16917    sp_convertir_date_mesaño(date)    FUNCTION     ?   CREATE FUNCTION public."sp_convertir_date_mesaño"(fecha date) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN right(to_char(fecha, 'DD-MM-YYYY'), 7);
END;
$$;
 >   DROP FUNCTION public."sp_convertir_date_mesaño"(fecha date);
       public          postgres    false    700            ?            1255    16918 +   sp_convertir_mesaño_date(public."mesaño")    FUNCTION     ?   CREATE FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño") RETURNS date
    LANGUAGE plpgsql
    AS $$
	BEGIN
	
		RETURN '01-' || v_mesaño; 
	END;
$$;
 P   DROP FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño");
       public          postgres    false    700            ?            1255    16919 2   sp_crear_cuota(integer, integer, public."mesaño")    FUNCTION     j  CREATE FUNCTION public.sp_crear_cuota(v_inmueble integer, v_cliente integer, fechacrear public."mesaño") RETURNS boolean
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
       public          postgres    false    700            ?            1255    16901    sp_crear_fecha_vencimiento()    FUNCTION     ?   CREATE FUNCTION public.sp_crear_fecha_vencimiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.vencimiento_cuota = extract ('day' from new.fechaContrato);
RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.sp_crear_fecha_vencimiento();
       public          postgres    false                       1255    16960    sp_crear_periodo_ocupacion()    FUNCTION       CREATE FUNCTION public.sp_crear_periodo_ocupacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO periodoocupacion(id_inmueble, fechainicio, fechabaja, motivobaja)
	VALUES (NEW.id_inmueble, NEW.fechaContrato, NULL, NULL);
	RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.sp_crear_periodo_ocupacion();
       public          postgres    false            ?            1255    16903    sp_dias_vencidos_recargo()    FUNCTION     ]  CREATE FUNCTION public.sp_dias_vencidos_recargo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_fechavencimiento DATE;
BEGIN
	select fechaVencimiento INTO v_fechavencimiento 
	WHERE id_inmueble = NEW.id_inmueble AND id_cliente = NEW.id_cliente AND mesaño = NEW.mesaño;
	
	NEW.diasVencidos = CURRENT_DATE - v_fechavencimiento;

END;
$$;
 1   DROP FUNCTION public.sp_dias_vencidos_recargo();
       public          postgres    false            ?            1255    16916 7   sp_es_igual_mesaño(public."mesaño", public."mesaño")    FUNCTION     ?   CREATE FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño) = SP_convertir_mesaño_date(comparar);

END;
$$;
 e   DROP FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño");
       public          postgres    false    700    700            ?            1255    16920 7   sp_es_mayor_mesaño(public."mesaño", public."mesaño")    FUNCTION     ?   CREATE FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño)>SP_convertir_mesaño_date(comparar);

END;
$$;
 e   DROP FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño");
       public          postgres    false    700    700                       1255    16921 =   sp_esta_en_rango_contrato(integer, integer, public."mesaño")    FUNCTION     8  CREATE FUNCTION public.sp_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    700                       1255    16908 0   sp_esta_paga(integer, integer, public."mesaño")    FUNCTION     ?  CREATE FUNCTION public.sp_esta_paga(v_cliente integer, v_inmueble integer, "v_mesaño" public."mesaño") RETURNS character varying
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
       public          postgres    false    700            ?            1255    16907 5   sp_esta_paga_bool(integer, integer, public."mesaño")    FUNCTION     ;  CREATE FUNCTION public.sp_esta_paga_bool(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    700            	           1255    16909 3   sp_existe_cuota(integer, integer, public."mesaño")    FUNCTION     X  CREATE FUNCTION public.sp_existe_cuota(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    700                       1255    16970 !   sp_historial_direcciones_dueño()    FUNCTION     I  CREATE FUNCTION public."sp_historial_direcciones_dueño"() RETURNS trigger
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
 :   DROP FUNCTION public."sp_historial_direcciones_dueño"();
       public          postgres    false                       1255    16974    sp_importepago()    FUNCTION     ?  CREATE FUNCTION public.sp_importepago() RETURNS trigger
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
 '   DROP FUNCTION public.sp_importepago();
       public          postgres    false                       1255    16966    sp_modificar_nombre_cliente()    FUNCTION     %  CREATE FUNCTION public.sp_modificar_nombre_cliente() RETURNS trigger
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
       public          postgres    false            ?            1255    16905    sp_obtener_importe_cuota()    FUNCTION     ?  CREATE FUNCTION public.sp_obtener_importe_cuota() RETURNS trigger
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
       public          postgres    false            
           1255    16910 <   sp_obtener_importe_cuota(integer, integer, public."mesaño")    FUNCTION     ?  CREATE FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño") RETURNS double precision
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
 v   DROP FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño");
       public          postgres    false    700                       1255    16912 H   sp_obtener_importe_por_tipo(integer, integer, public."mesaño", integer)    FUNCTION       CREATE FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer) RETURNS double precision
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
       public          postgres    false    700                       1255    16911 6   sp_obtener_mesaño_contrato(integer, integer, integer)    FUNCTION     ?  CREATE FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer) RETURNS public."mesaño"
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
 h   DROP FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer);
       public          postgres    false    700            ?            1255    16914 6   sp_operacion_resta_mes_año(public."mesaño", integer)    FUNCTION     u  CREATE FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) - (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;
 c   DROP FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer);
       public          postgres    false    700    700            ?            1255    16915 5   sp_operacion_suma_mes_año(public."mesaño", integer)    FUNCTION     t  CREATE FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) + (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;
 b   DROP FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer);
       public          postgres    false    700    700                       1255    16973 2   sp_pagar_cuota(integer, integer, public."mesaño")    FUNCTION       CREATE FUNCTION public.sp_pagar_cuota(v_inmueble integer, v_cliente integer, v_cuota public."mesaño") RETURNS boolean
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
 f   DROP FUNCTION public.sp_pagar_cuota(v_inmueble integer, v_cliente integer, v_cuota public."mesaño");
       public          postgres    false    700                       1255    16968    tg_iniciar_historial_dueños()    FUNCTION     !  CREATE FUNCTION public."tg_iniciar_historial_dueños"() RETURNS trigger
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
                numero, departamento, piso, observaciones, CURRENT_DATE, NULL
                FROM direcciones
                INNER JOIN Personas on personas.id_direccion = direcciones.id_direccion
                WHERE personas.id_persona = new.id_persona
            );
        RETURN NULL;

    END;
$$;
 7   DROP FUNCTION public."tg_iniciar_historial_dueños"();
       public          postgres    false            ?            1259    16547    anuncios    TABLE     e  CREATE TABLE public.anuncios (
    id_anuncio integer NOT NULL,
    titulo character varying(50) NOT NULL,
    texto character varying(100) NOT NULL,
    fecha date NOT NULL,
    vigencia integer NOT NULL,
    tipo_vigencia character(1) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.anuncios;
       public         heap    postgres    false            ?            1259    16595    clientes    TABLE     ?   CREATE TABLE public.clientes (
    id_cliente integer NOT NULL,
    id_persona integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.clientes;
       public         heap    postgres    false            ?            1259    16710    contratoalquiler    TABLE     ?  CREATE TABLE public.contratoalquiler (
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
 $   DROP TABLE public.contratoalquiler;
       public         heap    postgres    false            ?            1259    16705    contratos_estados    TABLE     ?   CREATE TABLE public.contratos_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 %   DROP TABLE public.contratos_estados;
       public         heap    postgres    false            ?            1259    16700    contratos_finalidades    TABLE     ?   CREATE TABLE public.contratos_finalidades (
    id_finalidad integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 )   DROP TABLE public.contratos_finalidades;
       public         heap    postgres    false            ?            1259    16809    cuotas    TABLE     k  CREATE TABLE public.cuotas (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    id_tipo_operacion integer DEFAULT 1 NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    importe double precision,
    fechavencimiento date NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.cuotas;
       public         heap    postgres    false    700            ?            1259    16582    personas    TABLE     D  CREATE TABLE public.personas (
    id_persona integer NOT NULL,
    dni public.dni NOT NULL,
    fechanacimiento date,
    fechainscripcion date,
    nombrecompleto character varying(50),
    id_direccion integer,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.personas;
       public         heap    postgres    false    692            ?            1259    16517    tipo_operacion_contable    TABLE     ?   CREATE TABLE public.tipo_operacion_contable (
    id_tipo_operacion integer NOT NULL,
    descripcion character varying(50),
    debito boolean,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 +   DROP TABLE public.tipo_operacion_contable;
       public         heap    postgres    false            ?            1259    16922    cuota_cta_cte    VIEW     /  CREATE VIEW public.cuota_cta_cte AS
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
       public          postgres    false    211    210    210    200    200    211    226    226    226    226    268    700            ?            1259    16784    pagos    TABLE     ?  CREATE TABLE public.pagos (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    id_tipo_operacion integer DEFAULT 2 NOT NULL,
    importepago double precision NOT NULL,
    fechapago date DEFAULT CURRENT_DATE NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.pagos;
       public         heap    postgres    false    700            ?            1259    16927    pago_cta_cte    VIEW     &  CREATE VIEW public.pago_cta_cte AS
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
       public          postgres    false    211    200    200    210    210    211    225    225    225    225    268    700            ?            1259    16833    recargos    TABLE     }  CREATE TABLE public.recargos (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    "mesaño" public."mesaño" NOT NULL,
    id_tipo_operacion integer DEFAULT 3 NOT NULL,
    importerecargo double precision NOT NULL,
    diasvencidos integer DEFAULT 0,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.recargos;
       public         heap    postgres    false    700            ?            1259    16932    recargo_cta_cte    VIEW     A  CREATE VIEW public.recargo_cta_cte AS
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
       public          postgres    false    268    227    227    227    227    211    211    210    210    200    200    700            ?            1259    16937    cta_cte_cliente    VIEW     ?  CREATE VIEW public.cta_cte_cliente AS
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
       public          postgres    false    231    231    231    231    231    230    230    230    230    230    229    229    229    229    229    700            ?            1259    16537    direcciones    TABLE     ?  CREATE TABLE public.direcciones (
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
    DROP TABLE public.direcciones;
       public         heap    postgres    false            ?            1259    16527    localidades    TABLE       CREATE TABLE public.localidades (
    id_localidad integer NOT NULL,
    nombre character varying(50) NOT NULL,
    codigo_postal integer,
    id_provincia integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.localidades;
       public         heap    postgres    false            ?            1259    16522    localizaciones    TABLE     ?   CREATE TABLE public.localizaciones (
    id_localizacion integer NOT NULL,
    provincia character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 "   DROP TABLE public.localizaciones;
       public         heap    postgres    false            ?            1259    16941    direccion_completa    VIEW     ?  CREATE VIEW public.direccion_completa AS
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
       public          postgres    false    203    203    203    203    203    203    203    202    202    202    202    201    201            ?            1259    16552    divisas    TABLE       CREATE TABLE public.divisas (
    id_divisa integer NOT NULL,
    acronimo character varying(3) NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.divisas;
       public         heap    postgres    false            ?            1259    16607    dueños    TABLE     ?   CREATE TABLE public."dueños" (
    "id_dueño" integer NOT NULL,
    id_persona integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public."dueños";
       public         heap    postgres    false            ?            1259    16858 	   empleados    TABLE     ?   CREATE TABLE public.empleados (
    cuit public.cuit NOT NULL,
    apellido_nombre character varying(70),
    fecha_ingreso date NOT NULL,
    cargo character varying(15) NOT NULL,
    superior public.cuit
);
    DROP TABLE public.empleados;
       public         heap    postgres    false    696    696            ?            1259    16743    garante    TABLE     `  CREATE TABLE public.garante (
    dni public.dni NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    nombre character varying(50) NOT NULL,
    fechanacimiento date NOT NULL,
    id_tipogarantia integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.garante;
       public         heap    postgres    false    692            ?            1259    16621    historial_direcciones    TABLE     ?  CREATE TABLE public.historial_direcciones (
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
    fechafinvigencia date
);
 )   DROP TABLE public.historial_direcciones;
       public         heap    postgres    false            ?            1259    16619 &   historial_direcciones_id_historial_seq    SEQUENCE     ?   CREATE SEQUENCE public.historial_direcciones_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.historial_direcciones_id_historial_seq;
       public          postgres    false    214                       0    0 &   historial_direcciones_id_historial_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.historial_direcciones_id_historial_seq OWNED BY public.historial_direcciones.id_historial;
          public          postgres    false    213            ?            1259    16637 	   inmuebles    TABLE     ?  CREATE TABLE public.inmuebles (
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
       public         heap    postgres    false            ?            1259    16672    inmuebles_operaciones    TABLE     ?   CREATE TABLE public.inmuebles_operaciones (
    id_inmueble integer NOT NULL,
    id_operacion integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 )   DROP TABLE public.inmuebles_operaciones;
       public         heap    postgres    false            ?            1259    16689    periodoocupacion    TABLE     2  CREATE TABLE public.periodoocupacion (
    id_periodo integer NOT NULL,
    id_inmueble integer NOT NULL,
    fechainicio date NOT NULL,
    fechabaja date,
    motivobaja character varying(100),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 $   DROP TABLE public.periodoocupacion;
       public         heap    postgres    false            ?            1259    16557    precios    TABLE     ?   CREATE TABLE public.precios (
    id_precio integer NOT NULL,
    id_divisa integer NOT NULL,
    monto double precision NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.precios;
       public         heap    postgres    false            ?            1259    16946    precio_inmueble    VIEW     ?   CREATE VIEW public.precio_inmueble AS
 SELECT p.id_precio,
    p.monto,
    d.acronimo
   FROM (public.precios p
     JOIN public.divisas d ON ((p.id_divisa = d.id_divisa)));
 "   DROP VIEW public.precio_inmueble;
       public          postgres    false    206    206    206    205    205            ?            1259    16567    tipoinmueble    TABLE     ?   CREATE TABLE public.tipoinmueble (
    id_tipo integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
     DROP TABLE public.tipoinmueble;
       public         heap    postgres    false            ?            1259    16950    info_inmuebles_completa    VIEW     ?	  CREATE VIEW public.info_inmuebles_completa AS
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
 *   DROP VIEW public.info_inmuebles_completa;
       public          postgres    false    234    234    234    233    233    233    233    233    233    233    233    233    218    218    216    216    215    215    215    215    215    215    212    212    210    210    207    207    204    204            ?            1259    16955    informacion_cuotas    VIEW     ?  CREATE VIEW public.informacion_cuotas AS
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
 %   DROP VIEW public.informacion_cuotas;
       public          postgres    false    221    235    264    226    226    226    221    221    211    211    210    210    210    210    210    210    210    210    692    700            ?            1259    16577    inmuebles_estados    TABLE     ?   CREATE TABLE public.inmuebles_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 %   DROP TABLE public.inmuebles_estados;
       public         heap    postgres    false            ?            1259    16572    operaciones    TABLE     ?   CREATE TABLE public.operaciones (
    id_operacion integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.operaciones;
       public         heap    postgres    false            ?            1259    16687    periodoocupacion_id_periodo_seq    SEQUENCE     ?   CREATE SEQUENCE public.periodoocupacion_id_periodo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.periodoocupacion_id_periodo_seq;
       public          postgres    false    218                       0    0    periodoocupacion_id_periodo_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.periodoocupacion_id_periodo_seq OWNED BY public.periodoocupacion.id_periodo;
          public          postgres    false    217            ?            1259    16768    precioalquiler    TABLE     H  CREATE TABLE public.precioalquiler (
    id_precioalquiler integer NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    importe double precision NOT NULL,
    fechadefinicion date NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 "   DROP TABLE public.precioalquiler;
       public         heap    postgres    false            ?            1259    16766 $   precioalquiler_id_precioalquiler_seq    SEQUENCE     ?   CREATE SEQUENCE public.precioalquiler_id_precioalquiler_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.precioalquiler_id_precioalquiler_seq;
       public          postgres    false    224                       0    0 $   precioalquiler_id_precioalquiler_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.precioalquiler_id_precioalquiler_seq OWNED BY public.precioalquiler.id_precioalquiler;
          public          postgres    false    223            ?            1259    16979    tipogarantia    TABLE     ?   CREATE TABLE public.tipogarantia (
    id_garantia integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
     DROP TABLE public.tipogarantia;
       public         heap    postgres    false            ?           2604    16624 "   historial_direcciones id_historial    DEFAULT     ?   ALTER TABLE ONLY public.historial_direcciones ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_direcciones_id_historial_seq'::regclass);
 Q   ALTER TABLE public.historial_direcciones ALTER COLUMN id_historial DROP DEFAULT;
       public          postgres    false    213    214    214            ?           2604    16692    periodoocupacion id_periodo    DEFAULT     ?   ALTER TABLE ONLY public.periodoocupacion ALTER COLUMN id_periodo SET DEFAULT nextval('public.periodoocupacion_id_periodo_seq'::regclass);
 J   ALTER TABLE public.periodoocupacion ALTER COLUMN id_periodo DROP DEFAULT;
       public          postgres    false    217    218    218            ?           2604    16771     precioalquiler id_precioalquiler    DEFAULT     ?   ALTER TABLE ONLY public.precioalquiler ALTER COLUMN id_precioalquiler SET DEFAULT nextval('public.precioalquiler_id_precioalquiler_seq'::regclass);
 O   ALTER TABLE public.precioalquiler ALTER COLUMN id_precioalquiler DROP DEFAULT;
       public          postgres    false    223    224    224            ?          0    16547    anuncios 
   TABLE DATA                 public          postgres    false    204   ԇ                0    16595    clientes 
   TABLE DATA                 public          postgres    false    211   ??                0    16710    contratoalquiler 
   TABLE DATA                 public          postgres    false    221   ??                0    16705    contratos_estados 
   TABLE DATA                 public          postgres    false    220   ??                0    16700    contratos_finalidades 
   TABLE DATA                 public          postgres    false    219   o?                0    16809    cuotas 
   TABLE DATA                 public          postgres    false    226   <?      ?          0    16537    direcciones 
   TABLE DATA                 public          postgres    false    203   V?      ?          0    16552    divisas 
   TABLE DATA                 public          postgres    false    205   x?                0    16607    dueños 
   TABLE DATA                 public          postgres    false    212   H?                0    16858 	   empleados 
   TABLE DATA                 public          postgres    false    228   ??                0    16743    garante 
   TABLE DATA                 public          postgres    false    222   ??                0    16621    historial_direcciones 
   TABLE DATA                 public          postgres    false    214   ?                0    16637 	   inmuebles 
   TABLE DATA                 public          postgres    false    215   1?                0    16577    inmuebles_estados 
   TABLE DATA                 public          postgres    false    209   ?                0    16672    inmuebles_operaciones 
   TABLE DATA                 public          postgres    false    216   ؐ      ?          0    16527    localidades 
   TABLE DATA                 public          postgres    false    202   ??      ?          0    16522    localizaciones 
   TABLE DATA                 public          postgres    false    201   ??                 0    16572    operaciones 
   TABLE DATA                 public          postgres    false    208   ??                0    16784    pagos 
   TABLE DATA                 public          postgres    false    225   >?      
          0    16689    periodoocupacion 
   TABLE DATA                 public          postgres    false    218   X?                0    16582    personas 
   TABLE DATA                 public          postgres    false    210   &?                0    16768    precioalquiler 
   TABLE DATA                 public          postgres    false    224   Z?      ?          0    16557    precios 
   TABLE DATA                 public          postgres    false    206   %?                0    16833    recargos 
   TABLE DATA                 public          postgres    false    227   ݗ      ?          0    16517    tipo_operacion_contable 
   TABLE DATA                 public          postgres    false    200   ??                0    16979    tipogarantia 
   TABLE DATA                 public          postgres    false    237         ?          0    16567    tipoinmueble 
   TABLE DATA                 public          postgres    false    207   }?                 0    0 &   historial_direcciones_id_historial_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('public.historial_direcciones_id_historial_seq', 1, false);
          public          postgres    false    213                        0    0    periodoocupacion_id_periodo_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.periodoocupacion_id_periodo_seq', 4, true);
          public          postgres    false    217            !           0    0 $   precioalquiler_id_precioalquiler_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.precioalquiler_id_precioalquiler_seq', 4, true);
          public          postgres    false    223            ?           2606    16551    anuncios anuncios_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.anuncios
    ADD CONSTRAINT anuncios_pkey PRIMARY KEY (id_anuncio);
 @   ALTER TABLE ONLY public.anuncios DROP CONSTRAINT anuncios_pkey;
       public            postgres    false    204                       2606    16601     clientes clientes_id_cliente_key 
   CONSTRAINT     a   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_cliente_key UNIQUE (id_cliente);
 J   ALTER TABLE ONLY public.clientes DROP CONSTRAINT clientes_id_cliente_key;
       public            postgres    false    211                       2606    16599    clientes clientes_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id_cliente, id_persona);
 @   ALTER TABLE ONLY public.clientes DROP CONSTRAINT clientes_pkey;
       public            postgres    false    211    211                       2606    16717 &   contratoalquiler contratoalquiler_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente);
 P   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_pkey;
       public            postgres    false    221    221                       2606    16709 (   contratos_estados contratos_estados_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.contratos_estados
    ADD CONSTRAINT contratos_estados_pkey PRIMARY KEY (id_estado);
 R   ALTER TABLE ONLY public.contratos_estados DROP CONSTRAINT contratos_estados_pkey;
       public            postgres    false    220                       2606    16704 0   contratos_finalidades contratos_finalidades_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.contratos_finalidades
    ADD CONSTRAINT contratos_finalidades_pkey PRIMARY KEY (id_finalidad);
 Z   ALTER TABLE ONLY public.contratos_finalidades DROP CONSTRAINT contratos_finalidades_pkey;
       public            postgres    false    219                       2606    16817    cuotas cuotas_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 <   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_pkey;
       public            postgres    false    226    226    226            ?           2606    16541    direcciones direcciones_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_pkey PRIMARY KEY (id_direccion);
 F   ALTER TABLE ONLY public.direcciones DROP CONSTRAINT direcciones_pkey;
       public            postgres    false    203            ?           2606    16556    divisas divisas_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.divisas
    ADD CONSTRAINT divisas_pkey PRIMARY KEY (id_divisa);
 >   ALTER TABLE ONLY public.divisas DROP CONSTRAINT divisas_pkey;
       public            postgres    false    205                       2606    16613    dueños dueños_id_dueño_key 
   CONSTRAINT     c   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_id_dueño_key" UNIQUE ("id_dueño");
 K   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "dueños_id_dueño_key";
       public            postgres    false    212            	           2606    16611    dueños dueños_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_pkey" PRIMARY KEY ("id_dueño", id_persona);
 B   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "dueños_pkey";
       public            postgres    false    212    212            #           2606    16865    empleados empleados_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_pkey PRIMARY KEY (cuit);
 B   ALTER TABLE ONLY public.empleados DROP CONSTRAINT empleados_pkey;
       public            postgres    false    228                       2606    16750    garante garante_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT garante_pkey PRIMARY KEY (id_inmueble, id_cliente, dni);
 >   ALTER TABLE ONLY public.garante DROP CONSTRAINT garante_pkey;
       public            postgres    false    222    222    222                       2606    16626 0   historial_direcciones historial_direcciones_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT historial_direcciones_pkey PRIMARY KEY (id_historial);
 Z   ALTER TABLE ONLY public.historial_direcciones DROP CONSTRAINT historial_direcciones_pkey;
       public            postgres    false    214            ?           2606    16581 (   inmuebles_estados inmuebles_estados_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.inmuebles_estados
    ADD CONSTRAINT inmuebles_estados_pkey PRIMARY KEY (id_estado);
 R   ALTER TABLE ONLY public.inmuebles_estados DROP CONSTRAINT inmuebles_estados_pkey;
       public            postgres    false    209                       2606    16676 0   inmuebles_operaciones inmuebles_operaciones_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_pkey PRIMARY KEY (id_inmueble, id_operacion);
 Z   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_pkey;
       public            postgres    false    216    216                       2606    16641    inmuebles inmuebles_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_pkey PRIMARY KEY (id_inmueble);
 B   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_pkey;
       public            postgres    false    215            ?           2606    16531    localidades localidades_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_pkey PRIMARY KEY (id_localidad);
 F   ALTER TABLE ONLY public.localidades DROP CONSTRAINT localidades_pkey;
       public            postgres    false    202            ?           2606    16526 "   localizaciones localizaciones_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.localizaciones
    ADD CONSTRAINT localizaciones_pkey PRIMARY KEY (id_localizacion);
 L   ALTER TABLE ONLY public.localizaciones DROP CONSTRAINT localizaciones_pkey;
       public            postgres    false    201            ?           2606    16576    operaciones operaciones_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_pkey PRIMARY KEY (id_operacion);
 F   ALTER TABLE ONLY public.operaciones DROP CONSTRAINT operaciones_pkey;
       public            postgres    false    208                       2606    16793    pagos pagos_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 :   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_pkey;
       public            postgres    false    225    225    225                       2606    16694 &   periodoocupacion periodoocupacion_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_pkey PRIMARY KEY (id_periodo);
 P   ALTER TABLE ONLY public.periodoocupacion DROP CONSTRAINT periodoocupacion_pkey;
       public            postgres    false    218                       2606    16589    personas personas_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (id_persona);
 @   ALTER TABLE ONLY public.personas DROP CONSTRAINT personas_pkey;
       public            postgres    false    210                       2606    16773 "   precioalquiler precioalquiler_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente, id_precioalquiler);
 L   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_pkey;
       public            postgres    false    224    224    224            ?           2606    16561    precios precios_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_pkey PRIMARY KEY (id_precio);
 >   ALTER TABLE ONLY public.precios DROP CONSTRAINT precios_pkey;
       public            postgres    false    206            !           2606    16842    recargos recargos_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 @   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_pkey;
       public            postgres    false    227    227    227            ?           2606    16521 4   tipo_operacion_contable tipo_operacion_contable_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.tipo_operacion_contable
    ADD CONSTRAINT tipo_operacion_contable_pkey PRIMARY KEY (id_tipo_operacion);
 ^   ALTER TABLE ONLY public.tipo_operacion_contable DROP CONSTRAINT tipo_operacion_contable_pkey;
       public            postgres    false    200            %           2606    16983    tipogarantia tipogarantia_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.tipogarantia
    ADD CONSTRAINT tipogarantia_pkey PRIMARY KEY (id_garantia);
 H   ALTER TABLE ONLY public.tipogarantia DROP CONSTRAINT tipogarantia_pkey;
       public            postgres    false    237            ?           2606    16571    tipoinmueble tipoinmueble_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.tipoinmueble
    ADD CONSTRAINT tipoinmueble_pkey PRIMARY KEY (id_tipo);
 H   ALTER TABLE ONLY public.tipoinmueble DROP CONSTRAINT tipoinmueble_pkey;
       public            postgres    false    207            b           2620    16963 0   contratoalquiler tg_actualizar_periodo_ocupacion    TRIGGER     ?   CREATE TRIGGER tg_actualizar_periodo_ocupacion BEFORE UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_periodo_ocupacion();
 I   DROP TRIGGER tg_actualizar_periodo_ocupacion ON public.contratoalquiler;
       public          postgres    false    271    221            h           2620    16898 #   cuotas tg_agregar_fecha_vencimiento    TRIGGER     ?   CREATE TRIGGER tg_agregar_fecha_vencimiento BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_agregar_fecha_vencimiento();
 <   DROP TRIGGER tg_agregar_fecha_vencimiento ON public.cuotas;
       public          postgres    false    241    226            N           2620    16877 "   anuncios tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.anuncios FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.anuncios;
       public          postgres    false    238    204            U           2620    16884 "   clientes tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.clientes;
       public          postgres    false    211    238            ^           2620    16890 *   contratoalquiler tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 C   DROP TRIGGER tg_auditorio_modificacion ON public.contratoalquiler;
       public          postgres    false    221    238            ]           2620    16889 +   contratos_estados tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratos_estados FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 D   DROP TRIGGER tg_auditorio_modificacion ON public.contratos_estados;
       public          postgres    false    238    220            \           2620    16888 /   contratos_finalidades tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratos_finalidades FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 H   DROP TRIGGER tg_auditorio_modificacion ON public.contratos_finalidades;
       public          postgres    false    219    238            g           2620    16895     cuotas tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 9   DROP TRIGGER tg_auditorio_modificacion ON public.cuotas;
       public          postgres    false    226    238            L           2620    16873 %   direcciones tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 >   DROP TRIGGER tg_auditorio_modificacion ON public.direcciones;
       public          postgres    false    238    203            O           2620    16878 !   divisas tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.divisas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 :   DROP TRIGGER tg_auditorio_modificacion ON public.divisas;
       public          postgres    false    205    238            V           2620    16885 !   dueños tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public."dueños" FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 <   DROP TRIGGER tg_auditorio_modificacion ON public."dueños";
       public          postgres    false    212    238            c           2620    16892 !   garante tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.garante FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 :   DROP TRIGGER tg_auditorio_modificacion ON public.garante;
       public          postgres    false    222    238            X           2620    16872 #   inmuebles tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 <   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles;
       public          postgres    false    238    215            S           2620    16882 +   inmuebles_estados tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles_estados FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 D   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles_estados;
       public          postgres    false    238    209            Z           2620    16886 /   inmuebles_operaciones tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles_operaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 H   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles_operaciones;
       public          postgres    false    238    216            K           2620    16876 %   localidades tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.localidades FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 >   DROP TRIGGER tg_auditorio_modificacion ON public.localidades;
       public          postgres    false    238    202            J           2620    16875 (   localizaciones tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.localizaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 A   DROP TRIGGER tg_auditorio_modificacion ON public.localizaciones;
       public          postgres    false    238    201            R           2620    16881 %   operaciones tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.operaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 >   DROP TRIGGER tg_auditorio_modificacion ON public.operaciones;
       public          postgres    false    208    238            e           2620    16894    pagos tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 8   DROP TRIGGER tg_auditorio_modificacion ON public.pagos;
       public          postgres    false    238    225            [           2620    16887 *   periodoocupacion tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.periodoocupacion FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 C   DROP TRIGGER tg_auditorio_modificacion ON public.periodoocupacion;
       public          postgres    false    238    218            T           2620    16883 "   personas tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.personas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.personas;
       public          postgres    false    210    238            d           2620    16893 (   precioalquiler tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.precioalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 A   DROP TRIGGER tg_auditorio_modificacion ON public.precioalquiler;
       public          postgres    false    224    238            P           2620    16879 !   precios tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.precios FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 :   DROP TRIGGER tg_auditorio_modificacion ON public.precios;
       public          postgres    false    206    238            j           2620    16896 "   recargos tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.recargos FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.recargos;
       public          postgres    false    238    227            I           2620    16874 1   tipo_operacion_contable tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipo_operacion_contable FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 J   DROP TRIGGER tg_auditorio_modificacion ON public.tipo_operacion_contable;
       public          postgres    false    238    200            m           2620    16984 &   tipogarantia tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipogarantia FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ?   DROP TRIGGER tg_auditorio_modificacion ON public.tipogarantia;
       public          postgres    false    238    237            Q           2620    16880 &   tipoinmueble tg_auditorio_modificacion    TRIGGER     ?   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipoinmueble FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ?   DROP TRIGGER tg_auditorio_modificacion ON public.tipoinmueble;
       public          postgres    false    207    238            Y           2620    16965 $   inmuebles tg_autoincremental_control    TRIGGER     ?   CREATE TRIGGER tg_autoincremental_control BEFORE INSERT ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_autoincremental_control();
 =   DROP TRIGGER tg_autoincremental_control ON public.inmuebles;
       public          postgres    false    215    272            _           2620    16900 (   contratoalquiler tg_cargarprecioalquiler    TRIGGER     ?   CREATE TRIGGER tg_cargarprecioalquiler AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_cargarprecioalquiler();
 A   DROP TRIGGER tg_cargarprecioalquiler ON public.contratoalquiler;
       public          postgres    false    242    221            `           2620    16902 +   contratoalquiler tg_crear_fecha_vencimiento    TRIGGER     ?   CREATE TRIGGER tg_crear_fecha_vencimiento BEFORE INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_fecha_vencimiento();
 D   DROP TRIGGER tg_crear_fecha_vencimiento ON public.contratoalquiler;
       public          postgres    false    221    243            a           2620    16961 +   contratoalquiler tg_crear_periodo_ocupacion    TRIGGER     ?   CREATE TRIGGER tg_crear_periodo_ocupacion AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_periodo_ocupacion();
 D   DROP TRIGGER tg_crear_periodo_ocupacion ON public.contratoalquiler;
       public          postgres    false    270    221            k           2620    16904 !   recargos tg_dias_vencidos_recargo    TRIGGER     ?   CREATE TRIGGER tg_dias_vencidos_recargo AFTER INSERT ON public.recargos FOR EACH ROW EXECUTE FUNCTION public.sp_dias_vencidos_recargo();
 :   DROP TRIGGER tg_dias_vencidos_recargo ON public.recargos;
       public          postgres    false    244    227            M           2620    16971 +   direcciones tg_historial_direcciones_dueño    TRIGGER     ?   CREATE TRIGGER "tg_historial_direcciones_dueño" BEFORE DELETE OR UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public."sp_historial_direcciones_dueño"();
 F   DROP TRIGGER "tg_historial_direcciones_dueño" ON public.direcciones;
       public          postgres    false    203    275            f           2620    16975    pagos tg_importepago    TRIGGER     s   CREATE TRIGGER tg_importepago BEFORE INSERT ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.sp_importepago();
 -   DROP TRIGGER tg_importepago ON public.pagos;
       public          postgres    false    277    225            W           2620    16969 $   dueños tg_iniciar_historial_dueños    TRIGGER     ?   CREATE TRIGGER "tg_iniciar_historial_dueños" AFTER INSERT ON public."dueños" FOR EACH ROW EXECUTE FUNCTION public."tg_iniciar_historial_dueños"();
 A   DROP TRIGGER "tg_iniciar_historial_dueños" ON public."dueños";
       public          postgres    false    212    274            l           2620    16967 +   cta_cte_cliente tg_modificar_nombre_cliente    TRIGGER     ?   CREATE TRIGGER tg_modificar_nombre_cliente INSTEAD OF UPDATE ON public.cta_cte_cliente FOR EACH ROW EXECUTE FUNCTION public.sp_modificar_nombre_cliente();
 D   DROP TRIGGER tg_modificar_nombre_cliente ON public.cta_cte_cliente;
       public          postgres    false    232    273            i           2620    16906    cuotas tg_obtener_importe_cuota    TRIGGER     ?   CREATE TRIGGER tg_obtener_importe_cuota BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_obtener_importe_cuota();
 8   DROP TRIGGER tg_obtener_importe_cuota ON public.cuotas;
       public          postgres    false    226    250            :           2606    16733 0   contratoalquiler contratoalquiler_id_estado_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.contratos_estados(id_estado);
 Z   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_id_estado_fkey;
       public          postgres    false    221    3093    220            9           2606    16728 3   contratoalquiler contratoalquiler_id_finalidad_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_finalidad_fkey FOREIGN KEY (id_finalidad) REFERENCES public.contratos_finalidades(id_finalidad);
 ]   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_id_finalidad_fkey;
       public          postgres    false    3091    221    219            C           2606    16823    cuotas cuotas_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_cliente_fkey;
       public          postgres    false    3075    226    211            B           2606    16818    cuotas cuotas_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_inmueble_fkey;
       public          postgres    false    3085    226    215            D           2606    16828 $   cuotas cuotas_id_tipo_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 N   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_tipo_operacion_fkey;
       public          postgres    false    226    200    3053            '           2606    16542 )   direcciones direcciones_id_localidad_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);
 S   ALTER TABLE ONLY public.direcciones DROP CONSTRAINT direcciones_id_localidad_fkey;
       public          postgres    false    3057    203    202            H           2606    16866 !   empleados empleados_superior_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_superior_fkey FOREIGN KEY (superior) REFERENCES public.empleados(cuit);
 K   ALTER TABLE ONLY public.empleados DROP CONSTRAINT empleados_superior_fkey;
       public          postgres    false    228    228    3107            *           2606    16602    clientes fk_cliente_persona    FK CONSTRAINT     ?   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.clientes DROP CONSTRAINT fk_cliente_persona;
       public          postgres    false    3073    211    210            8           2606    16723 $   contratoalquiler fk_contrato_cliente    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT fk_contrato_cliente;
       public          postgres    false    211    3075    221            7           2606    16718 %   contratoalquiler fk_contrato_inmueble    FK CONSTRAINT     ?   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT fk_contrato_inmueble;
       public          postgres    false    3085    221    215            )           2606    16590    personas fk_direccion    FK CONSTRAINT     ?   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_direccion FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);
 ?   ALTER TABLE ONLY public.personas DROP CONSTRAINT fk_direccion;
       public          postgres    false    203    210    3059            +           2606    16614    dueños fk_dueÑo_persona    FK CONSTRAINT     ?   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "fk_dueÑo_persona" FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "fk_dueÑo_persona";
       public          postgres    false    210    3073    212            <           2606    16756    garante fk_garante_cliente    FK CONSTRAINT     ?   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_cliente;
       public          postgres    false    222    211    3075            ;           2606    16751    garante fk_garante_inmueble    FK CONSTRAINT     ?   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_inmueble;
       public          postgres    false    222    3085    215            ,           2606    16627 :   historial_direcciones historial_direcciones_id_dueño_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT "historial_direcciones_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");
 f   ALTER TABLE ONLY public.historial_direcciones DROP CONSTRAINT "historial_direcciones_id_dueño_fkey";
       public          postgres    false    3079    212    214            -           2606    16632 =   historial_direcciones historial_direcciones_id_localidad_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT historial_direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);
 g   ALTER TABLE ONLY public.historial_direcciones DROP CONSTRAINT historial_direcciones_id_localidad_fkey;
       public          postgres    false    202    3057    214            1           2606    16657 #   inmuebles inmuebles_id_anuncio_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_anuncio_fkey FOREIGN KEY (id_anuncio) REFERENCES public.anuncios(id_anuncio);
 M   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_anuncio_fkey;
       public          postgres    false    215    204    3061            0           2606    16652 %   inmuebles inmuebles_id_direccion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);
 O   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_direccion_fkey;
       public          postgres    false    3059    203    215            3           2606    16667 "   inmuebles inmuebles_id_dueño_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT "inmuebles_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");
 N   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT "inmuebles_id_dueño_fkey";
       public          postgres    false    215    3079    212            /           2606    16647 +   inmuebles inmuebles_id_estado_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_estado_inmueble_fkey FOREIGN KEY (id_estado_inmueble) REFERENCES public.inmuebles_estados(id_estado);
 U   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_estado_inmueble_fkey;
       public          postgres    false    3071    209    215            2           2606    16662 "   inmuebles inmuebles_id_precio_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_precio_fkey FOREIGN KEY (id_precio) REFERENCES public.precios(id_precio);
 L   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_precio_fkey;
       public          postgres    false    3065    206    215            .           2606    16642 (   inmuebles inmuebles_id_tipoinmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_tipoinmueble_fkey FOREIGN KEY (id_tipoinmueble) REFERENCES public.tipoinmueble(id_tipo);
 R   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_tipoinmueble_fkey;
       public          postgres    false    3067    207    215            4           2606    16677 <   inmuebles_operaciones inmuebles_operaciones_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);
 f   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_id_inmueble_fkey;
       public          postgres    false    215    3085    216            5           2606    16682 =   inmuebles_operaciones inmuebles_operaciones_id_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_operacion_fkey FOREIGN KEY (id_operacion) REFERENCES public.operaciones(id_operacion);
 g   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_id_operacion_fkey;
       public          postgres    false    208    216    3069            &           2606    16532 )   localidades localidades_id_provincia_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_id_provincia_fkey FOREIGN KEY (id_provincia) REFERENCES public.localizaciones(id_localizacion);
 S   ALTER TABLE ONLY public.localidades DROP CONSTRAINT localidades_id_provincia_fkey;
       public          postgres    false    202    3055    201            @           2606    16799    pagos pagos_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_cliente_fkey;
       public          postgres    false    225    3075    211            ?           2606    16794    pagos pagos_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_inmueble_fkey;
       public          postgres    false    3085    225    215            A           2606    16804 "   pagos pagos_id_tipo_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 L   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_tipo_operacion_fkey;
       public          postgres    false    200    3053    225            6           2606    16695 2   periodoocupacion periodoocupacion_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);
 \   ALTER TABLE ONLY public.periodoocupacion DROP CONSTRAINT periodoocupacion_id_inmueble_fkey;
       public          postgres    false    218    3085    215            >           2606    16779 -   precioalquiler precioalquiler_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 W   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_id_cliente_fkey;
       public          postgres    false    224    3075    211            =           2606    16774 .   precioalquiler precioalquiler_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_id_inmueble_fkey;
       public          postgres    false    3085    215    224            (           2606    16562    precios precios_id_divisa_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_id_divisa_fkey FOREIGN KEY (id_divisa) REFERENCES public.divisas(id_divisa);
 H   ALTER TABLE ONLY public.precios DROP CONSTRAINT precios_id_divisa_fkey;
       public          postgres    false    206    3063    205            F           2606    16848 !   recargos recargos_id_cliente_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_cliente_fkey;
       public          postgres    false    3075    227    211            E           2606    16843 "   recargos recargos_id_inmueble_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_inmueble_fkey;
       public          postgres    false    3085    215    227            G           2606    16853 (   recargos recargos_id_tipo_operacion_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 R   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_tipo_operacion_fkey;
       public          postgres    false    200    3053    227            ?     x?ՒAo?0??????&Դ??$?%?y%?v?(?v???????.??/???I??ͷ??????	s?????ԥPLDU??H7???????C???3?oTqE#?xS??k???/?u<??j??????x?<???=U
ʁ(?a?(?b?d.nT??-??G戄@??8YD?,M?0J?????Y????????5Z?c?F?BD?%ߟex#媃V????aЈZs???SD'z?uF?uV?>k??Լ>)`??Q?X???
??o[m         ?   x???v
Q???W((M??L?K??L?+I-V??L??rt???Ԣ???D?Ҝ????????Ģ?|8?#???Ts?	uV?0?Q04?QP/?/.I/J-V???u?t?ͬL-?L,?,-L?M,?5??<i?#?s?s???1"?9\\  ??         ?   x?ݐ?n? ??y
?h%R]?֝v?!??Ik?kD???d??#?????N?o????voGh??W?ɡ^??ST)(????4?>ۓ????O%?[}U??ܲcR????L?nx?^??p?b??N???̟?+?F?2??P.a??????cVe?]_C??>?_?wXp?N?&x͚Z02$QZ??fb??t?v$wX?||?e|+Vb?(I?OU?/|)???"|?󥪾 $?5         ?   x???=
?@?>?x]?d????B@?kú???5/쏅??^????F?f??c??z??@??,??{??+?v?;????K??B??	He??F ?	x??L????w??y?6????t-?@</?Ԑu??3gi?:i?a9??0eÌu?b?X?GQ?]3???k?Ga~???Q%?B????Gp?#Xzu?}yp= ????         ?   x???M?@໿bn&??&Vv??A?4???f?,???[??%??;?S?U~??(?s9NZR???񉎼?]?`Żo??????q?|0??l?2Tr??;?9{???????m(?s?W?M??{???Q?5?M??l?]?$????N?Ohl9'f?K
?{1.????ж????rP?_???a?ھ         
   x???          ?     x??Q?j?0??+???;????ms74?kPl?.?Z#?9???NhN??V
b?aV????ܭ???)?o?vg?ոF??
?j?O,???J?U-??%خю$ԺU.?F???Eϕ?^????I?L??N???Cz?r=?1/?b	??+^??W?Cr[k/?K晄?P?Ul?,??O??|??۴H&I<?d?x
q?J??r?\???R??͟L ?'p?*?ªN??[2I???矝?????z?'ߢ????>?g??%A@m5?7???E_???	      ?   ?   x???;?0??_q7T|?vt?+>
NbUڀ5????&?t?R??9g??fy??5dy}??]g4#z"?SP?ؽ??@??X?q?A?????7>v??? ??wLDW??????@n?D?'?sO&*???v?d۴-??u?ˏ? rC#<?e? eQ?????Ż4:ܑ6?ऌ???rǱh???_-I/U?̦         ?   x???v
Q???W((M??L?SJ)M=?1?XIAC)3%?S?Q ?R????uJsJ2s??K?K?2?????"_S!??'?5XA?HG??PGA? ??$?(?X?6202?50?54V04?2??2?Գ?056?T״??? ?'-D         
   x???             
   x???             
   x???             ?   x?ݑ?
?0??>?ѥҒK??:9t(??_??#h?mJ?<?????T?????????}?;@?9l??e#?Pt??e???>????Q??c??X?????*!???Nw?ܛ??????~?.݌??g?t1?勯r?<??j}???#?? R4?@4uS???K5^?<?e?8?0I)???<Y?,?fK'?%]fu٤?e?k_J??w?????< bi??         ?   x?͐?
?@{??v*??FM%?B??Kra?5???Y!?O?f??pʪ.n?Us?EG?,?@??????0p????ˈ?Y ??3蘿????O??nB?_?E?g??3IՂ?p?b{?D?컾g?????Y?da??I??n???/y??8?X8C5|??`???$??Pu??M?k???yI??         ?   x?͐??0E?~??
I!}E1?Ɂ??`"?J m???????.?힜??e?_k(??????j??i=K??JO?B???0??JnXԨg]k?^??͇C??η?? 9????]?FZ???#?F? 2????إ4<??ρb???A?????@B?v??      ?     x????j?@??O17??U?驄?6	1?*?.??Ƒ]??O??C???a?0L~*???????֪?jjP?[ia????t???d?P??T?d??Po?[u?B?ԃ?юh=??)??|}?<?????g x0???i??H??~?|$.?'?8?G?6Kce?????:܁LK????Yϗ?????n?
1?å?#?+??4?,\?g?W???n@x????-??8ܕ??\?~?pgCPJ?ʿ> ??R7?`      ?   ?   x????O?0?=?ⶴRZ??G?N)?????Z?P?v????? o?nx??n?j????=?`=u??;??;b%L?????`??N?#???#?yo?EM??_X?)<?7OUGVj???&ti`3????I??Y\?D
?X??eV??E?fe8]????ܰ>??&NrO?R??0u?k+X??U?9I?jD??~
s'? <?y?t?????W??'??Ii????/?/??          ?   x??ν
?0@?ݧ??
*???NB?P?????I??U
???o;M???????4w?S $StB?0??af?'???W|??hC??O?v?0T?[݁C<?????B
?>?{GaD?0?I$+ӼL????8)l?d5???????r?~?????b?         
   x???          
   ?   x?͏??@E{?b??d1?+????	?D??,??`?~?/4?V6?{&?9Q??6DI????%?ƴH??6?@?a?????p?XW????p4?Yc?wm?\_4??z??k۲Ǌ????}h??}?v?x?Ja4? ??J??w?`?m?/k??O????
\9΅?+o??Y?l?p?????]??+???qn!.??         $  x??R?n!????d1???ؓ?lSmRm?Y?/??mX??q[Ͻ5&$?y??	???}??j|#?pn?,:?{t?'3?O#?H? #_?\??Z?.?? ??tq؞?5?v?M'??b??M?OC?h???????????@f?ed*9/??j?\???
??`?SVP!?? Q?6?0?#?#?a.???[%?9???X??Z?U???O???&?\?jɗ?c%eK?˻???h ?.??.V??B?ȉ?#???(?`r?????7?2hG?K҅?9
??H?Jb2???         ?   x?͏=?0?w?m*XIb??N?b?_k??A46??ߤC?s??q??{???չ8]??.G?L#?ǓU-???`{??"????o?Ÿ?<LJ??	?׭?pD?9F`䂃????Շ{??p????$J?????FW$]?ķ4?yyh1?_?YNh??1˶?&?ÝW??????"H~v???4??      ?   ?   x?͐?
?0?w???T??D#?N?b?ڮbUڀ6??>#?;????㊲?/5e}???Gх?:!5x?o6F`?o?[?|-v1?"&?mZ%??)??}?O׼? ???;K?<Ԡ]?S?$ ?$ci???,??????^t?b{?????[?l~?r?l??F         
   x???          ?   ?   x???;?0?὿?l?PK?V+:?t(?J??!??jO???G'q|??<?z???ԛ??k{?+RTB3.q???^@$????Y??zE+-??z+oH?qL?w_Q?z???X?!"1?+???1X??O??vZ??Y??q:?H9O?9?$yY??Y8Z?????X?^ya??x?u??L??_?<??޵?         ?   x???A?@?ỿbn*??&?v??A????????????ޡۼ<e?ue?^A?~?!2?h???9x(?O ?2hT???>???????[?p?_nE????=?{h????O?bF-??N℅?>d;`?<N?8??c?f??ON?d?"Z4vz#?&?Rp???q^Aj/      ?   ?   x???=k?0??ݟ?6'??o??T?Pm
M?5????:??ǯ?t?P?v??~<??t?8?p<??	??i??0?9??Vt??G7t?%3???4?5? -?o?٦^?????p??(E?k??H?=??;?eѥ?*+?)???At?v?o?m?k??????߼*??Q??0X?`h??r????xM$<I'?j??;ڥɺHx?ʰ?,?~ Ҫ#?     