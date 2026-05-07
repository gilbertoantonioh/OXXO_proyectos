SET DEFINE OFF;
PROMPT CREATE TABLE xxfc.xxfa_sn_trip_comp
CREATE TABLE xxfc.xxfa_sn_trip_comp(
id_trip_comp                   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
wst_trip_name	               VARCHAR2(30)   NOT NULL, 
freight_name                   VARCHAR2(250)  NOT NULL,
carrier_name                   VARCHAR2(250)  NOT NULL,
plate_number                   VARCHAR2(50)   NOT NULL,
inv_org_unit                   NUMBER,
attribute1                     VARCHAR2(250),
attribute2                     VARCHAR2(250),
attribute3                     VARCHAR2(250),
attribute4                     VARCHAR2(250),
attribute5                     VARCHAR2(250),
creation_date                  DATE DEFAULT SYSDATE,
created_by                     NUMBER DEFAULT -1,
last_update_date               DATE DEFAULT SYSDATE,
last_updated_by                NUMBER DEFAULT -1,
last_update_login              NUMBER DEFAULT -1
)
TABLESPACE APPS_TS_TX_DATA
;

GRANT ALL ON xxfc.xxfa_sn_trip_comp TO apps WITH GRANT OPTION;