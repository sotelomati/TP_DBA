/*
Se desea realizar un procedimiento que reciba como argumentos el identificador del contrato, el año y mes a facturar, y realice:
	-Controle que exista el contrato y esté activo.
	-Controle si este es mes correcto a facturar
i. que no haya “huecos entre meses”
ii. que no sea un mes que no corresponda al contrato
iii. que sea el mes actual o siguiente próximo
	-Genere la cuota del contrato.
*/
--devuelve true o false si el contrato esta activo
CREATE OR REPLACE FUNCTION SP_contrato_isActivo(v_inmueble integer, v_cliente integer)
RETURNS BOOLEAN AS
$$
DECLARE estado integer;
BEGIN
	select id_estado INTO estado FROM contratoAlquiler 
	where id_cliente = v_cliente AND id_inmueble = v_inmueble;
	IF estado = 1 THEN -- 1=activo
		RETURN TRUE;
	ELSE RETURN False;
	END IF;
END;
$$ LANGUAGE PLPGSQL;




CREATE OR REPLACE FUNCTION SP_check_facturacion_contrato(inmueble integer, cliente integer, v_mesaño mesaño)
RETURNS BOOLEAN AS
$$
DECLARE v_mes_pendiente_facturacion mesaño;
BEGIN
	IF NOT(SP_contrato_isActivo(inmueble, cliente)) THEN
		RAISE NOTICE 'El contrato no esta activo';
		RETURN FALSE;
	ELSE
		--este if verifica si la anterior esta paga
		IF (sp_esta_paga_bool(inmueble, cliente, sp_operacion_resta_mes_año(v_mesaño, 1))) THEN
					RETURN SP_crear_cuota(inmueble, cliente, v_mesaño);
		ELSE
			RAISE NOTICE 'La cuota anterior no esta paga';
			RETURN FALSE;
		END IF;
			
	END IF;
END;
$$ LANGUAGE PLPGSQL;

