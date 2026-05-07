SET DEFINE OFF;
PROMPT ALTER TABLE XXFA_SN_TRIPS ADD COLS prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion

ALTER TABLE xxfc.xxfa_sn_trips 
ADD (prl_oracle_cr_superior VARCHAR2(240)
   , prl_oracle_cr VARCHAR2(240)
   , prl_requistor_full_name VARCHAR2(240)
   , prh_solicitud_inversion VARCHAR2(240)
); 