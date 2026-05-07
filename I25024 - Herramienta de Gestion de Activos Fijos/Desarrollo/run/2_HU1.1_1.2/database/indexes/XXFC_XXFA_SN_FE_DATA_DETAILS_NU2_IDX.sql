SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_fe_data_details_nu2

CREATE INDEX xxfc.xxfa_sn_fe_data_details_nu2 ON xxfc.xxfa_sn_fe_data_details
(
   rcv_vendor_id     
 , rcv_invoice_num   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
