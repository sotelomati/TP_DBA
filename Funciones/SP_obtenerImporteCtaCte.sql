/*
1. cuota
2. pago
3. recargo
*/

CREATE OR REPLACE FUNCTION SP_obtener_importe_por_tipo(inmueble integer, cliente integer, 
													   mes_año mesaño, operacion integer)
RETURNS double precision AS
$$
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
$$ LANGUAGE PLPGSQL;