SET DEFINE OFF;
PROMPT ALTER TABLE xxfc.xxfc_demo_line_locations ADD CONSTRAINT xxfc_demo_line_locations_pk

ALTER TABLE xxfc.xxfc_demo_line_locations
ADD CONSTRAINT xxfc_demo_line_locations_pk PRIMARY KEY (demo_location_id)
USING INDEX TABLESPACE APPS_TS_TX_IDX;