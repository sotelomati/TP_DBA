
-- Creacion del SP
CREATE OR REPLACE FUNCTION SP_modificar_nombre_cliente()
RETURNS TRIGGER AS
$$
BEGIN
	
	UPDATE Personas SET nombreCompleto = new.nombreCompleto
	FROM Clientes
	WHERE clientes.id_persona = personas.id_persona and clientes.id_cliente = old.id_cliente;

RETURN new;
END;
$$
LANGUAGE plpgsql;

-- Creacion del trigger
CREATE TRIGGER TG_modificar_nombre_cliente
	INSTEAD OF UPDATE ON cta_cte_cliente
	FOR EACH ROW
	EXECUTE PROCEDURE SP_modificar_nombre_cliente();


