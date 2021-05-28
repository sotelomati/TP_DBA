/*Vista de direccion completa*/
CREATE VIEW direccion_completa AS
	SELECT d.id_direccion, d.calle, d.numero, d.departamento, d.piso, d.observaciones, 
			l.nombre, l.codigo_postal,
			loca.provincia
	FROM direcciones d
	INNER JOIN Localidades l ON d.id_localidad = l.id_localidad
	INNER JOIN Localizaciones loca ON l.id_provincia = loca.id_localizacion

/*Vista de precios*/
CREATE VIEW precio_inmueble 
	AS (
    SELECT p.id_precio, p.monto, d.acronimo 
	FROM Precios p
    INNER JOIN Divisas d ON p.id_divisa = d.id_divisa
	)