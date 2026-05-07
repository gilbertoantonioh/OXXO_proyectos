SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfa_sn_fe_data_details ADD PRIMARY KEY xxfa_sn_fe_data_details_pk
ALTER TABLE xxfc.xxfa_sn_fe_data_details
ADD   CONSTRAINT xxfa_sn_fe_data_details_pk
      PRIMARY KEY (fe_data_detail_id) USING INDEX TABLESPACE APPS_TS_TX_IDX;