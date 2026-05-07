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
SELECT rcv.transaction_id            AS rcv_transaction_id                           --HU26 
     , NULL                          AS sn_transaction_id                            --HU26 
	 , 'Directos'                    AS rcv_source_code                              --HU26
     , TO_CHAR(rcv.transaction_date, 'YYYY-MM-DD') AS rcv_transaction_date           --HU26 
     , rsh.receipt_num               AS rsh_receipt_num                              --HU26 
     , msi.segment1                  AS msi_item_number                              --HU26   
     , msi.attribute1                AS msi_use_type                                 --HU26
	 , msi.attribute2                AS msi_fa_code                                  --HU26    
     , rsl.item_description          AS rsl_item_description                         --HU26
	 , msi.attribute12				 AS msi_sat_code                                 --HU26
     , msi.attribute16               AS msi_asset_badgeable_flag                     --HU26             
     , msi.attribute17               AS msi_asset_seriable_flag                      --HU26      
	 , 'G01'                         AS msi_cfdi_use                                 --HU26   
     , item_categ.segment1           AS mic_item_categ_fam                           --HU26        
     , item_categ.segment2           AS mic_item_categ_subfam                        --HU26  
     , fca.description               AS fcb_asset_categ_descr	                     --HU26  
	 , fca.segment1                  AS fcb_asset_categ                              --HU26
	 , fca.segment2                  AS fcb_asset_subcateg                           --HU26
	 , fca.segment3                  AS fcb_asset_categ_fam                          --HU26
	 , fca.segment4                  AS fcb_asset_categ_fakey                        --HU26	 
     , rcv.quantity                  AS rcv_quantity                                 --HU26                
     , rcv.po_unit_price             AS rcv_po_unit_price                            --HU26
     , rcv.currency_code             AS rcv_currency_code                            --HU26
     , rcv.currency_conversion_rate  AS rcv_currency_conversion_rate                 --HU26 	 
     , xco.descripcion               AS ap_org_company_name                          --HU26               
     , hau_ou.attribute20            AS ap_org_company_rfc                           --HU26  
     , xmcr.oracle_cia               AS pol_oracle_cia                               --HU26  
     , pol.attribute1                AS pol_oracle_ef                                --HU26	 
	  , xmcr.oracle_cr_superior            AS pol_oracle_cr_superior                       --HU26  
     , pol.attribute2                AS pol_oracle_cr                                --HU26  
     , poh.segment1                  AS poh_po_number                                --HU26
     , pra.release_num               AS pra_release_num                              --HU26  			
     , asu.segment1                  AS asu_vendor_number                            --HU26    
     , asu.vendor_name               AS asu_vendor_name                              --HU26 
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
     , apps.hr_operating_units           hou   
     , apps.hr_all_organization_units    hau_ou     
     , apps.xxfc_companias               xco 
     , apps.xxfc_maestro_de_crs_v        xmcr
     , apps.xxfc_centros_responsabilidad xcrp	 
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
AND   hou.organization_id         = poh.org_id  
AND   hau_ou.organization_id      = hou.organization_id    
AND   xco.oracle_cia              = hau_ou.attribute1      
AND   pol.attribute1              = xmcr.oracle_ef
AND   pol.attribute2              = xmcr.oracle_cr
AND   xmcr.oracle_cr_superior     = xcrp.oracle_cr
AND  rcv.transaction_type         = 'RECEIVE'
--AND   rsl.item_id                 IN (1427377, 2703, 6199, 4568385, 4629419) 
AND   rcv.transaction_id > 66023602 --in  (66034059, 66034056, 66034055, 66034051, 66033549, 66033547)
;

AND   rcv.transaction_id          = p_rcv_transaction_id





         SELECT ximt.mmt_transaction_id 
              , ximt.mmt_creation_date
              , ximt.rl_attribute1_req_line_id 
              , ximt.msi_segment1_no_articulo
              , ximt.mmt_transaction_quantity 
              , ooh.header_id AS ooh_header_id 
              , ximt.rh_header_id AS ooh_order_number 
              , ximt.rl_line_id AS ool_line_id 
              , xmcr.oracle_cia
              , xmcr.oracle_ef
              , xmcr.oracle_cr_superior
              , xcrp.descripcion AS oracle_cr_sup_descr
              , xmcr.retek_cr 
              , xmcr.oracle_cr
              , xmcr.oracle_cr_desc   
         FROM  xxinv_pre_material_trx_temp ximt -- leer la tabla que tiene el split de los registros 
             , xxfc_maestro_de_crs_v  xmcr
             , xxfc_centros_responsabilidad xcrp
             , oe_order_headers_all ooh           
         WHERE 1=1
         AND   ximt.reql_attribute2_crsup = xmcr.oracle_cr_superior
         AND   ximt.reql_attribute3_cr    = xmcr.oracle_cr
         AND   xmcr.oracle_cr_superior    = xcrp.oracle_cr
         AND   ximt.rh_header_id          = ooh.order_number
         AND   ximt.rh_header_id          = pn_ooh_order_number
         AND   ximt.rl_line_id            = pn_ool_line_id     
      ;