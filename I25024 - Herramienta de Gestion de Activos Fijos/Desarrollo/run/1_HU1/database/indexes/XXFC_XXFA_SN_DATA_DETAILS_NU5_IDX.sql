SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_data_details_nu5

CREATE INDEX xxfc.xxfa_sn_data_details_nu5 ON xxfc.xxfa_sn_data_details
(
   ooh_order_number     ASC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;