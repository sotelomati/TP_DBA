-- se plantea como posibilidad agregar una fecha de inicio de vigencia a direcciones. 
/*
CREATE or REPLACE FUNCTION SP_fechaInicio_direcciones_dueño() RETURNS trigger AS $$
    DECLARE
    BEGIN
        new.fechaInicioVigencia  = current_timestamp;
        return new;
    END;
    $$
    language 'plpgsql';

    CREATE TRIGGER TG_fechaInicio_direcciones_dueño
    BEFORE insert OR update
    ON Direcciones
    FOR EACH ROW
    EXECUTE PROCEDURE SP_fechaInicio_direcciones_dueño();
*/
CREATE OR REPLACE FUNCTION SP_historial_direcciones_dueño()
RETURNS TRIGGER 
AS $$
DECLARE v_dueño dueños.id_dueño%TYPE;
BEGIN

select dueños.id_dueño INTO v_dueño from dueños 
inner join personas on dueños.id_persona = personas.id_persona
where personas.id_direccion = OLD.id_direccion;

--cierro el periodo de vigencia actual
UPDATE historial_direcciones SET fechaFinVigencia = CURRENT_DATE
WHERE id_direccion = OLD.id_direccion AND fechaFinVigencia IS NULL;
--inserto el nuevo
INSERT INTO Historial_Direcciones(
	id_dueño, id_direccion,
	id_localidad, calle,
	numero, departamento,
	piso, observaciones,
	fechaInicioVigencia, fechaFinVigencia) 
	values (
	v_dueño,
	NEW.id_direccion,
	NEW.id_localidad,
	NEW.calle,
	NEW.numero,
	NEW.departamento,
	NEW.piso,
	NEW.observaciones,
	CURRENT_DATE,
	NULL
	);
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER TG_historial_direcciones_dueño
BEFORE UPDATE OR DELETE
ON Direcciones
FOR EACH ROW 
EXECUTE PROCEDURE SP_historial_direcciones_dueño();

--Para dar el primer alta al crear el dueño
CREATE OR REPLACE FUNCTION TG_iniciar_historial_dueños()
RETURNS TRIGGER AS
$$
DECLARE v_nuevo_id_historial INTEGER;
BEGIN
--obtengo nuevo ID
select COUNT(id_historial)+1 INTO v_nuevo_id_historial FROM Historial_Direcciones;

--inicio el historial de dueño
INSERT INTO Historial_Direcciones
(select v_nuevo_id_historial, NEW.id_dueño, direcciones.id_direccion, id_localidad, calle, 
 numero, departamento, piso, observaciones, CURRENT_DATE, NULL
FROM direcciones
INNER JOIN Personas on personas.id_direccion = direcciones.id_direccion
WHERE personas.id_direccion = 1
);
RETURN NULL;

END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_iniciar_historial_dueños
AFTER INSERT
ON Dueños
FOR EACH ROW 
EXECUTE PROCEDURE TG_iniciar_historial_dueños();


select * from historial_direcciones




