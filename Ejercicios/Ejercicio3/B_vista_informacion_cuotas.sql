

CREATE VIEW informacion_cuotas AS
SELECT per.*, cuo.mesaño, sp_esta_paga(ca.id_cliente, ca.id_inmueble, cuo.mesaño) FROM contratoalquiler ca
INNER JOIN info_inmuebles_completa iic ON iic.id_inmueble = ca.id_inmueble
INNER JOIN Clientes cli ON cli.id_cliente = ca.id_cliente
INNER JOIN Personas per ON per.id_persona = cli.id_persona
INNER JOIN Cuotas cuo ON cuo.id_inmueble = iic.id_inmueble AND cuo.id_cliente = ca.id_cliente
WHERE id_estado = 1
