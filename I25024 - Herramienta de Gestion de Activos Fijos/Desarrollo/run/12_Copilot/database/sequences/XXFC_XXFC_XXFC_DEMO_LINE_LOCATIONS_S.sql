SET DEFINE OFF;
PROMPT CREATE SEQUENCE xxfc.xxfc_xxfc_demo_line_locations_s

CREATE SEQUENCE xxfc.xxfc_xxfc_demo_line_locations_s
  START WITH 1
  INCREMENT BY 1
  NOCYCLE
  NOCACHE
  ORDER;

GRANT SELECT ON xxfc.xxfc_xxfc_demo_line_locations_s TO APPS;

PROMPT CREATE SYNONYM apps.xxfc_xxfc_demo_line_locations_s
CREATE OR REPLACE SYNONYM apps.xxfc_xxfc_demo_line_locations_s FOR xxfc.xxfc_xxfc_demo_line_locations_s;