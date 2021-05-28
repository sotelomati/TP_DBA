-----------------CREACION DE VISTAS--------------------

/*El esquema deberá contener una vista con la información completa
de todos los inmuebles registrados, para el caso de los inmuebles 
que están en alquiler se deberá ver si está ocupado o no y en el caso
de estar ocupado la fecha de finalización de ese contrato. Tenga en cuenta
además que si el inmueble está en alquiler y en venta al mismo tiempo debe 
visualizarse en la misma fila.
*/

CREATE VIEW info_inmuebles_completa AS 
	SELECT  inmuebles.id_inmueble,
			tipo.descripcion ,
			anu.titulo ,
			pre.monto ,
			pre.acronimo,
			per.nombreCompleto,
			(CASE 	WHEN (1 = (SELECT id_operacion FROM tipooperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 1))
					THEN 'SI'
					ELSE 'NO'
			END  )AS SE_VENDE,
			(CASE 	WHEN (2 = (SELECT id_operacion FROM tipooperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
					THEN 'SI'
					ELSE 'NO'
			END  )AS SE_ALQUILA,
			(CASE 	WHEN ((2 = (SELECT id_operacion FROM tipooperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
					AND 
					((SELECT fechaBaja FROM PeriodoOcupacion) <> NULL ))
					THEN 'OCUPADO'
					ELSE 'LIBRE'
			 END) AS ESTADO_ALQUILER,
			(CASE 	WHEN ((2 = (SELECT id_operacion FROM tipooperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
					AND 
					((SELECT fechaBaja FROM PeriodoOcupacion) <> NULL ))
					THEN (SELECT fechaBaja FROM PeriodoOcupacion WHERE id_inmueble = Inmuebles.id_inmueble )
					ELSE NULL
			 END) AS FECHA_DESOCUPACION,
			direc.id_direccion, 
			direc.calle, 
			direc.numero, 
			direc.departamento, 
			direc.piso, 
			direc.observaciones,
			direc.nombre, 
			direc.codigo_postal,
			direc.provincia
			
	FROM Inmuebles
	INNER JOIN direccion_completa direc ON direc.id_direccion = inmuebles.id_direccion
	INNER JOIN dueños due ON due.id_dueño = inmuebles.id_dueño
	INNER JOIN personas per ON per.id_persona = due.id_persona
	INNER JOIN anuncios anu ON anu.id_anuncio = inmuebles.id_anuncio
	INNER JOIN precio_inmueble pre ON pre.id_precio = inmuebles.id_precio 
	INNER JOIN tipoInmueble tipo ON tipo.id_tipo = inmuebles.id_tipoInmueble
	
	
	
	
	
	
	
	
	