/*
Este trigger da el valor de la fecha de vencimiento de la cuota, siendo tal la misma fecha que el dia que se realizo el contrato
*/

CREATE OR REPLACE FUNCTION SP_crear_fecha_vencimiento()
RETURNS TRIGGER AS
$$
BEGIN
	new.vencimiento_cuota = extract ('day' from new.fechaContrato);
RETURN NEW;
END;
$$
LANGUAGE plpgsql;	
	

CREATE OR REPLACE TRIGGER TG_crear_fecha_vencimiento
BEFORE INSERT ON contratoalquiler
FOR EACH ROW
EXECUTE PROCEDURE SP_crear_fecha_vencimiento();