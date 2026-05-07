       WITH item_categ 
		 AS
		 ( 
		 SELECT mic.inventory_item_id
              , mic.organization_id
              , mic.category_id 
              , mcg.segment1
              , mcg.segment2     
         FROM   mtl_item_categories mic
              , mtl_category_sets mcs
              , mtl_categories mcg
         WHERE  mic.category_set_id    = mcs.category_set_id
         AND    mic.category_id        = mcg.category_id 
         AND    mcs.category_set_name  = 'Inventory'
		 ) 
		 SELECT rcv.transaction_id            AS rcv_transaction_id
              , rcv.destination_type_code     AS rcv_destination_type_code
              , rcv.transaction_date          AS rcv_transaction_date
              , rcv.primary_unit_of_measure   AS rcv_primary_unit_of_measure
              , rcv.shipment_header_id        AS rcv_shipment_header_id
              , rsh.receipt_num               AS rsh_receipt_num
              , rcv.shipment_line_id          AS rcv_shipment_line_id
              , rsl.line_num                  AS rsl_shipment_line_num
              , rsl.item_id                   AS rsl_item_id
              , msi.segment1                  AS msi_item_number 
              , msi.attribute1                AS msi_use_type
              , rsl.item_description          AS rsl_item_description
			  , item_categ.category_id        AS mic_item_category_id                --
              , item_categ.segment1           AS mic_item_categ_fam                  --
              , item_categ.segment2           AS mic_item_categ_subfam               --
              , msi.attribute7                AS msi_kit_type                        --
              , msi.attribute8                AS msi_kit_principal_flag              --
              , msi.attribute4                AS msi_kit_parent                      --
              , NULL                          AS msi_asset_badgable                  --
              , NULL                          AS msi_asset_seriable_flag             --
              , rcv.attribute1                AS rcv_invoice_num                     
              , xco.descripcion               AS ap_org_company_name                 -- 
              , hau_ou.attribute20            AS ap_org_company_rfc                  -- 
              , rcv.po_header_id              AS rcv_po_header_id
              , poh.segment1                  AS poh_po_number 
              , poh.creation_date             AS poh_po_date
              , rcv.po_release_id             AS rcv_po_release_id
              , pra.release_num               AS pra_release_num 
              , rcv.po_line_id                AS rcv_po_line_id
              , pol.line_num                  AS pol_line_num 
              , rcv.po_line_location_id       AS rcv_po_line_location_id
              , rcv.quantity                  AS rcv_quantity                        --
              , rcv.po_unit_price             AS rcv_po_unit_price
              , rcv.currency_code             AS rcv_currency_code
              , rcv.currency_conversion_rate  AS rcv_currency_conversion_rate
              , rcv.currency_conversion_date  AS rcv_currency_conversion_date
              , rcv.vendor_id                 AS rcv_vendor_id
              , asu.segment1                  AS asu_vendor_number
              , asu.vendor_name               AS asu_vendor_name
              , rcv.vendor_site_id            AS rcv_vendor_site_id
              , ass.vendor_site_code          AS ass_vendor_site_code
              , rcv.organization_id           AS rcv_organization_id
              , mtl.organization_code         AS mtl_inv_organization_code
              , poh.org_id                    AS poh_org_id
              , hou.short_code                AS hou_org_code
              , rcv.quantity                  AS quantity 
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
         AND   rcv.transaction_id          = 53475185
		 