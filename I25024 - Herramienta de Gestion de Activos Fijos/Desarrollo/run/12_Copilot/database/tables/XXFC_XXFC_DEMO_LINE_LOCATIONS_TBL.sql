SET DEFINE OFF;
PROMPT CREATE TABLE xxfc.xxfc_demo_line_locations

CREATE TABLE xxfc.xxfc_demo_line_locations
(
  demo_location_id   NUMBER DEFAULT xxfc.xxfc_xxfc_demo_line_locations_s.NEXTVAL NOT NULL,
  demo_line_id       NUMBER NOT NULL,
  demo_id            NUMBER NOT NULL,
  location_code      VARCHAR2(20),
  created_by         VARCHAR2(30) DEFAULT USER,
  creation_date      DATE DEFAULT SYSDATE,
  last_updated_by    VARCHAR2(30) DEFAULT USER,
  last_update_date   DATE DEFAULT SYSDATE
) TABLESPACE APPS_TS_TX_DATA;

GRANT ALL ON xxfc.xxfc_demo_line_locations TO APPS WITH GRANT OPTION;
