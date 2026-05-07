SET DEFINE OFF;
PROMPT PACKAGE SPEC XXFA_SN_DATA_API_PKG
CREATE OR REPLACE PACKAGE BODY apps.xxfa_sn_data_api_pkg 
AS 

   /********************************************************************************************
   * Modulo : XXFA_SN_DATA_API_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 15/Ago/2025
   * Descripcion : API para realizar cargas de informacion para la tabla xxfc.xxfa_sn_data_details
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   * Gilberto Hernandez (Hexaware)  12/Sep/2025   CHG0113888      LLenar la tabla intermedia validacion fiscal xxfa_sn_fe_data_details para service now
   ********************************************************************************************/
   
   gv_errbuf      VARCHAR2(4000);  
   gv_retcode     VARCHAR2(1);  
   

   /********************************************************************************************
   Modulo : load_details_from_rcv_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Carga informacion a la tabla intermedia desde la recepcion de inventario
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos.
   ********************************************************************************************/
   PROCEDURE load_details_from_rcv_prc (  errbuf               OUT VARCHAR2
                                        , retcode              OUT VARCHAR2
                                        , p_rcv_transaction_id IN NUMBER
                                        )
   IS 
      ln_rcv_exists             NUMBER := NULL;
      lv_rcv_transaction_type   rcv_transactions.transaction_type%TYPE:= NULL; 
      ln_rcv_organization_id    NUMBER := NULL;
      lv_rcv_invoice_num        rcv_transactions.attribute1%TYPE;
      lv_msi_use_type           mtl_system_items_b.attribute1%TYPE:= NULL; 
      lv_msi_item_number        mtl_system_items_b.segment1%TYPE:= NULL; 
      
      handled_exception  EXCEPTION;
      -- Procedimiento para insertar en el buffer de error 
      PROCEDURE write_errbuf_prc (p_errbuf IN VARCHAR2)
      IS 
      BEGIN
         IF gv_errbuf IS NOT NULL 
         THEN 
            gv_errbuf  := SUBSTR(gv_errbuf ||' '||p_errbuf, 1, 4000);  
         ELSE 
            gv_errbuf  := SUBSTR(p_errbuf, 1, 4000);  
         END IF;      
      EXCEPTION 
         WHEN OTHERS THEN 
            gv_errbuf := 'Error OTHERS xxfa_sn_data_api_pkg.load_details_from_rcv_prc.write_errbuf_prc: '||SQLERRM;          
      END write_errbuf_prc; 
      
   BEGIN 
      -- Reiniciar variables
      gv_errbuf      := NULL;
      gv_retcode     := NULL;
   
      -- Validar si la transaccion de rcv ya fue insertada anteriormente en la tabla intermedia. 
      SELECT COUNT(1)
      INTO   ln_rcv_exists
      FROM   xxfa_sn_data_details xsd
      WHERE  xsd.rcv_transaction_id = p_rcv_transaction_id;
      
      IF ln_rcv_exists > 0
      THEN 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', ya existe en la tabla intermedia.');
         gv_retcode := '1';
         RAISE handled_exception; 
      END IF;
      
      -- Obtener informacion del transaccion de recepcion y del articulo para su validacion 
      BEGIN 
         SELECT rcv.transaction_type
              , rcv.organization_id
              , rcv.attribute1
              , msi.attribute1
              , msi.segment1 
         INTO   lv_rcv_transaction_type 
              , ln_rcv_organization_id
              , lv_rcv_invoice_num
              , lv_msi_use_type
              , lv_msi_item_number
         FROM   rcv_transactions             rcv
              , rcv_shipment_headers         rsh
              , rcv_shipment_lines           rsl
              , mtl_system_items_b           msi            
         WHERE 1 = 1
         AND   rcv.shipment_line_id        = rsl.shipment_line_id
         AND   rsl.to_organization_id      = msi.organization_id   
         AND   rsl.item_id                 = msi.inventory_item_id    
         AND   rcv.transaction_id          = p_rcv_transaction_id
         AND   rownum = 1; 
      EXCEPTION  
         WHEN OTHERS THEN    
            gv_retcode := '2';
            write_errbuf_prc('Error al buscar la transaccion de recepcion con ID '||p_rcv_transaction_id||', relacionada a una linea de recepcion y articulo de inventario: '||SQLERRM||'.');
            RAISE handled_exception;
      END; 
      
      
      -- Validaciones previas a la insercion en la tabla intermedia
      IF lv_rcv_invoice_num IS NULL 
      THEN 
         gv_retcode := '1'; 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', no tiene No. de Factura (Attribue1) asociada.');    
      END IF;     
      
      -- Valida el tipo de recepcion 
      FOR rec IN (SELECT 1
                  FROM   dual
                  WHERE  NOT EXISTS 
                         (
                         SELECT 1
                         FROM   xxfc_mapeos_varios xmv
                         WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
                         AND    xmv.entrada    LIKE 'RCV_TRX_TYPE%'
                         AND    xmv.salida1    = lv_rcv_transaction_type
                         ) 
                  )
      LOOP 
         gv_retcode := '1'; 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', no es de tipo permitido. Revisar mapeo XXFA_SN_INSERT_DATA_DETAILS-RCV_TRX_TYPE.'); 
      END LOOP;       
                  
      -- Valida el uso de articulo
      FOR rec IN (SELECT 1
                  FROM   dual
                  WHERE  NOT EXISTS 
                         (
                         SELECT 1
                         FROM   xxfc_mapeos_varios xmv
                         WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
                         AND    xmv.entrada    LIKE 'USE_ITEM%'
                         AND    xmv.salida1    = lv_msi_use_type
                         AND    xmv.estado     = 'A'
                         AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
                         AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
                         ) 
                  )
      LOOP 
         gv_retcode := '1'; 
         write_errbuf_prc('Transaccion de recepcion con ID '||p_rcv_transaction_id||', el articulo '||lv_msi_item_number||', no es de uso permitido. Revisar mapeo XXFA_SN_INSERT_DATA_DETAILS-USE_ITEM.'); 
      END LOOP; 

      -- Valida la organizacion de inventario
      FOR rec IN (SELECT 1
                  FROM   dual
                  WHERE  NOT EXISTS 
                         (
                         SELECT 1
                         FROM   fnd_flex_values_vl ffv
                              , fnd_flex_value_sets fvs
                         WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                         AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                         AND    ffv.enabled_flag = 'Y'
                         AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                         AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                         AND    ffv.flex_value = TO_CHAR(ln_rcv_organization_id)
                         ) 
                  )
      LOOP 
         gv_retcode := '1'; 
         write_errbuf_prc('Transaccion de recepcion con ID '||p_rcv_transaction_id||', el ID de organizacion '||ln_rcv_organization_id||', no es esta permitido. Revisar juego de valores XXPO_ORG_REP_VALORIZA_ENT.'); 
      END LOOP;       

      -- Validar si en este punto hay advertencias para detener la ejecucion. 
      IF gv_retcode = '1'
      THEN 
         RAISE handled_exception; 
      END IF; 
      
      -- Relizar la insercion a la tabla intermedia. 
      BEGIN  
         INSERT INTO xxfa_sn_data_details
         (
           rcv_transaction_id
         , rcv_destination_type_code
         , rcv_transaction_date
         , rcv_primary_unit_of_measure
         , rcv_shipment_header_id
         , rsh_receipt_num
         , rcv_shipment_line_id
         , rsl_shipment_line_num
         , rsl_item_id
         , msi_item_number 
         , msi_use_type
         , rsl_item_description
         , mic_item_category_id             
         , mic_item_categ_fam               
         , mic_item_categ_subfam            
         , msi_kit_type                     
         , msi_kit_principal_flag           
         , msi_kit_parent                   
         , msi_asset_badgeable_flag               
         , msi_asset_seriable_flag  
         , fa_item_sequence 
         , rcv_invoice_num 
         , ap_org_company_name
         , ap_org_company_rfc        
         , rcv_po_header_id
         , poh_po_number 
         , poh_po_date
         , rcv_po_release_id
         , pra_release_num 
         , rcv_po_line_id
         , pol_po_line_num 
         , rcv_po_line_location_id
         , rcv_quantity
         , rcv_po_unit_price
         , rcv_currency_code
         , rcv_currency_conversion_rate
         , rcv_currency_conversion_date
         , rcv_vendor_id
         , asu_vendor_number
         , asu_vendor_name
         , rcv_vendor_site_id
         , ass_vendor_site_code
         , rcv_inv_organization_id
         , mtl_inv_organization_code
         , poh_org_id
         , hou_org_code     
         , creation_date 
         , created_by 
         , last_update_date
         , last_updated_by 
         , last_update_login         
         )
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
              , main.mic_item_category_id             
              , main.mic_item_categ_fam               
              , main.mic_item_categ_subfam            
              , main.msi_kit_type                     
              , main.msi_kit_principal_flag           
              , main.msi_kit_parent                   
              , main.msi_asset_badgeable_flag               
              , main.msi_asset_seriable_flag          
              , ROW_NUMBER() OVER (PARTITION BY main.rcv_transaction_id ORDER BY main.rcv_transaction_id) as fa_item_sequence
              , main.rcv_invoice_num 
              , main.ap_org_company_name
              , main.ap_org_company_rfc 
              , main.rcv_po_header_id
              , main.poh_po_number 
              , main.poh_po_date
              , main.rcv_po_release_id
              , main.pra_release_num 
              , main.rcv_po_line_id
              , main.pol_line_num 
              , main.rcv_po_line_location_id
              , main.rcv_quantity
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
              , SYSDATE 
              , FND_PROFILE.value('USER_ID')
              , SYSDATE
              , FND_PROFILE.value('USER_ID')
              , FND_PROFILE.value('LOGIN_ID')
         FROM 
         (   
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
            AND    mcs.category_set_name  IN ('Inventory', 'Inventario') 
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
                 , item_categ.category_id        AS mic_item_category_id               
                 , item_categ.segment1           AS mic_item_categ_fam                 
                 , item_categ.segment2           AS mic_item_categ_subfam              
                 , msi.attribute7                AS msi_kit_type                       
                 , msi.attribute8                AS msi_kit_principal_flag             
                 , msi.attribute4                AS msi_kit_parent                     
                 , msi.attribute16               AS msi_asset_badgeable_flag                 
                 , msi.attribute17               AS msi_asset_seriable_flag            
                 , rcv.attribute1                AS rcv_invoice_num                    
                 , xco.descripcion               AS ap_org_company_name                
                 , hau_ou.attribute20            AS ap_org_company_rfc                 
                 , rcv.po_header_id              AS rcv_po_header_id
                 , poh.segment1                  AS poh_po_number 
                 , poh.creation_date             AS poh_po_date
                 , rcv.po_release_id             AS rcv_po_release_id
                 , pra.release_num               AS pra_release_num 
                 , rcv.po_line_id                AS rcv_po_line_id
                 , pol.line_num                  AS pol_line_num 
                 , rcv.po_line_location_id       AS rcv_po_line_location_id
                 , rcv.quantity                  AS rcv_quantity                       
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
            AND   rcv.transaction_id          = p_rcv_transaction_id
         ) main 
         CROSS JOIN LATERAL 
         (
         SELECT 1
         FROM dual
         CONNECT BY LEVEL <= main.quantity
         )
         ;    
      EXCEPTION  
         WHEN OTHERS THEN    
            gv_retcode := '2';
            write_errbuf_prc('Error al insertar en la tabla intermedia la transaccion de recepcion con ID '||p_rcv_transaction_id||': '||SQLERRM||'.');
            RAISE handled_exception;
      END; 
      
      retcode := '0';
      errbuf  := 'Se realizo el registro en la tabla intermedia la transaccion de recepcion con ID '||p_rcv_transaction_id||'.'; 
   EXCEPTION 
   
      WHEN handled_exception THEN 
         retcode := gv_retcode; 
         errbuf  := gv_errbuf;       
      WHEN OTHERS THEN 
         retcode := '2';
         
         write_errbuf_prc('Error OTHERS xxfa_sn_data_api_pkg.load_details_from_rcv_prc: '||SQLERRM);
         errbuf := gv_errbuf;        
   END load_details_from_rcv_prc;     
   
   
   /********************************************************************************************
   Modulo : load_fe_details_from_rcv_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Carga informacion a la tabla intermedia para la validacion fiscal en service now desde la recepcion de inventario
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
   PROCEDURE load_fe_details_from_rcv_prc (  errbuf               OUT VARCHAR2
                                        , retcode              OUT VARCHAR2
                                        , p_rcv_transaction_id IN NUMBER
                                        )
   IS 
      ln_rcv_exists             NUMBER := NULL;
      lv_rcv_transaction_type   rcv_transactions.transaction_type%TYPE:= NULL; 
      ln_rcv_organization_id    NUMBER := NULL;
      lv_rcv_invoice_num        rcv_transactions.attribute1%TYPE;
      lv_msi_use_type           mtl_system_items_b.attribute1%TYPE:= NULL; 
      lv_msi_item_number        mtl_system_items_b.segment1%TYPE:= NULL; 
      
      handled_exception  EXCEPTION;
      -- Procedimiento para insertar en el buffer de error 
      PROCEDURE write_errbuf_prc (p_errbuf IN VARCHAR2)
      IS 
      BEGIN
         IF gv_errbuf IS NOT NULL 
         THEN 
            gv_errbuf  := SUBSTR(gv_errbuf ||' '||p_errbuf, 1, 4000);  
         ELSE 
            gv_errbuf  := SUBSTR(p_errbuf, 1, 4000);  
         END IF;      
      EXCEPTION 
         WHEN OTHERS THEN 
            gv_errbuf := 'Error OTHERS xxfa_sn_data_api_pkg.load_details_from_rcv_prc.write_errbuf_prc: '||SQLERRM;          
      END write_errbuf_prc; 
      
   BEGIN 
      -- Reiniciar variables
      gv_errbuf      := NULL;
      gv_retcode     := NULL;
   
      -- Validar si la transaccion de rcv ya fue insertada anteriormente en la tabla intermedia. 
      SELECT COUNT(1)
      INTO   ln_rcv_exists
      FROM   xxfa_sn_fe_data_details xsd
      WHERE  xsd.rcv_transaction_id = p_rcv_transaction_id;
      
      IF ln_rcv_exists > 0
      THEN 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', ya existe en la tabla intermedia de validacion fiscal.');
         gv_retcode := '1';
         RAISE handled_exception; 
      END IF;
      
      -- Obtener informacion del transaccion de recepcion y del articulo para su validacion 
      BEGIN 
         SELECT rcv.transaction_type
              , rcv.organization_id
              , rcv.attribute1
         INTO   lv_rcv_transaction_type 
              , ln_rcv_organization_id
              , lv_rcv_invoice_num
         FROM   rcv_transactions    rcv            
         WHERE 1 = 1 
         AND   rcv.transaction_id          = p_rcv_transaction_id
         AND   rownum = 1; 
      EXCEPTION  
         WHEN OTHERS THEN    
            gv_retcode := '2';
            write_errbuf_prc('Error al buscar la transaccion de recepcion con ID '||p_rcv_transaction_id||', relacionada a una linea de recepcion y articulo de inventario: '||SQLERRM||'. (load_fe_details_from_rcv_prc)');
            RAISE handled_exception;
      END; 
      
      
      -- Validaciones previas a la insercion en la tabla intermedia
      IF lv_rcv_invoice_num IS NULL 
      THEN 
         gv_retcode := '1'; 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', no tiene No. de Factura (Attribue1) asociada. (load_fe_details_from_rcv_prc)');    
      END IF;     
      
      -- Valida el tipo de recepcion 
      FOR rec IN (SELECT 1
                  FROM   dual
                  WHERE  NOT EXISTS 
                         (
                         SELECT 1
                         FROM   xxfc_mapeos_varios xmv
                         WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_FE_DATA_DETAILS'
                         AND    xmv.entrada    LIKE 'RCV_TRX_TYPE%'
                         AND    xmv.salida1    = lv_rcv_transaction_type
                         ) 
                  )
      LOOP 
         gv_retcode := '1'; 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', no es de tipo permitido. Revisar mapeo XXFA_SN_INSERT_FE_DATA_DETAILS-RCV_TRX_TYPE.'); 
      END LOOP;       
                  
      -- Valida la organizacion de inventario
      FOR rec IN (SELECT 1
                  FROM   dual
                  WHERE  NOT EXISTS 
                         (
                         SELECT 1
                         FROM   fnd_flex_values_vl ffv
                              , fnd_flex_value_sets fvs
                         WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                         AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                         AND    ffv.enabled_flag = 'Y'
                         AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                         AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                         AND    ffv.flex_value = TO_CHAR(ln_rcv_organization_id)
                         ) 
                  )
      LOOP 
         gv_retcode := '1'; 
         write_errbuf_prc('Transaccion de recepcion con ID '||p_rcv_transaction_id||', el ID de organizacion '||ln_rcv_organization_id||', no es esta permitido. Revisar juego de valores XXPO_ORG_REP_VALORIZA_ENT. (load_fe_details_from_rcv_prc)'); 
      END LOOP;       

      -- Validar si en este punto hay advertencias para detener la ejecucion. 
      IF gv_retcode = '1'
      THEN 
         RAISE handled_exception; 
      END IF; 
      
      -- Relizar la insercion a la tabla intermedia. 
      BEGIN  
         INSERT INTO xxfa_sn_fe_data_details
         (
           rcv_invoice_num              
         , rcv_po_header_id             
         , poh_org_id                   
         , ap_org_company_rfc           
         , ap_org_company_name          
         , rcv_vendor_id                
         , asu_vendor_number            
         , asu_vendor_name              
         , rsl_item_id                  
         , msi_item_number              
         , rcv_shipment_header_id  
         , rsh_receipt_num		 
         , rcv_shipment_line_id         
         , rsl_item_description         
         , rcv_quantity                  
         , rcv_transaction_id           
         , rcv_po_unit_price            
         , rcv_currency_code            
         , rcv_currency_conversion_rate 
         , creation_date                
         , created_by                   
         , last_update_date             
         , last_updated_by              
         , last_update_login                   
         )  
         SELECT rcv.attribute1                AS rcv_invoice_num  
              , rcv.po_header_id              AS rcv_po_header_id
              , poh.org_id                    AS poh_org_id
              , hau_ou.attribute20            AS ap_org_company_rfc
              , xco.descripcion               AS ap_org_company_name
              , rcv.vendor_id                 AS rcv_vendor_id
              , asu.segment1                  AS asu_vendor_number            
              , asu.vendor_name               AS asu_vendor_name
              , rsl.item_id                   AS rsl_item_id
              , msi.segment1                  AS msi_item_number 
              , rcv.shipment_header_id        AS rcv_shipment_header_id 
			  , rsh.receipt_num               AS rsh_receipt_num
              , rcv.shipment_line_id          AS rcv_shipment_line_id
              , rsl.item_description          AS rsl_item_description 
              , rcv.quantity                  AS rcv_quantity 
              , rcv.transaction_id            AS rcv_transaction_id
              , rcv.po_unit_price             AS rcv_po_unit_price
              , rcv.currency_code             AS rcv_currency_code
              , rcv.currency_conversion_rate  AS rcv_currency_conversion_rate         
              , SYSDATE 
              , FND_PROFILE.value('USER_ID')
              , SYSDATE
              , FND_PROFILE.value('USER_ID')
              , FND_PROFILE.value('LOGIN_ID')             
         FROM   rcv_transactions             rcv
              , rcv_shipment_headers         rsh
              , rcv_shipment_lines           rsl
              , mtl_system_items_b           msi      
              , po_headers_all               poh              
              , ap_suppliers                 asu
              , mtl_parameters               mtl 
              , hr_operating_units           hou   
              , hr_all_organization_units    hau_ou     
              , xxfc_companias               xco  
         WHERE 1 = 1
         AND   rcv.shipment_header_id      = rsh.shipment_header_id
         AND   rcv.shipment_line_id        = rsl.shipment_line_id
         AND   rsl.to_organization_id      = msi.organization_id   
         AND   rsl.item_id                 = msi.inventory_item_id          
         AND   rcv.po_header_id            = poh.po_header_id
         AND   rcv.vendor_id               = asu.vendor_id
         AND   rcv.organization_id         = mtl.organization_id 
         AND   hou.organization_id         = poh.org_id  
         AND   hau_ou.organization_id      = hou.organization_id    
         AND   xco.oracle_cia              = hau_ou.attribute1        
         AND   rcv.transaction_id          = p_rcv_transaction_id
         ;     
		 
      EXCEPTION  
         WHEN OTHERS THEN    
            gv_retcode := '2';
            write_errbuf_prc('Error al insertar en la tabla intermedia de validacion fiscal, la transaccion de recepcion con ID '||p_rcv_transaction_id||': '||SQLERRM||'.');
            RAISE handled_exception;
      END; 
      
      retcode := '0';
      errbuf  := 'Se realizo el registro en la tabla intermedia de validacion fiscal, la transaccion de recepcion con ID '||p_rcv_transaction_id||'.'; 
   EXCEPTION 
   
      WHEN handled_exception THEN 
         retcode := gv_retcode; 
         errbuf  := gv_errbuf;       
      WHEN OTHERS THEN 
         retcode := '2';
         
         write_errbuf_prc('Error OTHERS xxfa_sn_data_api_pkg.load_fe_details_from_rcv_prc: '||SQLERRM);
         errbuf := gv_errbuf;        
   END load_fe_details_from_rcv_prc;     
   
            
END xxfa_sn_data_api_pkg;
/
SHOW ERRORS;