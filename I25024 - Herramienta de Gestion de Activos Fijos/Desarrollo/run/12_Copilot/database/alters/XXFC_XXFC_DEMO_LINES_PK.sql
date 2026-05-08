SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfc_demo_lines ADD PRIMARY KEY xxfc_demo_lines_pk

ALTER TABLE xxfc.xxfc_demo_lines
ADD   CONSTRAINT xxfc_demo_lines_pk
      PRIMARY KEY (demo_line_id) USING INDEX TABLESPACE APPS_TS_TX_IDX;