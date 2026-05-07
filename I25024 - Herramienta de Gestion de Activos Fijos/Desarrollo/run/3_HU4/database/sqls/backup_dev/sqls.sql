  SELECT  ooh.order_number
        , wt.name  AS trip_name 
        , ooh.open_flag AS ooh_open_flag
        , ooh.cancelled_flag AS ooh_cancelled_flag
        , ooh.booked_flag
        , ool.line_number
        , ool.open_flag AS ool_open_flag
        , ool.cancelled_flag AS ool_cancelled_flag
        , ool.shipment_priority_code
        , ool.attribute3 AS ool_line_attribute3_cr
        , ool.ordered_item 
        , NVL(wdd.shipped_quantity, ool.ordered_quantity) AS ordered_quantity
        , msi.description AS item_description 
        , msi.attribute1
        , wds_pick.stop_id AS pick_stop_id
        , wds_pick.actual_arrival_date AS pick_actual_arrival_date
        , wds_pick.actual_departure_date AS pick_actual_departure_date
        , wds_drop.stop_id AS drop_stop_id
        , wds_drop.actual_arrival_date AS drop_actual_arrival_date
        , wds_drop.actual_departure_date AS drop_actual_departure_date               
FROM  apps.oe_order_headers_all ooh
    , oe_order_lines_all ool
    , mtl_system_items_b msi 
    , apps.wsh_delivery_details wdd
    , apps.wsh_new_deliveries wnd
    , apps.wsh_delivery_assignments wda
    , apps.wsh_trips wt
    , apps.wsh_delivery_legs wdl
    , apps.wsh_trip_stops wds_pick     
    , apps.wsh_trip_stops wds_drop   
WHERE  1 = 1
AND    ooh.header_id = ool.header_id
AND    ool.ship_from_org_id = msi.organization_id
AND    ool.inventory_item_id = msi.inventory_item_id
AND    ooh.header_id = wdd.source_header_id(+)
AND    wda.delivery_detail_id(+) = wdd.delivery_detail_id
AND    wda.delivery_id = wnd.delivery_id(+)
AND    ool.line_id = wdd.source_line_id
AND    wdl.delivery_id(+) = wnd.delivery_id  
AND    wt.trip_id(+) = wds_pick.trip_id
AND    wds_pick.stop_id(+) = wdl.pick_up_stop_id
AND    wt.trip_id(+) = wds_drop.trip_id
AND    wds_drop.stop_id(+) = wdl.drop_off_stop_id                       
AND    ooh.order_number = '100448'
ORDER BY ooh.order_number, wt.name, ool.line_number





  SELECT  ooh.header_id
        , ooh.order_number
        , wt.name  AS trip_name 
        , ooh.open_flag AS ooh_open_flag
        , ooh.cancelled_flag AS ooh_cancelled_flag
        , ooh.booked_flag
        , ool.line_number
        , ool.open_flag AS ool_open_flag
        , ool.cancelled_flag AS ool_cancelled_flag
        , ool.shipment_priority_code
        , ool.attribute3 AS ool_line_attribute3_cr
        , ool.ordered_item 
        , NVL(wdd.shipped_quantity, ool.ordered_quantity) AS ordered_quantity
        , msi.inventory_item_id 
        , msi.organization_id
        , msi.description AS item_description 
        , msi.attribute1      
        , mmt.transaction_id 
        , mmt.* 
FROM  apps.oe_order_headers_all ooh
    , oe_order_lines_all ool
    , mtl_system_items_b msi 
    , apps.wsh_delivery_details wdd
    , apps.wsh_new_deliveries wnd
    , apps.wsh_delivery_assignments wda
    , apps.wsh_trips wt
    , apps.wsh_delivery_legs wdl
    , apps.wsh_trip_stops wds_pick     
    , apps.wsh_trip_stops wds_drop   
    , mtl_material_transactions mmt
WHERE  1 = 1
AND    ooh.header_id = ool.header_id
AND    ool.ship_from_org_id = msi.organization_id
AND    ool.inventory_item_id = msi.inventory_item_id
AND    ool.ship_from_org_id = mmt.organization_id
AND    ool.inventory_item_id = mmt.inventory_item_id
AND    ooh.header_id = wdd.source_header_id(+)
AND    wda.delivery_detail_id(+) = wdd.delivery_detail_id
AND    wda.delivery_id = wnd.delivery_id(+)
AND    ool.line_id = wdd.source_line_id
AND    wdl.delivery_id(+) = wnd.delivery_id  
AND    wt.trip_id(+) = wds_pick.trip_id
AND    wds_pick.stop_id(+) = wdl.pick_up_stop_id
AND    wt.trip_id(+) = wds_drop.trip_id
AND    wds_drop.stop_id(+) = wdl.drop_off_stop_id         
AND    mmt.transaction_type_id IN (33)
AND    mmt.transaction_action_id IN (1)
AND    mmt.transaction_source_type_id IN (2)
AND    TO_CHAR(ooh.header_id) = mmt.transaction_reference
AND    mmt.trx_source_line_id = ool.line_id
--AND    ooh.order_number = '94693'
--and msi.segment1 = '10209'
and mmt.transaction_id = 5298955
ORDER BY ooh.order_number, wt.name, ool.line_number
;




SELECT xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc
     , ximt.*
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
WHERE 1=1
AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND   ximt.reql_attribute3_cr = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior = xcrp.oracle_cr
AND   ximt.rh_header_id = '94693'
; 



where 1=1
and   ximt.rh_header_id = '94693'


select xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc
from  xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
where xmcr.oracle_cr_superior = xcrp.oracle_cr
AND   xmcr.oracle_cr = '50SDP'
AND   xmcr.oracle_cr_superior = '10DZV'
;

SELECT xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc
     , ximt.*
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
WHERE 1=1
AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND   ximt.reql_attribute3_cr = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior = xcrp.oracle_cr
AND   ximt.rh_header_id = '94693'
; 






SELECT  
     , xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc
     , wt.name  AS trip_name
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
    , oe_order_headers_all ooh
    , oe_order_lines_all ool
    , mtl_system_items_b msi 
    , wsh_delivery_details wdd
    , wsh_new_deliveries wnd
    , wsh_delivery_assignments wda
    , wsh_trips wt
    , wsh_delivery_legs wdl
    , wsh_trip_stops wds_pick     
    , wsh_trip_stops wds_drop   
    , mtl_material_transactions mmt
WHERE  1=1
AND    ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND    ximt.reql_attribute3_cr    = xmcr.oracle_cr
AND    xmcr.oracle_cr_superior    = xcrp.oracle_cr
AND    ooh.header_id              = ool.header_id    
AND    ool.ship_from_org_id       = msi.organization_id
AND    ool.inventory_item_id      = msi.inventory_item_id
AND    ool.ship_from_org_id       = mmt.organization_id
AND    ool.inventory_item_id      = mmt.inventory_item_id
AND    ooh.header_id              = wdd.source_header_id(+)
AND    wda.delivery_detail_id(+)  = wdd.delivery_detail_id
AND    wda.delivery_id            = wnd.delivery_id(+)
AND    ool.line_id                = wdd.source_line_id
AND    wdl.delivery_id(+)         = wnd.delivery_id  
AND    wt.trip_id(+)              = wds_pick.trip_id
AND    wds_pick.stop_id(+)        = wdl.pick_up_stop_id
AND    wt.trip_id(+)              = wds_drop.trip_id
AND    wds_drop.stop_id(+)        = wdl.drop_off_stop_id         
AND    mmt.transaction_type_id    IN (33)
AND    mmt.transaction_action_id  IN (1)
AND    mmt.transaction_source_type_id IN (2)
AND    TO_CHAR(ooh.header_id)     = mmt.transaction_reference
AND    mmt.trx_source_line_id     = ool.line_id
AND    mmt.transaction_id         = ximt.mmt_transaction_id     
AND    ximt.rh_header_id          = '94693'
;



SELECT ximt.mmt_inventory_item_id
     , ximt.mmt_organization_id 
     , ximt.mmt_transaction_quantity 
     , ximt.rh_header_id AS ooh_order_number 
     , ximt.rl_line_id AS ool_line_id 
     , ximt.mmt_actual_cost_alm
     , xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc
     , ( SELECT wt.name  
         FROM   oe_order_headers_all ooh
              , oe_order_lines_all ool
              , mtl_system_items_b msi 
              , wsh_delivery_details wdd
              , wsh_new_deliveries wnd
              , wsh_delivery_assignments wda
              , wsh_trips wt
              , wsh_delivery_legs wdl
              , wsh_trip_stops wds_pick     
              , wsh_trip_stops wds_drop   
              , mtl_material_transactions mmt
         WHERE  1=1
         AND    ooh.header_id              = ool.header_id 
         AND    ool.ship_from_org_id       = msi.organization_id
         AND    ool.inventory_item_id      = msi.inventory_item_id
         AND    ool.ship_from_org_id       = mmt.organization_id
         AND    ool.inventory_item_id      = mmt.inventory_item_id
         AND    ooh.header_id              = wdd.source_header_id(+)
         AND    wda.delivery_detail_id(+)  = wdd.delivery_detail_id
         AND    wda.delivery_id            = wnd.delivery_id(+)
         AND    ool.line_id                = wdd.source_line_id
         AND    wdl.delivery_id(+)         = wnd.delivery_id  
         AND    wt.trip_id(+)              = wds_pick.trip_id
         AND    wds_pick.stop_id(+)        = wdl.pick_up_stop_id
         AND    wt.trip_id(+)              = wds_drop.trip_id
         AND    wds_drop.stop_id(+)        = wdl.drop_off_stop_id         
         AND    mmt.transaction_type_id    IN (33)
         AND    mmt.transaction_action_id  IN (1)
         AND    mmt.transaction_source_type_id IN (2)
         AND    TO_CHAR(ooh.header_id)     = mmt.transaction_reference
         AND    mmt.trx_source_line_id     = ool.line_id
         AND    mmt.transaction_id         = ximt.mmt_transaction_id  
         AND    rownum = 1 
        ) AS trip_name       
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
WHERE 1=1
AND   ximt.rh_header_id          = '199109'
AND   ximt.rl_line_id            = 6389903
AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND   ximt.reql_attribute3_cr    = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior    = xcrp.oracle_cr
;

 update    xxfa_sn_data_Details 
 set
    rcv_transaction_id = 999953476207
 ,  rcv_shipment_header_id = 999912690707
 , rsh_receipt_num = 9999393136
 , rcv_shipment_line_id = 999931764736
 , rsl_item_id = 4350
 , msi_item_number = '31624'
 , rsl_item_description = 'LETRERO REFRESCA TUS MOMENTOS'     
 , mic_item_category_id = 8307
 , mic_item_Categ_fam = 'L - CONSTRUCCIÓN'
 , mic_item_Categ_subfam = 'LQ - EQUIPO IMAGEN'
 , msi_kit_type = 'N/A'
 , rcv_po_header_id = 999915418404
 , poh_po_number = 99992414756
 , rcv_po_line_id = 999933597832
 , pol_po_line_num =99991
 , rcv_po_line_location_id = 999950878059
, rcv_po_unit_price = 2316.89
 where     data_detail_id = 12565;


        
            INSERT INTO xxfc_sn_escaneo (
        sn_escaneo_id,
        sn_viaje,
        purchase_order,
        item_number,
        faa_serial_number,
        quantity,
        po_unit_price,
        faa_tag_number
    )
        SELECT
            SN_ESCANEO_ID_SEQ.NEXTVAL,
            3897182 sn_viaje,
            RH_HEADER_ID,
            msi_segment1_no_articulo,
            RL_LINE_ID,
            mmt_transaction_quantity, 
            ROUND((MMT_ACTUAL_COST * .98),2),
            --MMT_ACTUAL_COST,
            RL_LINE_ID
        FROM xxinv_material_transactions
		 where mmt_transaction_id = 72798367;
        
update xxfc_sn_escaneo set sn_viaje = 3897182, purchase_order = '99992414756'	
where SN_ESCANEO_ID = 87336;
		
        


SELECT ximt.mmt_inventory_item_id
     , ximt.mmt_organization_id 
     , ximt.mmt_transaction_quantity 
     , ximt.rh_header_id AS ooh_order_number 
     , ximt.rl_line_id AS ool_line_id 
     , ximt.mmt_actual_cost_alm
     , ximt.mmt_transaction_id
     , xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc   
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
WHERE 1=1
AND   ximt.rh_header_id          = '199109'
AND   ximt.rl_line_id            = 6389903
AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND   ximt.reql_attribute3_cr    = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior    = xcrp.oracle_cr
;



SELECT  xsn.sn_viaje
      , xsn.purchase_order 
      , xsn.po_unit_price 
      , xsn.sn_escaneo_id 
      , xsl.sts_header_id
      , xsl.sts_line_id
FROM    xxfc_sn_escaneo xsn
     ,  xxfc_sn_escaneo_lineas xsl 
WHERE   xsn.sn_escaneo_id = xsl.sn_escaneo_id 
AND     xsn.sn_viaje      = '3897182';




SELECT *
FROM   xxfa_sn_data_details xdd
WHERE  xdd.rsl_item_id = 4350
AND    xdd.poh_po_number = 99992414756
AND    xdd.rcv_po_unit_price = 2316.89
;



      SELECT  data_detail_id          
, prl_requisition_line_id 
, prl_oracle_cia          
, prl_oracle_ef           
, prl_retek_distrito      
, prl_oracle_cr           
, prl_oracle_cr_descr     
, prl_oracle_cr_superior  
, prl_oracle_cr_sup_descr 
, ooh_header_id           
, ooh_order_number        
, ool_line_id             
, wst_trip_id             
, wst_trip_name           
, mmt_transaction_id      
, mmt_creation_date
      FROM   xxfa_sn_data_details xdd
      WHERE data_detail_id = 12565



FOR X IN 
(
SELECT ximt.mmt_inventory_item_id
     , ximt.mmt_organization_id 
     , ximt.mmt_transaction_quantity 
     , ximt.rh_header_id AS ooh_order_number 
     , ximt.rl_line_id AS ool_line_id 
     , ximt.mmt_actual_cost_alm
     , ximt.mmt_transaction_id
     , ximt.rh_header_id
     , ximt.rl_line_id
     , xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc   
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
WHERE 1=1
AND   ximt.rh_header_id          = '199109'
AND   ximt.rl_line_id            = 6389903
AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND   ximt.reql_attribute3_cr    = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior    = xcrp.oracle_cr
)
LOOP
SELECT  xsn.sn_viaje
      , xsn.purchase_order 
      , xsn.po_unit_price 
      , xsl.sts_header_id
      , xsl.sts_line_id
      , xsn.sn_escaneo_id 
FROM    xxfc_sn_escaneo xsn
     ,  xxfc_sn_escaneo_lineas xsl 
WHERE   xsn.sn_escaneo_id      = xsl.sn_escaneo_id 
AND     xsl.sts_header_id      = x. '199109'
AND     xsl.sts_line_id        = x. 6389903
; 
FOR y in
(
SELECT xdd.data_detail_id 
FROM   xxfa_sn_data_details xdd
WHERE  xdd.rsl_item_id = ln 4350
AND    xdd.poh_po_number = ln 99992414756
AND    xdd.rcv_po_unit_price = ln 2316.89
AND    xxf.wst_trip_name IS NULL  
;
)

LOOP
   FOR i IN 1..x.quantity 
      UPDATE xxfa_sn_data_details SET wst_trip_id
                                    , wst_trip_name
                                    , prl_oracle_cia          
prl_oracle_ef           
prl_retek_distrito      
prl_oracle_cr           
prl_oracle_cr_descr     
prl_oracle_cr_superior  
prl_oracle_cr_sup_descr 
      WHERE data_detaild_id = y.data_Detail_id 
      
                               
                                    
   
   END LOOP

END LOOP
END LOOP
   


END LOOP


++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN
   XXINV_KITS_CUENTAS_DIARIO.xxinv_mat_trx_prc( pn_ooh_order_number   => '94918'
                                              , pn_ool_line_id        => 18488
                                              , pn_x_ret_code         => ln_ret_code
                                              , pv_x_errors           => lv_errors   
                                                );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 

SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN
									   
   XXINV_KITS_CUENTAS_DIARIO.pre_xxinv_mat_trx_temp_prc( pn_ooh_order_number   => '94918'
                                                       , pn_ool_line_id        => 18488
                                                       , pv_retcode            => ln_ret_code
                                                       , pv_errors            => lv_errors   
                                                         );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 

SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN

   XXINV_KITS_CUENTAS_DIARIO.pre_xxinv_mat_trx_temp_prc( pd_date               => TO_DATE('06-04-2021', 'DD-MM-YYYY')    
                                                       , pv_retcode            => ln_ret_code
                                                       , pv_errors             => lv_errors   
                                                         );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 

delete  xxinv_material_trx_temp ximt
WHERE 1=1
AND   ximt.rh_header_id          = '94918'
AND   ximt.rl_line_id            = 18488
;




select po_unit_price, fa_tag_number, fa_serial_number, mmt_viaje, msi_segment1_no_articulo, rh_header_id, rl_line_id
from   xxinv_pre_material_trx_temp ximt_pre;

select sts_header_id, sts_line_id
FROM   xxfc_sn_escaneo_lineas ses
WHERE  ses.sn_viaje = 2157
AND    ses.item_number = '19216'
AND    ses.sts_header_id IS NULL;


update xxinv_pre_material_trx_temp set po_unit_price= null, fa_tag_number=null, fa_serial_number=null
where rh_header_id          = '94918'
AND   rl_line_id            = 18488
; 

update xxfc_sn_escaneo_lineas set sts_header_id=null, sts_line_id= null
WHERE  sn_viaje = 2157
AND    item_number = '19216'
;


SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN
									   
   XXINV_KITS_CUENTAS_DIARIO.procesa_info_articulo_prc( pn_ooh_order_number   => '94918'
                                                      , pn_ool_line_id        => 18488
                                                      , pv_retcode            => ln_ret_code
                                                      , pv_errors            => lv_errors   
                                                        );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 

SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN

   XXINV_KITS_CUENTAS_DIARIO.procesa_info_articulo_prc( pd_creation_date      => TO_DATE('06-04-2021', 'DD-MM-YYYY')    
                                                      , pv_retcode            => ln_ret_code
                                                      , pv_errors             => lv_errors   
                                                        );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 





SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN
									   
   XXINV_KITS_CUENTAS_DIARIO.reagrupa_info_prc( pn_ooh_order_number   => '94918'
                                              , pn_ool_line_id        => 18488
                                              , pv_retcode            => ln_ret_code
                                              , pv_errors            => lv_errors   
                                               );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 

SET SERVEROUTPUT ON
DECLARE 
   ln_ret_code NUMBER;
   lv_errors   VARCHAR2(4000); 
BEGIN

   XXINV_KITS_CUENTAS_DIARIO.reagrupa_info_prc( pv_retcode            => ln_ret_code
                                              , pv_errors             => lv_errors   
                                               );
												
    dbms_output.put_line('ln_ret_code '||ln_ret_code);   
    dbms_output.put_line('lv_errors '||lv_errors);    	
EXCEPTION 
   WHEN OTHERS THEN 
      dbms_output.put_line('SQLERRM '||sqlerrm);   
END; 


caso 2 con 6 lineas
SELECT ximt.mmt_transaction_id 
     , ximt.mmt_inventory_item_id
     , ximt.msi_segment1_no_articulo
     , ximt.mmt_organization_id 
     , ximt.mmt_transaction_quantity 
     , ximt.rh_header_id AS ooh_order_number 
     , ximt.rl_line_id AS ool_line_id 
     , ximt.mmt_actual_cost_alm
     , xmcr.oracle_cia
     , xmcr.oracle_ef
     , xmcr.oracle_cr_superior
     , xcrp.descripcion AS oracle_cr_sup_descr
     , xmcr.retek_cr 
     , xmcr.oracle_cr
     , xmcr.oracle_cr_desc
     , ( SELECT wt.name  
         FROM   oe_order_headers_all ooh
              , oe_order_lines_all ool
              , mtl_system_items_b msi 
              , wsh_delivery_details wdd
              , wsh_new_deliveries wnd
              , wsh_delivery_assignments wda
              , wsh_trips wt
              , wsh_delivery_legs wdl
              , wsh_trip_stops wds_pick     
              , wsh_trip_stops wds_drop   
              , mtl_material_transactions mmt
         WHERE  1=1
         AND    ooh.header_id              = ool.header_id 
         AND    ool.ship_from_org_id       = msi.organization_id
         AND    ool.inventory_item_id      = msi.inventory_item_id
         AND    ool.ship_from_org_id       = mmt.organization_id
         AND    ool.inventory_item_id      = mmt.inventory_item_id
         AND    ooh.header_id              = wdd.source_header_id(+)
         AND    wda.delivery_detail_id(+)  = wdd.delivery_detail_id
         AND    wda.delivery_id            = wnd.delivery_id(+)
         AND    ool.line_id                = wdd.source_line_id
         AND    wdl.delivery_id(+)         = wnd.delivery_id  
         AND    wt.trip_id(+)              = wds_pick.trip_id
         AND    wds_pick.stop_id(+)        = wdl.pick_up_stop_id
         AND    wt.trip_id(+)              = wds_drop.trip_id
         AND    wds_drop.stop_id(+)        = wdl.drop_off_stop_id         
         AND    mmt.transaction_type_id    IN (33)
         AND    mmt.transaction_action_id  IN (1)
         AND    mmt.transaction_source_type_id IN (2)
         AND    TO_CHAR(ooh.header_id)     = mmt.transaction_reference
         AND    mmt.trx_source_line_id     = ool.line_id
         AND    mmt.transaction_id         = ximt.mmt_transaction_id  
         AND    rownum = 1 
        ) AS trip_name       
FROM  xxinv_material_transactions ximt
    , xxfc_maestro_de_crs_v  xmcr
    , xxfc_centros_responsabilidad xcrp
WHERE 1=1
AND   ximt.rh_header_id          = '94918'
AND   ximt.rl_line_id            = 18488
AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
AND   ximt.reql_attribute3_cr    = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior    = xcrp.oracle_cr
;


    INSERT INTO xxfc_sn_escaneo (
        sn_escaneo_id,
        sn_viaje,
        purchase_order,
        item_number,
        faa_serial_number,
        quantity,
        po_unit_price,
        faa_tag_number
    )
        SELECT
            SN_ESCANEO_ID_SEQ.NEXTVAL,
            2157 sn_viaje,
            RH_HEADER_ID,
            msi_segment1_no_articulo,
            RL_LINE_ID,
            mmt_transaction_quantity, 
            ROUND((MMT_ACTUAL_COST * .98),2),
            --MMT_ACTUAL_COST,
            RL_LINE_ID
        FROM xxinv_material_transactions
		 where mmt_transaction_id = 5291303;
        

         SELECT  wst.trip_id
               , xsn.sn_viaje
               , xsn.purchase_order 
               , xsn.po_unit_price 
               , xsn.sn_escaneo_id
         FROM    xxfc_sn_escaneo xsn
              ,  xxfc_sn_escaneo_lineas xsl 
              ,  wsh_trips wst
         WHERE   xsn.sn_escaneo_id      = xsl.sn_escaneo_id 
         AND     xsn.sn_viaje           = wst.name       
         AND     xsl.sts_header_id      = '94918'
         AND     xsl.sts_line_id        = 18488
         ;

insert into xxfa_sn_data_details
(
rcv_transaction_id           
, rcv_destination_type_code    
, rcv_transaction_date         
, rcv_primary_unit_of_measure  
, rcv_shipment_header_id       
, rsh_receipt_num              
, rcv_shipment_line_id         
, rsl_shipment_line_num        
, rsl_item_id                  
, msi_item_number              
, msi_use_type                 
, rsl_item_description         
, mic_item_category_id         
, mic_item_categ_fam           
, mic_item_categ_subfam        
, msi_kit_type                 
, msi_kit_principal_flag       
, msi_kit_parent               
, msi_asset_badgeable_flag     
, msi_asset_seriable_flag      
, fa_item_sequence             
, rcv_invoice_num              
, ap_invoice_uuid              
, ap_org_company_name          
, ap_org_company_rfc           
, rcv_po_header_id             
, poh_po_number                
, poh_po_date                  
, pra_release_num              
, rcv_po_release_id            
, rcv_po_line_id               
, pol_po_line_num              
, rcv_po_line_location_id      
, rcv_quantity                 
, rcv_po_unit_price            
, rcv_currency_code            
, rcv_currency_conversion_rate 
, rcv_currency_conversion_date 
, rcv_vendor_id                
, asu_vendor_number            
, asu_vendor_name              
, rcv_vendor_site_id           
, ass_vendor_site_code         
, rcv_inv_organization_id      
, mtl_inv_organization_code    
, poh_org_id                   
, hou_org_code                 
, faa_asset_id                 
, faa_asset_number             
, faa_tag_number               
, faa_asset_category_id        
, fcb_asset_categ_seg_concat   
, fcb_asset_categ_acct         
, fcb_asset_categ_subacct      
, fcb_asset_categ_fam          
, fcb_asset_categ_fakey        
, faa_manufacturer_name        
, faa_model_number             
, faa_serial_number            
, faa_description              
, fbk_date_placed_mm           
, fbk_date_placed_yyyy         
, faa_property_type_code                  
, sn_u_estatus_assets          
, sn_u_estatus_contable        
, sn_u_estatus_factura         
, sn_u_folio_validacion_factura
, sn_u_tipo_error_factura      
, sn_u_folio_salida            
, sn_u_subtotal                
, sn_u_descuento               
, sn_u_impuesto                
, sn_u_retenciones             
, sn_u_total                   
, sn_u_clave_producto_sat      
, sn_uuid_folio_stat           
, sn_uso_cfdi                  
, sn_u_moneda                  
, sn_u_tipo_cambio             
, sn_u_metodo_pago             
, sn_u_forma_pago              
, sn_u_regiment_fiscal         
, sn_u_tipo_comprobante	     
, creation_date                
, created_by                   
, last_update_date             
, last_updated_by              
, last_update_login            
)
select rcv_transaction_id           
, rcv_destination_type_code    
, rcv_transaction_date         
, rcv_primary_unit_of_measure  
, rcv_shipment_header_id       
, rsh_receipt_num              
, rcv_shipment_line_id         
, rsl_shipment_line_num        
, rsl_item_id                  
, msi_item_number              
, msi_use_type                 
, rsl_item_description         
, mic_item_category_id         
, mic_item_categ_fam           
, mic_item_categ_subfam        
, msi_kit_type                 
, msi_kit_principal_flag       
, msi_kit_parent               
, msi_asset_badgeable_flag     
, msi_asset_seriable_flag      
, fa_item_sequence             
, rcv_invoice_num              
, ap_invoice_uuid              
, ap_org_company_name          
, ap_org_company_rfc           
, rcv_po_header_id             
, poh_po_number                
, poh_po_date                  
, pra_release_num              
, rcv_po_release_id            
, rcv_po_line_id               
, pol_po_line_num              
, rcv_po_line_location_id      
, rcv_quantity                 
, rcv_po_unit_price            
, rcv_currency_code            
, rcv_currency_conversion_rate 
, rcv_currency_conversion_date 
, rcv_vendor_id                
, asu_vendor_number            
, asu_vendor_name              
, rcv_vendor_site_id           
, ass_vendor_site_code         
, rcv_inv_organization_id      
, mtl_inv_organization_code    
, poh_org_id                   
, hou_org_code                 
, faa_asset_id                 
, faa_asset_number             
, faa_tag_number               
, faa_asset_category_id        
, fcb_asset_categ_seg_concat   
, fcb_asset_categ_acct         
, fcb_asset_categ_subacct      
, fcb_asset_categ_fam          
, fcb_asset_categ_fakey        
, faa_manufacturer_name        
, faa_model_number             
, faa_serial_number            
, faa_description              
, fbk_date_placed_mm           
, fbk_date_placed_yyyy         
, faa_property_type_code                  
, sn_u_estatus_assets          
, sn_u_estatus_contable        
, sn_u_estatus_factura         
, sn_u_folio_validacion_factura
, sn_u_tipo_error_factura      
, sn_u_folio_salida            
, sn_u_subtotal                
, sn_u_descuento               
, sn_u_impuesto                
, sn_u_retenciones             
, sn_u_total                   
, sn_u_clave_producto_sat      
, sn_uuid_folio_stat           
, sn_uso_cfdi                  
, sn_u_moneda                  
, sn_u_tipo_cambio             
, sn_u_metodo_pago             
, sn_u_forma_pago              
, sn_u_regiment_fiscal         
, sn_u_tipo_comprobante	     
, creation_date                
, created_by                   
, last_update_date             
, last_updated_by              
, last_update_login            
from xxfa_sn_data_details
where data_Detail_id = 12565;


 update    xxfa_sn_data_Details 
 set
    rcv_transaction_id = 999853476207
 ,  rcv_shipment_header_id = 999812690707
 , rsh_receipt_num = 9998393136
 , rcv_shipment_line_id = 999831764736
 , rsl_item_id = 2935
 , msi_item_number = '19216'
 , rsl_item_description = 'GANCHO DE 37 CMS CON PORTAPRECIO Y SUJETADOR PARA SOLERA COLOR NEGRO'     
 , mic_item_category_id = 8307
 , mic_item_Categ_fam = 'L - CONSTRUCCIÓN'
 , mic_item_Categ_subfam = 'LQ - EQUIPO IMAGEN'
 , msi_kit_type = 'GPOTOTAL'
 , msi_kit_principal_flag = 'N' 
 , rcv_po_header_id = 999815418404
 , poh_po_number = 99982414756
 , rcv_po_line_id = 999833597832
 , pol_po_line_num =99981
 , rcv_po_line_location_id = 999850878059
, rcv_po_unit_price = 42
 where     data_detail_id between 12578 and 12589;
 
 

 update    xxfc_sn_escaneo 
 set
    purchase_order = 99982414756
 where     sn_escaneo_id = 87340
 ;
 
 select *
 from xxfa_sn_data_Details
 where     data_detail_id between 12578 and 12589;
 
 
  update 
 xxfa_sn_data_Details set
 prl_requisition_line_id         = NULL
 , prl_oracle_cia                = NULL
 , prl_oracle_ef                 = NULL
 , prl_retek_distrito            = NULL
 , prl_oracle_cr                 = NULL
 , prl_oracle_cr_descr           = NULL
 , prl_oracle_cr_superior        = NULL
 , prl_oracle_cr_sup_descr       = NULL
 , ooh_header_id                 = NULL
 , ooh_order_number              = NULL
 , ool_line_id                   = NULL
 , wst_trip_id	                 = NULL
 , wst_trip_name	             = NULL
 , mmt_transaction_id            = NULL
 , mmt_creation_date             = NULL
 where     data_detail_id between 12578 and 12589;
 
 
 
  
update xxinv_pre_material_trx_temp set po_unit_price= null, fa_tag_number=null, fa_serial_number=null
where rh_header_id          = '94918'
AND   rl_line_id            = 18488
; 

update xxfc_sn_escaneo_lineas set sts_header_id=null, sts_line_id= null
WHERE  sn_viaje = 2157
AND    item_number = '19216'
;


select *
from   xxinv_pre_material_trx_temp ximt_pre
where rh_header_id          = '94918'
AND   rl_line_id            = 18488;

select *
from   xxinv_material_trx_temp ximt_pre
where rh_header_id          = '94918'
AND   rl_line_id            = 18488;

select *
from  xxfc_sn_escaneo_lineas 
where wsh_sts_header_id          = '94918'
AND   wsh_sts_line_id            = 18488;



------- 1 Obtener una transaccion previa de salida, para simular que sera nuestra salida 
select *
from   xxinv_material_transactions
where  msi_Segment1_no_articulo = '19216'
and    rl_line_id = 6495345
order by 1 desc;

------- 2 Conocer el viaje
SELECT DISTINCT wts.trip_id
FROM   apps.wsh_delivery_legs wdl
     , apps.wsh_trip_stops    wts
WHERE  1 = 1
AND    wdl.pick_up_stop_id = wts.stop_id
AND    wdl.delivery_id IN ( SELECT DISTINCT wda.delivery_id
                            FROM   apps.wsh_delivery_assignments wda
                                 , apps.wsh_delivery_details     wdd
                            WHERE  1 = 1
                            AND    wda.delivery_detail_id = wdd.delivery_detail_id
                            AND    wdd.source_header_number = 201178 --order_number
                            AND  wdd.source_line_id = 6495345
                          );

------- 3 Crear una OC con el articulo de la salida, autorizarla y recibirla. 
DECLARE
  l_return_status VARCHAR2 (1000);
  l_msg_data      VARCHAR2 (1000);
  CURSOR c1
  IS
    SELECT *
    FROM po_headers_all
    WHERE segment1            IN ('2414759' )
    AND  ORG_ID = 85
    AND type_lookup_code       = 'STANDARD'
    AND (authorization_status != 'APPROVED'
    OR authorization_status   IS NULL );
    
BEGIN
 --  mo_global.init ('PO');
   fnd_global.apps_initialize (9600, 54802, 201);
  
   FOR i IN c1
   LOOP
      po_document_action_pvt.do_approve (p_document_id      => i.po_header_id, 
                                         p_document_type    => 'PO', 
                                         p_document_subtype => 'STANDARD', 
                                         p_note             => '– Your comments that need TO be displayed IN action History', 
                                         p_approval_path_id => 62, 
                                         x_return_status    => l_return_status, 
                                         x_exception_msg    => l_msg_data 
                                         );
      DBMS_OUTPUT.put_line (l_return_status);
      COMMIT;
   END LOOP;
END;

------- 4 Se inserta la inforamacio de la recepcion en la tabla intermedia 
select *
from xxfa_sn_data_Details
where poh_po_number = '2414759';

------- 5 se escanea 
INSERT INTO xxfc_sn_escaneo( sn_escaneo_id
                           , sn_viaje
                           , purchase_order
                           , item_number
                           , faa_serial_number
                           , quantity
                           , po_unit_price
                           , faa_tag_number
                            )
VALUES 
(
  SN_ESCANEO_ID_SEQ.NEXTVAL
, 3911183
, 2414759
, 19216
, 19216123
, 8
, 55.38
, 19216456
);

------- 6 se registran las lineas del escaneo, en teoria la debe hacer el trigger del paso 5 

DECLARE
    ls_viaje VARCHAR2(30);
    CURSOR cur_registros IS
    SELECT
        scan.*
    FROM
        xxfc_sn_escaneo scan
    WHERE
         sn_escaneo_id      = 87347;

BEGIN
    INSERT INTO xxfc_sn_escaneo_lineas (
        sn_escaneo_linea_id,
        sn_viaje,
        item_number,
        faa_serial_number,
        po_unit_price,
        faa_tag_number,
        sts_header_id,
        sts_line_id,
        sn_escaneo_id
    )
        SELECT
            sn_escaneo_id_seq.NEXTVAL,
            sn_viaje,
            item_number,
            faa_serial_number,
            po_unit_price,
            faa_tag_number,
            NULL sts_header_id,
            NULL sts_line_id,
            sn_escaneo_id
        FROM
            xxfc_sn_escaneo
        WHERE
            abs(quantity) = 1;

    FOR k IN cur_registros LOOP
        FOR i IN 1..abs(k.quantity) LOOP
            INSERT INTO xxfc_sn_escaneo_lineas (
                sn_escaneo_linea_id,
                sn_viaje,
                item_number,
                faa_serial_number,
                po_unit_price,
                faa_tag_number,
                sts_header_id,
                sts_line_id,
                sn_escaneo_id
            ) VALUES (
                sn_escaneo_id_seq.NEXTVAL,
                k.sn_viaje,
                k.item_number,
                k.faa_serial_number,
                k.po_unit_price,
                k.faa_tag_number,
                NULL,
                NULL,
                k.sn_escaneo_id
            );

        END LOOP;
    END LOOP;

END;

							
------- 7 se ejecuta scrupt para actualizar la tabla intermedia previa la salida 

------- 8 verificar resultados
select *
from xxfa_sn_data_Details
where poh_po_number = '2414759';


  update 
 xxfa_sn_data_Details set
 prl_requisition_line_id         = NULL
 , prl_oracle_cia                = NULL
 , prl_oracle_ef                 = NULL
 , prl_retek_distrito            = NULL
 , prl_oracle_cr                 = NULL
 , prl_oracle_cr_descr           = NULL
 , prl_oracle_cr_superior        = NULL
 , prl_oracle_cr_sup_descr       = NULL
 , ooh_header_id                 = NULL
 , ooh_order_number              = NULL
 , ool_line_id                   = NULL
 , wst_trip_id	                 = NULL
 , wst_trip_name	             = NULL
 , mmt_transaction_id            = NULL
 , mmt_creation_date             = NULL
where poh_po_number = '2414759';


 SELECT  *
 FROM    xxfc_sn_escaneo xsn
      ,  xxfc_sn_escaneo_lineas xsl 
      ,  wsh_trips wst
 WHERE   xsn.sn_escaneo_id      = xsl.sn_escaneo_id 
 AND     xsn.sn_viaje           = wst.name       
 AND     xsn.purchase_order     = '2414759'
 ;

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

select distinct fcr_parent.concurrent_program_id 
from   apps.fnd_concurrent_requests fcr_child
  , apps.fnd_concurrent_requests fcr_parent
where 1=1
and fcr_child.parent_request_id =  fcr_parent.request_id 
and fcr_child.concurrent_program_id =256442
and fcr_child.parent_request_id != -1;

Generación de Lista de Selección
XXFC-Carta Porte Automatizacion


p_delivery_id 
p_organiaztion_id 

Informe Nota de Embalaje

Interface de Parada de Viaje - SRS
Interface de Parada de Viaje



SELECT  DISTINCT WDD.SOURCE_LINE_ID,	   WDD.SOURCE_HEADER_ID,	   WDD.ORGANIZATION_ID,	   WDD.INVENTORY_ITEM_ID,	   WDD.MOVE_ORDER_LINE_ID,	   WDD.DELIVERY_DETAIL_ID,	   WDD.SHIP_MODEL_COMPLETE_FLAG,	   WDD.TOP_MODEL_LINE_ID,	   WDD.SHIP_FROM_LOCATION_ID,	   NULL SHIP_METHOD_CODE,	   WDD.SHIPMENT_PRIORITY_CODE,	   WDD.DATE_SCHEDULED DATE_SCHEDULED,	   WDD.REQUESTED_QUANTITY,	   WDD.REQUESTED_QUANTITY_UOM,	   WDD.PREFERRED_GRADE,	   WDD.REQUESTED_QUANTITY2,	   
        WDD.REQUESTED_QUANTITY_UOM2,	   WDD.PROJECT_ID,	   WDD.TASK_ID,	   WDD.SUBINVENTORY FROM_SUBINVENTORY_CODE,	   WDD.SUBINVENTORY TO_SUBINVENTORY_CODE,	   WDD.RELEASED_STATUS RELEASED_STATUS,	   WDD.SHIP_SET_ID SHIP_SET_ID,	   WDD.SOURCE_CODE SOURCE_CODE,	   WDD.SOURCE_HEADER_NUMBER SOURCE_HEADER_NUMBER,	   WTS.PLANNED_DEPARTURE_DATE,	   WDA.DELIVERY_ID,	   OL.END_ITEM_UNIT_NUMBER,	   OL.SOURCE_DOCUMENT_TYPE_ID,	   MSI.RESERVABLE_TYPE,          WDD.LAST_UPDATE_DATE,       -1 DEMAND_SOURCE_HEADER_ID,	
        -1 OUTSTANDING_ORDER_VALUE,          WDD.CUSTOMER_ID,          WDD.REVISION,          WDD.LOCATOR_ID,          WDD.LOT_NUMBER,          WDD.CLIENT_ID 
        FROM  WSH_DELIVERY_DETAILS WDD,	   wsh_delivery_assignments_v WDA,	   WSH_NEW_DELIVERIES WDE,	   WSH_DELIVERY_LEGS WLG,	   WSH_TRIP_STOPS WTS,	   OE_ORDER_LINES_ALL OL, 	   MTL_SYSTEM_ITEMS MSI  
        WHERE   WDD.DATE_SCHEDULED IS NOT NULL AND   WTS.STOP_ID = WLG.PICK_UP_STOP_ID  AND   WLG.DELIVERY_ID = WDE.DELIVERY_ID  
        AND   WDE.DELIVERY_ID = WDA.DELIVERY_ID  
        AND   WDA.DELIVERY_DETAIL_ID = WDD.DELIVERY_DETAIL_ID 
        AND   WDD.SOURCE_LINE_ID = OL.LINE_ID 
        AND   WDD.SOURCE_CODE  = 'OE'  
        AND   WDD.INVENTORY_ITEM_ID  = MSI.INVENTORY_ITEM_ID  
        AND   WDD.ORGANIZATION_ID  = MSI.ORGANIZATION_ID  
        AND WDD.RELEASED_STATUS IN ( 'R','B','X') 
        AND NVL(WDD.REPLENISHMENT_STATUS,'C') = 'C'  
        AND WDD.SHIP_FROM_LOCATION_ID = 146
        AND WDD.SOURCE_HEADER_TYPE_ID = 1003
        AND WDD.ORGANIZATION_ID = 93
        --AND TO_CHAR(WDD.DATE_SCHEDULED, 'RRRR/MM/DD HH24:MI:SS') <= to_date('12/10/2025','dd/mm/yyyy')
        AND WDD.DATE_SCHEDULED <= to_date('13/10/2025','dd/mm/yyyy')
        AND (WDA.DELIVERY_ID IS NULL	  OR 3924117 <> 0	 ) 
        AND (NVL(WDD.DEP_PLAN_REQUIRED_FLAG,'N') = 'N'	  OR (NVL(WDD.DEP_PLAN_REQUIRED_FLAG,'N') = 'Y' 
        AND NVL(WDE.PLANNED_FLAG,'N') IN ('Y','F'))) 
        AND WTS.TRIP_ID = 3924117  ORDER BY  WDD.INVENTORY_ITEM_ID,  SHIPMENT_PRIORITY_CODE ASC,  DATE_SCHEDULED ASC,  to_number(SOURCE_HEADER_NUMBER) ASC,  SHIP_FROM_LOCATION_ID;




WITH a
AS
(
select 'C1246DFW1' AS folio
FROM DUAL
)
SELECT CASE 
       WHEN INSTR(a.folio,'-') > 0  -- Si ya trae guion 
       OR   NOT REGEXP_LIKE(a.folio, '^[A-Za-z]') -- Si no trae letras al inicio
       THEN
          a.folio
       ELSE
          REGEXP_REPLACE(a.folio, '([[:alpha:]]*?)([[:digit:]])', '\1-\2', 1, 1)
       END folio 
FROM a; 