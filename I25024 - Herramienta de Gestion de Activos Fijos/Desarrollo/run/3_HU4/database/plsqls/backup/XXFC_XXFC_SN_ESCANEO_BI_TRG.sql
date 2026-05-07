SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT TRIGGER xxfc_sn_escaneo_bi

CREATE OR REPLACE TRIGGER xxfc_sn_escaneo_bi
BEFORE INSERT ON xxfc_sn_escaneo
FOR EACH ROW
BEGIN
   IF INSTR(:NEW.purchase_order, '-') > 0
   THEN
   
     SELECT DECODE(currency_code,'MXN', pll.price_override,ROUND(pll.price_override*rate,4))
     INTO   :NEW.po_unit_price
     FROM   apps.po_headers_all        poh,
            apps.po_lines_all          pol,
            apps.po_releases_all       pr,
            apps.po_line_locations_all pll,
            apps.mtl_system_items_b msi
     WHERE   1 = 1
     AND    poh.type_lookup_code = 'BLANKET'
     AND    poh.po_header_id = pol.po_header_id
     AND    poh.org_id = pol.org_id
     AND    pr.po_header_id = poh.po_header_id 
     AND    pll.po_release_id = pr.po_release_id 
     AND    pol.po_line_id = pll.po_line_id 
     AND    pol.item_id = msi.inventory_item_id
     AND    pll.ship_to_organization_id = msi.organization_id
     AND    EXISTS (SELECT 1
                    FROM   apps.xxfc_mapeos_varios 
                    WHERE  tipo_mapeo = 'XXFA_EBS_CONF'
                    AND    entrada   = 'ORGANIZATION'
                    AND    salida1 = poh.org_id
                    AND    salida2 = msi.organization_id)
     AND    poh.segment1   = SUBSTR(:NEW.purchase_order, 1, INSTR(:NEW.purchase_order, '-') - 1) -- ANTES DEL GUION
     AND    pr.release_num = SUBSTR(:NEW.purchase_order, INSTR(:NEW.purchase_order, '-') + 1)--DESPUES DEL GUION
     AND    msi.segment1   = :NEW.item_number
     AND    ROWNUM =1;

   ELSE 
   
     SELECT DECODE(currency_code,'MXN', pll.price_override,ROUND(pll.price_override*rate,4))
     INTO   :NEW.po_unit_price
     FROM   apps.po_headers_all     poh,
            apps.po_lines_all       pol,
            apps.mtl_system_items_b msi,
            apps.po_line_locations_all pll
     WHERE  poh.po_header_id = pol.po_header_id
     AND    poh.org_id = pol.org_id
     AND    pol.item_id = msi.inventory_item_id
     AND    pol.po_line_id = pll.po_line_id 
     AND    poh.po_header_id = pll.po_header_id
     AND    pll.ship_to_organization_id = msi.organization_id
     AND    EXISTS (SELECT 1
                    FROM   apps.xxfc_mapeos_varios 
                    WHERE  tipo_mapeo = 'XXFA_EBS_CONF'
                    AND    entrada   = 'ORGANIZATION'
                    AND    salida1 = poh.org_id
                    AND    salida2 = msi.organization_id)
     AND    poh.segment1 = :NEW.purchase_order
     AND    msi.segment1 = :NEW.item_number
     AND    ROWNUM = 1;
     
   END IF;
   
EXCEPTION 
   WHEN OTHERS THEN
      NULL;
END;
/
SHOW ERRORS;
