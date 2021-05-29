--obtener importe para cuota
CREATE OR REPLACE FUNCTION SP_obtener_importe_cuota()
RETURNS TRIGGER AS
$$
DECLARE v_cantidad_importes integer = 0;
BEGIN

	IF NOT EXISTS (select importe INTO NEW.importe from precioAlquiler 
					where id_inmueble = inmueble 
					and id_cliente = cliente)
		THEN
			RAISE NOTICE 'No se puede determinar el importe para la cuota ya que no hay ningun precio para el contrato';
			RETURN NULL;
	ELSE
		SELECT COUNT(importe)INTO v_cantidad_importes FROM precioAlquiler 
		where id_inmueble = NEW.id_inmueble 
		and id_cliente = NEW.id_cliente;
		
		IF (v_cantidad_importes <= 1) THEN
			--solo existe el precio inicial, no aplico logica de definicion de importe
			select importe INTO NEW.importe from precioAlquiler 
			where id_inmueble = NEW.id_inmueble 
			and id_cliente = NEW.id_cliente;
		ELSE--aca existen varios prebios, aplico logica
			select importe INTO NEW.importe from precioAlquiler 
			where id_inmueble = NEW.id_inmueble 
			and id_cliente = NEW.id_cliente
			and date_part('MONTH', age(fechaDefinicion, SP_convertir_mesaño_date(NEW.mesaño))) <= 0 
			order by date_part('MONTH', age(fechaDefinicion, SP_convertir_mesaño_date(NEW.mesaño))) DESC
			LIMIT 1;
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;


CREATE TRIGGER TG_obtener_importe_cuota
BEFORE INSERT ON cuotas
FOR EACH ROW
EXECUTE PROCEDURE SP_obtener_importe_cuota();