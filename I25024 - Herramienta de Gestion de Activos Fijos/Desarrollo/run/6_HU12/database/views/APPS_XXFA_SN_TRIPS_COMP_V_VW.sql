SET DEFINE OFF
PROMPT VIEW APPS.XXFA_SN_TRIPS_COMP_V
CREATE OR REPLACE FORCE VIEW apps.xxfa_sn_trips_comp_v 
(
  firma_id
, wst_trip_name 
, nombre_fletera
, nombre_transportista 
, no_placa 
, organization_id 
, fecha_firma
, user_name_firma 
, xif_transaction_source_id
, xif_transaction_set_id
, mmt_transaction_id
)
AS 
SELECT data.firma_id 
     , data.wst_trip_name 
     , data.nombre_fletera 
     , data.nombre_transportista 
     , data.no_placa 
     , data.organization_id 
     , data.fecha_firma      
     , data.user_name_firma      
     , data.xif_transaction_source_id       
     , data.xif_transaction_set_id       
     , data.mmt_transaction_id 
FROM 
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
         AND     rownum = 1
        ) AS wst_trip_name
      , xif.nombre_fletera
      , xif.nombre_transportista 
      , xif.no_placa 
      , mmt.organization_id 
      , xif.fecha_firma
      , xif.user_name as user_name_firma
      , xif.firma_id
      , xif.transaction_source_id AS xif_transaction_source_id
      , xif.transaction_set_id AS xif_transaction_set_id
      , mmt.transaction_id AS mmt_transaction_id
FROM    xxfc_inv_firma_salidas xif
      , mtl_material_transactions mmt 
WHERE   mmt .transaction_set_id        = xif.transaction_set_id
AND     mmt.transaction_type_id        = 33
AND     mmt.transaction_action_id      = 1
AND     mmt.transaction_source_type_id = 2
AND     xif.fecha_firma               >= 
(
SELECT SYSDATE - TO_NUMBER(ffv.description)
FROM apps.fnd_flex_value_sets fvs
   , apps.fnd_flex_values_vl ffv
WHERE 1=1
AND   fvs.flex_value_set_id = ffv.flex_value_set_id
AND   fvs.flex_value_set_name = 'XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO'
AND   ffv.flex_value = 'DIAS_RESGUARDO'
AND   ffv.enabled_flag = 'Y'
AND  ( ffv.start_date_active    <= SYSDATE OR ffv.start_date_active IS NULL )
AND  ( ffv.end_date_active      >= SYSDATE OR ffv.end_date_active IS NULL )
)
) data
;

SHOW ERRORS;