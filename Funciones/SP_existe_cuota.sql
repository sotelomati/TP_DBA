CREATE OR REPLACE FUNCTION SP_existe_cuota(v_inmueble integer, v_cliente integer, v_mesaño mesaño)
RETURNS BOOLEAN AS
$$
BEGIN
	IF EXISTS (SELECT * from CUOTAS
			  WHERE inmueble = v_inmueble
			  AND cliente = v_cliente
			  AND mesaño = v_mesaño)
	THEN RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$ LANGUAGE PLPGSQL;
