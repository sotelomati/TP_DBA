/*
Al momento de crear un contrato de alquiler genere los registros necesarios en los periodos de ocupación.
*/

CREATE TRIGGER TG_crear_periodo_ocupacion
AFTER INSERT ON contratoAlquiler
FOR EACH ROW
EXECUTE PROCEDURE SP_crear_periodo_ocupacion();

CREATE OR REPLACE FUNCTION SP_crear_periodo_ocupacion()
RETURNS TRIGGER AS
$$
BEGIN
	INSERT INTO periodoocupacion(id_inmueble, fechainicio, fechabaja, motivobaja)
	VALUES (NEW.inmueble, CURRENT_DATE, NULL, NULL);
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;