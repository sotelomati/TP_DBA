CREATE OR REPLACE FUNCTION SP_convertir_mesaño_date(v_mesaño mesaño)
RETURNS date AS 
$$
	BEGIN
	
		RETURN '01-' || v_mesaño; 
	END;
$$
LANGUAGE plpgsql;
