SET DEFINE OFF;
PROMPT CREATE TABLE xxfc.xxfa_sn_data_rcv_others
CREATE TABLE xxfc.xxfa_sn_data_rcv_others (
data_rcv_other_id              NUMBER DEFAULT XXFC.xxfa_sn_data_rcv_others_s.NEXTVAL NOT NULL,              --OK       PK
rcv_transaction_id             NUMBER         NOT NULL,                                                     --OK       ID_transaccion_ebs  
sn_transaction_id              NUMBER,                                                                      --OK       ID_transaccion_sn
rcv_source_code                VARCHAR2(40),                                                                --OK       Tipo Recepcion   
rcv_destination_type_code      VARCHAR2(25),                                                                --OK       Sugerido para Tracking
rcv_transaction_date           DATE           NOT NULL,                                                     --OK       Fecha de transacción
rcv_primary_unit_of_measure    VARCHAR2(25),                                                                --OK       Sugerido para Tracking
rcv_shipment_header_id         NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking   
rsh_receipt_num                VARCHAR2(30)   NOT NULL,                                                     --OK       Num de Orden de Entrada
rcv_shipment_line_id           NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking 
rsl_shipment_line_num          NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking 
rsl_item_id                    NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking 
msi_item_number                VARCHAR2(40)   NOT NULL,                                                     --OK       Clave de Artículo 
msi_use_type                   VARCHAR2(240),                                                               --OK       Tipo Uso 
msi_fa_code                    VARCHAR2(240),                                                               --OK       Clave Activo Fijo
rsl_item_description           VARCHAR2(240),                                                               --OK       Descripcion del articul
msi_sat_code                   VARCHAR2(240),                                                               --OK       Clave de Producto SAT
msi_asset_badgeable_flag       VARCHAR2(240),                                                               --OK       Plaqueable
msi_asset_seriable_flag        VARCHAR2(240),                                                               --OK       Seriable   
msi_cfdi_use                   VARCHAR2(240),                                                               --OK       Uso CFDI  
mic_item_category_id           NUMBER,                                                                      --OK       Sugerido para Tracking 
mic_item_categ_seg_concat      VARCHAR2(1000),                                                              --OK       Sugerido para Tracking 
mic_item_categ_fam             VARCHAR2(40),                                                                --OK       Sugerido para Tracking 
mic_item_categ_subfam          VARCHAR2(40),                                                                --OK       Sugerido para Tracking 
faa_asset_category_id          NUMBER,                                                                      --OK       Sugerido para Tracking    
fcb_asset_categ_descr          VARCHAR2(240),                                                               --OK       Nombre del Activo 
fcb_asset_categ_seg_concat     VARCHAR2(1000),                                                              --OK       Sugerido para Tracking    
fcb_asset_categ                VARCHAR2(30),                                                                --OK       Cuenta Contable
fcb_asset_subcateg             VARCHAR2(30),                                                                --OK       Subcuenta Contable
fcb_asset_categ_fam            VARCHAR2(30),                                                                --OK       Sugerido para Tracking   
fcb_asset_categ_fakey          VARCHAR2(30),                                                                --OK       Sugerido para Tracking 
rcv_quantity                   NUMBER,                                                                      --OK       Cantidad
rcv_po_unit_price              NUMBER,                                                                      --OK       Precio Unitario
rcv_currency_code              VARCHAR2(15),                                                                --OK       Moneda (rcv_currency_code)
rcv_currency_conversion_rate   NUMBER,                                                                      --OK       Tipo de cambio (rcv_currency_conversion_rate)
rcv_currency_conversion_date   DATE,                                                                        --OK       Sugerido para Tracking 
ap_org_company_name            VARCHAR2(100),                                                               --OK       Nombre RFC Receptor (ap_org_company_name)
ap_org_company_rfc             VARCHAR2(150),                                                               --OK       RFC Receptor   
pol_oracle_cia                 VARCHAR2(240),                                                               --OK       Compañía (mcr_compania) 
pol_oracle_ef                  VARCHAR2(240),                                                               --OK       Edo Financiero Destino
pol_oracle_cr_superior         VARCHAR2(240),                                                               --OK       Plaza Destino
pol_retek_distrito             NUMBER,                                                                      --OK       Sugerido para Tracking 
pol_oracle_cr                  VARCHAR2(240),                                                               --OK       CR Destino
rcv_po_header_id               NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking 
poh_po_number                  VARCHAR2(20)   NOT NULL,                                                     --OK       Orden de Compra   
poh_po_date                    DATE,                                                                        --OK       Sugerido para Tracking 
rcv_po_release_id              NUMBER,                                                                      --OK       Sugerido para Tracking 
pra_release_num                NUMBER,                                                                      --OK       Numero de Release -- No lo traemos en la HU. 
rcv_po_line_id                 NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking 
pol_po_line_num                NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking  
rcv_vendor_id                  NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking 
asu_vendor_number              VARCHAR2(150)  NOT NULL,                                                     --OK       Proveedor
asu_vendor_name                VARCHAR2(240),                                                               --OK       Nombre RFC Proveedor (asu_vendor_name)
rcv_vendor_site_id             NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking  
ass_vendor_site_code           VARCHAR2(15)   NOT NULL,                                                     --OK       Sugerido para Tracking 
rcv_inv_organization_id        NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking  
mtl_inv_organization_code      VARCHAR2(3)    NOT NULL,                                                     --OK       Sugerido para Tracking    
poh_org_id                     NUMBER         NOT NULL,                                                     --OK       Sugerido para Tracking    
hou_org_code                   VARCHAR2(150)  NOT NULL,                                                     --OK       Sugerido para Tracking 
rcv_invoice_num                VARCHAR2(240),                                                               --OK       Numero de Factura
creation_date                  DATE DEFAULT SYSDATE,
created_by                     NUMBER DEFAULT -1,
last_update_date               DATE DEFAULT SYSDATE,
last_updated_by                NUMBER DEFAULT -1,
last_update_login              NUMBER DEFAULT -1
)
TABLESPACE APPS_TS_TX_DATA
;



GRANT ALL ON xxfc.xxfa_sn_data_rcv_others TO apps WITH GRANT OPTION;
