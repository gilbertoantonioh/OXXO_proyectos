SET DEFINE OFF;
PROMPT CREATE TABLE xxfc.xxfa_sn_trips
CREATE TABLE xxfc.xxfa_sn_trips (
sn_trip_detail_id          	   NUMBER DEFAULT XXFC.xxfa_sn_trip_details_s.NEXTVAL NOT NULL,
sn_trip_id               	   NUMBER         NOT NULL,
wst_trip_id                    NUMBER         NOT NULL,
wst_trip_name	               VARCHAR2(30), 
msi_item_number                VARCHAR2(40)   NOT NULL,
msi_item_description           VARCHAR2(240),
wdd_shipped_quantity           NUMBER, 
ooh_header_id                  NUMBER, 
ooh_order_number               NUMBER,
ool_line_id                    NUMBER,
ship_confirm_flag              VARCHAR2(1),
wnd_delivery_id                NUMBER, 
wnd_confirm_date               DATE, 
wt_status_code                 VARCHAR2(2),
wdd_delivery_detail_id         NUMBER, 
wdd_organization_id            NUMBER, 
wdd_released_status            VARCHAR2(1),
creation_date                  DATE DEFAULT SYSDATE,
created_by                     NUMBER DEFAULT -1,
last_update_date               DATE DEFAULT SYSDATE,
last_updated_by                NUMBER DEFAULT -1,
last_update_login              NUMBER DEFAULT -1
)
TABLESPACE APPS_TS_TX_DATA
;

GRANT ALL ON xxfc.xxfa_sn_trips TO apps WITH GRANT OPTION;
