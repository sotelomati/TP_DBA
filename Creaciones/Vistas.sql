/*Vista de direccion completa*/

CREATE VIEW direccion_completa AS
	SELECT d.calle, d.numero, d.departamento, d.piso, d.observaciones, 
			l.nombre, l.codigo_postal,
			loca.provincia
	FROM direcciones d
	INNER JOIN Localidades l ON d.id_localidad = l.id_localidad
	INNER JOIN Localizaciones loca ON l.id_provincia = loca.id_localizacion

