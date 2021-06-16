create or replace function empleados_dependientes(cuit) returns setof "record"
as $$
    DECLARE
    e record;
    e2 record;
    BEGIN
        for e in select emp.cuit, emp.apellido_nombre, emp.fecha_ingreso, emp.cargo, emp.superior as depende
                from empleados as emp
                where emp.superior = $1
            LOOP
                    for e2 in select cuit,apellido_nombre,fecha_ingreso, cargo, depende 
                        from empleados_dependientes(e.cuit) as (cuit cuit, apellido_nombre varchar(70),fecha_ingreso date, cargo varchar(15), depende cuit)
                        LOOP
                            return next e2;
                        end LOOP;
                return next e;
            end LOOP;
            return;
    end;
    $$
LANGUAGE plpgsql;

--Ejemplo de consulta de la funcion 
	select * from empleados_dependientes('23385703139') 
	as (cuit cuit, apellido_nombre varchar(70),fecha_ingreso date, cargo varchar(15), depende cuit)
	order by depende



