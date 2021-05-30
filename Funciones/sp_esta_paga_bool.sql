CREATE OR REPLACE FUNCTION sp_esta_paga_bool(v_cliente integer, v_inmueble integer, v_mesaño mesaño)
RETURNS boolean AS
$$
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
		RETURN True;
	END IF;

RETURN False;
END;
$$
LANGUAGE plpgsql;
