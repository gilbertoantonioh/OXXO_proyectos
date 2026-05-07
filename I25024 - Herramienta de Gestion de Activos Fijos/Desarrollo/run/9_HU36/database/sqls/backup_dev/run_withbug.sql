SET SERVEROUTPUT ON
DECLARE
gv_errbuf      VARCHAR2(4000);  
gv_retcode     VARCHAR2(1);  
   
errbuf                VARCHAR2(4000);
retcode               VARCHAR2(4000);
p_delivery_name       VARCHAR2(4000);
p_organization_id     NUMBER; 
									 
      TYPE lrec_trips IS RECORD (
                                  wst_trip_id               apps.wsh_trips.trip_id%TYPE      
                                , wst_trip_name             apps.wsh_trips.name%TYPE      
                                , msi_item_number           apps.mtl_system_items_b.segment1%TYPE      
                                , msi_item_description      apps.mtl_system_items_b.description%TYPE      
                                , wdd_shipped_quantity      apps.wsh_delivery_details.shipped_quantity%TYPE      
                                , ooh_header_id             apps.oe_order_headers_all.header_id%TYPE      
                                , ooh_order_number          apps.oe_order_headers_all.order_number%TYPE      
                                , ool_line_id               apps.wsh_delivery_details.source_line_id%TYPE      
                                , ship_confirm_flag         apps.xxfa_sn_trips.ship_confirm_flag%TYPE  
                                , wnd_delivery_id           apps.wsh_new_deliveries.delivery_id%TYPE 
                                , wnd_confirm_date          apps.wsh_new_deliveries.confirm_date%TYPE 
                                , wt_status_code            apps.wsh_trips.status_code%TYPE 
                                , wdd_delivery_detail_id    apps.wsh_delivery_details.delivery_detail_id%TYPE 
                                , wdd_organization_id       apps.wsh_delivery_details.organization_id%TYPE  
                                , wdd_released_status       apps.wsh_delivery_details.released_status%TYPE   
                                , prl_oracle_cr_superior    apps.po_requisition_lines_all.attribute2%TYPE 
                                , prl_oracle_cr             apps.po_requisition_lines_all.attribute3%TYPE  
                                , prl_requistor_full_name   apps.per_people_x.full_name%TYPE  
                                , prh_solicitud_inversion   apps.po_requisition_headers_all.attribute1%TYPE                                  
                                ); 
      TYPE ltab_trips IS TABLE OF lrec_trips INDEX BY PLS_INTEGER;
      TYPE ltab_dist_trips IS TABLE OF BOOLEAN INDEX BY VARCHAR2(30);
   
      
      larr_wsh_trips       ltab_trips;
      larr_sn_trips        ltab_trips;
      larr_dist_trips      ltab_dist_trips;
      lv_idx_dist_trip     VARCHAR2(30);
      
      ln_sn_trip_id        NUMBER; 
      idx                  NUMBER; 
      
      lv_phaseout          VARCHAR2(32767);
      lv_statusout         VARCHAR2(32767);
      lv_devphaseout       VARCHAR2(32767);
      lv_devstatusout      VARCHAR2(32767);
      lv_messageout        VARCHAR2(32767);
      ln_ReqActual         NUMBER; 
      ln_reqrunning        NUMBER;
      lb_callstatus        BOOLEAN;
      
	  ln_store_days        NUMBER; -- CHG0143308 
	  
      -- Informacion del viaje desde wsh
      CURSOR c_wsh_trip( p_trip_name IN VARCHAR2
                       ) 
      IS  
         SELECT  wt.trip_id              AS wst_trip_id
               , wt.name                 AS wst_trip_name 
               , msi.segment1            AS msi_item_number
               , msi.description         AS msi_item_description
               , CASE
                  WHEN wt.status_code != 'CL' 
                  THEN 
                     wdd.requested_quantity  
                  ELSE 
                     wdd.shipped_quantity
                 END wdd_shipped_quantity
               , ooh.header_id           AS ooh_header_id
               , ooh.order_number        AS ooh_order_number
               , wdd.source_line_id      AS ool_line_id        
               , CASE
                  WHEN wt.status_code != 'CL' 
                  THEN 
                     'N'     
                  ELSE 
                     'Y'
                 END ship_confirm_flag
               , wnd.delivery_id         AS wnd_delivery_id  
               , wnd.confirm_date        AS wnd_confirm_date   
               , wt.status_code          AS wt_status_code 
               , wdd.delivery_detail_id  AS wdd_delivery_detail_id
               , wdd.organization_id     AS wdd_organization_id
               , wdd.released_status     AS wdd_released_status   
               , prl.attribute2          AS prl_oracle_cr_superior
               , prl.attribute3          AS prl_oracle_cr
               , ppf.full_name           AS prl_requistor_full_name   
               , prh.attribute1          AS prh_solicitud_inversion            
         FROM    apps.oe_order_headers_all ooh
               , apps.oe_order_lines_all ool 
               , apps.po_requisition_lines_all prl
               , apps.po_requisition_headers_all prh
               , apps.per_people_f ppf
               , apps.wsh_delivery_details wdd
               , apps.wsh_new_deliveries wnd
               , apps.wsh_delivery_assignments wda
               , apps.wsh_trips wt
               , apps.wsh_delivery_legs wdl
               , apps.wsh_trip_stops wds_pick     
               , apps.wsh_trip_stops wds_drop   
               , apps.mtl_system_items_b msi 
         WHERE  1 = 1
         AND    ooh.header_id               = wdd.source_header_id (+)
         AND    ool.line_id                 = wdd.source_line_id (+)
         AND    ool.attribute1              = prl.requisition_line_id (+) 
         AND    prl.requisition_header_id   = prh.requisition_header_id (+) 
         AND    prl.to_person_id            = ppf.person_id (+) 
         AND   ( prl.creation_date          >= ppf.effective_start_date (+)
             AND prl.creation_date          <= ppf.effective_end_date (+) ) 
         AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
         AND    wda.delivery_id             = wnd.delivery_id(+)
         AND    wdl.delivery_id(+)          = wnd.delivery_id  
         AND    wt.trip_id                  = wds_pick.trip_id
         AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
         AND    wt.trip_id                  = wds_drop.trip_id
         AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
         AND    msi.inventory_item_id       = wdd.inventory_item_id 
         AND    msi.organization_id         = wdd.organization_id
         AND   EXISTS -- que sea de una organizacion de activo fijo 
               (
               SELECT 1
               FROM   apps.fnd_flex_values_vl ffv
                    , apps.fnd_flex_value_sets fvs
               WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
               AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
               AND    ffv.enabled_flag = 'Y'
               AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
               AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
               AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
               )
         AND   NOT EXISTS -- Que no haya sido compartido antes a SN con confirmacion de envio 
               ( SELECT 1 
                 FROM   apps.xxfa_sn_trips xst  
                 WHERE  xst.wst_trip_name  = wt.name 
                 AND    ship_confirm_flag  = 'Y'
                )             
         AND    wt.name  = p_trip_name
         ;
   
      -- Informacion de la ultima version de viaje que se ha compartido anteriormente 
      CURSOR c_sn_trip( p_trip_name IN VARCHAR2
                       ) 
      IS 
         SELECT  wst_trip_id
               , wst_trip_name 
               , msi_item_number
               , msi_item_description
               , wdd_shipped_quantity
               , ooh_header_id
               , ooh_order_number
               , ool_line_id        
               , ship_confirm_flag
               , wnd_delivery_id  
               , wnd_confirm_date  
               , wt_status_code    
               , wdd_delivery_detail_id
               , wdd_organization_id
               , wdd_released_status   
               , prl_oracle_cr_superior
               , prl_oracle_cr
               , prl_requistor_full_name 
               , prh_solicitud_inversion
         FROM    apps.xxfa_sn_trips 
         WHERE   wst_trip_name = p_trip_name
         AND     sn_trip_id    = (SELECT MAX(sn_trip_id)
                                  FROM   apps.xxfa_sn_trips 
                                  WHERE  wst_trip_name = p_trip_name
                                  )
         ;
      
      -- Funcion para comparar arreglos y saber si hay cambios que reportar a SN 
      FUNCTION arrays_equal(p_arr_wsh IN ltab_trips
                          , p_arr_sn  IN ltab_trips
                            ) 
      RETURN BOOLEAN IS
          idx PLS_INTEGER;
      BEGIN
      
         -- Checar si las cantidades no son iguales
         IF p_arr_wsh.COUNT != p_arr_sn.COUNT 
         THEN
            RETURN FALSE;
         END IF;
      
         -- Revisar los arreglos a partir de la llave, primer arreglo 
         idx := p_arr_wsh.FIRST;
		 
		 --dbms_output.put_line( 'idx1 '||idx); 
         
         WHILE idx IS NOT NULL 
         LOOP
            -- Revisa si el idx existe en el segundo arreglo 
            IF NOT p_arr_sn.EXISTS(idx) 
            THEN
               RETURN FALSE;
            END IF;
   
            -- Compara valores (solo los que se mandan a SN) 
            IF NVL(p_arr_wsh(idx).wst_trip_id, 0)                                  != NVL(p_arr_sn(idx).wst_trip_id, 0) 
            OR NVL(p_arr_wsh(idx).wst_trip_name, 'NULL')                           != NVL(p_arr_sn(idx).wst_trip_name, 'NULL')
            OR NVL(p_arr_wsh(idx).msi_item_number, 'NULL')                         != NVL(p_arr_sn(idx).msi_item_number, 'NULL')
            OR NVL(p_arr_wsh(idx).msi_item_description, 'NULL')                    != NVL(p_arr_sn(idx).msi_item_description, 'NULL')
            OR NVL(p_arr_wsh(idx).wdd_shipped_quantity, 0)                         != NVL(p_arr_sn(idx).wdd_shipped_quantity, 0)
            OR NVL(p_arr_wsh(idx).ooh_header_id, 0)                                != NVL(p_arr_sn(idx).ooh_header_id, 0)          
            OR NVL(p_arr_wsh(idx).ooh_order_number, 0)                             != NVL(p_arr_sn(idx).ooh_order_number, 0)  
            OR NVL(p_arr_wsh(idx).ool_line_id, 0)                                  != NVL(p_arr_sn(idx).ool_line_id, 0)  
            OR NVL(p_arr_wsh(idx).ship_confirm_flag, 'NULL')                       != NVL(p_arr_sn(idx).ship_confirm_flag, 'NULL')
            OR NVL(TO_CHAR(p_arr_wsh(idx).wnd_confirm_date, 'YYYYMMDD'), 'NULL')   != NVL(TO_CHAR(p_arr_sn(idx).wnd_confirm_date, 'YYYYMMDD'), 'NULL')
            OR NVL(p_arr_wsh(idx).prl_oracle_cr_superior, 'NULL')                  != NVL(p_arr_sn(idx).prl_oracle_cr_superior, 'NULL')
            OR NVL(p_arr_wsh(idx).prl_oracle_cr, 'NULL')                           != NVL(p_arr_sn(idx).prl_oracle_cr, 'NULL')
            OR NVL(p_arr_wsh(idx).prl_requistor_full_name, 'NULL')                 != NVL(p_arr_sn(idx).prl_requistor_full_name, 'NULL')
            OR NVL(p_arr_wsh(idx).prh_solicitud_inversion, 'NULL')                 != NVL(p_arr_sn(idx).prh_solicitud_inversion, 'NULL')            
            THEN
               RETURN FALSE;
            END IF;
      
            idx := p_arr_sn.NEXT(idx); 
			--dbms_output.put_line( 'idxn '||idx); 
         END LOOP;
   
   
         -- Revisar los arreglos a partir de la llave, segundo arreglo 
         idx := p_arr_sn.FIRST;
         WHILE idx IS NOT NULL 
         LOOP
            -- Revisa si el idx existe en el primer arreglo 
            IF NOT p_arr_wsh.EXISTS(idx) 
            THEN
               RETURN FALSE;
            END IF;
      
            idx := p_arr_sn.NEXT(idx);
         END LOOP;
   
      
         RETURN TRUE; -- Si los arrelos son iguales 
      EXCEPTION
         WHEN OTHERS THEN  
            dbms_output.put_line( 'arrays_equal: '||SQLERRM); 
            dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            RAISE; 
      END arrays_equal;
      
   BEGIN
      --dbms_output.put_line( ' +++++ Ejecutando proceso para cargar registros de viajes para compartir a service now. +++++'); 
      --dbms_output.put_line( 'p_delivery_name: '||p_delivery_name);
      --dbms_output.put_line( 'p_organization_id: '||p_organization_id);
      --dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');

      gv_retcode := '0';
      gv_errbuf  := NULL;


      --dbms_output.put_line( 'Ejecutando depuracion de informacion de viajes.'); 
      --dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');   
	  /*
      BEGIN
         purge_trips_prc(retcode => gv_retcode
                       , errbuf  => gv_errbuf
                         );
      EXCEPTION 
         WHEN OTHERS THEN 
            dbms_output.put_line( 'Error Ejecutando depuracion de informacion viajes: '||SQLERRM); 
            dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               
      END;  
      */ 
	  
      -- CHG0143308  Inicia. 
      -- Obtener los dias que se basara el borrado de la informacion de viajes
      BEGIN 
      
         SELECT ffv.description
         INTO   ln_store_days
         FROM   apps.fnd_flex_values_vl ffv
              , apps.fnd_flex_value_sets fvs
         WHERE  fvs.flex_value_set_id    = ffv.flex_value_set_id
         AND    fvs.flex_value_set_name  = 'XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO'
         AND    ffv.flex_value           = 'DIAS_RESGUARDO'
         AND    ffv.enabled_flag         = 'Y'
         AND  ( ffv.start_date_active    < SYSDATE OR ffv.start_date_active IS NULL)
         AND  ( ffv.end_date_active      > SYSDATE OR ffv.end_date_active IS NULL)
         ;
      EXCEPTION 
         WHEN OTHERS THEN 
		    ln_store_days := 30;
            gv_retcode := 1; 
      END; 
      -- CHG0143308  Termina. 

 
      IF p_delivery_name IS NOT NULL
      THEN -- Si se esta ejecutando para un viaje en especifico, hacer la consulta.       
         -- Obtener los viajes a compartir a service now 
         FOR wsh IN c_wsh_trip(p_trip_name => p_delivery_name
                              )
         LOOP
            IF NOT larr_dist_trips.EXISTS(wsh.wst_trip_name)
            THEN 
               larr_dist_trips(wsh.wst_trip_name) := TRUE;  
            END IF;    
         END LOOP; 
      ELSE 
         -- Si no hay viaje especifico, obtener los viajes por actualizar desde la tabla de service now       
         FOR sn IN (SELECT DISTINCT wst_trip_name
                    FROM   xxfa_sn_trips
                    WHERE  ship_confirm_flag = 'N' 
					--AND wst_trip_name NOT IN ( '4588519', '4588527')    
					-- CHG0143308  Inicia. 
					UNION 
                    SELECT  DISTINCT wt.name  AS wst_trip_name         
                    FROM    apps.oe_order_headers_all ooh
                          , apps.oe_order_lines_all ool 
                          , apps.po_requisition_lines_all prl
                          , apps.po_requisition_headers_all prh
                          , apps.per_people_f ppf
                          , apps.wsh_delivery_details wdd
                          , apps.wsh_new_deliveries wnd
                          , apps.wsh_delivery_assignments wda
                          , apps.wsh_trips wt
                          , apps.wsh_delivery_legs wdl
                          , apps.wsh_trip_stops wds_pick     
                          , apps.wsh_trip_stops wds_drop   
                          , apps.mtl_system_items_b msi 
                    WHERE  1 = 1
                    AND    ooh.header_id               = wdd.source_header_id (+)
                    AND    ool.line_id                 = wdd.source_line_id (+)
                    AND    ool.attribute1              = prl.requisition_line_id (+) 
                    AND    prl.requisition_header_id   = prh.requisition_header_id (+) 
                    AND    prl.to_person_id            = ppf.person_id (+) 
                    AND   ( prl.creation_date          >= ppf.effective_start_date (+)
                        AND prl.creation_date          <= ppf.effective_end_date (+) ) 
                    AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
                    AND    wda.delivery_id             = wnd.delivery_id(+)
                    AND    wdl.delivery_id(+)          = wnd.delivery_id  
                    AND    wt.trip_id                  = wds_pick.trip_id
                    AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
                    AND    wt.trip_id                  = wds_drop.trip_id
                    AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
                    AND    msi.inventory_item_id       = wdd.inventory_item_id 
                    AND    msi.organization_id         = wdd.organization_id
                    AND   EXISTS -- que sea de una organizacion de activo fijo 
                          (
                          SELECT 1
                          FROM   apps.fnd_flex_values_vl ffv
                               , apps.fnd_flex_value_sets fvs
                          WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                          AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                          AND    ffv.enabled_flag = 'Y'
                          AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                          AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                          AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
                          )
                    AND  wt.name NOT IN -- Que no haya sido registrado en xxfa_sn_trips, ya que lo obtiene la primer parte del UNION. 
                          ( SELECT xst.wst_trip_name 
                            FROM   apps.xxfa_sn_trips xst  
                           )             
                    AND TRUNC(wt.creation_date) >= TRUNC(SYSDATE) - ln_store_days		
                    --AND wt.name NOT IN ( '4588519', '4588527')    					
					-- CHG0143308  Termina
                    )
         LOOP 
            larr_dist_trips(sn.wst_trip_name) := TRUE;  
         END LOOP;       
      END IF; 
      
      IF larr_dist_trips.COUNT > 0
      THEN -- Si hay viajes que compartir a Service Now 
         
         lv_idx_dist_trip := larr_dist_trips.FIRST; 
         WHILE lv_idx_dist_trip IS NOT NULL 
         LOOP
            BEGIN 
               dbms_output.put_line( 'Validando informacion del viaje: '||lv_idx_dist_trip); 
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
                           
               -- Limpiar arreglos 
               larr_wsh_trips.DELETE;
               larr_sn_trips.DELETE;
            
            
               -- Cargar arreglo para wsh 
               FOR wsh IN c_wsh_trip(p_trip_name => lv_idx_dist_trip
                                    )
               LOOP
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wst_trip_id                := wsh.wst_trip_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wst_trip_name              := wsh.wst_trip_name;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).msi_item_number            := wsh.msi_item_number;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).msi_item_description       := wsh.msi_item_description;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_shipped_quantity       := wsh.wdd_shipped_quantity;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ooh_header_id              := wsh.ooh_header_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ooh_order_number           := wsh.ooh_order_number;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ool_line_id                := wsh.ool_line_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ship_confirm_flag          := wsh.ship_confirm_flag;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wnd_delivery_id            := wsh.wnd_delivery_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wnd_confirm_date           := wsh.wnd_confirm_date;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wt_status_code             := wsh.wt_status_code;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_delivery_detail_id     := wsh.wdd_delivery_detail_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_organization_id        := wsh.wdd_organization_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_released_status        := wsh.wdd_released_status;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prl_oracle_cr_superior     := wsh.prl_oracle_cr_superior;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prl_oracle_cr              := wsh.prl_oracle_cr;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prl_requistor_full_name    := wsh.prl_requistor_full_name;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prh_solicitud_inversion    := wsh.prh_solicitud_inversion;
               END LOOP; 
               
               dbms_output.put_line( 'larr_wsh_trips.COUNT: '||larr_wsh_trips.COUNT); 
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');            
            
               -- Cargar arreglo para sn 
               FOR sn IN c_sn_trip(p_trip_name => lv_idx_dist_trip
                                  )
               LOOP
                  larr_sn_trips(sn.wdd_delivery_detail_id).wst_trip_id                := sn.wst_trip_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wst_trip_name              := sn.wst_trip_name;
                  larr_sn_trips(sn.wdd_delivery_detail_id).msi_item_number            := sn.msi_item_number;
                  larr_sn_trips(sn.wdd_delivery_detail_id).msi_item_description       := sn.msi_item_description;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_shipped_quantity       := sn.wdd_shipped_quantity;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ooh_header_id              := sn.ooh_header_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ooh_order_number           := sn.ooh_order_number;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ool_line_id                := sn.ool_line_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ship_confirm_flag          := sn.ship_confirm_flag;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wnd_delivery_id            := sn.wnd_delivery_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wnd_confirm_date           := sn.wnd_confirm_date;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wt_status_code             := sn.wt_status_code;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_delivery_detail_id     := sn.wdd_delivery_detail_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_organization_id        := sn.wdd_organization_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_released_status        := sn.wdd_released_status;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prl_oracle_cr_superior     := sn.prl_oracle_cr_superior;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prl_oracle_cr              := sn.prl_oracle_cr;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prl_requistor_full_name    := sn.prl_requistor_full_name;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prh_solicitud_inversion    := sn.prh_solicitud_inversion;
               END LOOP; 
               
               dbms_output.put_line( 'larr_sn_trips.COUNT: '||larr_sn_trips.COUNT); 
               dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               

                       
               -- Comparar los arreglos para saber si hay cambios que enviar a SN 
               IF NOT arrays_equal( p_arr_wsh => larr_wsh_trips
                                  , p_arr_sn  => larr_sn_trips
                                  ) 
               AND larr_wsh_trips.COUNT > 0 -- Asegurarse que haya algo que actualizar
               THEN 
                  dbms_output.put_line( 'Se encontro informacion para compartir a service now.'); 
                  dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');  
                  
                  -- Obten id de viaje de sn (version)
				  /*
                  SELECT  xxfc.xxfa_sn_trips_s.nextval
                  INTO    ln_sn_trip_id
                  FROM    dual
                  ;
				  */
             
                  -- Insertar informacion en la tabla xxfa_sn_trips
                  idx := larr_wsh_trips.FIRST;
                  WHILE idx IS NOT NULL 
                  LOOP
                     --dbms_output.put_line( 'INSERTA.'); 
                     
                     idx := larr_wsh_trips.NEXT(idx);          
                  END LOOP;     
            
                  
                  COMMIT;
               ELSE 
                  dbms_output.put_line( 'No hay informacion actualizada para compartir a service now.'); 
                  dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');  
               END IF;
            
               -- Obtener el siguiente viaje 
               lv_idx_dist_trip := larr_dist_trips.NEXT(lv_idx_dist_trip);
         
            EXCEPTION
               WHEN OTHERS THEN 
                  -- Obtener el siguiente viaje --NEWHERNAGI
                  lv_idx_dist_trip := larr_dist_trips.NEXT(lv_idx_dist_trip); --NEWHERNAGI
				  
                  dbms_output.put_line( 'Error al validar el viaje: '||SQLERRM); 
                  dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
                  gv_retcode := 1;   
            END;
			--EXIT; 
         END LOOP;        
      ELSE 
         dbms_output.put_line('No existe informacion de viajes para compartir a Service Now. Revisar si ya ha sido compartido anteriormente con confirmacion de envio.');		 
      END IF;

      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL; 
      
      --dbms_output.put_line( ' +++++ Fin ejecutando proceso para cargar registros de viajes para compartir a service now. +++++'); 
      --dbms_output.put_line( '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');

   EXCEPTION
      WHEN OTHERS THEN 
         dbms_output.put_line( 'Error ejecutando proceso para cargar registros de viajes para compartir a service now: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END load_trips_from_wsh_prc;  