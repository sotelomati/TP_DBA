--obtener importe para cuota
CREATE OR REPLACE FUNCTION SP_obtener_importe_cuota(v_inmueble integer, v_cliente integer, fechaContable mesaño)
RETURNS double precision AS
$$
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
$$ LANGUAGE PLPGSQL;
