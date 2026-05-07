SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfa_sn_control ADD PRIMARY KEY xxfa_sn_control_pk
ALTER TABLE xxfc.xxfa_sn_control
ADD   CONSTRAINT xxfa_sn_control_pk
      PRIMARY KEY (data_control_id) USING INDEX TABLESPACE APPS_TS_TX_IDX;