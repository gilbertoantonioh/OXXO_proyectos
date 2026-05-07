SET DEFINE OFF;
PROMPT CREATE TABLE xxfc.xxfa_sn_fe_data_details
CREATE TABLE xxfc.xxfa_sn_fe_data_details (
fe_data_detail_id               NUMBER DEFAULT XXFC.xxfa_sn_fe_data_details_s.NEXTVAL NOT NULL, 
rcv_invoice_num                 VARCHAR2(240),    
rcv_po_header_id                NUMBER            NOT NULL,   
poh_org_id                      NUMBER            NOT NULL,              
ap_org_company_rfc              VARCHAR2(150),       
ap_org_company_name             VARCHAR2(100),      
rcv_vendor_id                   NUMBER            NOT NULL,              
asu_vendor_number               VARCHAR2(30),        
asu_vendor_name                 VARCHAR2(240),       
rsl_item_id                     NUMBER            NOT NULL,              
msi_item_number                 VARCHAR2(40),   
rcv_shipment_header_id          NUMBER,
rsh_receipt_num                 VARCHAR2(30)      NOT NULL, 
rcv_shipment_line_id            NUMBER            NOT NULL,        
rsl_item_description            VARCHAR2(240),       
rcv_quantity                    NUMBER,    
rcv_transaction_id              NUMBER            NOT NULL,          
rcv_po_unit_price               NUMBER,              
rcv_currency_code               VARCHAR2(15),        
rcv_currency_conversion_rate    NUMBER,              
creation_date                   DATE DEFAULT SYSDATE,
created_by                      NUMBER DEFAULT -1,
last_update_date                DATE DEFAULT SYSDATE,
last_updated_by                 NUMBER DEFAULT -1,
last_update_login               NUMBER DEFAULT -1
)
TABLESPACE APPS_TS_TX_DATA
;

GRANT ALL ON xxfc.xxfa_sn_fe_data_details TO apps WITH GRANT OPTION;
