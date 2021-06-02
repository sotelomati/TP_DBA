/*
Este trigger va en todas las tablas para hacer auditoria
*/

CREATE OR REPLACE FUNCTION SP_actualizar_usuario_y_tiempo()
RETURNS TRIGGER AS
$$
BEGIN
NEW.ultimo_usuario = CURRENT_USER;
NEW.ultimo_horario = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON inmuebles
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON direcciones
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();




