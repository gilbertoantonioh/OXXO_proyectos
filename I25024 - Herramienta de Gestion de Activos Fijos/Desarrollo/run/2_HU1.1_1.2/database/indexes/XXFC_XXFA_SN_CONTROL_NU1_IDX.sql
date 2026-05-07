SET DEFINE OFF;
PROMPT CREATE INDEX xxfa_sn_control_nu1

CREATE INDEX xxfc.xxfa_sn_control_nu1 ON xxfc.xxfa_sn_control
(
   data_source_id     ASC  
 , data_source_code      
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
