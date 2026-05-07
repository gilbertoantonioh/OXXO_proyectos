SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_data_details_nu4

CREATE INDEX xxfc.xxfa_sn_data_details_nu4 ON xxfc.xxfa_sn_data_details
(
   faa_tag_number      
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
