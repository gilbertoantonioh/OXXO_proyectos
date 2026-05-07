SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_fe_data_details_nu1

CREATE INDEX xxfc.xxfa_sn_fe_data_details_nu1 ON xxfc.xxfa_sn_fe_data_details
(
   rsh_receipt_num     DESC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
