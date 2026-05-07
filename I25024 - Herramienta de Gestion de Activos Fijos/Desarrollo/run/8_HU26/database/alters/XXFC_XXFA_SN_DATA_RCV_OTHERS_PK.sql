SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfa_sn_data_rcv_others ADD PRIMARY KEY xxfa_sn_data_rcv_others_pk
ALTER TABLE xxfc.xxfa_sn_data_rcv_others
ADD   CONSTRAINT xxfa_sn_data_rcv_others_pk
      PRIMARY KEY (data_rcv_other_id) USING INDEX TABLESPACE APPS_TS_TX_IDX;