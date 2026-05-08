SET DEFINE OFF;
PROMPT GRANT PRIVILEGES ON xxfc.xxfc_demo_line_locations

GRANT SELECT, INSERT, UPDATE, DELETE ON xxfc.xxfc_demo_line_locations TO APPS;
GRANT SELECT, INSERT, UPDATE, DELETE ON xxfc.xxfc_demo_line_locations TO APPSRO;

PROMPT CREATE SYNONYM apps.xxfc_demo_line_locations
CREATE OR REPLACE SYNONYM apps.xxfc_demo_line_locations FOR xxfc.xxfc_demo_line_locations;