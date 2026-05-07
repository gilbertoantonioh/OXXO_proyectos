SET SERVEROUTPUT ON
DECLARE

   pn_ooh_order_number       NUMBER := '201178';
   pn_ool_line_id            NUMBER := 6495345;

   CURSOR lc_xxinv_mmt( pn_ooh_order_number IN NUMBER 
                      , pn_ool_line_id      IN NUMBER 
                       ) 					  
   IS 
      SELECT ximt.mmt_transaction_id 
           , ximt.mmt_creation_date
           , ximt.rl_attribute1_req_line_id 
           , ximt.msi_segment1_no_articulo
           , ximt.mmt_transaction_quantity 
           , ooh.header_id AS ooh_header_id 
           , ximt.rh_header_id AS ooh_order_number 
           , ximt.rl_line_id AS ool_line_id 
           , xmcr.oracle_cia
           , xmcr.oracle_ef
           , xmcr.oracle_cr_superior
           , xcrp.descripcion AS oracle_cr_sup_descr
           , xmcr.retek_cr 
           , xmcr.oracle_cr
           , xmcr.oracle_cr_desc   
      FROM  xxinv_pre_material_trx_temp ximt -- leer la tabla que tiene el split de los registros 
          , xxfc_maestro_de_crs_v  xmcr
          , xxfc_centros_responsabilidad xcrp
          , oe_order_headers_all ooh           
      WHERE 1=1
      AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
      AND   ximt.reql_attribute3_cr    = xmcr.oracle_cr
      AND   xmcr.oracle_cr_superior    = xcrp.oracle_cr
      AND   ximt.rh_header_id          = ooh.order_number
      AND   ximt.rh_header_id          = pn_ooh_order_number
      AND   ximt.rl_line_id            = pn_ool_line_id     
	  ;
      
   CURSOR lc_sn_data_details( pv_msi_item_number     IN  xxfa_sn_data_details.msi_item_number%TYPE
                            , pn_poh_po_number       IN  xxfa_sn_data_details.poh_po_number%TYPE
                            , pn_rcv_po_unit_price   IN  xxfa_sn_data_details.rcv_po_unit_price%TYPE   
                            , pn_ooh_order_number    IN  xxfa_sn_data_details.ooh_order_number%TYPE   
                            , pn_ool_line_id         IN  xxfa_sn_data_details.ooh_order_number%TYPE   
                             )                          
   IS                           
      SELECT xdd.data_detail_id 
      FROM   xxfa_sn_data_details xdd
      WHERE  xdd.msi_item_number   = pv_msi_item_number
      AND    xdd.poh_po_number     = pn_poh_po_number
      AND    xdd.rcv_po_unit_price = pn_rcv_po_unit_price
      AND    xdd.ooh_order_number IS NULL 
      ;       
   
   ln_prev_updated_count    NUMBER := 0; 
   
   ln_trip_id          wsh_trips.trip_id%TYPE := NULL;
   ln_sn_viaje         xxfc_sn_escaneo.sn_viaje%TYPE := NULL; 
   ln_purchase_order   xxfc_sn_escaneo.purchase_order%TYPE := NULL; 
   ln_po_unit_price    xxfc_sn_escaneo.po_unit_price%TYPE := NULL;
   
   le_no_exception     EXCEPTION;
   
   ln_xxsnrec_rownum   NUMBER := 0;
   
   lv_x_errors         VARCHAR2(4000)  := NULL; 
   ln_x_retcode        NUMBER  := NULL; 
BEGIN
   dbms_output.put_line(' +++++ Inicio Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas. +++++'); 
  
   -- Validar que no existauna actualizacion previa en la tabla intermedia sobre el pedido y linea de movimiento, 
   BEGIN
      dbms_output.put_line('Validando si existe una previa actualizacion a la tabla intermedia para el pedido de movimiento: '||pn_ooh_order_number||' id de linea de pedido de movimiento: '||pn_ool_line_id);     
      SELECT COUNT(1)
	  INTO    ln_prev_updated_count
	  FROM    xxfa_sn_data_Details xsdd
	  WHERE   xsdd.ooh_order_number = pn_ooh_order_number
	  AND     xsdd.ool_line_id      = pn_ool_line_id
	  ;
	  
	  IF ln_prev_updated_count > 0
	  THEN 
	      dbms_output.put_line('Ya existe una previa actualizacion a la tabla intermedia para el pedido de movimiento.');     
	     RAISE le_no_exception; 
	  END IF; 
	  

   EXCEPTION      
      WHEN le_no_exception THEN 
         RAISE; 	  
      WHEN OTHERS THEN
	     dbms_output.put_line('Error validando si existe una previa actualizacion a la tabla intermedia, others: '||SQLERRM);
	     ROLLBACK;	  
		 RAISE; 
   END;

   -- Ejecuatar procesos de XXINV_KITS_CUENTAS_DIARIO para actualizar referencias de la linea de movimiento en la tabla de escenaro de service now
   BEGIN 
      dbms_output.put_line('Actualizando referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento: '||pn_ooh_order_number||' id de linea de pedido de movimiento: '||pn_ool_line_id);  
	  
      XXINV_KITS_CUENTAS_DIARIO.xxinv_mat_trx_prc( pn_ooh_order_number   => pn_ooh_order_number
                                                 , pn_ool_line_id        => pn_ool_line_id
                                                 , pn_x_ret_code         => ln_x_retcode
                                                 , pv_x_errors           => lv_x_errors   
                                                    );

      IF ln_x_retcode != 0
	  THEN 
	     dbms_output.put_line('Error actualizando referencias en xxinv_material_trx_temp: '|| lv_x_errors);  
	     RAISE le_no_exception;
	  END IF;
	  
	  COMMIT; 
	  ln_x_retcode := NULL;  
      lv_x_errors := NULL;  
      XXINV_KITS_CUENTAS_DIARIO.pre_xxinv_mat_trx_temp_prc( pn_ooh_order_number   => pn_ooh_order_number
                                                          , pn_ool_line_id        => pn_ool_line_id
                                                          , pv_retcode            => ln_x_retcode
                                                          , pv_errors             => lv_x_errors   
                                                            );   
															
      IF ln_x_retcode != 0
	  THEN 
	     dbms_output.put_line('Error actualizando referencias en xxinv_pre_material_trx_temp: '|| lv_x_errors);  
	     RAISE le_no_exception;
	  END IF;

	  COMMIT; 
      ln_x_retcode := NULL;  
      lv_x_errors := NULL;  
      XXINV_KITS_CUENTAS_DIARIO.procesa_info_articulo_prc( pn_ooh_order_number   => pn_ooh_order_number
                                                         , pn_ool_line_id        => pn_ool_line_id
                                                         , pv_retcode            => ln_x_retcode
                                                         , pv_errors             => lv_x_errors   
                                                           );
														   
      IF ln_x_retcode != 0
	  THEN 
	     dbms_output.put_line('Error actualizando referencias en xxfc_sn_escaneo_lineas: '|| lv_x_errors);  
	     RAISE le_no_exception;
	  END IF;
 
	  COMMIT;  
      dbms_output.put_line('Se actualizaron las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas.');
                                             
   EXCEPTION      
      WHEN le_no_exception THEN 
	     ROLLBACK;
         RAISE; 	  
      WHEN OTHERS THEN
	     dbms_output.put_line('Error actualizando las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas, others. Error: '||SQLERRM); 
	     ROLLBACK;	  
		 RAISE; 
   END;

   dbms_output.put_line('Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento: '||pn_ooh_order_number||' id de linea de pedido de movimiento: '||pn_ool_line_id);     

   -- Reiniciar contador de registros de tabla intermedia
   ln_xxsnrec_rownum := 0;
		 
   FOR xxinv_rec IN  lc_xxinv_mmt( pn_ooh_order_number => pn_ooh_order_number
                                 , pn_ool_line_id      => pn_ool_line_id 
                                  ) 
   LOOP 
      --Buscar datos del escaneo a partir de la linea de pedido de movimiento, para saber si hay un viaje
      BEGIN 
         SELECT  wst.trip_id
               , xsn.sn_viaje
               , xsn.purchase_order 
               , xsn.po_unit_price  
         INTO    ln_trip_id
               , ln_sn_viaje
               , ln_purchase_order  
               , ln_po_unit_price              
         FROM    xxfc_sn_escaneo xsn
              ,  xxfc_sn_escaneo_lineas xsl 
              ,  wsh_trips wst
         WHERE   xsn.sn_escaneo_id          = xsl.sn_escaneo_id 
         AND     xsn.sn_viaje               = wst.name       
         AND     xsl.wsh_sts_header_id      = xxinv_rec.ooh_order_number
         AND     xsl.wsh_sts_line_id        = xxinv_rec.ool_line_id
         AND     rownum = 1
         ;        
      EXCEPTION 
         WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('No existe escaneo con viaje para el pedido de movimiento: '||xxinv_rec.ooh_order_number||' id de linea de pedido de movimiento: '||xxinv_rec.ool_line_id);       
            EXIT; 
         WHEN OTHERS THEN 
		    dbms_output.put_line('Error al buscar el registro de escaneo con viaje para el pedido de movimiento: '||xxinv_rec.ooh_order_number||' id de linea de pedido de movimiento: '||xxinv_rec.ool_line_id||', others Error: '||SQLERRM);       
            EXIT; 
      END;       
      
      -- Bloque para actualizar el registro de xxfa_sn_data_details 
      BEGIN 
         -- Buscar registros de sn data details candidatos para actualizar, a partir de los datos de numero de articulo, numero de orden de compra y precio.  
		 dbms_output.put_line('Buscando registros para actualizar en la tabla intermedia, pedido de compra: '||ln_purchase_order||' articulo: '||xxinv_rec.msi_segment1_no_articulo||' precio: '||TO_CHAR(ln_po_unit_price)||' pedido movimiento: '||xxinv_rec.ooh_order_number||' id de linea de pedido de movimiento: '||xxinv_rec.ool_line_id);
         FOR xxsnrec IN lc_sn_data_details( pv_msi_item_number    => xxinv_rec.msi_segment1_no_articulo
                                          , pn_poh_po_number      => ln_purchase_order
                                          , pn_rcv_po_unit_price  => ln_po_unit_price
                                          , pn_ooh_order_number   => xxinv_rec.ooh_order_number
                                          , pn_ool_line_id        => xxinv_rec.ool_line_id
                                           )
         LOOP
            ln_xxsnrec_rownum := ln_xxsnrec_rownum + 1; 
            
            -- Actualizar registro. 
            XXFA_SN_DATA_DETAILS_PKG.update_row( p_data_detail_id             => xxsnrec.data_detail_id
                                               , p_prl_requisition_line_id    => xxinv_rec.rl_attribute1_req_line_id
                                               , p_prl_oracle_cia             => xxinv_rec.oracle_cia
                                               , p_prl_oracle_ef              => xxinv_rec.oracle_ef
                                               , p_prl_retek_distrito         => xxinv_rec.retek_cr
                                               , p_prl_oracle_cr              => xxinv_rec.oracle_cr
                                               , p_prl_oracle_cr_descr        => xxinv_rec.oracle_cr_desc
                                               , p_prl_oracle_cr_superior     => xxinv_rec.oracle_cr_superior
                                               , p_prl_oracle_cr_sup_descr    => xxinv_rec.oracle_cr_sup_descr
                                               , p_ooh_header_id              => xxinv_rec.ooh_header_id
                                               , p_ooh_order_number           => xxinv_rec.ooh_order_number
                                               , p_ool_line_id                => xxinv_rec.ool_line_id
                                               , p_wst_trip_id                => ln_trip_id
                                               , p_wst_trip_name              => ln_sn_viaje
                                               , p_mmt_transaction_id         => xxinv_rec.mmt_transaction_id
                                               , p_mmt_creation_date          => xxinv_rec.mmt_creation_date
                                               , x_errors                     => lv_x_errors
                                               , x_retcode                    => ln_x_retcode
                                               );
            IF ln_x_retcode = 0 
            THEN 
               dbms_output.put_line('Se actualizo el registro de xxfa_sn_data_details, pedido de compra: '||ln_purchase_order||' articulo: '||xxinv_rec.msi_segment1_no_articulo||' precio: '||TO_CHAR(ln_po_unit_price)||' id data detail: '||xxsnrec.data_detail_id||' pedido movimiento/viaje '||xxinv_rec.ooh_order_number||'/'||ln_sn_viaje);
               EXIT; -- Desde que estamos leyendo la tabla split xxinv_pre_material_trx_temp, actualizamos un solo registro en la tabla xxfa_sn_data_details. 
		    ELSE 
               dbms_output.put_line('Error al actualizar el registro de xxfa_sn_data_details, pedido de compra: '||ln_purchase_order||' articulo: '||xxinv_rec.msi_segment1_no_articulo||' precio: '||TO_CHAR(ln_po_unit_price)||' id data detail: '||xxsnrec.data_detail_id||' pedido movimiento/viaje '||xxinv_rec.ooh_order_number||'/'||ln_sn_viaje||' Error: '||lv_x_errors); 
               ROLLBACK; 
               RAISE le_no_exception; 
            END IF;         
         END LOOP;       
      EXCEPTION
         WHEN le_no_exception THEN 
	        ROLLBACK;
			ln_xxsnrec_rownum := 0; -- Reseteamos contador 
			EXIT; 
         WHEN OTHERS THEN
            dbms_output.put_line('Error actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento, others: '||SQLERRM);		 
	        ROLLBACK;
			ln_xxsnrec_rownum := 0; -- Reseteamos contador 
			EXIT; 
      END;    
   END LOOP; 

   IF ln_xxsnrec_rownum > 0 
   THEN
      -- Si modifico los registros que encontro en xxfa_sn_data_details, dar commit. 
      COMMIT;
	  dbms_output.put_line('Se actualizaron '||ln_xxsnrec_rownum||' registro(s) en la tabla xxfa_sn_data_details.');
   ELSE 
      dbms_output.put_line('No se actualizaron registros para actualizar en la tabla xxfa_sn_data_details.');
   END IF;     
   

   -- Ejecuatar procesos de XXINV_KITS_CUENTAS_DIARIO para eliminar registros temporales
   BEGIN 
      dbms_output.put_line('Eliminando registros temporales en xxinv_pre_material_trx_temp para el pedido de movimiento: '||pn_ooh_order_number||' id de linea de pedido de movimiento: '||pn_ool_line_id);  

	  ln_x_retcode := NULL;  
      lv_x_errors := NULL;  
	  
      XXINV_KITS_CUENTAS_DIARIO.reagrupa_info_prc( pn_ooh_order_number   => pn_ooh_order_number
                                                 , pn_ool_line_id        => pn_ool_line_id
                                                 , pv_retcode            => ln_x_retcode
                                                 , pv_errors             => lv_x_errors   
                                                    );

      IF ln_x_retcode != 0
	  THEN 
	     dbms_output.put_line('Error eliminando registros temporales en xxinv_pre_material_trx_temp: '|| lv_x_errors);  
	     RAISE le_no_exception;
	  END IF;
	  
	  COMMIT; 
      dbms_output.put_line('Se eliminaron registros temporales en xxinv_pre_material_trx_temp.');
                                             
   EXCEPTION      
      WHEN le_no_exception THEN 
	     ROLLBACK;
         RAISE; 	  
      WHEN OTHERS THEN 
	     dbms_output.put_line('Error eliminando registros temporales en xxinv_pre_material_trx_temp, others. Error: '||SQLERRM);	  
	     ROLLBACK;
		 RAISE; 
   END;
   
   
   dbms_output.put_line(' +++++ Fin Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas. +++++'); 
EXCEPTION
   WHEN le_no_exception THEN 
      dbms_output.put_line(' +++++ Fin Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas. +++++'); 
   WHEN OTHERS THEN 
      dbms_output.put_line('Error actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento, others/main: '||SQLERRM);
END;