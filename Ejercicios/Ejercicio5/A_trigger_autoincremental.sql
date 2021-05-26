/* se pretende manejar el ID de inmueble como autoincremental de tratamiento especial según la siguiente premisa:
1. Si es la primera fila de la tabla, el nro debe comenzar con 1000.
2. Si el Insert contiene un valor no nulo en este atributo, validar que 
	este valor no exista en la tabla y se debe modificar la secuencia o generador asociado
3. Si el Insert viene con nulo en este atributo y ademas existen filas en la tabla debe asignar el próximo nro
*/

CREATE OR REPLACE FUNCTION SP_autoincremental_control()
RETURNS trigger AS
$$
DECLARE v_contador integer = 1; 
DECLARE v_id_valido inmuebles.id_inmueble%TYPE;
BEGIN
--chequeo si es la primera fila
IF NOT EXISTS(select * from inmuebles) THEN
	NEW.id_inmueble = 1000;

	
ELSEIF NEW.id_inmueble IS NULL THEN
	select id_inmueble+v_contador INTO v_id_valido FROM inmuebles 
	order by ultimo_horario DESC LIMIT 1;
	WHILE EXISTS ( select id_inmueble FROM inmuebles where id_inmueble = v_id_valido) LOOP
		v_contador = v_contador + 1;
		select id_inmueble+v_contador INTO v_id_valido FROM inmuebles 
		order by ultimo_horario DESC LIMIT 1;
	END LOOP;
	new.id_inmueble = v_id_valido;

--En este caso no viene nulo y no es la primera fila
ELSEIF EXISTS (select id_inmueble from inmuebles where id_inmueble = NEW.id_inmueble) THEN
		RETURN NULL;

END IF;
RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_autoincremental_control
	before insert on inmuebles
	FOR EACH ROW
	EXECUTE PROCEDURE SP_autoincremental_control();

	
