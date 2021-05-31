CREATE OR REPLACE FUNCTION SP_crear_cuota(v_inmueble integer, v_cliente integer, fechaCrear mesaño)
RETURNS BOOLEAN AS
$$
BEGIN
	INSERT INTO public.cuotas(
	id_inmueble, id_cliente, "mesaño")
	VALUES (v_inmueble, v_cliente, fechaCrear);
	RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;