SET DEFINE OFF;
PROMPT ALTER TABLE XXFA_SN_TRIPS DROP COLS prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name

ALTER TABLE xxfc.xxfa_sn_trips DROP COLUMN prl_oracle_cr_superior;

ALTER TABLE xxfc.xxfa_sn_trips DROP COLUMN prl_oracle_cr;

ALTER TABLE xxfc.xxfa_sn_trips DROP COLUMN prl_requistor_full_name;

ALTER TABLE xxfc.xxfa_sn_trips DROP COLUMN prh_solicitud_inversion;