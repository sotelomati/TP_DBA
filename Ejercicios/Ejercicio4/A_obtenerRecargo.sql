--Funcion que calcula recargo recibiendo ID del contrato, mes y año
--Recibe el id_inmueble e id_cliente que hacen al id del contrato
-- LA FECHA VENCIMIENTO ES DE LA CUOTA

CREATE OR REPLACE FUNCTION calcular_recargo(inmueble integer, cliente integer, fecha_cuota mesaño)
RETURNS double precision AS
$$ 
DECLARE v_recargo double precision = 0;
DECLARE v_monto precios.monto%TYPE;
DECLARE porcentaje_recargo double precision = 0.01;
DECLARE diferencia_de_dias integer = 0;
DECLARE v_fecha_vencimiento date;
BEGIN
--Obtengo el monto a cobrar
select importe INTO v_monto from precioAlquiler 
where id_inmueble = inmueble 
and id_cliente = cliente
and date_part('MONTH', age(fechaDefinicion, SP_convertir_mesaño_date(fecha_cuota))) <= 0 
order by date_part('MONTH', age(fechaDefinicion, SP_convertir_mesaño_date(fecha_cuota))) DESC;

select fechaVencimiento INTO v_fecha_vencimiento from cuotas
where id_inmueble = inmueble 
and id_cliente = cliente
and mesaño LIKE fecha_cuota;

diferencia_de_dias = date_part('DAY', age(current_date, v_fecha_vencimiento));
IF  diferencia_de_dias > 0 THEN
	v_recargo = diferencia_de_dias * (v_monto * porcentaje_recargo);
	
END IF;

RETURN v_recargo;
END;
$$ 
LANGUAGE plpgsql;


/*
Como Funcion?
select date_part('MONTH', age('20/05/2021', '23/06/2021'))
age hace la diferencia de primero-segundo, si el segundo es mayor el resultado sera negativo
hago el date part del mes, si esto es menor entonces se aplica la a la cuota
el order by no lo tengo claro aun
*/

