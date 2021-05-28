/*
Se requiere crear una vista de estado de cuenta corriente donde se muestre para un cliente, 
las cuotas generadas, los montos de recargo de cada cuota (si los tiene)y los pagos realizados.

*/


--VISTA DE CLIENTES
CREATE VIEW cuota_cta_cte AS
select cuotas.id_cliente, personas.nombreCompleto, mesaño, tipo_operacion_contable.descripcion, 
		SP_obtener_importe_por_tipo(cuotas.id_inmueble, cuotas.id_cliente, cuotas.mesaño, 1) AS importe
from cuotas
INNER JOIN tipo_operacion_contable ON cuotas.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion
INNER JOIN clientes ON clientes.id_cliente = cuotas.id_cliente
INNER JOIN personas ON clientes.id_persona = personas.id_persona;

--VISTA DE PAGOS
CREATE VIEW pago_cta_cte AS
select pagos.id_cliente, personas.nombreCompleto, mesaño, tipo_operacion_contable.descripcion, 
		SP_obtener_importe_por_tipo(pagos.id_inmueble, pagos.id_cliente, pagos.mesaño, 2) AS importe
from pagos
INNER JOIN tipo_operacion_contable ON pagos.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion
INNER JOIN clientes ON clientes.id_cliente = pagos.id_cliente
INNER JOIN personas ON clientes.id_persona = personas.id_persona;

--VISTA DE RECARGOS
CREATE VIEW recargo_cta_cte AS
select recargos.id_cliente, personas.nombreCompleto, mesaño, tipo_operacion_contable.descripcion, 
		SP_obtener_importe_por_tipo(recargos.id_inmueble, recargos.id_cliente, recargos.mesaño, 3) AS importe
from recargos
INNER JOIN tipo_operacion_contable ON recargos.id_tipo_operacion = tipo_operacion_contable.id_tipo_operacion
INNER JOIN clientes ON clientes.id_cliente = recargos.id_cliente
INNER JOIN personas ON clientes.id_persona = personas.id_persona;

--VISTA cta_cte_cliente
CREATE VIEW cta_cte_cliente AS
select * from(
	SELECT * FROM cuota_cta_cte
	UNION
	SELECT * FROM pago_cta_cte
	UNION
	SELECT * FROM recargo_cta_cte
	) cta_cte
	order by cta_cte.id_cliente;