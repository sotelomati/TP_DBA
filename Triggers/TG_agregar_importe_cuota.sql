CREATE OR REPLACE FUNCTION SP_agregar_importe_cuota()
RETURNS TRIGGER AS
$$
BEGIN
	NEW.importe = SP_obtener_importe_cuota(NEW.id_inmueble, NEW.id_cliente, NEW.mesaño);
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;


CREATE TRIGGER TG_obtener_importe_cuota
BEFORE INSERT OR UPDATE ON cuotas
FOR EACH ROW
EXECUTE PROCEDURE SP_obtener_importe_cuota();