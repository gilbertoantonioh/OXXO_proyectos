SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfa_sn_trips ADD PRIMARY KEY xxfa_sn_trips_pk
ALTER TABLE xxfc.xxfa_sn_trips
ADD   CONSTRAINT xxfa_sn_trips_pk
      PRIMARY KEY (sn_trip_detail_id) USING INDEX TABLESPACE APPS_TS_TX_IDX;