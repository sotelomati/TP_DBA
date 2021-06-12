--trigger para alta de precio alquiler

CREATE OR REPLACE FUNCTION SP_cargarPrecioAlquiler()
    RETURNS TRIGGER AS 
    $$
        DECLARE
        BEGIN
            INSERT INTO public.precioalquiler(id_inmueble, id_cliente, importe, fechadefinicion)
				VALUES (NEW.id_inmueble,NEW.id_cliente,NEW.precio_inicial,CURRENT_DATE);
            RETURN NULL;
        END;
    $$
    LANGUAGE plpgsql;
	
CREATE TRIGGER TG_cargarPrecioAlquiler
AFTER INSERT ON contratoAlquiler
FOR EACH ROW 
EXECUTE PROCEDURE SP_cargarPrecioAlquiler();
