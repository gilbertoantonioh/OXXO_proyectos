SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_trips_nu1

CREATE INDEX xxfc.xxfa_sn_trips_nu1 ON xxfc.xxfa_sn_trips
(
   wst_trip_name     DESC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
