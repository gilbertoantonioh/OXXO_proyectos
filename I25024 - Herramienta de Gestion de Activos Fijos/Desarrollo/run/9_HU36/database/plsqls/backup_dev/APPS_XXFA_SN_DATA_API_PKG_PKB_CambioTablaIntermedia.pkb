SET DEFINE OFF;
PROMPT PACKAGE BODY XXFA_SN_DATA_API_PKG
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
   * Gilberto Hernandez (Hexaware)  11/Oct/2025   CHG0116809      Actualizar la tabla intermedia previo a la salida de pedido de movimiento
   * Gilberto Hernandez (Hexaware)  19/Nov/2025   CHG0132369      Incluir guion en el folio fiscal cuando aplique. 
   * Gilberto Hernandez (Hexaware)  6/Dic/2025    CHG0135592      Cargar informacion de viajes para compartir a service now 
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion en la insercion a XXFA_SN_TRIPS
   * Gilberto Hernandez (Hexaware)  10/Feb/2026   CHG0140503      LLenar la tabla intermedia xxfa_sn_data_rcv_others para otras recepciones (Directs) para service now.
   * Gilberto Hernandez (Hexaware)   4/Mar/2026   CHG0143308      Programar el registro de los viajes que se comparten con service now
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
   * Gilberto Hernandez (Hexaware)  10/Feb/2026   CHG0140503      Validar el perfil de origen de recepcion de activos fijos
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
         write_errbuf_prc('Transaccion de recepcion con ID '||p_rcv_transaction_id||', el ID de organizacion '||ln_rcv_organization_id||', no esta permitido. Revisar juego de valores XXPO_ORG_REP_VALORIZA_ENT.'); 
      END LOOP;       

      -- CHG0140503 Inicio. Validar el perfil de origen de recepcion de activos fijos
       --Validar perfil origen de recepcion de activos fijos 
      IF NOT (FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') IS NULL OR FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'ALMACEN')   
      THEN 
         gv_retcode := '1'; 
         write_errbuf_prc('El perfil XXFC_RCV_FA_ORIGENES no tiene valor de ALMACEN y no esta permitido registrar esta Transaccion de recepcion con ID. '||ln_rcv_organization_id);       
      END IF; 
      -- CHG0140503 Fin. Validar el perfil de origen de recepcion de activos fijos

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
                 -- Inicio CHG0132369. Incluir guion (-) en el folio fiscal cuando no lo traiga
                 --, rcv.attribute1                AS rcv_invoice_num    
                 , CASE
                      WHEN INSTR(rcv.attribute1,'-') > 0  -- Si ya trae guion 
                      OR   NOT REGEXP_LIKE(rcv.attribute1, '^[A-Za-z]') -- Si no trae letras al inicio
                      THEN -- Respetar el valor 
                         rcv.attribute1
                      ELSE
                         REGEXP_REPLACE(rcv.attribute1, '([[:alpha:]]*?)([[:digit:]])', '\1-\2', 1, 1) -- Colocar un guion antes del primer numero
                   END rcv_invoice_num      
                 -- Fin CHG0132369.                    
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
      errbuf  := 'Se realizo el registro ('||SQL%ROWCOUNT||') en la tabla intermedia la transaccion de recepcion con ID '||p_rcv_transaction_id||'.'; 
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
   * Gilberto Hernandez (Hexaware)  10/Feb/2026   CHG0140503      Validar el perfil de origen de recepcion de activos fijos
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
      
      -- Obtener informacion del transaccion de recepcion
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
            write_errbuf_prc('Error al buscar la transaccion de recepcion con ID '||p_rcv_transaction_id||', relacionada a una linea de recepcion: '||SQLERRM||'. (load_fe_details_from_rcv_prc)');
            RAISE handled_exception;
      END; 
      
      -- CHG0140503 Inicio. Validar el perfil de origen de recepcion de activos fijos
       --Validar perfil origen de recepcion de activos fijos 
      IF NOT (FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') IS NULL OR FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'ALMACEN')   
      THEN 
         gv_retcode := '1'; 
         write_errbuf_prc('El perfil XXFC_RCV_FA_ORIGENES no tiene valor de ALMACEN y no esta permitido registrar esta Transaccion de recepcion con ID. '||ln_rcv_organization_id);       
      END IF; 
      -- CHG0140503 Fin. Validar el perfil de origen de recepcion de activos fijos
      
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
         write_errbuf_prc('Transaccion de recepcion con ID '||p_rcv_transaction_id||', el ID de organizacion '||ln_rcv_organization_id||', no esta permitido. Revisar juego de valores XXPO_ORG_REP_VALORIZA_ENT. (load_fe_details_from_rcv_prc)'); 
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
         SELECT -- Inicio CHG0132369. Incluir guion (-) en el folio fiscal cuando no lo traiga
                --, rcv.attribute1                AS rcv_invoice_num    
                CASE
                   WHEN INSTR(rcv.attribute1,'-') > 0  -- Si ya trae guion 
                   OR   NOT REGEXP_LIKE(rcv.attribute1, '^[A-Za-z]') -- Si no trae letras al inicio
                   THEN -- Respetar el valor 
                      rcv.attribute1
                   ELSE
                      REGEXP_REPLACE(rcv.attribute1, '([[:alpha:]]*?)([[:digit:]])', '\1-\2', 1, 1) -- Colocar un guion antes del primer numero
                END rcv_invoice_num         
                -- Fin CHG0132369.
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
      errbuf  := 'Se realizo el registro ('||SQL%ROWCOUNT||') en la tabla intermedia de validacion fiscal, la transaccion de recepcion con ID '||p_rcv_transaction_id||'.'; 
   EXCEPTION 
   
      WHEN handled_exception THEN 
         retcode := gv_retcode; 
         errbuf  := gv_errbuf;       
      WHEN OTHERS THEN 
         retcode := '2';
         
         write_errbuf_prc('Error OTHERS xxfa_sn_data_api_pkg.load_fe_details_from_rcv_prc: '||SQLERRM);
         errbuf := gv_errbuf;        
   END load_fe_details_from_rcv_prc;     
   
   
   /********************************************************************************************
   Modulo : load_det_others_from_rcv_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 10/Feb/2026
   Descripcion : Carga informacion a la tabla intermedia de otras recepciones desde la recepcion de inventario
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  10/Feb/2026   CHG0140503      Version Inicial  
   ********************************************************************************************/
   PROCEDURE load_det_others_from_rcv_prc (  errbuf               OUT VARCHAR2
                                           , retcode              OUT VARCHAR2
                                           , p_rcv_transaction_id IN NUMBER
                                           )
   IS 
      ln_rcv_exists             NUMBER := NULL;
      lv_rcv_transaction_type   rcv_transactions.transaction_type%TYPE:= NULL; 
      ln_rcv_organization_id    NUMBER := NULL;
      lv_rcv_invoice_num        rcv_transactions.attribute1%TYPE;
      lv_msi_fa_code            mtl_system_items_b.attribute2%TYPE:= NULL; 
      lv_msi_item_number        mtl_system_items_b.segment1%TYPE:= NULL; 
	  ln_category_id            NUMBER; 
      
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
            gv_errbuf := 'Error OTHERS xxfa_sn_data_api_pkg.load_det_others_from_rcv_prc.write_errbuf_prc: '||SQLERRM;          
      END write_errbuf_prc; 
      
   BEGIN 
      -- Reiniciar variables
      gv_errbuf      := NULL;
      gv_retcode     := NULL;
	  
      fnd_file.put_line(fnd_file.LOG, 'Ejecutando depuracion de otras recepciones.'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');   
      BEGIN
         purge_rcv_others_prc(retcode => gv_retcode
                            , errbuf  => gv_errbuf
                              );
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line(fnd_file.LOG, 'Error Ejecutando depuracion de otras recepciones: '||SQLERRM); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               
      END;  	  
   
      -- Validar si la transaccion de rcv ya fue insertada anteriormente en la tabla intermedia. 
      SELECT COUNT(1)
      INTO   ln_rcv_exists
      FROM   xxfa_sn_data_rcv_others xsd
      WHERE  xsd.rcv_transaction_id = p_rcv_transaction_id;
      
      IF ln_rcv_exists > 0
      THEN 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', ya existe en la tabla intermedia de otras recepciones.');
         gv_retcode := '1';
         RAISE handled_exception; 
      END IF;
      
      -- Obtener informacion del transaccion de recepcion y del articulo para su validacion 
      BEGIN 
         SELECT rcv.transaction_type
              , rcv.organization_id
              , rcv.attribute1
              , msi.attribute2
              , msi.segment1 
         INTO   lv_rcv_transaction_type 
              , ln_rcv_organization_id
              , lv_rcv_invoice_num
              , lv_msi_fa_code
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
            write_errbuf_prc('Error al buscar la transaccion de recepcion con ID '||p_rcv_transaction_id||', relacionada a una linea de recepcion y articulo de inventario: '||SQLERRM||'. (load_det_others_from_rcv_prc)');
            RAISE handled_exception;
      END;
      
      -- Validar que el codigo del activo fijo exista en la categoria 
      BEGIN 
         SELECT  fca.category_id
		 INTO    ln_category_id  	   
         FROM    apps.fnd_shorthand_flex_aliases fsa
               , apps.fa_categories fca 
         WHERE   fsa.id_flex_code = 'CAT#'
         AND     fsa.concatenated_segments = fca.segment1 || '.' || fca.segment2 || '.' || fca.segment3 || '.' || fca.segment4 
         AND     fca.enabled_flag = 'Y'     
         AND     fsa.alias_name   = lv_msi_fa_code
         ;
      EXCEPTION  
         WHEN OTHERS THEN    
            gv_retcode := '2';
            write_errbuf_prc('Error al buscar la categoria del activo fijo para el codigo '||lv_msi_fa_code||', relacionado al articulo '||lv_msi_item_number||': '||SQLERRM||'. (load_det_others_from_rcv_prc)');
            RAISE handled_exception;
      END;         
      
      -- Validaciones previas a la insercion en la tabla intermedia
      IF lv_rcv_invoice_num IS NULL 
      THEN 
         gv_retcode := '1'; 
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', no tiene No. de Factura (Attribue1) asociada. (load_det_others_from_rcv_prc)');    
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
         write_errbuf_prc('La transaccion de recepcion con ID '||p_rcv_transaction_id||', no es de tipo permitido (load_det_others_from_rcv_prc). Revisar mapeo XXFA_SN_INSERT_DATA_DETAILS-RCV_TRX_TYPE.'); 
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
         write_errbuf_prc('Transaccion de recepcion con ID '||p_rcv_transaction_id||', el ID de organizacion '||ln_rcv_organization_id||', no esta permitido. Revisar juego de valores XXPO_ORG_REP_VALORIZA_ENT. (load_det_others_from_rcv_prc)'); 
      END LOOP;      

       --Validar perfil origen de recepcion de activos fijos 
      IF NOT (FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'DIRECTOS')   
      THEN 
         gv_retcode := '1'; 
         write_errbuf_prc('El perfil XXFC_RCV_FA_ORIGENES no tiene valor de DIRECTOS y no esta permitido registrar esta Transaccion de recepcion con ID. '||p_rcv_transaction_id);    
      END IF;
      
      -- Validar si en este punto hay advertencias para detener la ejecucion. 
      IF gv_retcode = '1'
      THEN 
         RAISE handled_exception; 
      END IF; 
      
      -- Relizar la insercion a la tabla intermedia. 
      BEGIN  
         INSERT INTO xxfa_sn_data_rcv_others
         ( rcv_transaction_id          
         , sn_transaction_id           
         , rcv_source_code             
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
         , msi_fa_code                 
         , rsl_item_description        
         , msi_sat_code                
         , msi_asset_badgeable_flag    
         , msi_asset_seriable_flag     
         , msi_cfdi_use                
         , mic_item_category_id        
         , mic_item_categ_seg_concat   
         , mic_item_categ_fam          
         , mic_item_categ_subfam       
         , faa_asset_category_id       
         , fcb_asset_categ_descr       
         , fcb_asset_categ_seg_concat  
         , fcb_asset_categ             
         , fcb_asset_subcateg          
         , fcb_asset_categ_fam         
         , fcb_asset_categ_fakey       
         , rcv_quantity                
         , rcv_po_unit_price           
         , rcv_currency_code           
         , rcv_currency_conversion_rate
         , rcv_currency_conversion_date
         , ap_org_company_name         
         , ap_org_company_rfc          
         , pol_oracle_cia              
         , pol_oracle_ef               
         , pol_oracle_cr_superior      
         , pol_retek_distrito          
         , pol_oracle_cr               
         , rcv_po_header_id            
         , poh_po_number               
         , poh_po_date                 
         , rcv_po_release_id           
         , pra_release_num             
         , rcv_po_line_id              
         , pol_po_line_num             
         , rcv_vendor_id               
         , asu_vendor_number           
         , asu_vendor_name             
         , rcv_vendor_site_id          
         , ass_vendor_site_code        
         , rcv_inv_organization_id     
         , mtl_inv_organization_code   
         , poh_org_id                  
         , hou_org_code                
         , rcv_invoice_num             
         , creation_date               
         , created_by                  
         , last_update_date            
         , last_updated_by             
         , last_update_login          
         )         
         SELECT rcv_transaction_id 
              , NULL AS sn_transaction_id 
              , FND_PROFILE.value('XXFC_RCV_FA_ORIGENES')  AS rcv_source_code            
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
              , msi_fa_code                 
              , rsl_item_description        
              , msi_sat_code                
              , msi_asset_badgeable_flag    
              , msi_asset_seriable_flag     
              , msi_cfdi_use                
              , mic_item_category_id        
              , mic_item_categ_seg_concat   
              , mic_item_categ_fam          
              , mic_item_categ_subfam       
              , faa_asset_category_id       
              , fcb_asset_categ_descr       
              , fcb_asset_categ_seg_concat  
              , fcb_asset_categ             
              , fcb_asset_subcateg          
              , fcb_asset_categ_fam         
              , fcb_asset_categ_fakey       
              , rcv_quantity                
              , rcv_po_unit_price           
              , rcv_currency_code           
              , rcv_currency_conversion_rate
              , rcv_currency_conversion_date
              , ap_org_company_name         
              , ap_org_company_rfc          
              , pol_oracle_cia              
              , pol_oracle_ef               
              , pol_oracle_cr_superior      
              , pol_retek_distrito          
              , pol_oracle_cr               
              , rcv_po_header_id            
              , poh_po_number               
              , poh_po_date                 
              , rcv_po_release_id           
              , pra_release_num             
              , rcv_po_line_id              
              , pol_po_line_num             
              , rcv_vendor_id               
              , asu_vendor_number           
              , asu_vendor_name             
              , rcv_vendor_site_id          
              , ass_vendor_site_code        
              , rcv_inv_organization_id     
              , mtl_inv_organization_code   
              , poh_org_id                  
              , hou_org_code                
              , rcv_invoice_num     
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
		   AND     fca.category_id = ln_category_id
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
                , msi.attribute2                AS msi_fa_code                                  
                , rsl.item_description          AS rsl_item_description    
                , msi.attribute12               AS msi_sat_code                                 
                , msi.attribute16               AS msi_asset_badgeable_flag                          
                , msi.attribute17               AS msi_asset_seriable_flag                      
                , msi.attribute13               AS msi_cfdi_use                                 
                , item_categ.category_id        AS mic_item_category_id
                , item_categ.segment1||'.'||item_categ.segment2  AS mic_item_categ_seg_concat
                , item_categ.segment1           AS mic_item_categ_fam                                  
                , item_categ.segment2           AS mic_item_categ_subfam      
                , fca.category_id                  AS faa_asset_category_id
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
                , pol.line_num                  AS pol_po_line_num 
                , rcv.vendor_id                 AS rcv_vendor_id  
                , asu.segment1                  AS asu_vendor_number                             
                , asu.vendor_name               AS asu_vendor_name
                , rcv.vendor_site_id            AS rcv_vendor_site_id
                , ass.vendor_site_code          AS ass_vendor_site_code
                , rcv.organization_id           AS rcv_inv_organization_id
                , mtl.organization_code         AS mtl_inv_organization_code
                , poh.org_id                    AS poh_org_id
                , hou.short_code                AS hou_org_code  
                , CASE
                     WHEN INSTR(rcv.attribute1,'-') > 0  -- Si ya trae guion 
                     OR   NOT REGEXP_LIKE(rcv.attribute1, '^[A-Za-z]') -- Si no trae letras al inicio
                     THEN -- Respetar el valor 
                        rcv.attribute1
                     ELSE
                        REGEXP_REPLACE(rcv.attribute1, '([[:alpha:]]*?)([[:digit:]])', '\1-\2', 1, 1) -- Colocar un guion antes del primer numero
                  END rcv_invoice_num                                                               
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
           AND   rcv.transaction_id          = p_rcv_transaction_id
         )
         ;   
      EXCEPTION  
         WHEN OTHERS THEN    
            gv_retcode := '2';
            write_errbuf_prc('Error al insertar en la tabla intermedia de otras recepciones la transaccion de recepcion con ID '||p_rcv_transaction_id||': '||SQLERRM||'.');
            RAISE handled_exception;
      END; 
      
      retcode := '0';
      errbuf  := 'Se realizo el registro ('||SQL%ROWCOUNT||') en la tabla intermedia de otras recepciones la transaccion de recepcion con ID '||p_rcv_transaction_id||'.'; 
   EXCEPTION 
   
      WHEN handled_exception THEN 
         retcode := gv_retcode; 
         errbuf  := gv_errbuf;       
      WHEN OTHERS THEN 
         retcode := '2';
         
         write_errbuf_prc('Error OTHERS xxfa_sn_data_api_pkg.load_det_others_from_rcv_prc: '||SQLERRM);
         errbuf := gv_errbuf;        
   END load_det_others_from_rcv_prc;      
    
   /********************************************************************************************
   Modulo : load_data_from_rcv_cp_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 16/Feb/2026
   Descripcion : Ejecuta los procedimientos de carga de informacion a service name para las tablas intermedias desde el programa concurrente XXFA - SN Actualiza Informacion de Tablas Intermedias desde la Recepcion de Almacen
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  16/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
   PROCEDURE load_data_from_rcv_cp_prc ( errbuf               OUT VARCHAR2
                                       , retcode              OUT VARCHAR2
								       , pn_ShipmentId         IN NUMBER 
                                       )   
   IS

   BEGIN 
   
      fnd_file.put_line (fnd_file.LOG,'Incia Proceso de Insertar Registros en Tablas Intermedias de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      DECLARE 
         lv_errbuf        VARCHAR2(4000):= NULL;  
         lv_retcode       VARCHAR2(1):= NULL;
      BEGIN 
         FOR rec IN ( SELECT rcv.transaction_id AS rcv_transaction_id 
                      FROM   rcv_transactions             rcv
                           , rcv_shipment_lines           rsl
                           , rcv_shipment_headers         rsh 
                           , mtl_system_items_b           msi            
                      WHERE 1 = 1
                      AND   rcv.shipment_header_id      = rsh.shipment_header_id
                      AND   rcv.shipment_line_id        = rsl.shipment_line_id
                      AND   rsl.to_organization_id      = msi.organization_id   
                      AND   rsl.item_id                 = msi.inventory_item_id    
                      AND   rsh.shipment_header_id      = pn_ShipmentId
					  AND   rcv.attribute1              IS NOT NULL -- Valida que tenga no. de factura. 
					  -- Valida el tipo de transaccion 
                      AND   EXISTS 
                                      (
                                      SELECT 1
                                      FROM   xxfc_mapeos_varios xmv
                                      WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
                                      AND    xmv.entrada    LIKE 'RCV_TRX_TYPE%'
                                      AND    xmv.salida1    = rcv.transaction_type
                                      ) 
					  -- Valida la organizacion de inventario 				  
                      AND   EXISTS 
                                      (
                                      SELECT 1
                                      FROM   fnd_flex_values_vl ffv
                                           , fnd_flex_value_sets fvs
                                      WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                                      AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                                      AND    ffv.enabled_flag = 'Y'
                                      AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                                      AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                                      AND    ffv.flex_value = TO_CHAR(rcv.organization_id)
                                      ) 
                      -- Valida el uso del articulo 
					  AND   EXISTS 
                                  (
                                  SELECT 1
                                  FROM   xxfc_mapeos_varios xmv
                                  WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
                                  AND    xmv.entrada    LIKE 'USE_ITEM%'
                                  AND    xmv.salida1    = msi.attribute1 
                                  AND    xmv.estado     = 'A'
                                  AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
                                  AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
                                  )       
                      -- Validar el origen de recepcion desde el perfil XXFC_RCV_FA_ORIGENES
					  AND (FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') IS NULL OR FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'ALMACEN')
                     )
         LOOP 
            lv_errbuf     := NULL;  
            lv_retcode    := NULL;               		    
            -- Ejecuta carga informacion de recepcion de inventario en tabla intermedia 
            xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, rec.rcv_transaction_id );
			
			fnd_file.put_line (fnd_file.LOG,'RCV_TRANSACTION_ID: '||rec.rcv_transaction_id||' lv_retcode:'||lv_retcode||' lv_errbuf: '||lv_errbuf);
			
			COMMIT; 
			
         END LOOP;       
         fnd_file.put_line (fnd_file.LOG,'Finaliza Proceso de Insertar Registros en Tabla Intermedia de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line (fnd_file.LOG,'Error al Insertar Registros en Tabla Intermedia de Service Now: '||SQLERRM );
      END;          
	  
      fnd_file.put_line (fnd_file.LOG,'Incia Proceso de Insertar Registros en Tabla Intermedia de Validacion Fiscal de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      DECLARE 
         lv_errbuf        VARCHAR2(4000):= NULL;  
         lv_retcode       VARCHAR2(1):= NULL;
      BEGIN 
         FOR rec IN ( SELECT rcv.transaction_id AS rcv_transaction_id 
                      FROM   rcv_transactions             rcv
                           , rcv_shipment_lines           rsl
                           , rcv_shipment_headers         rsh 
                           , mtl_system_items_b           msi            
                      WHERE 1 = 1
                      AND   rcv.shipment_header_id      = rsh.shipment_header_id
                      AND   rcv.shipment_line_id        = rsl.shipment_line_id
                      AND   rsl.to_organization_id      = msi.organization_id   
                      AND   rsl.item_id                 = msi.inventory_item_id    
                      AND   rsh.shipment_header_id      = pn_ShipmentId
					  AND   rcv.attribute1              IS NOT NULL -- Valida que tenga no. de factura. 
					  -- Valida el tipo de transaccion 
                      AND   EXISTS 
                                      (
                                      SELECT 1
                                      FROM   xxfc_mapeos_varios xmv
                                      WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_FE_DATA_DETAILS'
                                      AND    xmv.entrada    LIKE 'RCV_TRX_TYPE%'
                                      AND    xmv.salida1    = rcv.transaction_type
                                      ) 
					  -- Valida la organizacion de inventario 				  
                      AND   EXISTS 
                                      (
                                      SELECT 1
                                      FROM   fnd_flex_values_vl ffv
                                           , fnd_flex_value_sets fvs
                                      WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                                      AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                                      AND    ffv.enabled_flag = 'Y'
                                      AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                                      AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                                      AND    ffv.flex_value = TO_CHAR(rcv.organization_id)
                                      )   
                      -- Validar el origen de recepcion desde el perfil XXFC_RCV_FA_ORIGENES
					  AND (FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') IS NULL OR FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'ALMACEN')									  
                     )
         LOOP 
            lv_errbuf     := NULL;  
            lv_retcode    := NULL;               		    
            -- Ejecuta carga informacion de recepcion de inventario en tabla intermedia de validacion fiscal
            xxfa_sn_data_api_pkg.load_fe_details_from_rcv_prc(lv_errbuf, lv_retcode, rec.rcv_transaction_id );
			
			fnd_file.put_line (fnd_file.LOG,'RCV_TRANSACTION_ID: '||rec.rcv_transaction_id||' lv_retcode:'||lv_retcode||' lv_errbuf: '||lv_errbuf);
			
			COMMIT; 
			
         END LOOP;       
         fnd_file.put_line (fnd_file.LOG,'Finaliza Proceso de Insertar Registros en Tabla Intermedia de Validacion Fiscal de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line (fnd_file.LOG,'Error al Insertar Registros en Tabla Intermedia de Validacion Fiscal de Service Now: '||SQLERRM );
      END;           
	     
      fnd_file.put_line (fnd_file.LOG,'Incia Proceso de Insertar Registros en Tabla Intermedia de Otras Recepciones (Directos) de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      DECLARE 
         lv_errbuf        VARCHAR2(4000):= NULL;  
         lv_retcode       VARCHAR2(1):= NULL;
		 lb_succcess      BOOLEAN := TRUE;		 
      BEGIN 
         FOR rec IN ( SELECT rcv.transaction_id AS rcv_transaction_id 
                      FROM   rcv_transactions             rcv
                           , rcv_shipment_lines           rsl
                           , rcv_shipment_headers         rsh 
                           , mtl_system_items_b           msi            
                      WHERE 1 = 1
                      AND   rcv.shipment_header_id      = rsh.shipment_header_id
                      AND   rcv.shipment_line_id        = rsl.shipment_line_id
                      AND   rsl.to_organization_id      = msi.organization_id   
                      AND   rsl.item_id                 = msi.inventory_item_id    
                      AND   rsh.shipment_header_id      = pn_ShipmentId
					  AND   rcv.attribute1              IS NOT NULL -- Valida que tenga no. de factura. 
					  -- Valida el tipo de transaccion 
                      AND   EXISTS 
                                      (
                                      SELECT 1
                                      FROM   xxfc_mapeos_varios xmv
                                      WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
                                      AND    xmv.entrada    LIKE 'RCV_TRX_TYPE%'
                                      AND    xmv.salida1    = rcv.transaction_type
                                      ) 
					  -- Valida la organizacion de inventario 				  
                      AND   EXISTS 
                                      (
                                      SELECT 1
                                      FROM   fnd_flex_values_vl ffv
                                           , fnd_flex_value_sets fvs
                                      WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                                      AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                                      AND    ffv.enabled_flag = 'Y'
                                      AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                                      AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                                      AND    ffv.flex_value = TO_CHAR(rcv.organization_id)
                                      )   
                      -- Validar el origen de recepcion desde el perfil XXFC_RCV_FA_ORIGENES
					  AND FND_PROFILE.value('XXFC_RCV_FA_ORIGENES') = 'DIRECTOS'									  
                     )
         LOOP
            lv_errbuf     := NULL;  
            lv_retcode    := NULL;               		    
            -- Ejecuta carga informacion de recepcion de inventario en tabla intermedia de validacion fiscal
            xxfa_sn_data_api_pkg.load_det_others_from_rcv_prc(lv_errbuf, lv_retcode, rec.rcv_transaction_id );
			
			fnd_file.put_line (fnd_file.LOG,'RCV_TRANSACTION_ID: '||rec.rcv_transaction_id||' lv_retcode:'||lv_retcode||' lv_errbuf: '||lv_errbuf);
			
			-- Guardar bandera si hubo alguna falla en el procesamiento de las transacciones de recepcion
			IF lv_retcode != '0'
			THEN 
			   lb_succcess := FALSE; 
			END IF; 
			
         END LOOP;      

         -- Si hay una sola falla en el procesamiento de las transacciones de recepcion, se debe hacer rollback.
         IF  lb_succcess
         THEN   	
            COMMIT;  	
            fnd_file.put_line (fnd_file.LOG,'Se confirman los registros insertados en la Tabla Intermedia de Otras Recepciones (Directos) de Service Now.'); 			
		 ELSE 
            ROLLBACK;	
            fnd_file.put_line (fnd_file.LOG,'Debido a errores durante el proceso, se revierte la insercion de los registros insertados en la Tabla Intermedia de Otras Recepciones (Directos) de Service Now.'); 			
         END IF; 	
		 
         fnd_file.put_line (fnd_file.LOG,'Finaliza Proceso de Insertar Registros en Tabla Intermedia de Otras Recepciones (Directos) de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line (fnd_file.LOG,'Error al Insertar Registros en Tabla Intermedia de Otras Recepciones (Directos) de Service Now: '||SQLERRM );
      END;          	  

      fnd_file.put_line (fnd_file.LOG,'Finaliza Proceso de Insertar Registros en Tablas Intermedias de Service Now. '||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS'));
      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL;    	  

   EXCEPTION
      WHEN OTHERS THEN 
         fnd_file.put_line(fnd_file.LOG, 'Error ejecutando proceso para insertar registros de recepciones para compartir a service now: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END load_data_from_rcv_cp_prc;        
   
   /********************************************************************************************
   Modulo : load_details_from_assets
   Autor : Samanta Solis (Hexaware)
   Fecha : 08/Oct/2025
   Descripcion : Carga informacion a la tabla intermedia desde el activo
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Samanta Solis (Hexaware)  08/Oct/2025      CHG0116809       Version Inicial
   ********************************************************************************************/
   PROCEDURE load_details_from_assets(  errbuf               OUT VARCHAR2
                                      , retcode              OUT VARCHAR2)
   IS                                  
 
      CURSOR cur_asset IS
         SELECT fa.asset_id AS faa_asset_id 
              , fcat.segment1 AS fcb_asset_categ_acct
              , fcat.segment2 AS fcb_asset_categ_subacct
              , fcat.segment3 AS fcb_asset_categ_fam
              , fcat.segment4 AS fcb_asset_categ_fakey
              , to_char(fb.date_placed_in_service,'MM') fbk_date_placed_mm
              , to_char(fb.date_placed_in_service,'RRRR') fbk_date_placed_yyyy
              , fa.property_type_code AS faa_property_type_code
              , fa.description AS faa_description
              , fa.manufacturer_name AS faa_manufacturer_name
              , fa.model_number AS faa_model_number
              , fa.serial_number AS faa_serial_number
              , to_number(fa.attribute14) AS data_detail_id
              , fa.asset_number AS faa_asset_number
              , fa.tag_number AS faa_tag_number
              , fa.asset_category_id AS faa_asset_category_id
              , fcat.segment1||fcat.segment4 AS fcb_asset_categ_seg_concat 
         FROM   fa_additions fa 
              , fa_categories_b fcat 
              , fa_books fb 
         WHERE fa.asset_category_id = fcat.category_id
         AND   fa.asset_id = fb.asset_id
         AND   fa.attribute14 IS NOT NULL
         AND   EXISTS ( SELECT 1 
                        FROM   xxfa_sn_data_details dt
                        WHERE  dt.data_detail_id = fa.attribute14
                        AND    dt.faa_asset_id IS NULL)
         AND   fb.book_type_code = fnd_profile.VALUE ('OXXO_FA_BOOK_AJUSTADO')
         AND   fb.date_ineffective IS NULL
         AND  (SELECT ffv.description
               FROM   fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
               WHERE  fvs.flex_value_set_name = 'XXFC_AF_CATALOGO_ASEGURABLE'
               AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
               AND    ffv.enabled_flag = 'Y'
               AND    ffv.flex_value = SUBSTR(fa.attribute_category_code,11,3)) IS NOT NULL;
   
      BEGIN
         retcode := '0';
         fnd_file.put_line(Fnd_File.LOG,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'Inicia XXFA_SN_DATA_API_PKG.load_details_from_assets');

         FOR c IN cur_asset LOOP

            XXFA_SN_DATA_DETAILS_PKG.update_row( p_data_detail_id          => c.data_detail_id
                                               , p_faa_asset_id            => c.faa_asset_id
                                               , p_fcb_asset_categ_acct    => c.fcb_asset_categ_acct
                                               , p_fcb_asset_categ_subacct => c.fcb_asset_categ_subacct
                                               , p_fcb_asset_categ_fam     => c.fcb_asset_categ_fam
                                               , p_fcb_asset_categ_fakey   => c.fcb_asset_categ_fakey
                                               , p_faa_manufacturer_name   => c.faa_manufacturer_name
                                               , p_faa_model_number        => c.faa_model_number
                                               , p_faa_serial_number       => c.faa_serial_number
                                               , p_faa_description         => c.faa_description
                                               , p_fbk_date_placed_mm      => c.fbk_date_placed_mm
                                               , p_fbk_date_placed_yyyy    => c.fbk_date_placed_yyyy
                                               , p_faa_property_type_code  => c.faa_property_type_code
                                               , p_faa_asset_number        => c.faa_asset_number
                                               , p_faa_tag_number          => c.faa_tag_number
                                               , p_faa_asset_category_id   => c.faa_asset_category_id
                                               , p_fcb_asset_categ_seg_concat => c.fcb_asset_categ_seg_concat
                                               , x_errors                  => errbuf
                                               , x_retcode                 => retcode
                                               );
            IF retcode = '0' 
            THEN
               COMMIT;
               errbuf:='Se actualizo el registro de xxfa_sn_data_details activo: '||c.faa_asset_id||' data_detail_id '||c.data_detail_id;
               fnd_file.put_line(Fnd_File.LOG,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||errbuf);

            ELSE 
               ROLLBACK; 
               errbuf:='Error al actualizar el registro de xxfa_sn_data_details activo: '||c.faa_asset_id||' data_detail_id '||c.data_detail_id||' Error: '||errbuf; 
               fnd_file.put_line(Fnd_File.LOG,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||errbuf);
            END IF;           
         END LOOP;  

         fnd_file.put_line(Fnd_File.LOG,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||'Termina XXFA_SN_DATA_API_PKG.load_details_from_assets');       
   EXCEPTION   
      WHEN OTHERS THEN
         retcode := '2'; 
         errbuf  := 'ERROR : '||SQLERRM;
         fnd_file.put_line(Fnd_File.LOG,TO_CHAR(SYSDATE,'DD-MM-RRRR HH24:MI:SS')||' > '||errbuf);
         ROLLBACK; 
   END load_details_from_assets;
   
   /********************************************************************************************
   Modulo : update_details_from_wsh_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 10/Oct/2025
   Descripcion : Actualizar informacion a la tabla intermedia desde previo a la salida del pedido de movimiento 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  10/Oct/2025   CHG0116809      Version Inicial
   ********************************************************************************************/
   PROCEDURE update_details_from_wsh_prc(  errbuf               OUT VARCHAR2
                                         , retcode              OUT VARCHAR2
                                         , p_delivery_name       IN VARCHAR2
                                         , p_organization_id     IN NUMBER 
                                         )
   IS
   
      lv_ooh_order_number       NUMBER;
      ln_ool_line_id            NUMBER;
   
      CURSOR lc_wsh_data( p_delivery_name IN VARCHAR2 
                        , p_organization_id     IN NUMBER
                         )
      IS 
         SELECT  ooh.order_number
               , wdd.source_line_id ool_line_id        
         FROM    oe_order_headers_all ooh
               , wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop   
               , mtl_system_items_b msi 
         WHERE  1 = 1
         AND    ooh.header_id               = wdd.source_header_id (+)
         AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
         AND    wda.delivery_id             = wnd.delivery_id(+)
         AND    wdl.delivery_id(+)          = wnd.delivery_id  
         AND    wt.trip_id(+)               = wds_pick.trip_id
         AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
         AND    wt.trip_id(+)               = wds_drop.trip_id
         AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
         AND    msi.inventory_item_id       = wdd.inventory_item_id 
         AND    msi.organization_id         = wdd.organization_id
         --Valia la organizacion de inventario                
         AND   EXISTS 
               (
               SELECT 1
               FROM   fnd_flex_values_vl ffv
                    , fnd_flex_value_sets fvs
               WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
               AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
               AND    ffv.enabled_flag = 'Y'
               AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
               AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
               AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
               ) 
         -- Valida el uso del articulo 
         AND EXISTS 
             (
             SELECT 1
             FROM   xxfc_mapeos_varios xmv
             WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
             AND    xmv.entrada    LIKE 'USE_ITEM%'
             AND    xmv.salida1    = msi.attribute1 
             AND    xmv.estado     = 'A'
             AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
             AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
             ) 
          AND    wt.name                     = p_delivery_name 
          --AND    wdd.organization_id         = p_organization_id     --HERNGI: No se require    
          ORDER BY 1, 2;      
           
      CURSOR lc_xxinv_mmt( pn_ooh_order_number IN NUMBER 
                         , pn_ool_line_id      IN NUMBER 
                          )                       
      IS 
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
         
      CURSOR lc_sn_data_details( pv_msi_item_number     IN  xxfa_sn_data_details.msi_item_number%TYPE
                               , pn_poh_po_number       IN  xxfa_sn_data_details.poh_po_number%TYPE
                               , pn_po_unit_price       IN  xxfa_sn_data_details.rcv_po_unit_price%TYPE    
                                )                          
      IS                           
         SELECT xdd.data_detail_id 
         FROM   xxfa_sn_data_details xdd
         WHERE  xdd.msi_item_number   = pv_msi_item_number
         AND    xdd.poh_po_number     = pn_poh_po_number
         -- Validar vs el precio en pesos tomando la tasa cambiaria de la po. (Como la hace el registro en la tabla de escaneos). 
         AND    EXISTS 
         ( SELECT 1
           FROM   po_headers_all poh
                , po_line_locations_all pll
           WHERE  poh.po_header_id     = pll.po_header_id 
           AND    pll.po_header_id     = xdd.rcv_po_header_id 
           AND    pll.line_location_id = xdd.rcv_po_line_location_id
           AND    DECODE(poh.currency_code, 'MXN', pll.price_override, ROUND(pll.price_override * poh.rate,4)) = pn_po_unit_price
         )
         AND    xdd.ooh_order_number IS NULL 
         ;       
      
      ln_prev_updated_count    NUMBER := 0; 
      
      ln_trip_id          wsh_trips.trip_id%TYPE := NULL;
      ln_sn_viaje         xxfc_sn_escaneo.sn_viaje%TYPE := NULL; 
      ln_purchase_order   xxfc_sn_escaneo.purchase_order%TYPE := NULL; 
      ln_po_unit_price    xxfc_sn_escaneo.po_unit_price%TYPE := NULL;
      
      le_no_exception     EXCEPTION;
      
      ln_xxsnrec_rownum   NUMBER := 0;
      
      lv_x_errors         VARCHAR2(4000)  := NULL; 
      ln_x_retcode        NUMBER  := NULL; 
   BEGIN
      fnd_file.put_line(fnd_file.LOG, ' +++++ Inicio Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas previo a la salida. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      gv_retcode := '0';
      gv_errbuf  := NULL;
      
      fnd_file.put_line(fnd_file.LOG, 'Obtener informacion de las lineas del pedido de movimiento a partir del numero de viaje: '||p_delivery_name);   
      FOR  wsh IN lc_wsh_data( p_delivery_name   => p_delivery_name
                            , p_organization_id  => p_organization_id
                             )
      LOOP 
         BEGIN 
            lv_ooh_order_number   := wsh.order_number;
            ln_ool_line_id        := wsh.ool_line_id;
            
            -- Validar que no existauna actualizacion previa en la tabla intermedia sobre el pedido y linea de movimiento, 
            BEGIN
               fnd_file.put_line(fnd_file.LOG, 'Validando si existe una previa actualizacion a la tabla intermedia para el pedido de movimiento: '||lv_ooh_order_number||' id de linea de pedido de movimiento: '||ln_ool_line_id);
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               
               SELECT COUNT(1)
               INTO    ln_prev_updated_count
               FROM    xxfa_sn_data_details xsdd
               WHERE   xsdd.ooh_order_number = lv_ooh_order_number
               AND     xsdd.ool_line_id      = ln_ool_line_id
               ;
            
               IF ln_prev_updated_count > 0
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Ya existe una previa actualizacion a la tabla intermedia para el pedido de movimiento.');     
                  gv_retcode := '1';  
                  RAISE le_no_exception; 
               END IF; 
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            EXCEPTION      
               WHEN le_no_exception THEN 
                  RAISE;    
               WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.LOG, 'Error validando si existe una previa actualizacion a la tabla intermedia, others: '||SQLERRM);
                  ROLLBACK;    
                  gv_retcode := '1';  
                  RAISE; 
            END;
            
            -- Ejecuatar procesos de XXINV_KITS_CUENTAS_DIARIO para actualizar referencias de la linea de movimiento en la tabla de escenaro de service now
            BEGIN 
               fnd_file.put_line(fnd_file.LOG, 'Actualizando referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento: '||lv_ooh_order_number||' id de linea de pedido de movimiento: '||ln_ool_line_id);
               
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               
               XXINV_KITS_CUENTAS_DIARIO.xxinv_mat_trx_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                          , pn_ool_line_id        => ln_ool_line_id
                                                          , pn_x_ret_code         => ln_x_retcode
                                                          , pv_x_errors           => lv_x_errors   
                                                             );
                                                             
               IF ln_x_retcode != 0
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error actualizando referencias en xxinv_material_trx_temp: '|| lv_x_errors);  
                  gv_retcode := '1'; 
                  RAISE le_no_exception;
               END IF;
 
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '); 
               COMMIT; 
               
               ln_x_retcode := NULL;  
               lv_x_errors := NULL;  
               
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
               XXINV_KITS_CUENTAS_DIARIO.pre_xxinv_mat_trx_temp_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                                   , pn_ool_line_id        => ln_ool_line_id
                                                                   , pv_retcode            => ln_x_retcode
                                                                   , pv_errors             => lv_x_errors   
                                                                     );   

               IF ln_x_retcode != 0
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error actualizando referencias en xxinv_pre_material_trx_temp: '|| lv_x_errors);  
                  gv_retcode := '1'; 
                  RAISE le_no_exception;
               END IF;
               
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');            
               COMMIT; 
               ln_x_retcode := NULL;  
               lv_x_errors := NULL;  
               
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
               XXINV_KITS_CUENTAS_DIARIO.procesa_info_articulo_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                                  , pn_ool_line_id        => ln_ool_line_id
                                                                  , pv_retcode            => ln_x_retcode
                                                                  , pv_errors             => lv_x_errors   
                                                                    );
                                           
               IF ln_x_retcode != 0
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error actualizando referencias en xxfc_sn_escaneo_lineas: '|| lv_x_errors);
                  gv_retcode := '1';          
                  RAISE le_no_exception;
               END IF;
                        
               COMMIT;  
               fnd_file.put_line(fnd_file.LOG, 'Se actualizaron las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas.');
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');                                                      
            EXCEPTION      
               WHEN le_no_exception THEN 
                  ROLLBACK;
                  RAISE;    
               WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.LOG, 'Error actualizando las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas, others. Error: '||SQLERRM); 
                  ROLLBACK;    
                  gv_retcode := '1';
                  RAISE; 
            END;
            
            fnd_file.put_line(fnd_file.LOG, 'Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento: '||lv_ooh_order_number||' id de linea de pedido de movimiento: '||ln_ool_line_id);     
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            -- Reiniciar contador de registros de tabla intermedia
            ln_xxsnrec_rownum := 0;
            
            FOR xxinv_rec IN  lc_xxinv_mmt( pn_ooh_order_number => lv_ooh_order_number
                                          , pn_ool_line_id      => ln_ool_line_id 
                                           ) 
            LOOP 
               --Buscar datos del escaneo a partir de la linea de pedido de movimiento, para saber si hay un viaje
               BEGIN 
                  SELECT  wst.trip_id
                        , xsn.sn_viaje
                        , xsn.purchase_order 
                        , xsn.po_unit_price  
                  INTO    ln_trip_id
                        , ln_sn_viaje
                        , ln_purchase_order  
                        , ln_po_unit_price              
                  FROM    xxfc_sn_escaneo xsn
                       ,  xxfc_sn_escaneo_lineas xsl 
                       ,  wsh_trips wst
                  WHERE   xsn.sn_escaneo_id          = xsl.sn_escaneo_id 
                  AND     xsn.sn_viaje               = wst.name       
                  AND     xsl.wsh_sts_header_id      = xxinv_rec.ooh_order_number
                  AND     xsl.wsh_sts_line_id        = xxinv_rec.ool_line_id
                  AND     rownum = 1
                  ;        
               EXCEPTION 
                  WHEN NO_DATA_FOUND THEN
                     fnd_file.put_line(fnd_file.LOG, 'No existe escaneo con viaje para el pedido de movimiento: '||xxinv_rec.ooh_order_number||' id de linea de pedido de movimiento: '||xxinv_rec.ool_line_id);
                     gv_retcode := '1';              
                     EXIT; 
                  WHEN OTHERS THEN 
                     fnd_file.put_line(fnd_file.LOG, 'Error al buscar el registro de escaneo con viaje para el pedido de movimiento: '||xxinv_rec.ooh_order_number||' id de linea de pedido de movimiento: '||xxinv_rec.ool_line_id||', others Error: '||SQLERRM);   
                     gv_retcode := '1';              
                     EXIT; 
               END;       
               
               -- Bloque para actualizar el registro de xxfa_sn_data_details 
               BEGIN 
                  -- Buscar registros de sn data details candidatos para actualizar, a partir de los datos de numero de articulo, numero de orden de compra y precio.  
                  fnd_file.put_line(fnd_file.LOG, 'Buscando registros para actualizar en la tabla intermedia, pedido de compra: '||ln_purchase_order||' articulo: '||xxinv_rec.msi_segment1_no_articulo||' precio: '||TO_CHAR(ln_po_unit_price)||' pedido movimiento: '||xxinv_rec.ooh_order_number||' id de linea de pedido de movimiento: '||xxinv_rec.ool_line_id);
                  FOR xxsnrec IN lc_sn_data_details( pv_msi_item_number    => xxinv_rec.msi_segment1_no_articulo
                                                   , pn_poh_po_number      => ln_purchase_order
                                                   , pn_po_unit_price      => ln_po_unit_price
                                                    )
                  LOOP
                     ln_xxsnrec_rownum := ln_xxsnrec_rownum + 1; 
                     
                     -- Actualizar registro. 
                     XXFA_SN_DATA_DETAILS_PKG.update_row( p_data_detail_id             => xxsnrec.data_detail_id
                                                        , p_prl_requisition_line_id    => xxinv_rec.rl_attribute1_req_line_id
                                                        , p_prl_oracle_cia             => xxinv_rec.oracle_cia
                                                        , p_prl_oracle_ef              => xxinv_rec.oracle_ef
                                                        , p_prl_retek_distrito         => xxinv_rec.retek_cr
                                                        , p_prl_oracle_cr              => xxinv_rec.oracle_cr
                                                        , p_prl_oracle_cr_descr        => xxinv_rec.oracle_cr_desc
                                                        , p_prl_oracle_cr_superior     => xxinv_rec.oracle_cr_superior
                                                        , p_prl_oracle_cr_sup_descr    => xxinv_rec.oracle_cr_sup_descr
                                                        , p_ooh_header_id              => xxinv_rec.ooh_header_id
                                                        , p_ooh_order_number           => xxinv_rec.ooh_order_number
                                                        , p_ool_line_id                => xxinv_rec.ool_line_id
                                                        , p_wst_trip_id                => ln_trip_id
                                                        , p_wst_trip_name              => ln_sn_viaje
                                                        , p_mmt_transaction_id         => xxinv_rec.mmt_transaction_id
                                                        , p_mmt_creation_date          => xxinv_rec.mmt_creation_date
                                                        , x_errors                     => lv_x_errors
                                                        , x_retcode                    => ln_x_retcode
                                                        );
                     IF ln_x_retcode = 0 
                     THEN 
                        fnd_file.put_line(fnd_file.LOG, 'Se actualizo el registro de xxfa_sn_data_details, pedido de compra: '||ln_purchase_order||' articulo: '||xxinv_rec.msi_segment1_no_articulo||' precio: '||TO_CHAR(ln_po_unit_price)||' id data detail: '||xxsnrec.data_detail_id||' pedido movimiento/viaje '||xxinv_rec.ooh_order_number||'/'||ln_sn_viaje);
                        EXIT; -- Desde que estamos leyendo la tabla split xxinv_pre_material_trx_temp, actualizamos un solo registro en la tabla xxfa_sn_data_details. 
                     ELSE 
                        fnd_file.put_line(fnd_file.LOG, 'Error al actualizar el registro de xxfa_sn_data_details, pedido de compra: '||ln_purchase_order||' articulo: '||xxinv_rec.msi_segment1_no_articulo||' precio: '||TO_CHAR(ln_po_unit_price)||' id data detail: '||xxsnrec.data_detail_id||' pedido movimiento/viaje '||xxinv_rec.ooh_order_number||'/'||ln_sn_viaje||' Error: '||lv_x_errors); 
                        ROLLBACK; 
                        gv_retcode := '1';
                        RAISE le_no_exception; 
                     END IF;         
                  END LOOP;       
               EXCEPTION
                  WHEN le_no_exception THEN 
                     ROLLBACK;
                     ln_xxsnrec_rownum := 0; -- Reseteamos contador 
                     EXIT; 
                  WHEN OTHERS THEN
                     fnd_file.put_line(fnd_file.LOG, 'Error actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas para el pedido de movimiento, others: '||SQLERRM);      
                     ROLLBACK;
                     ln_xxsnrec_rownum := 0; -- Reseteamos contador 
                     gv_retcode := '1';
                     EXIT; 
               END;    
            END LOOP; 
            
            IF ln_xxsnrec_rownum > 0 
            THEN
               -- Si modifico los registros que encontro en xxfa_sn_data_details, dar commit. 
               COMMIT;
               fnd_file.put_line(fnd_file.LOG, 'Se actualizaron '||ln_xxsnrec_rownum||' registro(s) en la tabla xxfa_sn_data_details.');
            ELSE 
               fnd_file.put_line(fnd_file.LOG, 'No se actualizaron registros para actualizar en la tabla xxfa_sn_data_details.');
                gv_retcode := '1'; 
            END IF;     
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            
            -- Ejecuatar procesos de XXINV_KITS_CUENTAS_DIARIO para eliminar registros temporales
            BEGIN 
               fnd_file.put_line(fnd_file.LOG, 'Eliminando registros temporales en xxinv_pre_material_trx_temp para el pedido de movimiento: '||lv_ooh_order_number||' id de linea de pedido de movimiento: '||ln_ool_line_id);  
            
               ln_x_retcode := NULL;  
               lv_x_errors := NULL;  
               
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
               XXINV_KITS_CUENTAS_DIARIO.reagrupa_info_prc( pn_ooh_order_number   => lv_ooh_order_number
                                                          , pn_ool_line_id        => ln_ool_line_id
                                                          , pv_retcode            => ln_x_retcode
                                                          , pv_errors             => lv_x_errors   
                                                             );
                                                             
               IF ln_x_retcode != 0
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error eliminando registros temporales en xxinv_pre_material_trx_temp: '|| lv_x_errors); 
                  gv_retcode := '1';              
                  RAISE le_no_exception;
               END IF;
            
               COMMIT; 
               fnd_file.put_line(fnd_file.LOG, 'Se eliminaron registros temporales en xxinv_pre_material_trx_temp.');
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');                                                      
            EXCEPTION      
               WHEN le_no_exception THEN 
                  ROLLBACK;
                  RAISE;    
               WHEN OTHERS THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error eliminando registros temporales en xxinv_pre_material_trx_temp, others. Error: '||SQLERRM);      
                  ROLLBACK;
                  gv_retcode := '1';
                  RAISE; 
            END;

         EXCEPTION      
            WHEN le_no_exception THEN 
               ROLLBACK;
               -- Continua con la siguiente linea de pedido de movimiento.
            WHEN OTHERS THEN  
               ROLLBACK;
                -- Continua con la siguiente linea de pedido de movimiento.
         END;
      END LOOP;     
    
      IF lv_ooh_order_number IS NULL 
      THEN -- En caso de que no entro al Loop principal. 
         fnd_file.put_line(fnd_file.LOG, 'No se encontro informacion de las lineas del pedido de movimiento a partir del numero de viaje.'); 
         gv_retcode := '1';              
      END IF;
      
      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL; 
       
      
      fnd_file.put_line(fnd_file.LOG, ' +++++ Fin Actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas previo a la salida. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
   EXCEPTION
      WHEN OTHERS THEN 
         fnd_file.put_line(fnd_file.LOG, 'Error actualizando tabla intermedia a partir de las referencias en xxinv_pre_material_trx_temp y xxfc_sn_escaneo_lineas previo a la salida, others/main: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END update_details_from_wsh_prc;   
   
 
   /********************************************************************************************
   Modulo : upd_det_from_wsh_set_doc_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 10/Oct/2025
   Descripcion : Ejecutar proceso de actualizar informacion a la tabla intermedia desde previo a la salida del pedido de movimiento durante el Pick Release (Juego de Documentos de Envio WSH) 
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  10/Oct/2025   CHG0116809      Version Inicial
   ********************************************************************************************/ 
   PROCEDURE upd_det_from_wsh_set_doc_prc( errbuf               OUT VARCHAR2
                                         , retcode              OUT VARCHAR2
                                         , p_delivery_name       IN VARCHAR2
                                         , p_organization_id     IN NUMBER 
                                         )
    IS

       lv_phaseout       VARCHAR2(32767);
       lv_statusout      VARCHAR2(32767);
       lv_devphaseout    VARCHAR2(32767);
       lv_devstatusout   VARCHAR2(32767);
       lv_messageout     VARCHAR2(32767);
       ln_ReqActual      NUMBER; 
       ln_reqrunning     NUMBER;
       lb_callstatus     BOOLEAN;
   BEGIN
      fnd_file.put_line(fnd_file.log, ' +++++ Ejecutando proceso para actualizar tabla intermedia previo a la salida desde el juego de documentos de confirmacion de envio. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      gv_retcode := '0';
      gv_errbuf  := NULL;
      
      -- Esperar 5 segundos para que inicie la ejecucion del programa concurrente 
       dbms_lock.sleep(5);
       
      -- Obtener el req id de la solicitud concurrente del programa WSHINTERFACE que se ha ejecutado posterior a la actual 
      ln_ReqActual:= fnd_global.conc_request_id; 
      BEGIN
         
         SELECT MAX(fcr_wsh.request_id) 
         INTO   ln_reqrunning
         FROM   fnd_concurrent_requests  fcr_curr
              , fnd_concurrent_requests  fcr_wsh
              , fnd_concurrent_programs  fcp_wsh
         WHERE  1=1
         AND    fcr_wsh.concurrent_program_id     = fcp_wsh.concurrent_program_id
         AND    fcr_wsh.requested_by              = fcr_wsh.requested_by
         AND    fcr_wsh.request_id                > fcr_curr.request_id
         AND    fcp_wsh.concurrent_program_name   = 'WSHINTERFACE' 
         AND    fcr_curr.request_id               = ln_ReqActual
         ;
         
      EXCEPTION
         WHEN OTHERS THEN
            ln_reqrunning := NULL;
      END;

      IF  ln_reqrunning IS NOT NULL
      THEN -- Se encontro solicitud concurrente WSHINTERFACE 
         fnd_file.put_line(fnd_file.LOG, 'Esperar a que termine solicitud concurrente '||ln_reqrunning||' de confirmacion de envio para el viaje: '||p_delivery_name); 

         lb_callstatus := apps.fnd_concurrent.wait_for_request( request_id => ln_reqrunning
                                                              , interval   => 15
                                                              , max_wait   => 0 -- 0 para que se espere hasta completar. 
                                                              , phase      => lv_phaseout
                                                              , status     => lv_statusout
                                                              , dev_phase  => lv_devphaseout
                                                              , dev_status => lv_devstatusout
                                                              , message    => lv_messageout
                                                              ); 
                                                             
         IF lv_devphaseout = 'COMPLETE'  
         THEN 
            fnd_file.put_line(fnd_file.LOG, 'Termino ejecucion de solicitud concurrente de confirmacion de envio, status: '||lv_statusout); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            
         ELSE 
            -- No se termino la ejecucion de la solicitud concurrente 
            fnd_file.put_line(fnd_file.LOG, 'No termino ejecucion de solicitud concurrente de confirmacion de envio.'); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            gv_retcode := 1; 
         END IF;
      ELSE
         -- No se encontro solicitud concurrente  
         fnd_file.put_line(fnd_file.LOG, 'No existe solicitud concurrente de confirmacion de envio para el viaje: '||p_delivery_name); 
         gv_retcode := 1; 
      END IF
      ;

      -- Ejecutar proceso de actualizacion de tabla intermedia previo a la salida 
      BEGIN 
         update_details_from_wsh_prc( errbuf              => gv_errbuf
                                    , retcode             => gv_retcode 
                                    , p_delivery_name     => p_delivery_name
                                    , p_organization_id   => p_organization_id
                                    );         
      EXCEPTION
         WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.LOG, 'Error al ejecutar proceso para actualizar tabla intermedia previo a la salida, error: '||SQLERRM); 
           fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
           gv_retcode := 1;                
      END; 


      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL; 
      
      fnd_file.put_line(fnd_file.log, ' +++++ Fin ejecutando proceso para actualizar tabla intermedia previo a la salida desde el juego de documentos de confirmacion de envio. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');

   EXCEPTION
      WHEN OTHERS THEN 
         fnd_file.put_line(fnd_file.LOG, 'Error ejecutando proceso para actualizar tabla intermedia previo a la salida desde el juego de documentos de confirmacion de envio, others/main: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END upd_det_from_wsh_set_doc_prc; 
   
   
    /********************************************************************************************
   Modulo : load_trips_from_wsh_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 6/Dic/2025
   Descripcion : Carga informacion a la tabla de viajes para compartir a service now
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  6/Dic/2025   CHG0135592      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026  CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion en la insercion a XXFA_SN_TRIPS
   * Gilberto Hernandez (Hexaware)   4/Mar/2026  CHG0143308      Programar el registro de los viajes que se comparten con service now
   ********************************************************************************************/
   PROCEDURE load_trips_from_wsh_prc ( errbuf               OUT VARCHAR2
                                     , retcode              OUT VARCHAR2
                                     , p_delivery_name       IN VARCHAR2
                                     , p_organization_id     IN NUMBER 
                                     )
   IS 
      TYPE lrec_trips IS RECORD (
                                  wst_trip_id               wsh_trips.trip_id%TYPE      
                                , wst_trip_name             wsh_trips.name%TYPE      
                                , msi_item_number           mtl_system_items_b.segment1%TYPE      
                                , msi_item_description      mtl_system_items_b.description%TYPE      
                                , wdd_shipped_quantity      wsh_delivery_details.shipped_quantity%TYPE      
                                , ooh_header_id             oe_order_headers_all.header_id%TYPE      
                                , ooh_order_number          oe_order_headers_all.order_number%TYPE      
                                , ool_line_id               wsh_delivery_details.source_line_id%TYPE      
                                , ship_confirm_flag         xxfa_sn_trips.ship_confirm_flag%TYPE  
                                , wnd_delivery_id           wsh_new_deliveries.delivery_id%TYPE 
                                , wnd_confirm_date          wsh_new_deliveries.confirm_date%TYPE 
                                , wt_status_code            wsh_trips.status_code%TYPE 
                                , wdd_delivery_detail_id    wsh_delivery_details.delivery_detail_id%TYPE 
                                , wdd_organization_id       wsh_delivery_details.organization_id%TYPE  
                                , wdd_released_status       wsh_delivery_details.released_status%TYPE   
                                , prl_oracle_cr_superior    po_requisition_lines_all.attribute2%TYPE 
                                , prl_oracle_cr             po_requisition_lines_all.attribute3%TYPE  
                                , prl_requistor_full_name   per_people_x.full_name%TYPE  
                                , prh_solicitud_inversion   po_requisition_headers_all.attribute1%TYPE                                  
                                ); 
      TYPE ltab_trips IS TABLE OF lrec_trips INDEX BY PLS_INTEGER;
      TYPE ltab_dist_trips IS TABLE OF BOOLEAN INDEX BY VARCHAR2(30);
   
      
      larr_wsh_trips       ltab_trips;
      larr_sn_trips        ltab_trips;
      larr_dist_trips      ltab_dist_trips;
      lv_idx_dist_trip     VARCHAR2(30);
      
      ln_sn_trip_id        NUMBER; 
      idx                  NUMBER; 
      
      lv_phaseout          VARCHAR2(32767);
      lv_statusout         VARCHAR2(32767);
      lv_devphaseout       VARCHAR2(32767);
      lv_devstatusout      VARCHAR2(32767);
      lv_messageout        VARCHAR2(32767);
      ln_ReqActual         NUMBER; 
      ln_reqrunning        NUMBER;
      lb_callstatus        BOOLEAN;
      
	  ln_store_days        NUMBER; -- CHG0143308 
	  
      -- Informacion del viaje desde wsh
      CURSOR c_wsh_trip( p_trip_name IN VARCHAR2
                       ) 
      IS  
         SELECT  wt.trip_id              AS wst_trip_id
               , wt.name                 AS wst_trip_name 
               , msi.segment1            AS msi_item_number
               , msi.description         AS msi_item_description
               , CASE
                  WHEN wt.status_code != 'CL' 
                  THEN 
                     wdd.requested_quantity  
                  ELSE 
                     wdd.shipped_quantity
                 END wdd_shipped_quantity
               , ooh.header_id           AS ooh_header_id
               , ooh.order_number        AS ooh_order_number
               , wdd.source_line_id      AS ool_line_id        
               , CASE
                  WHEN wt.status_code != 'CL' 
                  THEN 
                     'N'     
                  ELSE 
                     'Y'
                 END ship_confirm_flag
               , wnd.delivery_id         AS wnd_delivery_id  
               , wnd.confirm_date        AS wnd_confirm_date   
               , wt.status_code          AS wt_status_code 
               , wdd.delivery_detail_id  AS wdd_delivery_detail_id
               , wdd.organization_id     AS wdd_organization_id
               , wdd.released_status     AS wdd_released_status   
               , prl.attribute2          AS prl_oracle_cr_superior
               , prl.attribute3          AS prl_oracle_cr
               , ppf.full_name           AS prl_requistor_full_name   
               , prh.attribute1          AS prh_solicitud_inversion            
         FROM    oe_order_headers_all ooh
               , oe_order_lines_all ool 
               , po_requisition_lines_all prl
               , po_requisition_headers_all prh
               , per_people_f ppf
               , wsh_delivery_details wdd
               , wsh_new_deliveries wnd
               , wsh_delivery_assignments wda
               , wsh_trips wt
               , wsh_delivery_legs wdl
               , wsh_trip_stops wds_pick     
               , wsh_trip_stops wds_drop   
               , mtl_system_items_b msi 
         WHERE  1 = 1
         AND    ooh.header_id               = wdd.source_header_id (+)
         AND    ool.line_id                 = wdd.source_line_id (+)
         AND    ool.attribute1              = prl.requisition_line_id (+) 
         AND    prl.requisition_header_id   = prh.requisition_header_id (+) 
         AND    prl.to_person_id            = ppf.person_id (+) 
         AND   ( prl.creation_date          >= ppf.effective_start_date (+)
             AND prl.creation_date          <= ppf.effective_end_date (+) ) 
         AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
         AND    wda.delivery_id             = wnd.delivery_id(+)
         AND    wdl.delivery_id(+)          = wnd.delivery_id  
         AND    wt.trip_id                  = wds_pick.trip_id
         AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
         AND    wt.trip_id                  = wds_drop.trip_id
         AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
         AND    msi.inventory_item_id       = wdd.inventory_item_id 
         AND    msi.organization_id         = wdd.organization_id
         AND   EXISTS -- que sea de una organizacion de activo fijo 
               (
               SELECT 1
               FROM   fnd_flex_values_vl ffv
                    , fnd_flex_value_sets fvs
               WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
               AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
               AND    ffv.enabled_flag = 'Y'
               AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
               AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
               AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
               )
         AND   NOT EXISTS -- Que no haya sido compartido antes a SN con confirmacion de envio 
               ( SELECT 1 
                 FROM   xxfa_sn_trips xst  
                 WHERE  xst.wst_trip_name  = wt.name 
                 AND    ship_confirm_flag  = 'Y'
                )             
         AND    wt.name  = p_trip_name
         ;
   
      -- Informacion de la ultima version de viaje que se ha compartido anteriormente 
      CURSOR c_sn_trip( p_trip_name IN VARCHAR2
                       ) 
      IS 
         SELECT  wst_trip_id
               , wst_trip_name 
               , msi_item_number
               , msi_item_description
               , wdd_shipped_quantity
               , ooh_header_id
               , ooh_order_number
               , ool_line_id        
               , ship_confirm_flag
               , wnd_delivery_id  
               , wnd_confirm_date  
               , wt_status_code    
               , wdd_delivery_detail_id
               , wdd_organization_id
               , wdd_released_status   
               , prl_oracle_cr_superior
               , prl_oracle_cr
               , prl_requistor_full_name 
               , prh_solicitud_inversion
         FROM    xxfa_sn_trips 
         WHERE   wst_trip_name = p_trip_name
         AND     sn_trip_id    = (SELECT MAX(sn_trip_id)
                                  FROM   xxfa_sn_trips 
                                  WHERE  wst_trip_name = p_trip_name
                                  )
         ;
      
      -- Funcion para comparar arreglos y saber si hay cambios que reportar a SN 
      FUNCTION arrays_equal(p_arr_wsh IN ltab_trips
                          , p_arr_sn  IN ltab_trips
                            ) 
      RETURN BOOLEAN IS
          idx PLS_INTEGER;
      BEGIN
      
         -- Checar si las cantidades no son iguales
         IF p_arr_wsh.COUNT != p_arr_sn.COUNT 
         THEN
            RETURN FALSE;
         END IF;
      
         -- Revisar los arreglos a partir de la llave, primer arreglo 
         idx := p_arr_wsh.FIRST;
         
         WHILE idx IS NOT NULL 
         LOOP
            -- Revisa si el idx existe en el segundo arreglo 
            IF NOT p_arr_sn.EXISTS(idx) 
            THEN
               RETURN FALSE;
            END IF;
   
            -- Compara valores (solo los que se mandan a SN) 
            IF NVL(p_arr_wsh(idx).wst_trip_id, 0)                                  != NVL(p_arr_sn(idx).wst_trip_id, 0) 
            OR NVL(p_arr_wsh(idx).wst_trip_name, 'NULL')                           != NVL(p_arr_sn(idx).wst_trip_name, 'NULL')
            OR NVL(p_arr_wsh(idx).msi_item_number, 'NULL')                         != NVL(p_arr_sn(idx).msi_item_number, 'NULL')
            OR NVL(p_arr_wsh(idx).msi_item_description, 'NULL')                    != NVL(p_arr_sn(idx).msi_item_description, 'NULL')
            OR NVL(p_arr_wsh(idx).wdd_shipped_quantity, 0)                         != NVL(p_arr_sn(idx).wdd_shipped_quantity, 0)
            OR NVL(p_arr_wsh(idx).ooh_header_id, 0)                                != NVL(p_arr_sn(idx).ooh_header_id, 0)          
            OR NVL(p_arr_wsh(idx).ooh_order_number, 0)                             != NVL(p_arr_sn(idx).ooh_order_number, 0)  
            OR NVL(p_arr_wsh(idx).ool_line_id, 0)                                  != NVL(p_arr_sn(idx).ool_line_id, 0)  
            OR NVL(p_arr_wsh(idx).ship_confirm_flag, 'NULL')                       != NVL(p_arr_sn(idx).ship_confirm_flag, 'NULL')
            OR NVL(TO_CHAR(p_arr_wsh(idx).wnd_confirm_date, 'YYYYMMDD'), 'NULL')   != NVL(TO_CHAR(p_arr_sn(idx).wnd_confirm_date, 'YYYYMMDD'), 'NULL')
            OR NVL(p_arr_wsh(idx).prl_oracle_cr_superior, 'NULL')                  != NVL(p_arr_sn(idx).prl_oracle_cr_superior, 'NULL')
            OR NVL(p_arr_wsh(idx).prl_oracle_cr, 'NULL')                           != NVL(p_arr_sn(idx).prl_oracle_cr, 'NULL')
            OR NVL(p_arr_wsh(idx).prl_requistor_full_name, 'NULL')                 != NVL(p_arr_sn(idx).prl_requistor_full_name, 'NULL')
            OR NVL(p_arr_wsh(idx).prh_solicitud_inversion, 'NULL')                 != NVL(p_arr_sn(idx).prh_solicitud_inversion, 'NULL')            
            THEN
               RETURN FALSE;
            END IF;
      
            idx := p_arr_sn.NEXT(idx);
         END LOOP;
   
   
         -- Revisar los arreglos a partir de la llave, segundo arreglo 
         idx := p_arr_sn.FIRST;
         WHILE idx IS NOT NULL 
         LOOP
            -- Revisa si el idx existe en el primer arreglo 
            IF NOT p_arr_wsh.EXISTS(idx) 
            THEN
               RETURN FALSE;
            END IF;
      
            idx := p_arr_sn.NEXT(idx);
         END LOOP;
   
      
         RETURN TRUE; -- Si los arrelos son iguales 
      EXCEPTION
         WHEN OTHERS THEN  
            fnd_file.put_line(fnd_file.LOG, 'arrays_equal: '||SQLERRM); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            RAISE; 
      END arrays_equal;
      
   BEGIN
      fnd_file.put_line(fnd_file.log, ' +++++ Ejecutando proceso para cargar registros de viajes para compartir a service now. +++++'); 
      fnd_file.put_line(fnd_file.log, 'p_delivery_name: '||p_delivery_name);
      fnd_file.put_line(fnd_file.log, 'p_organization_id: '||p_organization_id);
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      gv_retcode := '0';
      gv_errbuf  := NULL;


      fnd_file.put_line(fnd_file.LOG, 'Ejecutando depuracion de informacion de viajes.'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');   
      BEGIN
         purge_trips_prc(retcode => gv_retcode
                       , errbuf  => gv_errbuf
                         );
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line(fnd_file.LOG, 'Error Ejecutando depuracion de informacion viajes: '||SQLERRM); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               
      END;  
 
      -- CHG0143308  Inicia. 
      -- Obtener los dias que se basara el borrado de la informacion de viajes
      BEGIN 
      
         SELECT ffv.description
         INTO   ln_store_days
         FROM   fnd_flex_values_vl ffv
              , fnd_flex_value_sets fvs
         WHERE  fvs.flex_value_set_id    = ffv.flex_value_set_id
         AND    fvs.flex_value_set_name  = 'XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO'
         AND    ffv.flex_value           = 'DIAS_RESGUARDO'
         AND    ffv.enabled_flag         = 'Y'
         AND  ( ffv.start_date_active    < SYSDATE OR ffv.start_date_active IS NULL)
         AND  ( ffv.end_date_active      > SYSDATE OR ffv.end_date_active IS NULL)
         ;
      EXCEPTION 
         WHEN OTHERS THEN 
		    ln_store_days := 30;
            gv_retcode := 1; 
      END; 
      -- CHG0143308  Termina. 

 
      IF p_delivery_name IS NOT NULL
      THEN -- Si se esta ejecutando para un viaje en especifico, hacer la consulta.       
         -- Obtener los viajes a compartir a service now 
         FOR wsh IN c_wsh_trip(p_trip_name => p_delivery_name
                              )
         LOOP
            IF NOT larr_dist_trips.EXISTS(wsh.wst_trip_name)
            THEN 
               larr_dist_trips(wsh.wst_trip_name) := TRUE;  
            END IF;    
         END LOOP; 
      ELSE 
         -- Si no hay viaje especifico, obtener los viajes por actualizar desde la tabla de service now       
         FOR sn IN (SELECT DISTINCT wst_trip_name
                    FROM   xxfa_sn_trips
                    WHERE  ship_confirm_flag = 'N' 
					-- CHG0143308  Inicia. 
					UNION 
                    SELECT  DISTINCT wt.name  AS wst_trip_name         
                    FROM    apps.oe_order_headers_all ooh
                          , apps.oe_order_lines_all ool 
                          , apps.po_requisition_lines_all prl
                          , apps.po_requisition_headers_all prh
                          , apps.per_people_f ppf
                          , apps.wsh_delivery_details wdd
                          , apps.wsh_new_deliveries wnd
                          , apps.wsh_delivery_assignments wda
                          , apps.wsh_trips wt
                          , apps.wsh_delivery_legs wdl
                          , apps.wsh_trip_stops wds_pick     
                          , apps.wsh_trip_stops wds_drop   
                          , apps.mtl_system_items_b msi 
                    WHERE  1 = 1
                    AND    ooh.header_id               = wdd.source_header_id (+)
                    AND    ool.line_id                 = wdd.source_line_id (+)
                    AND    ool.attribute1              = prl.requisition_line_id (+) 
                    AND    prl.requisition_header_id   = prh.requisition_header_id (+) 
                    AND    prl.to_person_id            = ppf.person_id (+) 
                    AND   ( prl.creation_date          >= ppf.effective_start_date (+)
                        AND prl.creation_date          <= ppf.effective_end_date (+) ) 
                    AND    wda.delivery_detail_id(+)   = wdd.delivery_detail_id
                    AND    wda.delivery_id             = wnd.delivery_id(+)
                    AND    wdl.delivery_id(+)          = wnd.delivery_id  
                    AND    wt.trip_id                  = wds_pick.trip_id
                    AND    wds_pick.stop_id(+)         = wdl.pick_up_stop_id
                    AND    wt.trip_id                  = wds_drop.trip_id
                    AND    wds_drop.stop_id(+)         = wdl.drop_off_stop_id     
                    AND    msi.inventory_item_id       = wdd.inventory_item_id 
                    AND    msi.organization_id         = wdd.organization_id
                    AND   EXISTS -- que sea de una organizacion de activo fijo 
                          (
                          SELECT 1
                          FROM   apps.fnd_flex_values_vl ffv
                               , apps.fnd_flex_value_sets fvs
                          WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                          AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                          AND    ffv.enabled_flag = 'Y'
                          AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                          AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                          AND    ffv.flex_value = TO_CHAR(wdd.organization_id)
                          )
                    AND  wt.name NOT IN -- Que no haya sido registrado en xxfa_sn_trips, ya que lo obtiene la primer parte del UNION. 
                          ( SELECT xst.wst_trip_name 
                            FROM   apps.xxfa_sn_trips xst  
                           )             
                    AND TRUNC(wt.creation_date) >= TRUNC(SYSDATE) - ln_store_days									
					-- CHG0143308  Termina
                    )
         LOOP 
            larr_dist_trips(sn.wst_trip_name) := TRUE;  
         END LOOP;       
      END IF; 
      
      IF larr_dist_trips.COUNT > 0
      THEN -- Si hay viajes que compartir a Service Now 
         
         lv_idx_dist_trip := larr_dist_trips.FIRST; 
         WHILE lv_idx_dist_trip IS NOT NULL 
         LOOP
            BEGIN 
               fnd_file.put_line(fnd_file.LOG, 'Validando informacion del viaje: '||lv_idx_dist_trip); 
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
                           
               -- Limpiar arreglos 
               larr_wsh_trips.DELETE;
               larr_sn_trips.DELETE;
            
            
               -- Cargar arreglo para wsh 
               FOR wsh IN c_wsh_trip(p_trip_name => lv_idx_dist_trip
                                    )
               LOOP
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wst_trip_id                := wsh.wst_trip_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wst_trip_name              := wsh.wst_trip_name;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).msi_item_number            := wsh.msi_item_number;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).msi_item_description       := wsh.msi_item_description;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_shipped_quantity       := wsh.wdd_shipped_quantity;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ooh_header_id              := wsh.ooh_header_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ooh_order_number           := wsh.ooh_order_number;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ool_line_id                := wsh.ool_line_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).ship_confirm_flag          := wsh.ship_confirm_flag;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wnd_delivery_id            := wsh.wnd_delivery_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wnd_confirm_date           := wsh.wnd_confirm_date;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wt_status_code             := wsh.wt_status_code;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_delivery_detail_id     := wsh.wdd_delivery_detail_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_organization_id        := wsh.wdd_organization_id;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).wdd_released_status        := wsh.wdd_released_status;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prl_oracle_cr_superior     := wsh.prl_oracle_cr_superior;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prl_oracle_cr              := wsh.prl_oracle_cr;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prl_requistor_full_name    := wsh.prl_requistor_full_name;
                  larr_wsh_trips(wsh.wdd_delivery_detail_id).prh_solicitud_inversion    := wsh.prh_solicitud_inversion;
               END LOOP; 
               
               fnd_file.put_line(fnd_file.LOG, 'larr_wsh_trips.COUNT: '||larr_wsh_trips.COUNT); 
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');            
            
               -- Cargar arreglo para sn 
               FOR sn IN c_sn_trip(p_trip_name => lv_idx_dist_trip
                                  )
               LOOP
                  larr_sn_trips(sn.wdd_delivery_detail_id).wst_trip_id                := sn.wst_trip_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wst_trip_name              := sn.wst_trip_name;
                  larr_sn_trips(sn.wdd_delivery_detail_id).msi_item_number            := sn.msi_item_number;
                  larr_sn_trips(sn.wdd_delivery_detail_id).msi_item_description       := sn.msi_item_description;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_shipped_quantity       := sn.wdd_shipped_quantity;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ooh_header_id              := sn.ooh_header_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ooh_order_number           := sn.ooh_order_number;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ool_line_id                := sn.ool_line_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).ship_confirm_flag          := sn.ship_confirm_flag;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wnd_delivery_id            := sn.wnd_delivery_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wnd_confirm_date           := sn.wnd_confirm_date;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wt_status_code             := sn.wt_status_code;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_delivery_detail_id     := sn.wdd_delivery_detail_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_organization_id        := sn.wdd_organization_id;
                  larr_sn_trips(sn.wdd_delivery_detail_id).wdd_released_status        := sn.wdd_released_status;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prl_oracle_cr_superior     := sn.prl_oracle_cr_superior;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prl_oracle_cr              := sn.prl_oracle_cr;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prl_requistor_full_name    := sn.prl_requistor_full_name;
                  larr_sn_trips(sn.wdd_delivery_detail_id).prh_solicitud_inversion    := sn.prh_solicitud_inversion;
               END LOOP; 
               
               fnd_file.put_line(fnd_file.LOG, 'larr_sn_trips.COUNT: '||larr_sn_trips.COUNT); 
               fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');               

                       
               -- Comparar los arreglos para saber si hay cambios que enviar a SN 
               IF NOT arrays_equal( p_arr_wsh => larr_wsh_trips
                                  , p_arr_sn  => larr_sn_trips
                                  ) 
               AND larr_wsh_trips.COUNT > 0 -- Asegurarse que haya algo que actualizar
               THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Se encontro informacion para compartir a service now.'); 
                  fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');  
                  
                  -- Obten id de viaje de sn (version)
                  SELECT  xxfc.xxfa_sn_trips_s.nextval
                  INTO    ln_sn_trip_id
                  FROM    dual
                  ;
             
                  -- Insertar informacion en la tabla xxfa_sn_trips
                  idx := larr_wsh_trips.FIRST;
                  WHILE idx IS NOT NULL 
                  LOOP
                     INSERT INTO xxfa_sn_trips( sn_trip_id
                                              , wst_trip_id            
                                              , wst_trip_name         
                                              , msi_item_number        
                                              , msi_item_description   
                                              , wdd_shipped_quantity   
                                              , ooh_header_id          
                                              , ooh_order_number       
                                              , ool_line_id            
                                              , ship_confirm_flag      
                                              , wnd_delivery_id        
                                              , wnd_confirm_date       
                                              , wt_status_code         
                                              , wdd_delivery_detail_id 
                                              , wdd_organization_id    
                                              , wdd_released_status   
                                              , prl_oracle_cr_superior 
                                              , prl_oracle_cr
                                              , prl_requistor_full_name   
                                              , prh_solicitud_inversion                                           
                                              , creation_date          
                                              , created_by             
                                              , last_update_date       
                                              , last_updated_by        
                                              , last_update_login  
                                               )
                     VALUES ( ln_sn_trip_id
                            , larr_wsh_trips(idx).wst_trip_id           
                            , larr_wsh_trips(idx).wst_trip_name         
                            , larr_wsh_trips(idx).msi_item_number       
                            , larr_wsh_trips(idx).msi_item_description  
                            , larr_wsh_trips(idx).wdd_shipped_quantity  
                            , larr_wsh_trips(idx).ooh_header_id         
                            , larr_wsh_trips(idx).ooh_order_number      
                            , larr_wsh_trips(idx).ool_line_id           
                            , larr_wsh_trips(idx).ship_confirm_flag     
                            , larr_wsh_trips(idx).wnd_delivery_id       
                            , larr_wsh_trips(idx).wnd_confirm_date      
                            , larr_wsh_trips(idx).wt_status_code        
                            , larr_wsh_trips(idx).wdd_delivery_detail_id
                            , larr_wsh_trips(idx).wdd_organization_id   
                            , larr_wsh_trips(idx).wdd_released_status 
                            , larr_wsh_trips(idx).prl_oracle_cr_superior 
                            , larr_wsh_trips(idx).prl_oracle_cr 
                            , larr_wsh_trips(idx).prl_requistor_full_name 
                            , larr_wsh_trips(idx).prh_solicitud_inversion                           
                            , SYSDATE
                            , FND_PROFILE.value('USER_ID')
                            , SYSDATE
                            , FND_PROFILE.value('USER_ID')
                            , FND_PROFILE.value('LOGIN_ID')
                             );
                     
                     idx := larr_wsh_trips.NEXT(idx);          
                  END LOOP;     
            
                  
                  COMMIT;
				  
				  -- Llamar actualiza tabla intermedia 
				  BEGIN 
                     fnd_file.put_line(fnd_file.LOG, 'Inicia ejecutar proceso para actualizar tabla intermedia previo a la salida.'); 
                     fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '); 
					 


                     -- Recorrer nuevamente el arreglo 
                     idx := larr_wsh_trips.FIRST;
                     WHILE idx IS NOT NULL 
                     LOOP
                        IF  
                        
                        idx := larr_wsh_trips.NEXT(idx);          
                     END LOOP;



				     FOR x_trip IN (SELECT wst_trip_name
                                         , wdd_organization_id					 
					                FROM   xxfa_sn_trips
					 				WHERE  ship_confirm_flag = 'Y' 
					 				)
					 LOOP
                        update_details_from_wsh_prc( errbuf               => gv_errbuf
                                                   , retcode              => gv_retcode
                                                   , p_delivery_name      => x_trip.wst_trip_name  
                                                   , p_organization_id    => x_trip.wdd_organization_id  
                                                   ); 
                     END LOOP; 					 
				  
                     fnd_file.put_line(fnd_file.LOG, 'Finaliza ejecutar proceso para actualizar tabla intermedia previo a la salida.'); 
                     fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] '); 				  
				  EXCEPTION
				     WHEN OTHERS THEN 
					    NULL; -- Sin accion por realizar. 
				  END; 
               ELSE 
                  fnd_file.put_line(fnd_file.LOG, 'No hay informacion actualizada para compartir a service now.'); 
                  fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');  
               END IF;
            
               -- Obtener el siguiente viaje 
               lv_idx_dist_trip := larr_dist_trips.NEXT(lv_idx_dist_trip);
         
            EXCEPTION
               WHEN OTHERS THEN 
                  fnd_file.put_line(fnd_file.LOG, 'Error al validar el viaje: '||SQLERRM); 
                  fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
                  gv_retcode := 1;   
            END;
         END LOOP;        
      ELSE 
         fnd_file.put_line(fnd_file.log,'No existe informacion de viajes para compartir a Service Now. Revisar si ya ha sido compartido anteriormente con confirmacion de envio.');  
      END IF;

      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL; 
      
      fnd_file.put_line(fnd_file.log, ' +++++ Fin ejecutando proceso para cargar registros de viajes para compartir a service now. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');

   EXCEPTION
      WHEN OTHERS THEN 
         fnd_file.put_line(fnd_file.LOG, 'Error ejecutando proceso para cargar registros de viajes para compartir a service now: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END load_trips_from_wsh_prc;  
   
   /********************************************************************************************
   Modulo : purge_trips_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Purga informacion de la tabla de viajes
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135592      Version Inicial
   ********************************************************************************************/
   PROCEDURE purge_trips_prc ( errbuf               OUT VARCHAR2
                             , retcode              OUT VARCHAR2
                              )   
   IS
      ln_store_days      NUMBER;
      ln_purge_countrows NUMBER;
   BEGIN 
      fnd_file.put_line(fnd_file.log, ' +++++ Ejecutando proceso para depurar registros de viajes para compartir a service now. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      gv_retcode := 0; 
      gv_errbuf  := NULL;
      
      -- Obtener los dias que se basara el borrado de la informacion de viajes
      BEGIN 
      
         SELECT ffv.description
         INTO   ln_store_days
         FROM   fnd_flex_values_vl ffv
              , fnd_flex_value_sets fvs
         WHERE  fvs.flex_value_set_id    = ffv.flex_value_set_id
         AND    fvs.flex_value_set_name  = 'XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO'
         AND    ffv.flex_value           = 'DIAS_RESGUARDO'
         AND    ffv.enabled_flag         = 'Y'
         AND  ( ffv.start_date_active    < SYSDATE OR ffv.start_date_active IS NULL)
         AND  ( ffv.end_date_active      > SYSDATE OR ffv.end_date_active IS NULL)
         ;

         fnd_file.put_line(fnd_file.LOG, 'Dias de resguardo de informacion de viajes: '||ln_store_days); 
         fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');    
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line(fnd_file.LOG, 'Error al obtener los dias de conservacion de informacion para ejecutar el proceso de depuracion de viajes desde el juego de valores XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO(DIAS_RESGUARDO): '||SQLERRM); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            gv_retcode := 1; 
      END;   

      IF ln_store_days IS NOT NULL 
      THEN 
         DELETE xxfa_sn_trips xst
         WHERE  TRUNC(xst.creation_date) < TRUNC(SYSDATE) - ln_store_days;
      
         ln_purge_countrows := SQL%ROWCOUNT;
         
         fnd_file.put_line(fnd_file.LOG, 'Se depuraron '||ln_purge_countrows||' registros de informacion de viajes para compartir a service now.'); 
         fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      END IF;

      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL;      

   EXCEPTION
      WHEN OTHERS THEN 
         fnd_file.put_line(fnd_file.LOG, 'Error ejecutando proceso para depurar registros de viajes para compartir a service now: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END purge_trips_prc;  
   
   /********************************************************************************************
   Modulo : purge_rcv_others_prc
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 11/Feb/2026
   Descripcion : Purfa informacion de la tabla de otras recepciones de activo fijo
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  10/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
   PROCEDURE purge_rcv_others_prc ( errbuf               OUT VARCHAR2
                                  , retcode              OUT VARCHAR2
                                  )   
   IS
      ln_store_days      NUMBER;
      ln_purge_countrows NUMBER;
   BEGIN 
      fnd_file.put_line(fnd_file.log, ' +++++ Ejecutando proceso para depurar registros de viajes para compartir a service now. +++++'); 
      fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      gv_retcode := 0; 
      gv_errbuf  := NULL;
      
      -- Obtener los dias que se basara el borrado de la informacion de viajes
      BEGIN 
      
         SELECT ffv.description
         INTO   ln_store_days
         FROM   fnd_flex_values_vl ffv
              , fnd_flex_value_sets fvs
         WHERE  fvs.flex_value_set_id    = ffv.flex_value_set_id
         AND    fvs.flex_value_set_name  = 'XXFA_SN_RCV_OTROS_DEPURA_DIAS_RESGUARDO'
         AND    ffv.flex_value           = 'DIAS_RESGUARDO'
         AND    ffv.enabled_flag         = 'Y'
         AND  ( ffv.start_date_active    < SYSDATE OR ffv.start_date_active IS NULL)
         AND  ( ffv.end_date_active      > SYSDATE OR ffv.end_date_active IS NULL)
         ;

         fnd_file.put_line(fnd_file.LOG, 'Dias de resguardo de informacion de viajes: '||ln_store_days); 
         fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');    
      EXCEPTION 
         WHEN OTHERS THEN 
            fnd_file.put_line(fnd_file.LOG, 'Error al obtener los dias de conservacion de informacion para ejecutar el proceso de depuracion de viajes desde el juego de valores XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO(DIAS_RESGUARDO): '||SQLERRM); 
            fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
            gv_retcode := 1; 
      END;   

      IF ln_store_days IS NOT NULL 
      THEN 
         DELETE xxfa_sn_data_rcv_others xst
         WHERE  TRUNC(xst.creation_date) < TRUNC(SYSDATE) - ln_store_days;
      
         ln_purge_countrows := SQL%ROWCOUNT;
         
         fnd_file.put_line(fnd_file.LOG, 'Se depuraron '||ln_purge_countrows||' registros de informacion de otras recepciones para compartir a service now.'); 
         fnd_file.put_line(fnd_file.log, '['||TO_CHAR(SYSDATE,'RRRR/MM/DD HH24:MI:SS')||'] ');
      END IF;

      retcode := gv_retcode;
      
      SELECT  CASE 
              WHEN  gv_retcode = '0'
              THEN
                    NULL              
              WHEN  gv_retcode = '1'
              THEN   
                   'Existen advertencias en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'   
              WHEN  gv_retcode = '2'
              THEN  
                   'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'
              END AS errbuf                    
       INTO    errbuf
       FROM    DUAL;      

   EXCEPTION
      WHEN OTHERS THEN 
         fnd_file.put_line(fnd_file.LOG, 'Error ejecutando proceso para depurar registros de otras recepciones para compartir a service now: '||SQLERRM);
         retcode := 2;
         errbuf := 'Existen errores en la ejecucion del programa concurrente, para mayor informacion revisar el archivo LOG'; 
   END purge_rcv_others_prc;  
      
END xxfa_sn_data_api_pkg;
/
SHOW ERRORS;