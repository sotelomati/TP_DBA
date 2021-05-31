CREATE OR REPLACE FUNCTION SP_es_mayor_mesaño(v_mesaño mesaño, comparar mesaño)
RETURNS BOOLEAN AS
$$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño)>SP_convertir_mesaño_date(comparar)
		OR SP_convertir_mesaño_date(v_mesaño) = SP_convertir_mesaño_date(comparar);

END;
$$ LANGUAGE PLPGSQL;

select SP_es_mayor('05-2021', '05-2021')