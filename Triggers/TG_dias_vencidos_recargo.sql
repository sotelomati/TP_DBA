CREATE OR REPLACE FUNCTION SP_dias_vencidos_recargo()
RETURNS TRIGGER AS
$$
DECLARE v_fechavencimiento DATE;
BEGIN
	select fechaVencimiento INTO v_fechavencimiento 
	WHERE id_inmueble = NEW.id_inmueble AND id_cliente = NEW.id_cliente AND mesaño = NEW.mesaño;
	
	NEW.diasVencidos = CURRENT_DATE - v_fechavencimiento;

END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TG_dias_vencidos_recargo
AFTER INSERT ON recargos
FOR EACH ROW
EXECUTE PROCEDURE SP_dias_vencidos_recargo()