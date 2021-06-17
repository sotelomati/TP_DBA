PGDMP         .                y         	   Prueboide    13.3    13.3 �    "           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            #           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            $           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            %           1262    34153 	   Prueboide    DATABASE     k   CREATE DATABASE "Prueboide" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Spanish_Argentina.1252';
    DROP DATABASE "Prueboide";
                postgres    false            �           1247    34155    cuit    DOMAIN     ~   CREATE DOMAIN public.cuit AS character varying(13)
	CONSTRAINT cuit_check CHECK (((VALUE)::bigint <= '99999999999'::bigint));
    DROP DOMAIN public.cuit;
       public          postgres    false            �           1247    34158    dni    DOMAIN     o   CREATE DOMAIN public.dni AS character varying(8)
	CONSTRAINT dni_check CHECK (((VALUE)::integer <= 99999999));
    DROP DOMAIN public.dni;
       public          postgres    false            �           1247    34161    mesaño    DOMAIN     �   CREATE DOMAIN public."mesaño" AS character varying(7)
	CONSTRAINT date_check CHECK (('1990-01-01'::date < to_date(('01-'::text || (VALUE)::text), 'DD-MM-YYYY'::text)))
	CONSTRAINT format_check CHECK ((3 = "position"((VALUE)::text, '-'::text)));
    DROP DOMAIN public."mesaño";
       public          postgres    false            �            1255    34164 (   calcular_recargo(integer, integer, date)    FUNCTION     �  CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota date) RETURNS double precision
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
       public          postgres    false                       1255    34165 4   calcular_recargo(integer, integer, public."mesaño")    FUNCTION     b  CREATE FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota public."mesaño") RETURNS double precision
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
 h   DROP FUNCTION public.calcular_recargo(inmueble integer, cliente integer, fecha_cuota public."mesaño");
       public          postgres    false    705            �            1255    34166 #   empleados_dependientes(public.cuit)    FUNCTION     +  CREATE FUNCTION public.empleados_dependientes(public.cuit) RETURNS SETOF record
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
                        from empleados_dependientes(e.cuit) as (cuit cuit, apellido_nombre varchar(70),fecha_ingreso date, cargo varchar(150), depende cuit)
                        LOOP
                            return next e2;
                        end LOOP;
                return next e;
            end LOOP;
            return;
    end;
    $_$;
 :   DROP FUNCTION public.empleados_dependientes(public.cuit);
       public          postgres    false    697            �            1255    34167 !   sp_actualizar_periodo_ocupacion()    FUNCTION     5  CREATE FUNCTION public.sp_actualizar_periodo_ocupacion() RETURNS trigger
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
       public          postgres    false            �            1255    34168     sp_actualizar_usuario_y_tiempo()    FUNCTION     �   CREATE FUNCTION public.sp_actualizar_usuario_y_tiempo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
NEW.ultimo_usuario = CURRENT_USER;
NEW.ultimo_horario = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$;
 7   DROP FUNCTION public.sp_actualizar_usuario_y_tiempo();
       public          postgres    false                        1255    34169    sp_agregar_fecha_vencimiento()    FUNCTION     0  CREATE FUNCTION public.sp_agregar_fecha_vencimiento() RETURNS trigger
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
       public          postgres    false                       1255    34170    sp_aumentar_precio_periodico()    FUNCTION     �  CREATE FUNCTION public.sp_aumentar_precio_periodico() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE n_mes integer = 0;
DECLARE periodicidad integer;
DECLARE porcentaje_aumento decimal(10, 2);
BEGIN

SELECT periodicidad_aumento, porcentaje_aumento_periodicidad INTO periodicidad, porcentaje_aumento 
FROM contratoAlquiler 
WHERE NEW.id_inmueble = id_inmueble AND NEW.id_cliente = id_cliente;

SELECT ABS(DATE_PART('MONTH',SP_convertir_mesaño_date(NEW.mesaño)) - DATE_PART('MONTH', fechaContrato))
 INTO n_mes 
FROM contratoAlquiler WHERE NEW.id_inmueble = id_inmueble 
AND NEW.id_cliente = id_cliente;

	IF (mod(n_mes, periodicidad) = 0) THEN
		porcentaje_aumento = porcentaje_aumento + 1.00;
		INSERT INTO precioalquiler(
		id_inmueble, id_cliente, importe, fechadefinicion)
		VALUES (NEW.id_inmueble, NEW.id_cliente, NEW.importe * porcentaje_aumento, CURRENT_DATE);
	END IF;
	
	RETURN NULL;
END;
$$;
 5   DROP FUNCTION public.sp_aumentar_precio_periodico();
       public          postgres    false                       1255    34171    sp_autoincremental_control()    FUNCTION     v  CREATE FUNCTION public.sp_autoincremental_control() RETURNS trigger
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
       public          postgres    false                       1255    34172    sp_cargarprecioalquiler()    FUNCTION     Z  CREATE FUNCTION public.sp_cargarprecioalquiler() RETURNS trigger
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
       public          postgres    false                       1255    34173 A   sp_check_facturacion_contrato(integer, integer, public."mesaño")    FUNCTION       CREATE FUNCTION public.sp_check_facturacion_contrato(inmueble integer, cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    705                       1255    34174 &   sp_contrato_isactivo(integer, integer)    FUNCTION     f  CREATE FUNCTION public.sp_contrato_isactivo(v_inmueble integer, v_cliente integer) RETURNS boolean
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
       public          postgres    false                       1255    34175    sp_convertir_date_mesaño(date)    FUNCTION     �   CREATE FUNCTION public."sp_convertir_date_mesaño"(fecha date) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN right(to_char(fecha, 'DD-MM-YYYY'), 7);
END;
$$;
 >   DROP FUNCTION public."sp_convertir_date_mesaño"(fecha date);
       public          postgres    false    705                       1255    34176 +   sp_convertir_mesaño_date(public."mesaño")    FUNCTION     �   CREATE FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño") RETURNS date
    LANGUAGE plpgsql
    AS $$
	BEGIN
	
		RETURN '01-' || v_mesaño; 
	END;
$$;
 P   DROP FUNCTION public."sp_convertir_mesaño_date"("v_mesaño" public."mesaño");
       public          postgres    false    705                       1255    34177 2   sp_crear_cuota(integer, integer, public."mesaño")    FUNCTION     j  CREATE FUNCTION public.sp_crear_cuota(v_inmueble integer, v_cliente integer, fechacrear public."mesaño") RETURNS boolean
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
       public          postgres    false    705            	           1255    34178    sp_crear_fecha_vencimiento()    FUNCTION     �   CREATE FUNCTION public.sp_crear_fecha_vencimiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.vencimiento_cuota = extract ('day' from new.fechaContrato);
RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.sp_crear_fecha_vencimiento();
       public          postgres    false            
           1255    34179    sp_crear_periodo_ocupacion()    FUNCTION       CREATE FUNCTION public.sp_crear_periodo_ocupacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO periodoocupacion(id_inmueble, fechainicio, fechabaja, motivobaja)
	VALUES (NEW.id_inmueble, NEW.fechaContrato, NULL, NULL);
	RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.sp_crear_periodo_ocupacion();
       public          postgres    false                       1255    34180    sp_dias_vencidos_recargo()    FUNCTION     u  CREATE FUNCTION public.sp_dias_vencidos_recargo() RETURNS trigger
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
 1   DROP FUNCTION public.sp_dias_vencidos_recargo();
       public          postgres    false                       1255    34181 7   sp_es_igual_mesaño(public."mesaño", public."mesaño")    FUNCTION     �   CREATE FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño) = SP_convertir_mesaño_date(comparar);

END;
$$;
 e   DROP FUNCTION public."sp_es_igual_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño");
       public          postgres    false    705    705                       1255    34182 7   sp_es_mayor_mesaño(public."mesaño", public."mesaño")    FUNCTION     �   CREATE FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño") RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño)>SP_convertir_mesaño_date(comparar);

END;
$$;
 e   DROP FUNCTION public."sp_es_mayor_mesaño"("v_mesaño" public."mesaño", comparar public."mesaño");
       public          postgres    false    705    705                       1255    34183 =   sp_esta_en_rango_contrato(integer, integer, public."mesaño")    FUNCTION     8  CREATE FUNCTION public.sp_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    705                       1255    34184 0   sp_esta_paga(integer, integer, public."mesaño")    FUNCTION     �  CREATE FUNCTION public.sp_esta_paga(v_cliente integer, v_inmueble integer, "v_mesaño" public."mesaño") RETURNS character varying
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
       public          postgres    false    705                       1255    34185 5   sp_esta_paga_bool(integer, integer, public."mesaño")    FUNCTION     ;  CREATE FUNCTION public.sp_esta_paga_bool(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    705            �            1255    34186 3   sp_existe_cuota(integer, integer, public."mesaño")    FUNCTION     X  CREATE FUNCTION public.sp_existe_cuota(v_inmueble integer, v_cliente integer, "v_mesaño" public."mesaño") RETURNS boolean
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
       public          postgres    false    705                       1255    34187 !   sp_historial_direcciones_dueño()    FUNCTION     I  CREATE FUNCTION public."sp_historial_direcciones_dueño"() RETURNS trigger
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
       public          postgres    false                       1255    34188    sp_importepago()    FUNCTION     �  CREATE FUNCTION public.sp_importepago() RETURNS trigger
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
       public          postgres    false                       1255    34189    sp_mi_propio_jefe()    FUNCTION     �   CREATE FUNCTION public.sp_mi_propio_jefe() RETURNS trigger
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
 *   DROP FUNCTION public.sp_mi_propio_jefe();
       public          postgres    false                       1255    34190    sp_modificar_nombre_cliente()    FUNCTION     %  CREATE FUNCTION public.sp_modificar_nombre_cliente() RETURNS trigger
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
       public          postgres    false                       1255    34191    sp_obtener_importe_cuota()    FUNCTION     �  CREATE FUNCTION public.sp_obtener_importe_cuota() RETURNS trigger
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
       public          postgres    false                       1255    34192 <   sp_obtener_importe_cuota(integer, integer, public."mesaño")    FUNCTION     �  CREATE FUNCTION public.sp_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechacontable public."mesaño") RETURNS double precision
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
       public          postgres    false    705                       1255    34193 H   sp_obtener_importe_por_tipo(integer, integer, public."mesaño", integer)    FUNCTION       CREATE FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer) RETURNS double precision
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
	select importePago INTO resultado from pagos
	where id_inmueble = inmueble AND id_cliente = cliente AND mesaño LIKE mes_año;
	select id_tipo_operacion INTO tipo_operacion FROM pagos;
	
ELSEIF operacion = 3 THEN
	select importeRecargo INTO resultado from recargos
	where id_inmueble = inmueble AND id_cliente = cliente AND mesaño LIKE mes_año;
	select id_tipo_operacion INTO tipo_operacion FROM recargos;
END IF;

IF tipo_operacion = 1 OR tipo_operacion = 3 THEN
	--Es Debito
	resultado = resultado * -1;
END IF;

RETURN resultado;
END;
$$;
 �   DROP FUNCTION public.sp_obtener_importe_por_tipo(inmueble integer, cliente integer, "mes_año" public."mesaño", operacion integer);
       public          postgres    false    705                       1255    34194 6   sp_obtener_mesaño_contrato(integer, integer, integer)    FUNCTION     �  CREATE FUNCTION public."sp_obtener_mesaño_contrato"(v_inmueble integer, v_cliente integer, mes integer) RETURNS public."mesaño"
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
       public          postgres    false    705                       1255    34195 6   sp_operacion_resta_mes_año(public."mesaño", integer)    FUNCTION     u  CREATE FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) - (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;
 c   DROP FUNCTION public."sp_operacion_resta_mes_año"("v_mesaño" public."mesaño", v_valor integer);
       public          postgres    false    705    705            �            1255    34196 5   sp_operacion_suma_mes_año(public."mesaño", integer)    FUNCTION     t  CREATE FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer) RETURNS public."mesaño"
    LANGUAGE plpgsql
    AS $$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) + (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$;
 b   DROP FUNCTION public."sp_operacion_suma_mes_año"("v_mesaño" public."mesaño", v_valor integer);
       public          postgres    false    705    705            �            1255    34197 2   sp_pagar_cuota(integer, integer, public."mesaño")    FUNCTION       CREATE FUNCTION public.sp_pagar_cuota(v_inmueble integer, v_cliente integer, v_cuota public."mesaño") RETURNS boolean
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
       public          postgres    false    705                       1255    34198     sp_validar_integridad_contrato()    FUNCTION     Y  CREATE FUNCTION public.sp_validar_integridad_contrato() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	IF NOT EXISTS (Select * from contratoAlquiler 
				  where id_inmueble= NEW.id_inmueble AND id_estado = 1)
	THEN
		RETURN NEW;
	END IF;

RAISE NOTICE 'Ya existe un contrato que esta activo para este inmueble';
RETURN NULL;

END;
$$;
 7   DROP FUNCTION public.sp_validar_integridad_contrato();
       public          postgres    false                       1255    34199    sp_verificar_jefe_maximo()    FUNCTION     U  CREATE FUNCTION public.sp_verificar_jefe_maximo() RETURNS trigger
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
 1   DROP FUNCTION public.sp_verificar_jefe_maximo();
       public          postgres    false                       1255    34200    tg_iniciar_historial_dueños()    FUNCTION     /  CREATE FUNCTION public."tg_iniciar_historial_dueños"() RETURNS trigger
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
 7   DROP FUNCTION public."tg_iniciar_historial_dueños"();
       public          postgres    false            �            1259    34201    anuncios    TABLE     e  CREATE TABLE public.anuncios (
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
       public         heap    postgres    false            �            1259    34204    clientes    TABLE     �   CREATE TABLE public.clientes (
    id_cliente integer NOT NULL,
    id_persona integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.clientes;
       public         heap    postgres    false            �            1259    34207    contratoalquiler    TABLE     H  CREATE TABLE public.contratoalquiler (
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    fechacontrato date DEFAULT CURRENT_DATE NOT NULL,
    id_estado integer DEFAULT 1 NOT NULL,
    periodo_vigencia integer NOT NULL,
    vencimiento_cuota integer DEFAULT 10 NOT NULL,
    id_finalidad integer,
    precio_inicial double precision NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL,
    periodicidad_aumento integer DEFAULT 6,
    porcentaje_aumento_periodicidad double precision DEFAULT 0.1
);
 $   DROP TABLE public.contratoalquiler;
       public         heap    postgres    false            �            1259    34213    contratos_estados    TABLE     �   CREATE TABLE public.contratos_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 %   DROP TABLE public.contratos_estados;
       public         heap    postgres    false            �            1259    34216    contratos_finalidades    TABLE     �   CREATE TABLE public.contratos_finalidades (
    id_finalidad integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 )   DROP TABLE public.contratos_finalidades;
       public         heap    postgres    false            �            1259    34219    cuotas    TABLE     k  CREATE TABLE public.cuotas (
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
       public         heap    postgres    false    705            �            1259    34226    personas    TABLE     D  CREATE TABLE public.personas (
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
       public         heap    postgres    false    701            �            1259    34232    tipo_operacion_contable    TABLE     �   CREATE TABLE public.tipo_operacion_contable (
    id_tipo_operacion integer NOT NULL,
    descripcion character varying(50),
    debito boolean,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 +   DROP TABLE public.tipo_operacion_contable;
       public         heap    postgres    false            �            1259    34235    cuota_cta_cte    VIEW     /  CREATE VIEW public.cuota_cta_cte AS
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
       public          postgres    false    280    201    201    205    205    205    205    206    206    207    207    705            �            1259    34240    pagos    TABLE     �  CREATE TABLE public.pagos (
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
       public         heap    postgres    false    705            �            1259    34248    pago_cta_cte    VIEW     &  CREATE VIEW public.pago_cta_cte AS
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
       public          postgres    false    280    209    209    209    209    207    207    206    206    201    201    705            �            1259    34253    recargos    TABLE     }  CREATE TABLE public.recargos (
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
       public         heap    postgres    false    705            �            1259    34261    recargo_cta_cte    VIEW     A  CREATE VIEW public.recargo_cta_cte AS
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
       public          postgres    false    201    211    211    211    211    207    207    206    206    201    280    705            �            1259    34266    cta_cte_cliente    VIEW     �  CREATE VIEW public.cta_cte_cliente AS
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
       public          postgres    false    212    212    212    212    212    210    210    210    210    210    208    208    208    208    208    705            �            1259    34270    direcciones    TABLE     �  CREATE TABLE public.direcciones (
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
       public         heap    postgres    false            �            1259    34273    localidades    TABLE       CREATE TABLE public.localidades (
    id_localidad integer NOT NULL,
    nombre character varying(50) NOT NULL,
    codigo_postal integer,
    id_provincia integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.localidades;
       public         heap    postgres    false            �            1259    34276    localizaciones    TABLE     �   CREATE TABLE public.localizaciones (
    id_localizacion integer NOT NULL,
    provincia character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 "   DROP TABLE public.localizaciones;
       public         heap    postgres    false            �            1259    34279    direccion_completa    VIEW     �  CREATE VIEW public.direccion_completa AS
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
       public          postgres    false    215    215    214    214    214    214    216    216    214    215    215    214    214            �            1259    34284    divisas    TABLE       CREATE TABLE public.divisas (
    id_divisa integer NOT NULL,
    acronimo character varying(3) NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.divisas;
       public         heap    postgres    false            �            1259    34287    dueños    TABLE     �   CREATE TABLE public."dueños" (
    "id_dueño" integer NOT NULL,
    id_persona integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public."dueños";
       public         heap    postgres    false            �            1259    34290 	   empleados    TABLE     �   CREATE TABLE public.empleados (
    cuit public.cuit NOT NULL,
    apellido_nombre character varying(70),
    fecha_ingreso date NOT NULL,
    cargo character varying(150) NOT NULL,
    superior public.cuit
);
    DROP TABLE public.empleados;
       public         heap    postgres    false    697    697            �            1259    34296    garante    TABLE     `  CREATE TABLE public.garante (
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
       public         heap    postgres    false    701            �            1259    34302    historial_direcciones    TABLE     �  CREATE TABLE public.historial_direcciones (
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
 )   DROP TABLE public.historial_direcciones;
       public         heap    postgres    false            �            1259    34305 &   historial_direcciones_id_historial_seq    SEQUENCE     �   CREATE SEQUENCE public.historial_direcciones_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.historial_direcciones_id_historial_seq;
       public          postgres    false    222            &           0    0 &   historial_direcciones_id_historial_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.historial_direcciones_id_historial_seq OWNED BY public.historial_direcciones.id_historial;
          public          postgres    false    223            �            1259    34307 	   inmuebles    TABLE     �  CREATE TABLE public.inmuebles (
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
       public         heap    postgres    false            �            1259    34310    inmuebles_operaciones    TABLE     �   CREATE TABLE public.inmuebles_operaciones (
    id_inmueble integer NOT NULL,
    id_operacion integer NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 )   DROP TABLE public.inmuebles_operaciones;
       public         heap    postgres    false            �            1259    34313    periodoocupacion    TABLE     2  CREATE TABLE public.periodoocupacion (
    id_periodo integer NOT NULL,
    id_inmueble integer NOT NULL,
    fechainicio date NOT NULL,
    fechabaja date,
    motivobaja character varying(100),
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 $   DROP TABLE public.periodoocupacion;
       public         heap    postgres    false            �            1259    34316    precios    TABLE     �   CREATE TABLE public.precios (
    id_precio integer NOT NULL,
    id_divisa integer NOT NULL,
    monto double precision NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.precios;
       public         heap    postgres    false            �            1259    34319    precio_inmueble    VIEW     �   CREATE VIEW public.precio_inmueble AS
 SELECT p.id_precio,
    p.monto,
    d.acronimo
   FROM (public.precios p
     JOIN public.divisas d ON ((p.id_divisa = d.id_divisa)));
 "   DROP VIEW public.precio_inmueble;
       public          postgres    false    218    218    227    227    227            �            1259    34323    tipoinmueble    TABLE     �   CREATE TABLE public.tipoinmueble (
    id_tipo integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
     DROP TABLE public.tipoinmueble;
       public         heap    postgres    false            �            1259    34326    info_inmuebles_completa    VIEW     �	  CREATE VIEW public.info_inmuebles_completa AS
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
       public          postgres    false    219    229    229    228    228    228    226    226    225    225    224    224    224    224    224    224    219    217    217    217    217    217    217    217    217    217    206    206    200    200            �            1259    34331    informacion_cuotas    VIEW     �  CREATE VIEW public.informacion_cuotas AS
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
       public          postgres    false    230    271    201    201    202    205    205    205    206    206    206    206    206    206    206    206    202    202    705    701            �            1259    34336    inmuebles_estados    TABLE     �   CREATE TABLE public.inmuebles_estados (
    id_estado integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 %   DROP TABLE public.inmuebles_estados;
       public         heap    postgres    false            �            1259    34339    operaciones    TABLE     �   CREATE TABLE public.operaciones (
    id_operacion integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
    DROP TABLE public.operaciones;
       public         heap    postgres    false            �            1259    34342    periodoocupacion_id_periodo_seq    SEQUENCE     �   CREATE SEQUENCE public.periodoocupacion_id_periodo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.periodoocupacion_id_periodo_seq;
       public          postgres    false    226            '           0    0    periodoocupacion_id_periodo_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.periodoocupacion_id_periodo_seq OWNED BY public.periodoocupacion.id_periodo;
          public          postgres    false    234            �            1259    34344    precioalquiler    TABLE     H  CREATE TABLE public.precioalquiler (
    id_precioalquiler integer NOT NULL,
    id_inmueble integer NOT NULL,
    id_cliente integer NOT NULL,
    importe double precision NOT NULL,
    fechadefinicion date NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
 "   DROP TABLE public.precioalquiler;
       public         heap    postgres    false            �            1259    34347 $   precioalquiler_id_precioalquiler_seq    SEQUENCE     �   CREATE SEQUENCE public.precioalquiler_id_precioalquiler_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.precioalquiler_id_precioalquiler_seq;
       public          postgres    false    235            (           0    0 $   precioalquiler_id_precioalquiler_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.precioalquiler_id_precioalquiler_seq OWNED BY public.precioalquiler.id_precioalquiler;
          public          postgres    false    236            �            1259    34349    tipogarantia    TABLE     �   CREATE TABLE public.tipogarantia (
    id_garantia integer NOT NULL,
    descripcion character varying(50) NOT NULL,
    ultimo_usuario character varying(50) NOT NULL,
    ultimo_horario timestamp without time zone NOT NULL
);
     DROP TABLE public.tipogarantia;
       public         heap    postgres    false            �           2604    34352 "   historial_direcciones id_historial    DEFAULT     �   ALTER TABLE ONLY public.historial_direcciones ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_direcciones_id_historial_seq'::regclass);
 Q   ALTER TABLE public.historial_direcciones ALTER COLUMN id_historial DROP DEFAULT;
       public          postgres    false    223    222            �           2604    34353    periodoocupacion id_periodo    DEFAULT     �   ALTER TABLE ONLY public.periodoocupacion ALTER COLUMN id_periodo SET DEFAULT nextval('public.periodoocupacion_id_periodo_seq'::regclass);
 J   ALTER TABLE public.periodoocupacion ALTER COLUMN id_periodo DROP DEFAULT;
       public          postgres    false    234    226            �           2604    34354     precioalquiler id_precioalquiler    DEFAULT     �   ALTER TABLE ONLY public.precioalquiler ALTER COLUMN id_precioalquiler SET DEFAULT nextval('public.precioalquiler_id_precioalquiler_seq'::regclass);
 O   ALTER TABLE public.precioalquiler ALTER COLUMN id_precioalquiler DROP DEFAULT;
       public          postgres    false    236    235                      0    34201    anuncios 
   TABLE DATA                 public          postgres    false    200   ��                0    34204    clientes 
   TABLE DATA                 public          postgres    false    201   ��                0    34207    contratoalquiler 
   TABLE DATA                 public          postgres    false    202   e�                0    34213    contratos_estados 
   TABLE DATA                 public          postgres    false    203   ��                0    34216    contratos_finalidades 
   TABLE DATA                 public          postgres    false    204   e�                0    34219    cuotas 
   TABLE DATA                 public          postgres    false    205   1�                0    34270    direcciones 
   TABLE DATA                 public          postgres    false    214   }�                0    34284    divisas 
   TABLE DATA                 public          postgres    false    218   ��                0    34287    dueños 
   TABLE DATA                 public          postgres    false    219   n�                0    34290 	   empleados 
   TABLE DATA                 public          postgres    false    220   �                0    34296    garante 
   TABLE DATA                 public          postgres    false    221   �                0    34302    historial_direcciones 
   TABLE DATA                 public          postgres    false    222   �                0    34307 	   inmuebles 
   TABLE DATA                 public          postgres    false    224   �                0    34336    inmuebles_estados 
   TABLE DATA                 public          postgres    false    232   ��                0    34310    inmuebles_operaciones 
   TABLE DATA                 public          postgres    false    225   ��                0    34273    localidades 
   TABLE DATA                 public          postgres    false    215   k�                0    34276    localizaciones 
   TABLE DATA                 public          postgres    false    216   �                0    34339    operaciones 
   TABLE DATA                 public          postgres    false    233   v�      
          0    34240    pagos 
   TABLE DATA                 public          postgres    false    209   �                0    34313    periodoocupacion 
   TABLE DATA                 public          postgres    false    226   m�                0    34226    personas 
   TABLE DATA                 public          postgres    false    206   X�                0    34344    precioalquiler 
   TABLE DATA                 public          postgres    false    235   ��                0    34316    precios 
   TABLE DATA                 public          postgres    false    227   ��                0    34253    recargos 
   TABLE DATA                 public          postgres    false    211   D�      	          0    34232    tipo_operacion_contable 
   TABLE DATA                 public          postgres    false    207   ��                0    34349    tipogarantia 
   TABLE DATA                 public          postgres    false    237   w�                0    34323    tipoinmueble 
   TABLE DATA                 public          postgres    false    229   2�      )           0    0 &   historial_direcciones_id_historial_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('public.historial_direcciones_id_historial_seq', 1, false);
          public          postgres    false    223            *           0    0    periodoocupacion_id_periodo_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.periodoocupacion_id_periodo_seq', 2, true);
          public          postgres    false    234            +           0    0 $   precioalquiler_id_precioalquiler_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.precioalquiler_id_precioalquiler_seq', 3, true);
          public          postgres    false    236            �           2606    34356    anuncios anuncios_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.anuncios
    ADD CONSTRAINT anuncios_pkey PRIMARY KEY (id_anuncio);
 @   ALTER TABLE ONLY public.anuncios DROP CONSTRAINT anuncios_pkey;
       public            postgres    false    200            �           2606    34358     clientes clientes_id_cliente_key 
   CONSTRAINT     a   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_cliente_key UNIQUE (id_cliente);
 J   ALTER TABLE ONLY public.clientes DROP CONSTRAINT clientes_id_cliente_key;
       public            postgres    false    201            �           2606    34360    clientes clientes_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id_cliente, id_persona);
 @   ALTER TABLE ONLY public.clientes DROP CONSTRAINT clientes_pkey;
       public            postgres    false    201    201            �           2606    34362 &   contratoalquiler contratoalquiler_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente);
 P   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_pkey;
       public            postgres    false    202    202            �           2606    34364 (   contratos_estados contratos_estados_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.contratos_estados
    ADD CONSTRAINT contratos_estados_pkey PRIMARY KEY (id_estado);
 R   ALTER TABLE ONLY public.contratos_estados DROP CONSTRAINT contratos_estados_pkey;
       public            postgres    false    203            �           2606    34366 0   contratos_finalidades contratos_finalidades_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.contratos_finalidades
    ADD CONSTRAINT contratos_finalidades_pkey PRIMARY KEY (id_finalidad);
 Z   ALTER TABLE ONLY public.contratos_finalidades DROP CONSTRAINT contratos_finalidades_pkey;
       public            postgres    false    204                        2606    34368    cuotas cuotas_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 <   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_pkey;
       public            postgres    false    205    205    205            
           2606    34370    direcciones direcciones_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_pkey PRIMARY KEY (id_direccion);
 F   ALTER TABLE ONLY public.direcciones DROP CONSTRAINT direcciones_pkey;
       public            postgres    false    214                       2606    34372    divisas divisas_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.divisas
    ADD CONSTRAINT divisas_pkey PRIMARY KEY (id_divisa);
 >   ALTER TABLE ONLY public.divisas DROP CONSTRAINT divisas_pkey;
       public            postgres    false    218                       2606    34374    dueños dueños_id_dueño_key 
   CONSTRAINT     c   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_id_dueño_key" UNIQUE ("id_dueño");
 K   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "dueños_id_dueño_key";
       public            postgres    false    219                       2606    34376    dueños dueños_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "dueños_pkey" PRIMARY KEY ("id_dueño", id_persona);
 B   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "dueños_pkey";
       public            postgres    false    219    219                       2606    34378    empleados empleados_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_pkey PRIMARY KEY (cuit);
 B   ALTER TABLE ONLY public.empleados DROP CONSTRAINT empleados_pkey;
       public            postgres    false    220                       2606    34380    garante garante_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT garante_pkey PRIMARY KEY (id_inmueble, id_cliente, dni);
 >   ALTER TABLE ONLY public.garante DROP CONSTRAINT garante_pkey;
       public            postgres    false    221    221    221                       2606    34382 0   historial_direcciones historial_direcciones_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT historial_direcciones_pkey PRIMARY KEY (id_historial);
 Z   ALTER TABLE ONLY public.historial_direcciones DROP CONSTRAINT historial_direcciones_pkey;
       public            postgres    false    222            &           2606    34384 (   inmuebles_estados inmuebles_estados_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.inmuebles_estados
    ADD CONSTRAINT inmuebles_estados_pkey PRIMARY KEY (id_estado);
 R   ALTER TABLE ONLY public.inmuebles_estados DROP CONSTRAINT inmuebles_estados_pkey;
       public            postgres    false    232                       2606    34386 0   inmuebles_operaciones inmuebles_operaciones_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_pkey PRIMARY KEY (id_inmueble, id_operacion);
 Z   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_pkey;
       public            postgres    false    225    225                       2606    34388    inmuebles inmuebles_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_pkey PRIMARY KEY (id_inmueble);
 B   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_pkey;
       public            postgres    false    224                       2606    34390    localidades localidades_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_pkey PRIMARY KEY (id_localidad);
 F   ALTER TABLE ONLY public.localidades DROP CONSTRAINT localidades_pkey;
       public            postgres    false    215                       2606    34392 "   localizaciones localizaciones_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.localizaciones
    ADD CONSTRAINT localizaciones_pkey PRIMARY KEY (id_localizacion);
 L   ALTER TABLE ONLY public.localizaciones DROP CONSTRAINT localizaciones_pkey;
       public            postgres    false    216            (           2606    34394    operaciones operaciones_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_pkey PRIMARY KEY (id_operacion);
 F   ALTER TABLE ONLY public.operaciones DROP CONSTRAINT operaciones_pkey;
       public            postgres    false    233                       2606    34396    pagos pagos_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 :   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_pkey;
       public            postgres    false    209    209    209                        2606    34398 &   periodoocupacion periodoocupacion_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_pkey PRIMARY KEY (id_periodo);
 P   ALTER TABLE ONLY public.periodoocupacion DROP CONSTRAINT periodoocupacion_pkey;
       public            postgres    false    226                       2606    34400    personas personas_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (id_persona);
 @   ALTER TABLE ONLY public.personas DROP CONSTRAINT personas_pkey;
       public            postgres    false    206            *           2606    34402 "   precioalquiler precioalquiler_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_pkey PRIMARY KEY (id_inmueble, id_cliente, id_precioalquiler);
 L   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_pkey;
       public            postgres    false    235    235    235            "           2606    34404    precios precios_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_pkey PRIMARY KEY (id_precio);
 >   ALTER TABLE ONLY public.precios DROP CONSTRAINT precios_pkey;
       public            postgres    false    227                       2606    34406    recargos recargos_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_pkey PRIMARY KEY (id_inmueble, id_cliente, "mesaño");
 @   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_pkey;
       public            postgres    false    211    211    211                       2606    34408 4   tipo_operacion_contable tipo_operacion_contable_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.tipo_operacion_contable
    ADD CONSTRAINT tipo_operacion_contable_pkey PRIMARY KEY (id_tipo_operacion);
 ^   ALTER TABLE ONLY public.tipo_operacion_contable DROP CONSTRAINT tipo_operacion_contable_pkey;
       public            postgres    false    207            ,           2606    34410    tipogarantia tipogarantia_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.tipogarantia
    ADD CONSTRAINT tipogarantia_pkey PRIMARY KEY (id_garantia);
 H   ALTER TABLE ONLY public.tipogarantia DROP CONSTRAINT tipogarantia_pkey;
       public            postgres    false    237            $           2606    34412    tipoinmueble tipoinmueble_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.tipoinmueble
    ADD CONSTRAINT tipoinmueble_pkey PRIMARY KEY (id_tipo);
 H   ALTER TABLE ONLY public.tipoinmueble DROP CONSTRAINT tipoinmueble_pkey;
       public            postgres    false    229            S           2620    34413 0   contratoalquiler tg_actualizar_periodo_ocupacion    TRIGGER     �   CREATE TRIGGER tg_actualizar_periodo_ocupacion BEFORE UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_periodo_ocupacion();
 I   DROP TRIGGER tg_actualizar_periodo_ocupacion ON public.contratoalquiler;
       public          postgres    false    242    202            [           2620    34414 #   cuotas tg_agregar_fecha_vencimiento    TRIGGER     �   CREATE TRIGGER tg_agregar_fecha_vencimiento BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_agregar_fecha_vencimiento();
 <   DROP TRIGGER tg_agregar_fecha_vencimiento ON public.cuotas;
       public          postgres    false    256    205            Q           2620    34415 "   anuncios tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.anuncios FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.anuncios;
       public          postgres    false    200    243            R           2620    34416 "   clientes tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.clientes;
       public          postgres    false    243    201            T           2620    34417 *   contratoalquiler tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 C   DROP TRIGGER tg_auditorio_modificacion ON public.contratoalquiler;
       public          postgres    false    243    202            Y           2620    34418 +   contratos_estados tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratos_estados FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 D   DROP TRIGGER tg_auditorio_modificacion ON public.contratos_estados;
       public          postgres    false    203    243            Z           2620    34419 /   contratos_finalidades tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.contratos_finalidades FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 H   DROP TRIGGER tg_auditorio_modificacion ON public.contratos_finalidades;
       public          postgres    false    204    243            \           2620    34420     cuotas tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 9   DROP TRIGGER tg_auditorio_modificacion ON public.cuotas;
       public          postgres    false    243    205            f           2620    34421 %   direcciones tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 >   DROP TRIGGER tg_auditorio_modificacion ON public.direcciones;
       public          postgres    false    243    214            j           2620    34422 !   divisas tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.divisas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 :   DROP TRIGGER tg_auditorio_modificacion ON public.divisas;
       public          postgres    false    243    218            k           2620    34423 !   dueños tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public."dueños" FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 <   DROP TRIGGER tg_auditorio_modificacion ON public."dueños";
       public          postgres    false    243    219            m           2620    34424 !   garante tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.garante FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 :   DROP TRIGGER tg_auditorio_modificacion ON public.garante;
       public          postgres    false    243    221            n           2620    34425 #   inmuebles tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 <   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles;
       public          postgres    false    243    224            t           2620    34426 +   inmuebles_estados tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles_estados FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 D   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles_estados;
       public          postgres    false    243    232            p           2620    34427 /   inmuebles_operaciones tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.inmuebles_operaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 H   DROP TRIGGER tg_auditorio_modificacion ON public.inmuebles_operaciones;
       public          postgres    false    225    243            h           2620    34428 %   localidades tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.localidades FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 >   DROP TRIGGER tg_auditorio_modificacion ON public.localidades;
       public          postgres    false    243    215            i           2620    34429 (   localizaciones tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.localizaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 A   DROP TRIGGER tg_auditorio_modificacion ON public.localizaciones;
       public          postgres    false    216    243            u           2620    34430 %   operaciones tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.operaciones FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 >   DROP TRIGGER tg_auditorio_modificacion ON public.operaciones;
       public          postgres    false    243    233            a           2620    34431    pagos tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 8   DROP TRIGGER tg_auditorio_modificacion ON public.pagos;
       public          postgres    false    243    209            q           2620    34432 *   periodoocupacion tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.periodoocupacion FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 C   DROP TRIGGER tg_auditorio_modificacion ON public.periodoocupacion;
       public          postgres    false    226    243            _           2620    34433 "   personas tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.personas FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.personas;
       public          postgres    false    243    206            v           2620    34434 (   precioalquiler tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.precioalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 A   DROP TRIGGER tg_auditorio_modificacion ON public.precioalquiler;
       public          postgres    false    235    243            r           2620    34435 !   precios tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.precios FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 :   DROP TRIGGER tg_auditorio_modificacion ON public.precios;
       public          postgres    false    243    227            c           2620    34436 "   recargos tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.recargos FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ;   DROP TRIGGER tg_auditorio_modificacion ON public.recargos;
       public          postgres    false    211    243            `           2620    34437 1   tipo_operacion_contable tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipo_operacion_contable FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 J   DROP TRIGGER tg_auditorio_modificacion ON public.tipo_operacion_contable;
       public          postgres    false    243    207            w           2620    34438 &   tipogarantia tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipogarantia FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ?   DROP TRIGGER tg_auditorio_modificacion ON public.tipogarantia;
       public          postgres    false    237    243            s           2620    34439 &   tipoinmueble tg_auditorio_modificacion    TRIGGER     �   CREATE TRIGGER tg_auditorio_modificacion BEFORE INSERT OR UPDATE ON public.tipoinmueble FOR EACH ROW EXECUTE FUNCTION public.sp_actualizar_usuario_y_tiempo();
 ?   DROP TRIGGER tg_auditorio_modificacion ON public.tipoinmueble;
       public          postgres    false    243    229            ]           2620    34440 #   cuotas tg_aumentar_precio_periodico    TRIGGER     �   CREATE TRIGGER tg_aumentar_precio_periodico AFTER INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_aumentar_precio_periodico();
 <   DROP TRIGGER tg_aumentar_precio_periodico ON public.cuotas;
       public          postgres    false    285    205            o           2620    34441 $   inmuebles tg_autoincremental_control    TRIGGER     �   CREATE TRIGGER tg_autoincremental_control BEFORE INSERT ON public.inmuebles FOR EACH ROW EXECUTE FUNCTION public.sp_autoincremental_control();
 =   DROP TRIGGER tg_autoincremental_control ON public.inmuebles;
       public          postgres    false    257    224            U           2620    34442 (   contratoalquiler tg_cargarprecioalquiler    TRIGGER     �   CREATE TRIGGER tg_cargarprecioalquiler AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_cargarprecioalquiler();
 A   DROP TRIGGER tg_cargarprecioalquiler ON public.contratoalquiler;
       public          postgres    false    258    202            V           2620    34443 +   contratoalquiler tg_crear_fecha_vencimiento    TRIGGER     �   CREATE TRIGGER tg_crear_fecha_vencimiento BEFORE INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_fecha_vencimiento();
 D   DROP TRIGGER tg_crear_fecha_vencimiento ON public.contratoalquiler;
       public          postgres    false    202    265            W           2620    34444 +   contratoalquiler tg_crear_periodo_ocupacion    TRIGGER     �   CREATE TRIGGER tg_crear_periodo_ocupacion AFTER INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_crear_periodo_ocupacion();
 D   DROP TRIGGER tg_crear_periodo_ocupacion ON public.contratoalquiler;
       public          postgres    false    266    202            d           2620    34445 !   recargos tg_dias_vencidos_recargo    TRIGGER     �   CREATE TRIGGER tg_dias_vencidos_recargo BEFORE INSERT ON public.recargos FOR EACH ROW EXECUTE FUNCTION public.sp_dias_vencidos_recargo();
 :   DROP TRIGGER tg_dias_vencidos_recargo ON public.recargos;
       public          postgres    false    267    211            g           2620    34446 +   direcciones tg_historial_direcciones_dueño    TRIGGER     �   CREATE TRIGGER "tg_historial_direcciones_dueño" BEFORE DELETE OR UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public."sp_historial_direcciones_dueño"();
 F   DROP TRIGGER "tg_historial_direcciones_dueño" ON public.direcciones;
       public          postgres    false    214    274            b           2620    34447    pagos tg_importepago    TRIGGER     s   CREATE TRIGGER tg_importepago BEFORE INSERT ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.sp_importepago();
 -   DROP TRIGGER tg_importepago ON public.pagos;
       public          postgres    false    209    275            l           2620    34448 $   dueños tg_iniciar_historial_dueños    TRIGGER     �   CREATE TRIGGER "tg_iniciar_historial_dueños" AFTER INSERT ON public."dueños" FOR EACH ROW EXECUTE FUNCTION public."tg_iniciar_historial_dueños"();
 A   DROP TRIGGER "tg_iniciar_historial_dueños" ON public."dueños";
       public          postgres    false    219    283            e           2620    34449 +   cta_cte_cliente tg_modificar_nombre_cliente    TRIGGER     �   CREATE TRIGGER tg_modificar_nombre_cliente INSTEAD OF UPDATE ON public.cta_cte_cliente FOR EACH ROW EXECUTE FUNCTION public.sp_modificar_nombre_cliente();
 D   DROP TRIGGER tg_modificar_nombre_cliente ON public.cta_cte_cliente;
       public          postgres    false    277    213            ^           2620    34450    cuotas tg_obtener_importe_cuota    TRIGGER     �   CREATE TRIGGER tg_obtener_importe_cuota BEFORE INSERT ON public.cuotas FOR EACH ROW EXECUTE FUNCTION public.sp_obtener_importe_cuota();
 8   DROP TRIGGER tg_obtener_importe_cuota ON public.cuotas;
       public          postgres    false    278    205            X           2620    34451 /   contratoalquiler tg_validar_integridad_contrato    TRIGGER     �   CREATE TRIGGER tg_validar_integridad_contrato BEFORE INSERT ON public.contratoalquiler FOR EACH ROW EXECUTE FUNCTION public.sp_validar_integridad_contrato();
 H   DROP TRIGGER tg_validar_integridad_contrato ON public.contratoalquiler;
       public          postgres    false    273    202            .           2606    34452 0   contratoalquiler contratoalquiler_id_estado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.contratos_estados(id_estado);
 Z   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_id_estado_fkey;
       public          postgres    false    202    3068    203            /           2606    34457 3   contratoalquiler contratoalquiler_id_finalidad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT contratoalquiler_id_finalidad_fkey FOREIGN KEY (id_finalidad) REFERENCES public.contratos_finalidades(id_finalidad);
 ]   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT contratoalquiler_id_finalidad_fkey;
       public          postgres    false    204    3070    202            2           2606    34462    cuotas cuotas_id_cliente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_cliente_fkey;
       public          postgres    false    3062    201    205            3           2606    34467    cuotas cuotas_id_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_inmueble_fkey;
       public          postgres    false    224    205    3100            4           2606    34472 $   cuotas cuotas_id_tipo_operacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuotas
    ADD CONSTRAINT cuotas_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 N   ALTER TABLE ONLY public.cuotas DROP CONSTRAINT cuotas_id_tipo_operacion_fkey;
       public          postgres    false    207    3076    205            <           2606    34477 )   direcciones direcciones_id_localidad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);
 S   ALTER TABLE ONLY public.direcciones DROP CONSTRAINT direcciones_id_localidad_fkey;
       public          postgres    false    3084    215    214            ?           2606    34482 !   empleados empleados_superior_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_superior_fkey FOREIGN KEY (superior) REFERENCES public.empleados(cuit);
 K   ALTER TABLE ONLY public.empleados DROP CONSTRAINT empleados_superior_fkey;
       public          postgres    false    220    220    3094            -           2606    34487    clientes fk_cliente_persona    FK CONSTRAINT     �   ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.clientes DROP CONSTRAINT fk_cliente_persona;
       public          postgres    false    206    201    3074            0           2606    34492 $   contratoalquiler fk_contrato_cliente    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT fk_contrato_cliente;
       public          postgres    false    201    3062    202            1           2606    34497 %   contratoalquiler fk_contrato_inmueble    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratoalquiler
    ADD CONSTRAINT fk_contrato_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.contratoalquiler DROP CONSTRAINT fk_contrato_inmueble;
       public          postgres    false    3100    202    224            5           2606    34502    personas fk_direccion    FK CONSTRAINT     �   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_direccion FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);
 ?   ALTER TABLE ONLY public.personas DROP CONSTRAINT fk_direccion;
       public          postgres    false    3082    206    214            >           2606    34507    dueños fk_dueÑo_persona    FK CONSTRAINT     �   ALTER TABLE ONLY public."dueños"
    ADD CONSTRAINT "fk_dueÑo_persona" FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public."dueños" DROP CONSTRAINT "fk_dueÑo_persona";
       public          postgres    false    219    3074    206            @           2606    34512    garante fk_garante_cliente    FK CONSTRAINT     �   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_cliente;
       public          postgres    false    221    3062    201            A           2606    34517    garante fk_garante_inmueble    FK CONSTRAINT     �   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_inmueble FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_inmueble;
       public          postgres    false    224    221    3100            B           2606    34522    garante fk_garante_tipo    FK CONSTRAINT     �   ALTER TABLE ONLY public.garante
    ADD CONSTRAINT fk_garante_tipo FOREIGN KEY (id_tipogarantia) REFERENCES public.tipogarantia(id_garantia) ON DELETE CASCADE;
 A   ALTER TABLE ONLY public.garante DROP CONSTRAINT fk_garante_tipo;
       public          postgres    false    221    3116    237            C           2606    34527 :   historial_direcciones historial_direcciones_id_dueño_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT "historial_direcciones_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");
 f   ALTER TABLE ONLY public.historial_direcciones DROP CONSTRAINT "historial_direcciones_id_dueño_fkey";
       public          postgres    false    219    222    3090            D           2606    34532 =   historial_direcciones historial_direcciones_id_localidad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.historial_direcciones
    ADD CONSTRAINT historial_direcciones_id_localidad_fkey FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);
 g   ALTER TABLE ONLY public.historial_direcciones DROP CONSTRAINT historial_direcciones_id_localidad_fkey;
       public          postgres    false    3084    215    222            E           2606    34537 #   inmuebles inmuebles_id_anuncio_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_anuncio_fkey FOREIGN KEY (id_anuncio) REFERENCES public.anuncios(id_anuncio);
 M   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_anuncio_fkey;
       public          postgres    false    224    200    3060            F           2606    34542 %   inmuebles inmuebles_id_direccion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direcciones(id_direccion);
 O   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_direccion_fkey;
       public          postgres    false    3082    214    224            G           2606    34547 "   inmuebles inmuebles_id_dueño_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT "inmuebles_id_dueño_fkey" FOREIGN KEY ("id_dueño") REFERENCES public."dueños"("id_dueño");
 N   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT "inmuebles_id_dueño_fkey";
       public          postgres    false    3090    219    224            H           2606    34552 +   inmuebles inmuebles_id_estado_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_estado_inmueble_fkey FOREIGN KEY (id_estado_inmueble) REFERENCES public.inmuebles_estados(id_estado);
 U   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_estado_inmueble_fkey;
       public          postgres    false    224    232    3110            I           2606    34557 "   inmuebles inmuebles_id_precio_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_precio_fkey FOREIGN KEY (id_precio) REFERENCES public.precios(id_precio);
 L   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_precio_fkey;
       public          postgres    false    224    227    3106            J           2606    34562 (   inmuebles inmuebles_id_tipoinmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles
    ADD CONSTRAINT inmuebles_id_tipoinmueble_fkey FOREIGN KEY (id_tipoinmueble) REFERENCES public.tipoinmueble(id_tipo);
 R   ALTER TABLE ONLY public.inmuebles DROP CONSTRAINT inmuebles_id_tipoinmueble_fkey;
       public          postgres    false    229    3108    224            K           2606    34567 <   inmuebles_operaciones inmuebles_operaciones_id_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);
 f   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_id_inmueble_fkey;
       public          postgres    false    225    3100    224            L           2606    34572 =   inmuebles_operaciones inmuebles_operaciones_id_operacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inmuebles_operaciones
    ADD CONSTRAINT inmuebles_operaciones_id_operacion_fkey FOREIGN KEY (id_operacion) REFERENCES public.operaciones(id_operacion);
 g   ALTER TABLE ONLY public.inmuebles_operaciones DROP CONSTRAINT inmuebles_operaciones_id_operacion_fkey;
       public          postgres    false    3112    233    225            =           2606    34577 )   localidades localidades_id_provincia_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_id_provincia_fkey FOREIGN KEY (id_provincia) REFERENCES public.localizaciones(id_localizacion);
 S   ALTER TABLE ONLY public.localidades DROP CONSTRAINT localidades_id_provincia_fkey;
       public          postgres    false    215    3086    216            6           2606    34582    pagos pagos_id_cliente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_cliente_fkey;
       public          postgres    false    201    3062    209            7           2606    34587    pagos pagos_id_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_inmueble_fkey;
       public          postgres    false    224    3100    209            8           2606    34592 "   pagos pagos_id_tipo_operacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 L   ALTER TABLE ONLY public.pagos DROP CONSTRAINT pagos_id_tipo_operacion_fkey;
       public          postgres    false    3076    209    207            M           2606    34597 2   periodoocupacion periodoocupacion_id_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.periodoocupacion
    ADD CONSTRAINT periodoocupacion_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble);
 \   ALTER TABLE ONLY public.periodoocupacion DROP CONSTRAINT periodoocupacion_id_inmueble_fkey;
       public          postgres    false    224    226    3100            O           2606    34602 -   precioalquiler precioalquiler_id_cliente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 W   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_id_cliente_fkey;
       public          postgres    false    3062    235    201            P           2606    34607 .   precioalquiler precioalquiler_id_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.precioalquiler
    ADD CONSTRAINT precioalquiler_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.precioalquiler DROP CONSTRAINT precioalquiler_id_inmueble_fkey;
       public          postgres    false    235    3100    224            N           2606    34612    precios precios_id_divisa_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_id_divisa_fkey FOREIGN KEY (id_divisa) REFERENCES public.divisas(id_divisa);
 H   ALTER TABLE ONLY public.precios DROP CONSTRAINT precios_id_divisa_fkey;
       public          postgres    false    218    3088    227            9           2606    34617 !   recargos recargos_id_cliente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_cliente_fkey;
       public          postgres    false    211    3062    201            :           2606    34622 "   recargos recargos_id_inmueble_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_inmueble_fkey FOREIGN KEY (id_inmueble) REFERENCES public.inmuebles(id_inmueble) ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_inmueble_fkey;
       public          postgres    false    211    3100    224            ;           2606    34627 (   recargos recargos_id_tipo_operacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.recargos
    ADD CONSTRAINT recargos_id_tipo_operacion_fkey FOREIGN KEY (id_tipo_operacion) REFERENCES public.tipo_operacion_contable(id_tipo_operacion);
 R   ALTER TABLE ONLY public.recargos DROP CONSTRAINT recargos_id_tipo_operacion_fkey;
       public          postgres    false    3076    207    211                 x�ՒAO�0����m����&<�a	b"�u)[���ε5��m�\=N_��k�>y��7˗-���34v/E9a��K�4�DU���J?��q�����S��3�oTqA+�xW�Ֆ��z�'�z�n�z]n`D"w�6�faG���'�)A� ���%���ͱ��rd��=��<I�$��iO��C���u\�+$o!k�
�@�ĈG���$�+'_������FԆ���#LM��학\�Y��h�M����IȞO�<G�3~ U�}         �   x���v
Q���W((M��L�K��L�+I-V��L��rt��Ԣ���D�Ҝ��������Ģ�|8?#���Ts�	uV�0�Q04�QP/�/.I/J-V���u�t�-�LL�-�,,����5��<i�#�k�k���1"�5\\ ����           x��1o�0�w~�m�Av�I�S�H�
���UN�:6��� P�ug���}�Nz�v�y�C�ݿA�\�6x�����0ź¶��`*�E��G���Ə#�U��GW��'�jT.��FW���#��b�j�x���%$�2�6`��GE�����k}=A0�+�a3u�פԗ�����>_^?6;�
�9� �x�S^�B&2O��Q	90I��p�O��Hy�����r���|��˕�i΀���yR>r��➔L�<N��3��ZR��ȋ?�N&?�)�"         �   x���=
�@�>�x]��IШ��B@�ke�]�ɚ���[y/�
bec#v3��1�|5Y����P��F�T9�ٝ��K��@��	He��Z U	x��L;o=7H�~$��M؎f��
,�x$^(�&�F�gN;)ku�-�������Ȳn�F�Opi`L���a��Y`����ZI�f4��r���G���~���(z e�u         �   x���M�@໿bn*��*fv��A�4���V�,����
��%��;�SVuqj���#s9�ZR���򙎼������7`WLr�8��Q�	;��?���}h��sQ�Gp[��5(�&�J��{��Y��� ��I��,̲8N]��tFVsdF����I؋q���j�ᆶ��&V�Z�Ht����         <  x��Խj�0�=O!�8[�N�-�S���B�f��6�2��{��b�������IÏ��������ϤlϙMiں&��ʾ�l����t!ͬ)�뽱�;��TIj]�en����-�n^���n�K�i����G�6kl�Nm�&���W�yM��O��=Y1 �	�*@@�$��ק t0Լ���Gej��a��B���J(����O�cT��<f�
��!L�R6E*8y��gBe�T�B�@�dJ�3��-�M����Q4�B��:a�"f�j�A��Pq���SØ+�B���T�(Uܧ��j���s�<�           x��Q=k�0��+nSJ���N��m3���5(�H�����=;4S�n� �{���޻�ڮ�wPT�7h���z֠�u�d��16�;���P�6�����lwю$4�U.����Q��+��vWuS�Й�:v�S�?��x��ܯ�0�$��xE�_Yy�m��`.�R	վ,��ؐ<X�#�-�pvô��q4���(��q�X���l�L�TL�Fş �p�:�ªN��Z<�6�v�xO$d�y�ߠ���Q��3wL�� ������,�F_Z(�U         �   x����
�@�Oqw*�8*f�ta��?�+1�0Gf�����m��=�>�iV&EiV�a��	�ր��u4<��l@�S2�1`YO��c2��U�-g���|��P�u�D�:)AC�u���d���d\[o���2m�D;@���BXA຾���/HG0����|dd�DW0������M=�8��4����l�˶         �   x���v
Q���W((M��L�SJ)M=�1�XIAC)3%�S�Q �R����uJsJ2s��K�K�2�����"_S!��'�5XA�HG��PGA� ��$�(�X�6202�50�54W0��21�2�г�066S״��� b0-         �  x�͘[o�8���+���R"E����d��b��OcOlnhҠ�,�_�#J����b%B��6�|�9s����٧����'��ƚ�Xo,�/ȫye����,�w��7��+�ݸe���\�%�*���k�e4�|6%�^&��W�r@^�Cp�-<����o$4aC���_]�� �����߼�<�����1��UsL�F�ю̂/
�a��-��O�O�k�^��l�]��?��yq�BҔ5�W��o���b�\�_h?x،(y{E�Qi��d�લ4����!�bW�~I<�*�N4
� S_���<�f�1��+��mU���c�et�O�V�#�I���F���n�߂>���"W2I�4р���#�|��-���u�-G�UJ
E3�rz��_��g�Z?:j�2�;�r���v@��kM&o��|�4$�Ȼ��������T*��X��a�u�B��p��!m\bq�4��;j"S�3������LQȕߒ�AaŐ����J[Snɨ(����/-!s��<���(Hr��M��c�ύ�!���iƱ�BD8E��U-`�2���
�6�2C�JY3	�ڕi1�l�lJ�!�5?�����½y�J���^0ZV&�\i���a31>�m=,��2"e�g��0�@�1���A����e�U�к
_�V�C��L�<��q��	�rE1|��@��62���J�0�%:n.�8��wx����N��Zϡ��V�$X�`#{��? �ZL�i៮~�s��H���Uk<��=��SmȨk�1��We"Ie�+�w
��&۠ɗ�X��s�D*2)�T3	��j�r��N��N��8�G��+���/k�ӂ%y�#ɉ�wx����N����S�WNƱ��ficd��ޚr��Ū�g�����
�K��m����
`T�2[rzP��q�=L�ǟ�)�b�a�ɍ:�8� 5��M�.�Snmb*m����B�s�3�J�o��m&�!���B�<���)�ʔ�µ�ce�ۻB���g�-��Lt���K�[�Da�%*S�%&��1`�����I|6�0_E�S��7kpe��
-��RՄw���< S<����C�.7����ѡ|fte�()UsN�UM;�ٵ'_������eL��x�9"[[_at0��*�%�EֹD�<��4�s���� �x�)4}���+2ci��%��fnh��;c�h�`���L��f�C�:N����\4{>����78���do����F��`_���X�         
   x���             �   x�ENKj�0��C6J@)�����P��4��Q�q2 k�>Y�V=C/V�mR�7�l���c�v�c:Z�g
�=)��5�� s2�=�0��$��♄+�U'eY+KF	�X��Ҁ�%��j@�)d�c@Q��$��ϊe}�:M�����;)$剻�����V�~��y%��&q }���5�ʱ�Q���v�47��#;X}&��.�jY>-�gq����c���(~ �i�         �   x�ݑ��0�w���&��� ���@b0u%�i�	RB����m���Q���������,OGH��zU���ywS�j��9o�7!�0�^|��F|5|`u�Eg��T���^/L��+�w1C�ڑ�D��*�|�U�p��NIs�1F@0�A`�.���/���S���#+ �x��I�GQ��b㤿dK�-���'�g[�P�;�W���Di�         �   x�͐�
�0Fw��n*�k�$�A(�uB{!&֘�o�ҽKq;g�8|EY����¬z���|R�gT�T��($X8~؁��a�y@�Pl�I�J�nA���X6���.���8`f\1�`j��\�~@\?v��1���$^��al�'��K]�3�(g�Q�00��c/�;=0��#�Xgo���         �   x�͐�
�0Fw���T�����N�b�ڮ�%�5���o:ԽKq�g9|EY�����b�Q���'+�Q�F-B��T�0ȡ�6�����Tc�m�T���p���W�1��_�Y�Z�m�)�p��c�$�1猥~x�?�ѝ�����؏}��*˼           x����j�@�O17��5Ʀ�R�$�ī��.l����]=�z)���������p�B~���j������(�����33h�Q[Š!��Tu�z4�Pg�[��F������h5=��1/�|��
Xp�-�2<�p_��n���0�b�����%Ɏg�,"��A�����d%�#~�Mx>��O�4��S�I�D�x[��Aأ5���?����
l{�w5� ���L���]ȍ����v���R����/	��         �   x���AO�@�{��
I!ݶ��'4%��J(z%C�蘲Sv�&��]9�\������;��n���z���w�N;n��ol��40����A���TK��:�����/����cx]�^�F"� ,ՠ%l�M�R�fx��|'q"&q>3��,��bZi��㻠�'�p��ޣ���A�Ȝ+��ro�bҞ"3iPK�%��AVk<�~�0w�G�a��������vx�/~ :ۚ�         �   x���?�@���O�n*�x����� �A������]�����m�o{ꦭ��Mwi��HH��	��4x8�����/,7���vT(v?���C_�oU	���bFw)�y(���1%a��� �X�iA�(ϓ$s��S���%[�L���8ޥb#      
   >  x��Խj�0�=O!�8Gܝ$Kv�%�&�jWMvd��`}��X��Pw����/���v�����v��3k�S�J�g߱�{�ݵ쩲1MY9{�C��mW|}��=�]�s�ض(����n|���%1����)��w�χn(Z��_|{������u{`+��a�"0�(f3�T�����G���sk���	#�Hd�p)����݌�阉0���'h&3g"��2jS&�M�Ν�c&��L%y�Jh1w&��BӤ��H.R�Μ	�i�/�Ԥi�5�iXڹOh�$3�m&�NZJMsg�1S�IK�f ���?�b�t�/L         �   x�͏=o�0Ew~�ۜHنP�L		Q��X#n�"�!�����j��]��;i�߾ ���٢�2�L�T���%R3��S�ᑱm�)j��Ք�->f��944�>��Gl�l�{7��B��9�6�q���� ��J�b�+�8��,����a|����W�/�@.WQ��I�$a���K�����R?����;�a�k���ߚJ8�Pj."�<=�A(��         +  x�ݐ�j�0��y
ݜ�����S��4)4i�A��d��[~�J�iz���h�ٯ���GV�/���-��^#5�%6�Y��1�]_�Q5v�����f��k$2C�y�5u}��7�AW��Sk���4Nj@��W�^�������� !�"�,.D��PiĳR�q��Xl��΍P���h3Y����i��A���4��AQJYB���8N��â��,�R$)\�,������Y=Mʰ��s{t��у3�� �{ ���A�@$�O��NYtqduK� ����L�:�3�X,>���W         �   x��ϱn�0����F"�ug0wʐ�J�&��4�&�M��,�����������R�d�'�[:8�jۘ��F9�����*!a��Ϋ�Q����i��`�.��6guѽ?��x3�������_����|o޿�{�b	A�0�8@BbS(R,��;N?N��Ӆ`%�\��BdY�ߢ��hx�.i�B�"���@2�9�X	`�Kڲ���@a��C��K��H�ȑ��4�~r���         �   x�͐=�0Ew��T��ďZ;up��j��Uih#���oġs��p�s�t�yQf�
�:ä���$���ze;|�j��5�E3���J7��)��]�O׬��"J){j~�^ن9�̣��v��i�,�$b�=X�����mL+ `��k�2��ʲ>�f�V         X  x��սj�0�=O!�8Gܝ$Kv�%�&�G�;2��{��b��R<ճ���~�Y��ۗ#��Ϭ�ϥ+xc���������nUoϥ�Y(���[��ʶ�ק_������k���U�o:��O�..o?�p�Ƭ/;W�S��y��_�^��ǧ�큭 b�1��l����IP!&Q�����6�����d��d$2H�FF��n�t����d��	��\�c&
��N1e�	Ѥ�l�8bRb�$SIvZ̆Ic&�K�?Sf �H�8&ܻ�?L�j�&�)&j��0���&И)��L�l�Iथ�4�)�p����M3��Q�cv����@o      	   �   x���K�@�὿��40qT�l�B�
�le'0�0���D�l-��lN�=����qҶ�`��\Q&pl����@t��-��k��|E+�`#n�Xm�ﾢz�Ϋͩ<@@B���C0�r����n�8!�x6%s �"�
�Gy��3��������B�7���jΨzҿ�����۵]         �   x���A�@�ỿbn*��&fv��A�����.6`β���4�{�n�|��M[]:�����#�آ��>Y���"�faP�)7Z|��͎�o?Ȭ��x�V-,�����uj��/?M����;MR�I��ۗYV�".��6�ÃW�ߘ.���FmH��\����Gmi�         �   x���?k�0��ݟ�6'��v]7�B��M�I��9�Y'���+-�;��{�ï?���O�70aP4�=&=n��(��n�dFb]@P�&��%��;��K�ܾ|ΰ�( e�r��<�a�,�tWe%Ve�� �6M�ݺ��͗�Y�ߺ*
��(����N.4�z9��x^�&
v��y����;ڙ��(8JeX�ɕe?��"Q     