 
CREATE TABLE Historial_Direcciones(
id_historial integer not null PRIMARY KEY,
id_dueño integer,
id_direccion integer not null ,
id_localidad integer not null,
calle varchar(50) not null,
numero integer not null,
departamento varchar(10),
piso integer,
observaciones varchar(100),
fechaInicioVigencia date,
fechaFinVigencia date
);

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
    DECLARE 
        v_dueño integer;
    BEGIN

        select dueños.id_dueño INTO v_ dueño from dueños inner join personas on personas.id_direccion = OLD.id_direccion where  dueños.id_persona = personas.id_persona;
        
        INSERT INTO Historial_Direcciones(
            
            id_dueño,
            id_direccion,
            id_localidad ,
            calle,
            numero,
            departamento,
            piso,
            observaciones,
            fechaInicioVigencia,
            fechaFinVigencia
        ) values (
            
            v_dueño,
            OLD.id_direccion,
            OLD.id_localidad ,
            OLD.calle,
            OLD.numero,
            OLD.departamento,
            OLD.piso,
            OLD.observaciones,
            OLD.fechaInicioVigencia, -- en caso de decidir prescindir de fechaInicioVigencia se quita este dato.
            CURRENT_DATE
        );
    END;
    $$
    LANGUAGE plpgsql;

CREATE TRIGGER TG_historial_direcciones_dueño
BEFORE UPDATE OR DELETE
ON Direcciones
FOR EACH ROW 
EXECUTE PROCEDURE SP_historial_direcciones_dueño();
