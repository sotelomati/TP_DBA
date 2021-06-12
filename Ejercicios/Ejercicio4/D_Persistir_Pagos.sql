CREATE OR REPLACE FUNCTION SP_pagar_cuota(v_inmueble integer, v_cliente integer, v_cuota mesaño)
RETURNS BOOLEAN AS
$$
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
$$ LANGUAGE PLPGSQL


CREATE TRIGGER TG_importepago
BEFORE INSERT ON pagos 
FOR EACH ROW
EXECUTE PROCEDURE SP_importepago();

CREATE OR REPLACE FUNCTION SP_importepago() 
RETURNS TRIGGER AS
$$
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
$$ LANGUAGE PLPGSQL;



