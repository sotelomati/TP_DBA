CREATE OR REPLACE FUNCTION SP_esta_en_rango_contrato(v_inmueble integer, v_cliente integer, v_mesaño mesaño)
RETURNS BOOLEAN AS
$$
DECLARE rango_inferior DATE;
DECLARE rango_superior DATE;
DECLARE v_vigencia INTEGER;
BEGIN

SELECT fechacontrato, periodo_vigencia INTO rango_inferior, v_vigencia FROM contratoalquiler
WHERE id_inmueble = v_inmueble AND id_cliente = v_cliente AND id_estado = 1;

rango_superior = rango_inferior + (CAST(v_vigencia AS varchar) || ' MONTH')::interval;

	IF NOT (SP_es_mayor_mesaño(v_mesaño, rangoinferior) OR SP_es_mayor_mesaño(rangosuperior, v_mesaño))
		THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE PLPGSQL;

select * from contratoAlquiler
select SP_esta_en_rango_contrato(1000, 1, '05-2021')