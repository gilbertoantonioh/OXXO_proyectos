SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_data_details_nu2

CREATE INDEX xxfc.xxfa_sn_data_details_nu2 ON xxfc.xxfa_sn_data_details
(
   faa_asset_id     ASC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
