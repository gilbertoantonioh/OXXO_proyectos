SELECT main.rcv_transaction_id
     , main.rcv_destination_type_code
     , main.rcv_transaction_date
     , main.rcv_primary_unit_of_measure
     , main.rcv_shipment_header_id
     , main.rsh_receipt_num
     , main.rcv_shipment_line_id
     , main.rsl_shipment_line_num
     , main.rsl_item_id
     , main.msi_item_number 
     , main.msi_use_type
     , main.rsl_item_description
     , main.rcv_invoice_num 
     , main.rcv_po_header_id
     , main.poh_po_number 
     , main.poh_po_date
     , main.rcv_po_release_id
     , main.pra_release_num 
     , main.rcv_po_line_id
     , main.pol_line_num 
     , main.rcv_po_line_location_id
     , main.rcv_po_unit_price
     , main.rcv_currency_code
     , main.rcv_currency_conversion_rate
     , main.rcv_currency_conversion_date
     , main.rcv_vendor_id
     , main.asu_vendor_number
     , main.asu_vendor_name
     , main.rcv_vendor_site_id
     , main.ass_vendor_site_code
     , main.rcv_organization_id
     , main.mtl_inv_organization_code
     , main.poh_org_id
     , main.hou_org_code
	 , main.quantity 
	 , ROW_NUMBER() OVER (PARTITION BY main.rcv_transaction_id ORDER BY main.rcv_transaction_id) as fa_item_sequence
FROM 
(	 
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
     , rcv.attribute1                AS rcv_invoice_num 
     , rcv.po_header_id              AS rcv_po_header_id
     , poh.segment1                  AS poh_po_number 
     , poh.creation_date             AS poh_po_date
     , rcv.po_release_id             AS rcv_po_release_id
     , pra.release_num               AS pra_release_num 
     , rcv.po_line_id                AS rcv_po_line_id
     , pol.line_num                  AS pol_line_num 
     , rcv.po_line_location_id       AS rcv_po_line_location_id
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
	 , rcv.quantity 
FROM   rcv_transactions             rcv
     , rcv_shipment_headers         rsh
     , rcv_shipment_lines           rsl
     , mtl_system_items_b           msi      
     , po_lines_all                 pol
     , po_line_locations_all        pll
     , po_headers_all               poh
     , po_releases_all              pra
     , ap_suppliers                 asu
     , ap_supplier_sites_all        ass
     , mtl_parameters               mtl 
     , hr_operating_units           hou       
WHERE 1 = 1
AND   rcv.shipment_header_id      = rsh.shipment_header_id
AND   rcv.shipment_line_id        = rsl.shipment_line_id
AND   rsl.to_organization_id      = msi.organization_id   
AND   rsl.item_id                 = msi.inventory_item_id    
AND   rcv.po_header_id            = poh.po_header_id
AND   rcv.po_line_id              = pol.po_line_id
AND   rcv.po_line_location_id     = pll.line_location_id
AND   rcv.po_release_id           = pra.po_release_id (+)
AND   rcv.vendor_id               = asu.vendor_id
AND   rcv.vendor_site_id          = ass.vendor_site_id 
AND   rcv.organization_id         = mtl.organization_id 
AND   hou.organization_id         = poh.org_id   
AND   rcv.transaction_type        = 'RECEIVE'
AND   msi.attribute1              = '04'
AND   rcv.transaction_id          IN ( 5321737, 5313315, 5357899)
) main 
CROSS JOIN LATERAl 
(
SELECT 1
FROM dual
CONNECT BY LEVEL <= main.quantity
)
ORDER BY main.rcv_transaction_id