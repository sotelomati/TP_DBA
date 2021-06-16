CREATE OR REPLACE FUNCTION SP_aumentar_precio_periodico()
RETURNS TRIGGER AS
$$
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
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_aumentar_precio_periodico
AFTER INSERT ON cuotas
FOR EACH ROW
EXECUTE PROCEDURE SP_aumentar_precio_periodico();