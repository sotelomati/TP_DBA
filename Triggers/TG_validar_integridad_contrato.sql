CREATE OR REPLACE FUNCTION SP_validar_integridad_contrato()
RETURNS TRIGGER AS
$$
BEGIN
	
	IF NOT EXISTS (Select * from contratoAlquiler 
				  where id_inmueble= NEW.idinmueble AND id_estado = 1)
	THEN
		RETURN NEW;
	END IF;

RAISE NOTICE 'Ya existe un contrato que esta activo para este inmueble';
RETURN NULL;

END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_validar_integridad_contrato
BEFORE INSERT ON contratoAlquiler
FOR EACH ROW
EXECUTE PROCEDURE SP_validar_integridad_contrato();