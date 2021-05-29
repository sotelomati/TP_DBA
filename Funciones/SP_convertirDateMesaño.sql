--Convierte date a mes año

CREATE OR REPLACE FUNCTION SP_convertir_date_mesaño(fecha date)
RETURNS mesaño AS
$$
BEGIN
	RETURN right(to_char(fecha, 'DD-MM-YYYY'), 7);
END;
$$ LANGUAGE PLPGSQL;
