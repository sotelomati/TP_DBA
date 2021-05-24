/*
Se requiere crear una vista de estado de cuenta corriente donde se muestre para un cliente, 
las cuotas generadas, los montos de recargo de cada cuota (si los tiene)y los pagos realizados.

*/

CREATE VIEW cta_cte_cliente AS
	SELECT clientes.id_cliente, personas.nombreCompleto, cuotas.mesAño, 
	FROM clientes
	INNER JOIN personas ON clientes.id_persona = personas.id_persona
	INNER JOIN CUOTAS ON clientes.id_cliente = cuotas.id_cliente