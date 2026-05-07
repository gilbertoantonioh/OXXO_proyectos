WITH 
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
SELECT mtl.organization_id           AS mtl_organization_id 
     , mtl.organization_code         AS mtl_inv_organization_code
     , msi.inventory_item_id         AS msi_inventory_item_id
     , msi.segment1                  AS msi_item_number                              
     , msi.attribute1                AS msi_use_type                                 
     , msi.attribute2                AS msi_fa_code                                  
     , msi.attribute12               AS msi_sat_code                                                       
     , msi.attribute13               AS msi_cfdi_use                                      
     , fca.category_id               AS faa_asset_category_id
     , fca.description               AS fcb_asset_categ_descr                       
     , fca.segment1||'.'||fca.segment2||'.'||fca.segment3||'.'||fca.segment4 AS fcb_asset_categ_seg_concat                           
     , poh.po_header_id              AS rcv_po_header_id
     , poh.segment1                  AS poh_po_number    
     , poh.type_lookup_code          AS poh_type_lookup_code	 
     , pra.po_release_id             AS pra_po_release_id 
     , pra.release_num               AS pra_release_num                                    
     , pol.po_line_id                AS rcv_po_line_id
     , pol.line_num                  AS pol_po_line_num 
     , pol.attribute1                AS pol_oracle_ef                                 
     , pol.attribute2                AS pol_oracle_cr                                                            
FROM   apps.mtl_system_items_b           msi     
     , apps.mtl_parameters               mtl
     , fca
     , apps.po_lines_all                 pol
     , apps.po_line_locations_all        pll
     , apps.po_headers_all               poh
     , apps.po_releases_all              pra 
WHERE 1 = 1
AND   pll.ship_to_organization_id   = mtl.organization_id
AND   pll.ship_to_organization_id   = msi.organization_id   (+) 
AND   pol.item_id                   = msi.inventory_item_id (+)    
AND   msi.attribute2                = fca.alias_name        (+)     
AND   poh.po_header_id              = pol.po_header_id 
AND   pol.po_line_id                = pll.po_line_id  
AND   pll.po_release_id             = pra.po_release_id     (+)      
AND   poh.segment1 = '2414769' -- Standard
AND   poh.segment1 = '2400025' -- Blanket    
           
           