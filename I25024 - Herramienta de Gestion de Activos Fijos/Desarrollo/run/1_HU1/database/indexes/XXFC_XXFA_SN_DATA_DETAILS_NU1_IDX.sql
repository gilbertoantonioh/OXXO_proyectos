SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_data_details_nu1

CREATE INDEX xxfc.xxfa_sn_data_details_nu1 ON xxfc.xxfa_sn_data_details
(
   rcv_transaction_id     ASC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
