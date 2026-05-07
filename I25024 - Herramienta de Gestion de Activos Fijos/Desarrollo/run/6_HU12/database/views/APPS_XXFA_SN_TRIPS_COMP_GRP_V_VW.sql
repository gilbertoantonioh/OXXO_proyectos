SET DEFINE OFF
PROMPT VIEW APPS.XXFA_SN_TRIPS_COMP_GRP_V
CREATE OR REPLACE FORCE VIEW apps.xxfa_sn_trips_comp_grp_v 
(
  wst_trip_name 
, nombre_fletera
, nombre_transportista 
, no_placa 
, organization_id 
)
AS 
SELECT xstc.wst_trip_name 
     , xstc.nombre_fletera 
     , xstc.nombre_transportista 
     , xstc.no_placa 
     , xstc.organization_id 
FROM   xxfa_sn_trips_comp_v xstc
GROUP BY xstc.wst_trip_name 
       , xstc.nombre_fletera 
       , xstc.nombre_transportista 
       , xstc.no_placa 
       , xstc.organization_id 
;	   
SHOW ERRORS;