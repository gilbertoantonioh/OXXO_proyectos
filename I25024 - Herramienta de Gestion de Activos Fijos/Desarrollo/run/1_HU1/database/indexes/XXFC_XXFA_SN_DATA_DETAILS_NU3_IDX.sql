SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_data_details_nu3

CREATE INDEX xxfc.xxfa_sn_data_details_nu3 ON xxfc.xxfa_sn_data_details
(
   faa_asset_number     ASC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
