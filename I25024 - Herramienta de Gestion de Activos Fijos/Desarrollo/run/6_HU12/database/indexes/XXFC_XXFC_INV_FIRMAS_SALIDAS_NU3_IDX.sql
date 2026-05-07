SET DEFINE OFF;
PROMPT CREATE INDEX xxfc_inv_firmas_salidas_nu3

CREATE INDEX xxfc.xxfc_inv_firmas_salidas_nu3 ON xxfc.xxfc_inv_firma_salidas
(
   fecha_firma     DESC   
   ) 
  TABLESPACE APPS_TS_TX_IDX ;
