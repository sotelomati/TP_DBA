-- Operacion restar meses
CREATE OR REPLACE FUNCTION sp_operacion_resta_mes_año(v_mesaño mesaño, v_valor INTEGER)
RETURNS mesaño AS
$$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) - (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$
LANGUAGE plpgsql;


-- Operacion sumar meses
CREATE OR REPLACE FUNCTION sp_operacion_suma_mes_año(v_mesaño mesaño, v_valor INTEGER)
RETURNS mesaño AS
$$
DECLARE retorno mesaño;
BEGIN
	SELECT SP_convertir_date_mesaño(CAST(SP_convertir_mesaño_date(v_mesaño) + (SELECT (CAST(v_valor AS VARCHAR) || ' MONTH')::INTERVAL) AS DATE)) INTO retorno;
	RETURN retorno;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SP_es_igual_mesaño(v_mesaño mesaño, comparar mesaño)
RETURNS BOOLEAN AS
$$
BEGIN
RETURN SP_convertir_mesaño_date(v_mesaño) = SP_convertir_mesaño_date(comparar);

END;
$$ LANGUAGE PLPGSQL;