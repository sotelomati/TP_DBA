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
BEFORE INSERT OR UPDATE ON Inmuebles
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Direcciones
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON tipo_operacion_contable
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Localizaciones
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Localidades
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Anuncios
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Divisas
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Precios
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON TipoInmueble
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON operaciones
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Inmuebles_Estados
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Personas
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Clientes
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Dueños
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON inmuebles_operaciones
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON PeriodoOcupacion
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON contratos_finalidades
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON contratos_estados
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON ContratoAlquiler
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON TipoGarantia
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Garante
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON PrecioAlquiler
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Pagos
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Cuotas
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();

CREATE TRIGGER TG_auditorio_modificacion
BEFORE INSERT OR UPDATE ON Recargos
FOR EACH ROW
EXECUTE PROCEDURE SP_actualizar_usuario_y_tiempo();