CREATE OR REPLACE FUNCTION SP_verificar_jefe_maximo()
RETURNS TRIGGER AS
$$
BEGIN

	IF NEW.superior IS NULL AND EXISTS (SELECT * FROM empleados where superior IS NULL) THEN
		--Solo puede haber un empleado sin jefe
		RAISE NOTICE 'Solo puede existir un empleado sin jefe';
		RETURN NULL;
	END IF;
	
	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_verificar_jefe_maximo
BEFORE INSERT OR UPDATE ON empleados
FOR EACH ROW
EXECUTE PROCEDURE SP_verificar_jefe_maximo()