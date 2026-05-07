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
         FROM    oe_order_headers_all ooh
               , oe_order_lines_all ool 
               , po_requisition_lines_all prl
               , po_requisition_headers_all prh
               , per_people_f ppf
               , wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop   
               , mtl_system_items_b msi 
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
               FROM   fnd_flex_values_vl ffv
                    , fnd_flex_value_sets fvs
               WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
               AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
               AND    ffv.enabled_flag = 'Y'
               AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
               AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
               AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
               )
         AND   NOT EXISTS -- Que no haya sido compartido antes a SN con confirmacion de envio 
               ( SELECT 1 
                 FROM   xxfa_sn_trips xst  
                 WHERE  xst.wst_trip_name  = wt.name 
                )             
         AND TRUNC(wt.creation_date) >=TRUNC(SYSDATE) - 30				
         ;
		 
		 
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
         AND  wt.name NOT IN -- Que no haya sido compartido antes a SN con confirmacion de envio 
               ( SELECT xst.wst_trip_name 
                 FROM   apps.xxfa_sn_trips xst  
                )             
         AND TRUNC(wt.creation_date) >= TRUNC(SYSDATE) - 30				
         ;