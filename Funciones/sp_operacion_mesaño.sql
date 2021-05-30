-- Operacion restar meses
create or replace function sp_operacion_resta_mes_año(v_mesaño mesaño, v_valor integer)
returns mesaño as
$$
declare retorno mesaño;
BEGIN
	select SP_convertir_date_mesaño(cast(SP_convertir_mesaño_date(v_mesaño) - (select (CAST(v_valor AS varchar) || ' MONTH')::interval) as date)) into retorno;
	return retorno;
END;
$$
language plpgsql;


-- Operacion sumar meses
create or replace function sp_operacion_suma_mes_año(v_mesaño mesaño, v_valor integer)
returns mesaño as
$$
declare retorno mesaño;
BEGIN
	select SP_convertir_date_mesaño(cast(SP_convertir_mesaño_date(v_mesaño) + (select (CAST(v_valor AS varchar) || ' MONTH')::interval) as date)) into retorno;
	return retorno;
END;
$$
language plpgsql;



