-----------------CREACION DE VISTAS--------------------

/*El esquema deberá contener una vista con la información completa
de todos los inmuebles registrados, para el caso de los inmuebles 
que están en alquiler se deberá ver si está ocupado o no y en el caso
de estar ocupado la fecha de finalización de ese contrato. Tenga en cuenta
además que si el inmueble está en alquiler y en venta al mismo tiempo debe 
visualizarse en la misma fila.
*/

CREATE VIEW info_inmuebles_view AS 
	(
		SELECT id_inmueble,
				id_tipoInmueble ,
				id_tipoOperacion ,
				id_estado ,
				id_direccion ,
				id_anuncio ,
				id_precio ,
				id_dueño
		FROM Inmuebles
		IF( id_tipoInmueble = id_tipo )
	)

--alter table Inmuebles drop column id_tipoOperacion;
SELECT id_operacion FROM InmuebleOperacion 
where (id_inmueble = (select Inmuebles.id_inmueble from Inmuebles)) and (id_operacion = 1);




SELECT id_inmueble,
		id_tipoInmueble ,
		id_direccion ,
		id_anuncio ,
		id_precio ,
		id_dueño,
		(CASE 
			WHEN (1 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 1))
				THEN 'SI'

				ELSE 'NO'

				END  )AS SE_VENDE
		,
		(CASE 
			WHEN (2 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
				THEN 'SI'

				ELSE 'NO'

				END  )AS SE_ALQUILA
		,
		(CASE 
		 	WHEN ((2 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
				  AND 
				  ((SELECT fechaBaja FROM PeriodoOcupacion) <> NULL ))
		 		THEN 'OCUPADO'
		 		
		 		ELSE 'LIBRE'
		 		
		 END) AS ESTADO_ALQUILER
		,
		(CASE 
		 	WHEN ((2 = (SELECT id_operacion FROM InmuebleOperacion WHERE id_inmueble = Inmuebles.id_inmueble and id_operacion = 2))
				  AND 
				  ((SELECT fechaBaja FROM PeriodoOcupacion) <> NULL ))
		 		THEN (SELECT fechaBaja FROM PeriodoOcupacion WHERE id_inmueble = Inmuebles.id_inmueble )
				ELSE NULL
		 		
		 END) AS FECHA_DESOCUPACION
FROM Inmuebles