WITH msi AS
(
SELECT msi.organization_id 
     , msi.inventory_item_id     
     , msi.segment1             
     , msi.attribute1           
FROM   mtl_system_items_b msi 
WHERE  msi.attribute1   = '04'
)
select rsh.*
, msi.* 
from      rcv_shipment_headers         rsh
     , rcv_shipment_lines           rsl
     , msi
     --, rcv_transactions rcv 
where    rsh.shipment_header_id      = rsl.shipment_header_id
--AND      rsl.shipment_line_id        = rcv.shipment_line_id 
and      rsl.item_id = msi.inventory_item_id
AND      rsl.to_organization_id = msi.organization_id 



SELECT rcv.transaction_type
     , msi.attribute1
FROM   rcv_transactions             rcv
     , rcv_shipment_headers         rsh
     , rcv_shipment_lines           rsl
     , mtl_system_items_b           msi            
WHERE 1 = 1
AND   rcv.shipment_header_id      = rsh.shipment_header_id
AND   rcv.shipment_line_id        = rsl.shipment_line_id
AND   rsl.to_organization_id      = msi.organization_id   
AND   rsl.item_id                 = msi.inventory_item_id    
AND   rcv.transaction_id          IN ( 5321737, 5313315, 5357899)


set SERVEROUTPUT off
DECLARE 

   lv_errbuf      VARCHAR2(4000);  
   lv_retcode     VARCHAR2(1);  

BEGIN
   FOR x in 1..2 
   LOOP
      xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, 5321737 );
      xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, 5313315 );
	  xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, 5357899 );
  END LOOP;	  
   	commit;  
END; 



set SERVEROUTPUT on
DECLARE 

   lv_errbuf      VARCHAR2(4000);  
   lv_retcode     VARCHAR2(1);  

BEGIN
   xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, 5321737 );
   dbms_output.put_line('lv_errbuf '||lv_errbuf) ;   
    dbms_output.put_line('lv_retcode '||lv_retcode) ;   
   	commit;  
END; 




select *
from dba_triggers
where table_name like 'XXPO_RECEIPT_PRINT%'


select *
from  XXPO_RECEIPT_PRINT a
where a.organization_id = 93
and exists 
(
select 1
from rcv_Transactions b
 , rcv_shipment_lines c
 , mtl_system_items_b d
where b.shipment_header_id = a.shipment_header_id 
AND b.shipment_line_id = c.shipment_line_id 
and  c.item_id = d.inventory_item_id 
and   d.attribute1 = '04'
)
order by a.shipment_header_id;

select  *
from  apps.rcv_transactions a
   , apps.po_lines_All b
   , apps.mtl_system_items_B c
where a.attribute1 is not null
and a.transaction_type = 'RECEIVE' 
and   a.po_line_id = b.po_line_id 
and  b.item_id = c.inventory_item_id
and  c.organization_id = 93
and   c.attribute1 = '04'
order by a.transaction_date desc, a.po_header_id, a.po_line_id;


update rcv_transactions set attribute1 = 'NAFACT35388'
where po_header_id = 15338703
and attribute1 = 'FACT35388';

select *
from ap_invoices_all
where invoice_num ='FACT35388';

update ap_invoices_all set invoice_num = 'NAFACT35381'
where invoice_num ='FACT35381';




DECLARE
  l_return_status VARCHAR2 (1000);
  l_msg_data      VARCHAR2 (1000);
  CURSOR c1
  IS
    SELECT *
    FROM po_headers_all
    WHERE segment1            IN ('2414752' )
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

DECLARE 
   lv_errbuf VARCHAR2(1000);
   lv_retcode VARCHAR2(1000);
BEGIN

   xxfa_sn_data_api_pkg.load_details_from_rcv_prc (  errbuf               => lv_errbuf
                                                   , retcode              => lv_retcode
                                                   , p_rcv_transaction_id => 
                                                    );
										
   xxfa_sn_data_api_pkg.load_fe_details_from_rcv_prc  (  errbuf               => lv_errbuf
                                                       , retcode              => lv_retcode
                                                      , p_rcv_transaction_id  => 
                                                    );
EXCEPTION 
   WHEN OTHERS THEN 
       dbms_output.put_line('error '||sqlerrm);
END;




select *
from   apps.xxfa_sn_data_details
where  wst_trip_name is not null
;

select *
from   apps.xxfc_sn_escaneo_lineas;

select *
from  apps.fnd_concurrent_programs_tl
where  user_concurrent_program_name like 'XX%SN%DATA%';

select *
from  apps.fnd_concurrent_requests
where concurrent_program_id = 319443
and argument1 = 4384370
;

select *
from  apps.fnd_concurrent_requests
where concurrent_program_id = 319443
and argument1 in ( select sn_viaje
from   apps.xxfc_sn_escaneo_lineas);
;


select distinct sn_viaje
from   apps.xxfc_sn_escaneo_lineas;



         SELECT  ooh.order_number
               , wdd.source_line_id ool_line_id        
         FROM    apps.oe_order_headers_all ooh
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
         AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
         AND    wda.delivery_id             = wnd.delivery_id(+)
         AND    wdl.delivery_id(+)          = wnd.delivery_id  
         AND    wt.trip_id(+)               = wds_pick.trip_id
         AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
         AND    wt.trip_id(+)               = wds_drop.trip_id
         AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
         AND    msi.inventory_item_id       = wdd.inventory_item_id 
         AND    msi.organization_id         = wdd.organization_id
         --Valia la organizacion de inventario                
         AND   EXISTS 
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
         -- Valida el uso del articulo 
         AND EXISTS 
             (
             SELECT 1
             FROM   apps.xxfc_mapeos_varios xmv
             WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
             AND    xmv.entrada    LIKE 'USE_ITEM%'
             AND    xmv.salida1    = msi.attribute1 
             AND    xmv.estado     = 'A'
             AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
             AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
             ) 
          AND    wt.name                     = 4420435 
          AND    wdd.organization_id         = 93        
          ORDER BY 1, 2;      
           

      SELECT  reqs.segment1 reqh_segment1_no_requisicion
            , reqs.requisition_header_id reqh_requisition_header_id
            , msi.segment1 msi_segment1_no_articulo
            , msi.description msi_descripcion
            , msi.attribute1 msi_attribute1_uso
            , msi.attribute2 msi_attribute2_mae_activo
            , msi.attribute3
            , msi.attribute7 msi_attribute7_mae_tipo
            , msi.attribute8 msi_attribute8_mae_yn
            , msi.attribute4 msi_attribute4_parent_mand
            , msi.attribute6 msi_attribute6_parent_hijos
            , mmt.transaction_id  mmt_transaction_id
            , mmt.creation_date mmt_creation_date
            , mmt.created_by mmt_created_by
            , mmt.inventory_item_id mmt_inventory_item_id
            , mmt.transaction_quantity mmt_transaction_quantity
            , mmt.transaction_date mmt_transaction_date
            , mmt.distribution_account_id mmt_distribution_account_id
            , mmt.new_cost mmt_actual_cost
            , mmt.source_code mmt_source_code
            , mmt.transaction_type_id mmt_transaction_type_id
            , mmt.transaction_action_id mmt_transaction_action_id
            , mmt.transaction_source_type_id mmt_transaction_source_type_id
            , mmt.organization_id mmt_organization_id
            , rl.line_id rl_line_id
            , rh.order_number  rh_header_id
            , rl.attribute1
            , mmt.distribution_account_id af_ccid
            , msi.purchasing_tax_code
            , NULL --mta.gl_batch_id
            , mmt.attribute15
      FROM  apps.mtl_material_transactions mmt
          , apps.mtl_system_items_b msi
          , apps.oe_order_headers_all rh
          , apps.oe_order_lines_all rl
          , apps.po_requisition_headers_all reqs
          --, mtl_transaction_accounts   mta 
      WHERE  mmt.transaction_type_id         IN (33)  --33-change Sales order issue WMS 23-03-17
      AND    mmt.transaction_action_id       IN (1)
      AND    mmt.transaction_source_type_id  IN (2) --2-change Sales order issue WMS 23-03-17
      AND    mmt.inventory_item_id           = msi.inventory_item_id
      AND    msi.organization_id             = mmt.organization_id 
      AND    rh.attribute2                   = TO_CHAR(reqs.requisition_header_id)
      AND    rh.header_id                    = mmt.transaction_reference 
      AND    rh.header_id                    =  rl.header_id
      AND    mmt.trx_source_line_id          = rl.line_id
      --AND    mta.organization_id             = mmt.organization_id
      --AND    mta.transaction_id              = mmt.transaction_id
      --AND    mta.reference_account           = mmt.distribution_account_id
      --AND    mta.accounting_line_type        = 36
      AND    rh.order_number                 = 226916
      AND    rl.line_id                      = 7620735
      ; 
