SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_trip_comp_nu1

CREATE INDEX xxfc.xxfa_sn_trip_comp_nu1 ON xxfc.xxfa_sn_trip_comp
(
   wst_trip_name     DESC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;