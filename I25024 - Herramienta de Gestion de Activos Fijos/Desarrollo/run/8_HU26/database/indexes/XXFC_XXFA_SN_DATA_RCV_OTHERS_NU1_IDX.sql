SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_data_rcv_others_nu1

CREATE INDEX xxfc.xxfa_sn_data_rcv_others_nu1 ON xxfc.xxfa_sn_data_rcv_others
(
   rcv_transaction_id     DESC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
