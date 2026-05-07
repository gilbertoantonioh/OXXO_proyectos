XXFC_XXFA_SN_TRIP_COMP_TBL

XXFA_SN_TRIP_COMP_NU1_IDX


APPSVIEW_XXFA_SN_TRIP_COMP_SYN

APPS_XXFA_SN_TRIP_COMP_APPSVIEW_GRN


SELECT  xif.transaction_source_id    
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , xih.organization_id
FROM    xxfc_inv_firma_salidas xif
      , xxfc_inv_header_salidas_v xih
WHERE   xif.transaction_source_id   = xih.move_order
AND     xif.transaction_set_id      = xih.header_id 
AND     xif.transaction_set_id      = 74269037;



           XXFA_SN_TRIPS_COMP_V    
xxfa_sn_trips_comp_v






SELECT  DISTINCT wt.name AS wst_trip_name 
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , xih.organization_id 
      , xif.fecha_firma
FROM    xxfc_inv_firma_salidas xif
      , xxfc_inv_header_salidas_v xih
      , mtl_material_transactions mmt
      , wsh_delivery_details wdd
      , wsh_new_deliveries wnd
      , wsh_delivery_assignments wda
      , wsh_trips wt
      , wsh_delivery_legs wdl
      , wsh_trip_stops wds_pick     
      , wsh_trip_stops wds_drop 
WHERE   xif.transaction_source_id   = xih.move_order
AND     xif.transaction_set_id      = xih.header_id 
AND     mmt.transaction_set_id      = xif.transaction_set_id
AND     mmt.picking_line_id         = wdd.delivery_detail_id
AND     wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND     wda.delivery_id             = wnd.delivery_id(+)
AND     wdl.delivery_id(+)          = wnd.delivery_id  
AND     wt.trip_id                  = wds_pick.trip_id
AND     wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND     wt.trip_id                  = wds_drop.trip_id
AND     wds_drop.stop_id(+)         = wdl.drop_off_stop_id  
AND     xif.transaction_source_id   = 202346;





SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */ 
        DISTINCT wt.name AS wst_trip_name 
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
      , xif.user_name
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt
      , wsh_delivery_details wdd
      , wsh_new_deliveries wnd
      , wsh_delivery_assignments wda
      , wsh_trips wt
      , wsh_delivery_legs wdl
      , wsh_trip_stops wds_pick     
      , wsh_trip_stops wds_drop 
WHERE   mmt.transaction_set_id      = xif.transaction_set_id
AND     mmt.picking_line_id         = wdd.delivery_detail_id
AND     wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND     wda.delivery_id             = wnd.delivery_id(+)
AND     wdl.delivery_id(+)          = wnd.delivery_id  
AND     wt.trip_id                  = wds_pick.trip_id
AND     wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND     wt.trip_id                  = wds_drop.trip_id
AND     wds_drop.stop_id(+)         = wdl.drop_off_stop_id 
AND     wt.status_code              = 'CL';






SELECT  DISTINCT wt.name AS wst_trip_name 
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , xih.organization_id 
      , xif.fecha_firma
      , xif.user_name
FROM    xxfc_inv_firma_salidas xif
      , xxfc_inv_header_salidas_v xih
      , mtl_material_transactions mmt
      , wsh_delivery_details wdd
      , wsh_new_deliveries wnd
      , wsh_delivery_assignments wda
      , wsh_trips wt
      , wsh_delivery_legs wdl
      , wsh_trip_stops wds_pick     
      , wsh_trip_stops wds_drop 
WHERE   xif.transaction_source_id   = xih.move_order
AND     xif.transaction_set_id      = xih.header_id 
AND     mmt.transaction_set_id      = xif.transaction_set_id
AND     mmt.picking_line_id         = wdd.delivery_detail_id
AND     wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND     wda.delivery_id             = wnd.delivery_id(+)
AND     wdl.delivery_id(+)          = wnd.delivery_id  
AND     wt.trip_id                  = wds_pick.trip_id
AND     wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND     wt.trip_id                  = wds_drop.trip_id
AND     wds_drop.stop_id(+)         = wdl.drop_off_stop_id 
AND     xif.fecha_firma            > 
(
SELECT SYSDATE - TO_NUMBER(ffv.description)
FROM apps.fnd_flex_value_sets fvs
   , apps.fnd_flex_values_vl ffv
WHERE 1=1
AND   fvs.flex_value_set_id = ffv.flex_value_set_id
AND   fvs.flex_value_set_name = 'XXINV_DEP_ESCANEO_TBS'
AND   ffv.flex_value = 'DIAS_DEP'
AND   ffv.enabled_flag = 'Y'
AND  ( ffv.start_date_active    <= SYSDATE OR ffv.start_date_active IS NULL )
AND  ( ffv.end_date_active      >= SYSDATE OR ffv.end_date_active IS NULL )
);



WITH wsh_data
AS
(
SELECT  wt.name AS wst_trip_name 
      , mmt.transaction_set_id 
      , mmt.organization_id
FROM    mtl_material_transactions mmt
      , wsh_delivery_details wdd
      , wsh_new_deliveries wnd
      , wsh_delivery_assignments wda
      , wsh_trips wt
      , wsh_delivery_legs wdl
      , wsh_trip_stops wds_pick     
      , wsh_trip_stops wds_drop 
WHERE   mmt.picking_line_id         = wdd.delivery_detail_id
AND     wda.delivery_detail_id(+)   = wdd.delivery_detail_id
AND     wda.delivery_id             = wnd.delivery_id(+)
AND     wdl.delivery_id(+)          = wnd.delivery_id  
AND     wt.trip_id                  = wds_pick.trip_id
AND     wds_pick.stop_id(+)         = wdl.pick_up_stop_id
AND     wt.trip_id                  = wds_drop.trip_id
AND     wds_drop.stop_id(+)         = wdl.drop_off_stop_id 
AND     wt.status_code              = 'CL'

)
SELECT  DISTINCT 
        wsh_data.wst_trip_name 
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , wsh_data.organization_id 
      , xif.fecha_firma
      , xif.user_name as user_name_firma
FROM    xxfc_inv_firma_salidas xif
      , wsh_data
WHERE   xif.transaction_set_id      = wsh_data.transaction_set_id;









WITH xif_mmt_data
AS
(
SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
        mmt.picking_line_id
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
      , xif.user_name as user_name_firma
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
)
SELECT  wt.name AS wst_trip_name
      , xif_mmt_data.nombre_fletera
      , xif_mmt_data.nombre_transportista 
      , xif_mmt_data.no_placa 
      , xif_mmt_data.organization_id 
      , xif_mmt_data.fecha_firma
      , xif_mmt_data.user_name_firma
FROM    wsh_delivery_details wdd
      , wsh_new_deliveries wnd
      , wsh_delivery_assignments wda
      , wsh_trips wt
      , wsh_delivery_legs wdl
      , wsh_trip_stops wds_pick     
      , wsh_trip_stops wds_drop 
      , xif_mmt_data
WHERE   xif_mmt_data.picking_line_id     = wdd.delivery_detail_id
AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
AND     wda.delivery_id                  = wnd.delivery_id(+)
AND     wdl.delivery_id(+)               = wnd.delivery_id  
AND     wt.trip_id                       = wds_pick.trip_id
AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
AND     wt.trip_id                       = wds_drop.trip_id
AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
AND     wt.status_code                   = 'CL';




SELECT DISTINCT 
       (
        SELECT  wt.name AS wst_trip_name
        FROM    wsh_delivery_details wdd
              , wsh_new_deliveries wnd
              , wsh_delivery_assignments wda
              , wsh_trips wt
              , wsh_delivery_legs wdl
              , wsh_trip_stops wds_pick     
              , wsh_trip_stops wds_drop 
        WHERE   xif_mmt.picking_line_id          = wdd.delivery_detail_id
        AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
        AND     wda.delivery_id                  = wnd.delivery_id
        AND     wdl.delivery_id                  = wnd.delivery_id  
        AND     wt.trip_id                       = wds_pick.trip_id
        AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
        AND     wt.trip_id                       = wds_drop.trip_id
        AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
        AND     wt.status_code                   = 'CL'
       ) AS wst_trip_name
     , xif_mmt.nombre_fletera
     , xif_mmt.nombre_transportista 
     , xif_mmt.no_placa 
     , xif_mmt.organization_id 
     , xif_mmt.fecha_firma
     , xif_mmt.user_name_firma
FROM 
(
SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
        xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
      , xif.user_name as user_name_firma
      , mmt.picking_line_id
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
) xif_mmt

WITH xif_mmt AS
(
SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
		(
         SELECT  wt.name AS wst_trip_name
         FROM    wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop 
         WHERE   mmt.picking_line_id              = wdd.delivery_detail_id
         AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
         AND     wda.delivery_id                  = wnd.delivery_id
         AND     wdl.delivery_id                  = wnd.delivery_id  
         AND     wt.trip_id                       = wds_pick.trip_id
         AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
         AND     wt.trip_id                       = wds_drop.trip_id
         AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
         AND     wt.status_code                   = 'CL'
		) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
	  , xif.user_name as user_name_firma
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
)
SELECT DISTINCT xif_mmt.wst_trip_name
              , xif_mmt.nombre_fletera
              , xif_mmt.nombre_transportista 
              , xif_mmt.no_placa 
              , xif_mmt.organization_id 
              , xif_mmt.fecha_firma
	          , xif_mmt.user_name_firma
FROM   xif_mmt
;



WITH xif_mmt AS
(
SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
		(
         SELECT  wt.name AS wst_trip_name
         FROM    wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop 
         WHERE   mmt.picking_line_id              = wdd.delivery_detail_id
         AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
         AND     wda.delivery_id                  = wnd.delivery_id
         AND     wdl.delivery_id                  = wnd.delivery_id  
         AND     wt.trip_id                       = wds_pick.trip_id
         AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
         AND     wt.trip_id                       = wds_drop.trip_id
         AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
         AND     wt.status_code                   = 'CL'
		) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
	  , xif.user_name as user_name_firma
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
)
SELECT  xif_mmt.wst_trip_name
              , xif_mmt.nombre_fletera
              , xif_mmt.nombre_transportista 
              , xif_mmt.no_placa 
              , xif_mmt.organization_id 
              , xif_mmt.fecha_firma
	          , xif_mmt.user_name_firma
FROM   xif_mmt
GROUP BY xif_mmt.wst_trip_name
              , xif_mmt.nombre_fletera
              , xif_mmt.nombre_transportista 
              , xif_mmt.no_placa 
              , xif_mmt.organization_id 
              , xif_mmt.fecha_firma
	          , xif_mmt.user_name_firma
;

WITH
SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
		(
         SELECT  wt.name AS wst_trip_name
         FROM    wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop 
         WHERE   mmt.picking_line_id              = wdd.delivery_detail_id
         AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
         AND     wda.delivery_id                  = wnd.delivery_id
         AND     wdl.delivery_id                  = wnd.delivery_id  
         AND     wt.trip_id                       = wds_pick.trip_id
         AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
         AND     wt.trip_id                       = wds_drop.trip_id
         AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
         AND     wt.status_code                   = 'CL'
		) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
	  , xif.user_name as user_name_firmad
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
;
	   
	   

SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
		(
         SELECT  wt.name AS wst_trip_name
         FROM    wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop 
         WHERE   mmt.picking_line_id              = wdd.delivery_detail_id
         AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
         AND     wda.delivery_id                  = wnd.delivery_id
         AND     wdl.delivery_id                  = wnd.delivery_id  
         AND     wt.trip_id                       = wds_pick.trip_id
         AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
         AND     wt.trip_id                       = wds_drop.trip_id
         AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
         AND     wt.status_code                   = 'CL'
		) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
	  , xif.user_name as user_name_firma
	  , mmt.transaction_id  AS mmt_transaction_id
	  , mmt.transaction_set_id AS mmt_transaction_set_id
      , mmt.picking_line_id AS mmt_picking_line_id
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2;



SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
		(
         SELECT  wt.name AS wst_trip_name
         FROM    wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop 
         WHERE   mmt.picking_line_id              = wdd.delivery_detail_id
         AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
         AND     wda.delivery_id                  = wnd.delivery_id
         AND     wdl.delivery_id                  = wnd.delivery_id  
         AND     wt.trip_id                       = wds_pick.trip_id
         AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
         AND     wt.trip_id                       = wds_drop.trip_id
         AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
         AND     wt.status_code                   = 'CL'
		) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2;



SELECT  /*+ INDEX(mmt MTL_MATERIAL_TRANSACTIONS_N12) */
		DISTINCT 
		(
         SELECT  wt.name AS wst_trip_name
         FROM    wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop 
         WHERE   mmt.picking_line_id              = wdd.delivery_detail_id
         AND     wda.delivery_detail_id(+)        = wdd.delivery_detail_id
         AND     wda.delivery_id                  = wnd.delivery_id
         AND     wdl.delivery_id                  = wnd.delivery_id  
         AND     wt.trip_id                       = wds_pick.trip_id
         AND     wds_pick.stop_id(+)              = wdl.pick_up_stop_id
         AND     wt.trip_id                       = wds_drop.trip_id
         AND     wds_drop.stop_id(+)              = wdl.drop_off_stop_id 
         AND     wt.status_code                   = 'CL'
		) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2;







SELECT  mmt.picking_line_id
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
      , xif.user_name as user_name_firma
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id   = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2




WITH mmt_data
AS
(
SELECT  mmt.picking_line_id
      , mmt.organization_id 
      , mmt.transaction_set_id
FROM    mtl_material_transactions mmt
WHERE   mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
)
SELECT  mmt_data.picking_line_id
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt_data.organization_id 
      , xif.fecha_firma
      , xif.user_name as user_name_firma
FROM    xxfc_inv_firma_salidas xif
      , mmt_data
WHERE   xif.transaction_set_id         = mmt_data.transaction_set_id


























SELECT TO_NUMBER(ffv.description)
INTO ln_dias
FROM apps.fnd_flex_value_sets fvs
   , apps.fnd_flex_values_vl ffv
WHERE 1=1
AND   fvs.flex_value_set_id = ffv.flex_value_set_id
AND   fvs.flex_value_set_name = 'XXINV_DEP_ESCANEO_TBS'
AND   ffv.flex_value = 'DIAS_DEP'
AND   ffv.enabled_flag = 'Y'
AND  ( ffv.start_date_active    <= SYSDATE OR ffv.start_date_active IS NULL )
AND  ( ffv.end_date_active      >= SYSDATE OR ffv.end_date_active IS NULL );