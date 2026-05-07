SET DEFINE OFF
PROMPT VIEW APPS.XXFA_SN_TRIPS_V
CREATE OR REPLACE FORCE VIEW apps.xxfa_sn_trips_v 
(
  sn_trip_detail_id      
, sn_trip_id             
, wst_trip_id            
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
, plaza_destino
, cr_destino
, solicitante
, solicitud_inversion
, creation_date          
, created_by             
, last_update_date       
, last_updated_by        
, last_update_login     
, sn_trip_name_ver	
, wnd_confirm_date_yyyymmdd
)
AS 
SELECT sn_trip_detail_id      
     , sn_trip_id             
     , wst_trip_id            
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
     , creation_date          
     , created_by             
     , last_update_date       
     , last_updated_by        
     , last_update_login     
     , wst_trip_name||'_'||sn_trip_id AS sn_trip_name_ver	 
	 , TO_CHAR(wnd_confirm_date,'YYYY-MM-DD') AS wnd_confirm_date_yyyymmdd
FROM   xxfa_sn_trips
;
SHOW ERRORS;