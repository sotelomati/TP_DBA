--obtener importe para cuota
CREATE OR REPLACE FUNCTION SP_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechaContable mesaño)
RETURNS double precision AS
$$
DECLARE v_importe double precision = 0;
BEGIN
	select importe INTO v_importe from precioAlquiler 
	where id_inmueble = inmueble 
	and id_cliente = cliente
	and date_part('MONTH', age(fechaDefinicion, SP_convertir_mesaño_date(fecha_cuota))) <= 0 
	order by date_part('MONTH', age(fechaDefinicion, SP_convertir_mesaño_date(fecha_cuota))) DESC;
	
	RETURN v_importe;
END;
$$ LANGUAGE PLPGSQL;


