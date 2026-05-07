WITH item_categ
AS
( 
SELECT mic.inventory_item_id
     , mic.organization_id
     , mic.category_id 
     , mcg.segment1
     , mcg.segment2     
FROM   apps.mtl_item_categories mic
     , apps.mtl_category_sets mcs
     , apps.mtl_categories mcg
WHERE  mic.category_set_id    = mcs.category_set_id
AND    mic.category_id        = mcg.category_id 
AND    mcs.category_set_name  IN ('Inventory', 'Inventario') 
) 
,
fca AS
(
SELECT  fsa.alias_name
      , fca.category_id
      , fca.description
      , fca.segment1
      , fca.segment2
      , fca.segment3
      , fca.segment4 
FROM    apps.fnd_shorthand_flex_aliases fsa
      , apps.fa_categories fca 
WHERE   fsa.id_flex_code = 'CAT#'
AND     fsa.concatenated_segments = fca.segment1 || '.' || fca.segment2 || '.' || fca.segment3 || '.' || fca.segment4 
AND     fca.enabled_flag = 'Y'  
)
SELECT rcv.transaction_id            AS rcv_transaction_id                           
     , NULL                          AS sn_transaction_id                            
	 , 'Directos'                    AS rcv_source_code                              --PENDIENTE 
	 , rcv.destination_type_code     AS rcv_destination_type_code
     , TO_CHAR(rcv.transaction_date, 'YYYY-MM-DD') AS rcv_transaction_date   
     , rcv.primary_unit_of_measure   AS rcv_primary_unit_of_measure
     , rcv.shipment_header_id        AS rcv_shipment_header_id
     , rsh.receipt_num               AS rsh_receipt_num  
     , rcv.shipment_line_id          AS rcv_shipment_line_id
     , rsl.line_num                  AS rsl_shipment_line_num
     , rsl.item_id                   AS rsl_item_id      
     , msi.segment1                  AS msi_item_number                              
     , msi.attribute1                AS msi_use_type                                 
	 , msi.attribute2                AS msi_fa_code                                  
     , rsl.item_description          AS rsl_item_description 	 
	 , msi.attribute12				 AS msi_sat_code                                 
     , msi.attribute16               AS msi_asset_badgeable_flag                          
     , msi.attribute17               AS msi_asset_seriable_flag                      
	 , 'G01'                         AS msi_cfdi_use                                 
	 , item_categ.category_id        AS mic_item_category_id
	 , item_categ.segment1||'.'||item_categ.segment2  AS mic_item_categ_seg_concat
     , item_categ.segment1           AS mic_item_categ_fam                                  
     , item_categ.segment2           AS mic_item_categ_subfam      
     , fca.category_id 	             AS faa_asset_category_id
     , fca.description               AS fcb_asset_categ_descr	                     
	 , fca.segment1||'.'||fca.segment2||'.'||fca.segment3||'.'||fca.segment4 AS fcb_asset_categ_seg_concat   
	 , fca.segment1                  AS fcb_asset_categ                              
	 , fca.segment2                  AS fcb_asset_subcateg                           
	 , fca.segment3                  AS fcb_asset_categ_fam                          
	 , fca.segment4                  AS fcb_asset_categ_fakey                        
     , rcv.quantity                  AS rcv_quantity                                                
     , rcv.po_unit_price             AS rcv_po_unit_price                            
     , rcv.currency_code             AS rcv_currency_code                            
     , rcv.currency_conversion_rate  AS rcv_currency_conversion_rate                 
	 , rcv.currency_conversion_date  AS rcv_currency_conversion_date
     , xco.descripcion               AS ap_org_company_name                                         
     , hau_ou.attribute20            AS ap_org_company_rfc                             
     , xmcr.oracle_cia               AS pol_oracle_cia                                
     , pol.attribute1                AS pol_oracle_ef                                 
	 , xmcr.oracle_cr_superior       AS pol_oracle_cr_superior                       
	 , xmcr.retek_cr                 AS pol_retek_distrito   
     , pol.attribute2                AS pol_oracle_cr   
     , rcv.po_header_id              AS rcv_po_header_id
     , poh.segment1                  AS poh_po_number                            
     , poh.creation_date             AS poh_po_date
	 , rcv.po_release_id             AS rcv_po_release_id 
     , pra.release_num               AS pra_release_num                              		
     , rcv.po_line_id                AS rcv_po_line_id
     , pol.line_num                  AS pol_line_num 
     , rcv.vendor_id                 AS rcv_vendor_id  
     , asu.segment1                  AS asu_vendor_number                             
     , asu.vendor_name               AS asu_vendor_name
     , rcv.vendor_site_id            AS rcv_vendor_site_id
     , ass.vendor_site_code          AS ass_vendor_site_code
     , rcv.organization_id           AS rcv_organization_id
     , mtl.organization_code         AS mtl_inv_organization_code
     , poh.org_id                    AS poh_org_id
     , hou.short_code                AS hou_org_co	 
     , CASE
          WHEN INSTR(rcv.attribute1,'-') > 0  -- Si ya trae guion 
          OR   NOT REGEXP_LIKE(rcv.attribute1, '^[A-Za-z]') -- Si no trae letras al inicio
          THEN -- Respetar el valor 
             rcv.attribute1
          ELSE
             REGEXP_REPLACE(rcv.attribute1, '([[:alpha:]]*?)([[:digit:]])', '\1-\2', 1, 1) -- Colocar un guion antes del primer numero
       END rcv_invoice_num                                                           --HU26
FROM   apps.rcv_transactions             rcv
     , apps.rcv_shipment_headers         rsh
     , apps.rcv_shipment_lines           rsl
     , apps.mtl_system_items_b           msi   
     , item_categ     
     , fca		 
     , apps.po_lines_all                 pol
     , apps.po_line_locations_all        pll
     , apps.po_headers_all               poh
     , apps.po_releases_all              pra
     , apps.ap_suppliers                 asu
     , apps.ap_supplier_sites_all        ass
     , apps.mtl_parameters               mtl
     , apps.hr_operating_units           hou   
     , apps.hr_all_organization_units    hau_ou     
     , apps.xxfc_companias               xco 
     , apps.xxfc_maestro_de_crs_v        xmcr	 
WHERE 1 = 1
AND   rcv.shipment_header_id      = rsh.shipment_header_id
AND   rcv.shipment_line_id        = rsl.shipment_line_id
AND   rsl.to_organization_id      = msi.organization_id   
AND   rsl.item_id                 = msi.inventory_item_id    
AND   msi.organization_id         = item_categ.organization_id   (+)   
AND   msi.inventory_item_id       = item_categ.inventory_item_id (+)   
AND   msi.attribute2              = fca.alias_name      
AND   rcv.po_header_id            = poh.po_header_id
AND   rcv.po_line_id              = pol.po_line_id
AND   rcv.po_line_location_id     = pll.line_location_id
AND   rcv.po_release_id           = pra.po_release_id (+)
AND   rcv.vendor_id               = asu.vendor_id 
AND   rcv.vendor_site_id          = ass.vendor_site_id 
AND   rcv.organization_id         = mtl.organization_id 
AND   hou.organization_id         = poh.org_id  
AND   hau_ou.organization_id      = hou.organization_id    
AND   xco.oracle_cia              = hau_ou.attribute1      
AND   pol.attribute1              = xmcr.oracle_ef
AND   pol.attribute2              = xmcr.oracle_cr
AND  rcv.transaction_type         = 'RECEIVE'
--AND   rsl.item_id                 IN (1427377, 2703, 6199, 4568385, 4629419) 
AND   rcv.transaction_id > 66023602 --in  (66034059, 66034056, 66034055, 66034051, 66033549, 66033547)
;


























SELECT rcv.transaction_id            AS rcv_transaction_id                           --HU26 
     , NULL                          AS sn_transaction_id                            --HU26 
	 , 'Directos'                    AS rcv_source_code                              --HU26
	 , rcv.destination_type_code     AS rcv_destination_type_code
     , rcv.transaction_date          AS rcv_transaction_date                         --HU26
     , rcv.primary_unit_of_measure   AS rcv_primary_unit_of_measure
     , rcv.shipment_header_id        AS rcv_shipment_header_id
     , rsh.receipt_num               AS rsh_receipt_num                              --HU26 
     , rcv.shipment_line_id          AS rcv_shipment_line_id
     , rsl.line_num                  AS rsl_shipment_line_num
     , rsl.item_id                   AS rsl_item_id
     , msi.segment1                  AS msi_item_number                              --HU26   
     , msi.attribute1                AS msi_use_type
	 , msi.attribute2                AS msi_fa_code                                  --HU26    
     , rsl.item_description          AS rsl_item_description                         --HU26
     , item_categ.category_id        AS mic_item_category_id               
     , item_categ.segment1           AS mic_item_categ_fam                           --HU26        
     , item_categ.segment2           AS mic_item_categ_subfam                        --HU26  
     , msi.attribute7                AS msi_kit_type                       
     , msi.attribute8                AS msi_kit_principal_flag             
     , msi.attribute4                AS msi_kit_parent                     
     , msi.attribute16               AS msi_asset_badgeable_flag                     --HU26             
     , msi.attribute17               AS msi_asset_seriable_flag                      --HU26      
     , CASE
          WHEN INSTR(rcv.attribute1,'-') > 0  -- Si ya trae guion 
          OR   NOT REGEXP_LIKE(rcv.attribute1, '^[A-Za-z]') -- Si no trae letras al inicio
          THEN -- Respetar el valor 
             rcv.attribute1
          ELSE
             REGEXP_REPLACE(rcv.attribute1, '([[:alpha:]]*?)([[:digit:]])', '\1-\2', 1, 1) -- Colocar un guion antes del primer numero
       END rcv_invoice_num                                                             --HU26     
     -- Fin CHG0132369.                    
     , xco.descripcion               AS ap_org_company_name                            --HU26               
     , hau_ou.attribute20            AS ap_org_company_rfc                             --HU26  
     , rcv.po_header_id              AS rcv_po_header_id
     , poh.segment1                  AS poh_po_number                                  --HU26
     , poh.creation_date             AS poh_po_date
     , rcv.po_release_id             AS rcv_po_release_id
     , pra.release_num               AS pra_release_num 
     , rcv.po_line_id                AS rcv_po_line_id
     , pol.line_num                  AS pol_line_num 
     , rcv.po_line_location_id       AS rcv_po_line_location_id
     , rcv.quantity                  AS rcv_quantity                                  --HU26                
     , rcv.po_unit_price             AS rcv_po_unit_price                             --HU26
     , rcv.currency_code             AS rcv_currency_code                             --HU26
     , rcv.currency_conversion_rate  AS rcv_currency_conversion_rate                  --HU26 
     , rcv.currency_conversion_date  AS rcv_currency_conversion_date 
     , rcv.vendor_id                 AS rcv_vendor_id 
     , asu.segment1                  AS asu_vendor_number                             --HU26    
     , asu.vendor_name               AS asu_vendor_name                               --HU26 
     , rcv.vendor_site_id            AS rcv_vendor_site_id
     , ass.vendor_site_code          AS ass_vendor_site_code
     , rcv.organization_id           AS rcv_organization_id
     , mtl.organization_code         AS mtl_inv_organization_code
     , poh.org_id                    AS poh_org_id
     , hou.short_code                AS hou_org_code
FROM   rcv_transactions             rcv
     , rcv_shipment_headers         rsh
     , rcv_shipment_lines           rsl
     , mtl_system_items_b           msi   
     , item_categ                    
     , po_lines_all                 pol
     , po_line_locations_all        pll
     , po_headers_all               poh
     , po_releases_all              pra
     , ap_suppliers                 asu
     , ap_supplier_sites_all        ass
     , mtl_parameters               mtl 
     , hr_operating_units           hou   
     , hr_all_organization_units    hau_ou     
     , xxfc_companias               xco  
WHERE 1 = 1
AND   rcv.shipment_header_id      = rsh.shipment_header_id
AND   rcv.shipment_line_id        = rsl.shipment_line_id
AND   rsl.to_organization_id      = msi.organization_id   
AND   rsl.item_id                 = msi.inventory_item_id    
AND   msi.organization_id         = item_categ.organization_id   (+)   
AND   msi.inventory_item_id       = item_categ.inventory_item_id (+)        
AND   rcv.po_header_id            = poh.po_header_id
AND   rcv.po_line_id              = pol.po_line_id
AND   rcv.po_line_location_id     = pll.line_location_id
AND   rcv.po_release_id           = pra.po_release_id (+)
AND   rcv.vendor_id               = asu.vendor_id
AND   rcv.vendor_site_id          = ass.vendor_site_id 
AND   rcv.organization_id         = mtl.organization_id 
AND   hou.organization_id         = poh.org_id  
AND   hau_ou.organization_id      = hou.organization_id    
AND   xco.oracle_cia              = hau_ou.attribute1        
AND   rcv.transaction_id          = p_rcv_transaction_id