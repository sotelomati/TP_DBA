CREATE OR REPLACE FUNCTION SP_crear_cuota(v_inmueble integer, v_cliente integer, fechaCrear mesaño)
RETURNS BOOLEAN AS
$$
BEGIN
	IF NOT SP_existe_cuota(v_inmueble, v_cliente, fechaCrear) THEN
		IF SP_esta_en_rango_contrato(inmueble, cliente, fechaCrear) THEN
			INSERT INTO public.cuotas(id_inmueble, id_cliente, "mesaño")
			VALUES (v_inmueble, v_cliente, fechaCrear);
			RETURN TRUE;
		ELSE
			RAISE NOTICE 'La cuota no corresponde al contrato';
			RETURN FALSE;
		END IF;
	ELSE
		RAISE NOTICE 'La cuota para el mes año % ya existe', fechaCrear;
		RETURN False;
	END IF;
END;
$$ LANGUAGE PLPGSQL;