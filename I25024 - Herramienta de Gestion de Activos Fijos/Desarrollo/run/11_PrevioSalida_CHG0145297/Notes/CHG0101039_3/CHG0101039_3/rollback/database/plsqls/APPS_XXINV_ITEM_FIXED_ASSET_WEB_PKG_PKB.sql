create or replace PACKAGE BODY      XXINV_ITEM_FIXED_ASSET_WEB_PKG
IS

   /********************************************************************************************
   * Modulo      : MAIN
   * Autor       :
   * Fecha       :
   * Descripci�n : Procedimiento principal para el proceso diario de almacen

   * Modificado Por             Fecha           Codigo          Descripci�n
   ---------------------------------------------------------------------------------------------
   * Roberto Ruiz Facundo OT    Consulting		CHG-38343	    Cambios para incluir el CR y EF de Oracle
   *													    en la tabla de interface XXINV_ISSUE_FIXED_ASSET_WEB
   * Laura De Santiago          08.oct.2013     CHO 51413405    Se elimina las validaciones para determinar
   *                                                        si es plaza Legacy u Oracle
   * Laura De Santiago(LDSM)    13.mar.2014     CHO 51906487    Se agregan mensajes a fa_mass_additions_iface
   *                                                            para log y output las transacciones procesadas.
   *                                                            Se cambia a guardar por cada transaccion.
   * Egomez (GTIM)              25,Mar,2017     CHO 51967670    1. Se comentan lineas para origen MOVE ORDER
                                                                2. Se agregan lineas para nUevo origen SALES ORDER ISSUE
   * Armando Padilla          Diciembre 2020	CHO 52070104    Para descartar Activos y Devoluciones de OxxoGas
   ********************************************************************************************/
   PROCEDURE main (errbuf OUT VARCHAR2, retcode OUT VARCHAR2, p_date IN DATE, p_org_id IN NUMBER)
   IS
      CURSOR c_insert_table_gpototal_det (p_org_id IN NUMBER, p_date IN DATE)
      IS
         SELECT xmde.legacy_ef legacy_ef
              , xmde.legacy_cr legacy_cr
              , xmde.oracle_cr                         /*-- CHG-38343 --*/
              , xmde.oracle_ef
              , xmt.msi_segment1_no_articulo item_number
              , xmt.msi_descripcion description
              , DECODE (xmt.msi_attribute1_uso, '04', xmt.msi_attribute2_mae_activo, NULL) item_type
-- JP 12.2.4 ppr              , DECODE (xmde.oracle_cia, '099', 3, 1) sa_state
              , DECODE (xmde.oracle_cia, '00099', 3, 1) sa_state -- JP 12.2.4 ppr
              --  GDS 15-jul-2010              , xmt.reqh_requisition_header_id header_number
              , xmt.rh_header_id                  header_number
              , xmt.rl_attribute1_req_line_id line_number
              , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY') creation_date
              , ABS (xmt.mmt_transaction_quantity) quantity
              , xmt.mmt_actual_cost item_cost
              , DECODE (xmde.oracle_cia
-- JP 12.2.4 ppr                      , '099', NULL
                      , '00099', NULL                  -- JP 12.2.4 ppr
                      , DECODE (apc.tax_rate, 0, NULL, ((xmt.mmt_actual_cost) * (apc.tax_rate / 100)))
                       ) tax_rate
              , 'AFSAL001_GPO' || xmde.legacy_ef || '.IND' || TO_CHAR (TRUNC (xmt.mmt_creation_date), 'MMDD')
                                                                                                         interface_type
         FROM 	xxinv_material_trx_temp xmt
              , xxfc_maestro_de_crs_v xmde
              ,(SELECT 	tax_rate
                      , enabled_flag
                      , name                                         --R12 UPGRADE  ADDED BY  BHAVYA SHARMA 16-JULY-2008
                FROM 	ap_tax_codes_all                        -- R12 UPG BY EDGAR VILLAGRAN 2008-11-06    AP_TAX_CODES
                WHERE 	1 = 1
                AND 	enabled_flag = 'Y'
                AND 	SYSDATE BETWEEN NVL (start_date, SYSDATE - 1) AND NVL (inactive_date, SYSDATE + 1)
                AND 	tax_type = 'AWT'
                UNION
                SELECT 	b.percentage_rate tax_rate
                      , b.active_flag enabled_flag
                      , b.tax_rate_code name
                FROM 	zx_taxes_b a, zx_rates_b b, zx_party_tax_profile c
                WHERE 	b.active_flag = 'Y'
                AND 	a.tax_type_code <> 'AWT'
                AND 	a.tax = b.tax
                AND 	a.tax_regime_code = b.tax_regime_code
                AND 	a.content_owner_id = b.content_owner_id
                AND 	b.content_owner_id = c.party_tax_profile_id
-- JP 12.2.4                AND 	c.party_type_code = 'OU'
                AND 	c.party_type_code = 'GCO'
                AND 	SYSDATE BETWEEN NVL (b.effective_from, SYSDATE - 1) AND NVL (b.effective_to, SYSDATE + 1)) apc
         WHERE 	msi_attribute2_mae_activo IN (SELECT 	ffv.flex_value
                                              FROM 		fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
                                              WHERE 	fvs.flex_value_set_name = 'XXINV_AF_AFSAL001_GPO'
                                              AND 		fvs.flex_value_set_id   = ffv.flex_value_set_id
                                              AND 		ffv.enabled_flag = 'Y')
         --inicio ChO ***51967670***
         --AND 	xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
         AND     xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND 	xmt.mmt_transaction_action_id = 1
         --AND 	xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND     xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         --Fin ChO ***51967670***
         AND 	xmde.oracle_cr = xmt.reql_attribute3_cr
         AND 	xmde.oracle_cr_superior = xmt.reql_attribute2_crsup
         AND 	xmde.oracle_ef = xmt.af_oracle_ef
         AND 	xmde.estado = 'A'
-- JP 12.2.4         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, '0% IVA')
         AND 	apc.NAME = NVL (xmt.msi_purchasing_tax_code, 'TASA-0%IVA')
         AND 	apc.enabled_flag = 'Y'
         AND    	xmt.msi_attribute7_mae_tipo = 'GPOTOTAL'
         AND 	xmt.mmt_organization_id = p_org_id
         AND 	TRUNC (xmt.mmt_creation_date) = TRUNC (p_date)
         AND 	xxinv_item_fixed_asset_web_pkg.check_item_attribute ( xmt.mmt_organization_id
																    , xmt.mmt_inventory_item_id
																	, xmt.reqh_requisition_header_id
																	, xmt.rl_attribute1_req_line_id
																	) = '04';
      CURSOR c_dev
      IS
         SELECT  	oracle_cr,oracle_ef,legacy_ef, legacy_cr, clave_activo item_type, numero_salida header_number,
-- JP 12.2.4 ppr					monto item_cost,DECODE (sa, '099', 3, 1) sa_state,fecha_salida
					monto item_cost,DECODE (sa, '00099', 3, 1) sa_state,fecha_salida    -- JP 12.2.4 ppr
         FROM		xxfc_inv_devolucion_almacen ida, xxfc_maestro_de_crs_v mcr
		 WHERE 	    ida.cr = mcr.oracle_cr
		 AND   	    ida.plaza = mcr.oracle_cr_superior
		 AND   	    ida.status_inventario = 'P'
		 AND   	    mcr.oracle_ef != '03MTC'
		 FOR UPDATE OF IDA.STATUS_INVENTARIO;

      CURSOR hijos_sin_papa (p_org_id IN NUMBER, p_date IN DATE)
      IS
         SELECT xmt.mmt_transaction_id transaction_id
              , xmt.mmt_inventory_item_id item_id
              , xmt.reqh_requisition_header_id req_header_id
              , xmt.reql_attribute3_cr oracle_cr
              , xmde.legacy_ef legacy_ef
              , xmde.legacy_cr legacy_cr
              , xmde.oracle_ef                         /*-- CHG-38343 --*/
              , xmt.msi_segment1_no_articulo item_number
              , xmt.msi_descripcion description
              , xmt.msi_attribute1_uso attribute1
              , xmt.msi_attribute2_mae_activo attribute2
              , xmt.msi_attribute6_parent_hijos attribute6
              , xmt.msi_attribute7_mae_tipo attribute7
              , xmt.rl_line_id trn_source_line_id
              , DECODE (xmt.msi_attribute1_uso, '04', xmt.msi_attribute2_mae_activo, NULL) item_type
-- JP 12.2.4 ppr              , DECODE (xmt.af_oracle_cia, '099', 3, 1) sa_state
              , DECODE (xmt.af_oracle_cia, '00099', 3, 1) sa_state      -- JP 12.2.4 ppr
                --  GDS 15-jul-2010                     , xmt.reqh_requisition_header_id header_number
              , xmt.rh_header_id                   header_number
              , xmt.rl_attribute1_req_line_id line_number
              , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY') creation_date
              , ABS (xmt.mmt_transaction_quantity) quantity
              , xmt.mmt_actual_cost item_cost
              , DECODE (xmde.oracle_cia
                      , '00099', NULL
                      , DECODE (apc.tax_rate, 0, NULL, ((xmt.mmt_actual_cost) * (apc.tax_rate / 100)))
                        ) tax_rate
              , xmt.mmt_creation_date transaction_date
              , 'AFALT01.' || xmde.legacy_ef || '_' || TO_CHAR (TRUNC (p_date), 'YYMMDD') interface_type
         --FROM 	xxfc.xxinv_material_trx_temp xmt
         FROM   apps.xxinv_material_trx_temp xmt    -- Upgrade R12.2.4 Cambia esquema de la tabla a APPS by GTIM
              , xxfc_maestro_de_crs_v xmde
              ,(SELECT 	tax_rate
					  , enabled_flag
					  , name                                  --R12 UPGRADE  ADDED BY  BHAVYA SHARMA 16-JULY-2008
                FROM	ap_tax_codes_all                 -- R12 UPG BY EDGAR VILLAGRAN 2008-11-06    AP_TAX_CODES
                WHERE 	1 = 1
                AND 	enabled_flag = 'Y'
                AND 	SYSDATE BETWEEN NVL (start_date, SYSDATE - 1) AND NVL (inactive_date, SYSDATE + 1)
                AND 	tax_type = 'AWT'
                UNION
                SELECT 	b.percentage_rate tax_rate
                      , b.active_flag enabled_flag
                      , b.tax_rate_code NAME
                FROM    zx_taxes_b a, zx_rates_b b, zx_party_tax_profile c
                WHERE                                                             --B.TAX_RATE_CODE = PCVATNAME
                        b.active_flag = 'Y'
                AND     a.tax_type_code <> 'AWT'
                AND     a.tax = b.tax
                AND     a.tax_regime_code = b.tax_regime_code
                AND     a.content_owner_id = b.content_owner_id
                AND     b.content_owner_id = c.party_tax_profile_id
-- JP 12.2.4                AND 	c.party_type_code = 'OU'
                AND     c.party_type_code = 'GCO'
                AND     SYSDATE BETWEEN NVL (b.effective_from, SYSDATE - 1) AND NVL (b.effective_to, SYSDATE + 1)) apc
         --inicio ChO ***51967670***
         WHERE 	--xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND 	xmt.mmt_transaction_action_id = 1
         --AND 	xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND    xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         --Fin ChO ***51967670***
         AND 	xmde.oracle_cr = xmt.reql_attribute3_cr
         AND 	xmde.oracle_cr_superior = xmt.reql_attribute2_crsup
         AND 	xmde.oracle_ef = xmt.af_oracle_ef
         AND 	xmde.estado = 'A'
-- JP 12.2.4         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, '0% IVA')
         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, 'TASA-0%IVA')
         AND 	apc.enabled_flag = 'Y'
         AND 	NVL (xmt.msi_attribute7_mae_tipo, 'XXX') = 'KIT'
         AND 	xmde.oracle_cr_type != 'P'
         AND 	xmt.msi_attribute1_uso = '01'
         AND 	NVL (msi_attribute8_mae_yn, 'N') != 'Y'
         AND 	NVL (af_tipo_uso_convertido, 'XX') = 'XX'
         AND 	mmt_organization_id = p_org_id
         AND 	TRUNC (mmt_creation_date) = TRUNC (p_date)
         FOR UPDATE OF af_interface_type;
      CURSOR gpototal_gasto (p_org_id IN NUMBER, p_date IN DATE)
      IS
         SELECT	xmt.mmt_transaction_id transaction_id
              , xmt.mmt_inventory_item_id item_id
              , xmt.reqh_requisition_header_id req_header_id
              , xmt.reql_attribute3_cr oracle_cr
              , xmde.legacy_ef legacy_ef
              , xmde.legacy_cr legacy_cr
              , xmde.oracle_ef                         /*-- CHG-38343 --*/
              , xmt.msi_segment1_no_articulo item_number
              , xmt.msi_descripcion description
              , xmt.msi_attribute1_uso attribute1
              , xmt.msi_attribute2_mae_activo attribute2
              , xmt.msi_attribute6_parent_hijos attribute6
              , xmt.msi_attribute7_mae_tipo attribute7
              , xmt.rl_line_id trn_source_line_id
              , DECODE (xmt.msi_attribute1_uso, '04', xmt.msi_attribute2_mae_activo, NULL) item_type
-- JP 12.2.4 ppr              , DECODE (xmt.af_oracle_cia, '099', 3, 1) sa_state  -- JP 12.2.4 ppr
              , DECODE (xmt.af_oracle_cia, '00099', 3, 1) sa_state
              --  GDS 15-jul-2010                     , xmt.reqh_requisition_header_id header_number
              , xmt.rh_header_id                   header_number
              , xmt.rl_attribute1_req_line_id line_number
              , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY') creation_date
              , ABS (xmt.mmt_transaction_quantity) quantity
              , xmt.mmt_actual_cost item_cost
              , DECODE (xmde.oracle_cia
-- JP 12.2.4 ppr                      , '099', NULL
                      , '00099', NULL   -- JP 12.2.4 ppr
                      , DECODE (apc.tax_rate, 0, NULL, ((xmt.mmt_actual_cost) * (apc.tax_rate / 100)))
                       ) tax_rate
              , xmt.mmt_creation_date transaction_date
              , 'AFALT01.' || xmde.legacy_ef || '_' || TO_CHAR (TRUNC (p_date), 'YYMMDD') interface_type
         FROM	  xxinv_material_trx_temp xmt
              , xxfc_maestro_de_crs_v xmde
              ,(SELECT 	tax_rate
                      , enabled_flag
                      , name                                  --R12 UPGRADE  ADDED BY  BHAVYA SHARMA 16-JULY-2008
                FROM	ap_tax_codes_all                 -- R12 UPG BY EDGAR VILLAGRAN 2008-11-06    AP_TAX_CODES
                WHERE 	1 = 1
                AND 	enabled_flag = 'Y'
                AND 	SYSDATE BETWEEN NVL (start_date, SYSDATE - 1) AND NVL (inactive_date, SYSDATE + 1)
                AND 	tax_type = 'AWT'
                UNION
                SELECT 	b.percentage_rate tax_rate
                      , b.active_flag enabled_flag
                      , b.tax_rate_code name
                FROM 	zx_taxes_b a, zx_rates_b b, zx_party_tax_profile c
                WHERE                                                             --B.TAX_RATE_CODE = PCVATNAME
                        b.active_flag = 'Y'
                AND 	a.tax_type_code <> 'AWT'
                AND 	a.tax = b.tax
                AND 	a.tax_regime_code = b.tax_regime_code
                AND 	a.content_owner_id = b.content_owner_id
                AND 	b.content_owner_id = c.party_tax_profile_id
-- JP 12.2.4                AND 	c.party_type_code = 'OU'
                AND 	c.party_type_code = 'GCO'
                AND 	SYSDATE BETWEEN NVL (b.effective_from, SYSDATE - 1) AND NVL (b.effective_to, SYSDATE + 1)) apc
         --inicio ChO ***51967670***
         WHERE 	--xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND 	xmt.mmt_transaction_action_id = 1
         --AND 	xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND    xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         --Fin ChO ***51967670***
         AND 	xmde.oracle_cr = xmt.reql_attribute3_cr
         AND 	xmde.oracle_cr_superior = xmt.reql_attribute2_crsup
         AND 	xmde.oracle_ef = xmt.af_oracle_ef
         AND 	xmde.estado = 'A'
-- JP 12.2.4         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, '0% IVA')
         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, 'TASA-0%IVA')
         AND 	apc.enabled_flag = 'Y'
         AND 	NVL (xmt.msi_attribute7_mae_tipo, 'xxxxxxxx') = 'GPOTOTAL'
         AND 	xxinv_item_fixed_asset_web_pkg.check_item_attribute (xmt.mmt_organization_id
                                                                   , xmt.mmt_inventory_item_id
                                                                   , xmt.reqh_requisition_header_id
                                                                   , xmt.rl_attribute1_req_line_id
                                                                     ) != '04'
         AND 	mmt_organization_id = p_org_id
         AND 	TRUNC (mmt_creation_date) = TRUNC (p_date)
         ORDER BY xmt.msi_segment1_no_articulo, xmt.msi_attribute6_parent_hijos, xmt.reql_attribute3_cr
         FOR UPDATE OF af_interface_type;
      CURSOR c_insert_table (p_org_id IN NUMBER, p_date IN DATE)
      IS
         SELECT	xmt.mmt_transaction_id transaction_id
              , xmt.mmt_inventory_item_id item_id
              , xmde.legacy_ef legacy_ef
              , xmde.legacy_cr legacy_cr
              , xmde.oracle_cr                         /*-- CHG-38343 --*/
              , xmde.oracle_ef
              , xmt.msi_segment1_no_articulo item_number
              , xmt.msi_descripcion description
              , xmt.msi_attribute1_uso attribute1
              , xmt.msi_attribute2_mae_activo attribute2
              , xmt.msi_attribute7_mae_tipo attribute7
              , xmt.rl_line_id trn_source_line_id
              , DECODE (xmt.msi_attribute1_uso, '04', xmt.msi_attribute2_mae_activo, NULL) item_type
-- JP 12.2.4 ppr              , DECODE (xmt.af_oracle_cia, '099', 3, 1) sa_state    -- JP 12.2.4 ppr
              , DECODE (xmt.af_oracle_cia, '00099', 3, 1) sa_state    -- JP 12.2.4 ppr
              --  GDS 15-jul-2010
              , xmt.reqh_requisition_header_id req_header_number
              , XMT.RH_HEADER_ID                   HEADER_NUMBER
              , xmt.rl_attribute1_req_line_id line_number
              , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY') creation_date
              , ABS (xmt.mmt_transaction_quantity) quantity
              , xmt.mmt_actual_cost item_cost
              , DECODE (xmde.oracle_cia
-- JP 12.2.4 ppr                      , '099', NULL
                      , '00099', NULL  -- JP 12.2.4 ppr
                      , DECODE (apc.tax_rate, 0, NULL, ((xmt.mmt_actual_cost) * (apc.tax_rate / 100)))
                        ) tax_rate
                      , xmt.mmt_creation_date transaction_date
         FROM	 xxinv_material_trx_temp xmt
              , xxfc_maestro_de_crs_v xmde
              ,(SELECT 	tax_rate
                      , enabled_flag
                      , name                                  --R12 UPGRADE  ADDED BY  BHAVYA SHARMA 16-JULY-2008
                FROM 	ap_tax_codes_all                 -- R12 UPG BY EDGAR VILLAGRAN 2008-11-06    AP_TAX_CODES
                WHERE 	1 = 1
                AND 	enabled_flag = 'Y'
                AND 	SYSDATE BETWEEN NVL (start_date, SYSDATE - 1) AND NVL (inactive_date, SYSDATE + 1)
                AND 	tax_type = 'AWT'
                UNION
                SELECT 	b.percentage_rate tax_rate
                      , b.active_flag enabled_flag
                      , b.tax_rate_code name
                FROM 	zx_taxes_b a, zx_rates_b b, zx_party_tax_profile c
                WHERE                                                             --B.TAX_RATE_CODE = PCVATNAME
						b.active_flag = 'Y'
                AND 	a.tax_type_code <> 'AWT'
                AND 	a.tax = b.tax
                AND 	a.tax_regime_code = b.tax_regime_code
                AND 	a.content_owner_id = b.content_owner_id
                AND 	b.content_owner_id = c.party_tax_profile_id
-- JP 12.2.4                AND 	c.party_type_code = 'OU'
                AND 	c.party_type_code = 'GCO'
                AND 	SYSDATE BETWEEN NVL (b.effective_from, SYSDATE - 1) AND NVL (b.effective_to, SYSDATE + 1)) apc
         --inicio ChO ***51967670***
         WHERE 	--xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND 	xmt.mmt_transaction_action_id = 1
         --AND 	xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND     xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         --Fin ChO ***51967670***
         AND 	xmde.oracle_cr = xmt.reql_attribute3_cr
         AND 	xmde.oracle_cr_superior = xmt.reql_attribute2_crsup
         AND 	xmde.oracle_ef = xmt.af_oracle_ef
         AND 	xmde.estado = 'A'
-- JP 12.2.4         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, '0% IVA')
         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, 'TASA-0%IVA')
         AND 	apc.enabled_flag = 'Y'
         AND 	NVL (xmt.msi_attribute7_mae_tipo, 'xxx') NOT IN ('KIT', 'GPOTOTAL')
         AND 	mmt_organization_id = p_org_id
         AND 	TRUNC (mmt_creation_date) = TRUNC (p_date)
         FOR UPDATE OF af_interface_type;
      CURSOR c_insert_table_gpototal (p_org_id IN NUMBER, p_date IN DATE)
      IS
         SELECT	xmde.legacy_ef legacy_ef
              , xmde.legacy_cr legacy_cr
              , xmde.oracle_cr                         /*-- CHG-38343 --*/
              , xmde.oracle_ef
              , flv.description description
              , DECODE (xmt.msi_attribute1_uso, '04', xmt.msi_attribute2_mae_activo, NULL) item_type
-- JP 12.2.4 ppr              , DECODE (xmt.af_oracle_cia, '099', 3, 1) sa_state
              , DECODE (xmt.af_oracle_cia, '00099', 3, 1) sa_state -- JP 12.2.4 ppr
              --  GDS 15-jul-2010                , MAX (xmt.reqh_requisition_header_id) header_id
              , MAX(xmt.rh_header_id)               header_id
              , MAX (xmt.rl_line_id) line_id
              , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY') creation_date
              , SUM (ABS (xmt.mmt_transaction_quantity)) quantity
              , SUM (xmt.mmt_actual_cost * ABS (xmt.mmt_transaction_quantity)) item_cost
              , SUM (DECODE (xmde.oracle_cia
-- JP 12.2.4 ppr                           , '099', NULL
                           , '00099', NULL       -- JP 12.2.4 ppr
                           , DECODE (apc.tax_rate
                                   , 0, NULL
                                   , (  (xmt.mmt_actual_cost)
                                        * ABS (xmt.mmt_transaction_quantity)
                                        * (apc.tax_rate / 100)
                                       )
                                    )
                            )
                      ) tax_rate
              , 'AFALT' || xmt.msi_attribute1_uso || '.' || xmde.legacy_ef || '_'
                  || TO_CHAR (TRUNC (p_date), 'YYMMDD') interface_type
              --GDS 20-Jul-2010         , reqh_requisition_header_id req_header_id
         FROM 	xxinv_material_trx_temp xmt
-- JP 12.2.4  Inicia
              ,(SELECT ffv.flex_value flex_value_meaning, ffv.description description
                FROM   fnd_flex_value_sets fvs, fnd_flex_values_vl ffv
                WHERE  fvs.flex_value_set_name = 'XXINV_AF_CLAVES'
                AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
				AND    ffv.parent_flex_value_low =  '04'
                AND    ffv.enabled_flag = 'Y')	flv
-- JP 12.2.4 Termina
              , xxfc_maestro_de_crs_v xmde
-- JP 12.2.4              , fnd_flex_values_vl flv
              ,(SELECT 	tax_rate
                      , enabled_flag
                      , name                                       --R12 UPGRADE  ADDED BY  BHAVYA SHARMA 16-JULY-2008
                FROM	ap_tax_codes_all                      -- R12 UPG BY EDGAR VILLAGRAN 2008-11-06    AP_TAX_CODES
                WHERE 	1 = 1
                AND 	enabled_flag = 'Y'
                AND 	SYSDATE BETWEEN NVL (start_date, SYSDATE - 1) AND NVL (inactive_date, SYSDATE + 1)
                AND 	tax_type = 'AWT'
                UNION
                SELECT 	b.percentage_rate tax_rate
                      , b.active_flag enabled_flag
                      , b.tax_rate_code name
                FROM 	zx_taxes_b a, zx_rates_b b, zx_party_tax_profile c
                WHERE                                                                  --B.TAX_RATE_CODE = PCVATNAME
                        b.active_flag = 'Y'
                AND 	a.tax_type_code <> 'AWT'
                AND 	a.tax = b.tax
                AND 	a.tax_regime_code = b.tax_regime_code
                AND 	a.content_owner_id = b.content_owner_id
                AND 	b.content_owner_id = c.party_tax_profile_id
-- JP 12.2.4                AND 	c.party_type_code = 'OU'
                AND 	c.party_type_code = 'GCO'
                AND 	SYSDATE BETWEEN NVL (b.effective_from, SYSDATE - 1) AND NVL (b.effective_to, SYSDATE + 1)) apc
         --inicio ChO ***51967670***
         WHERE     --xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND     xmt.mmt_transaction_action_id = 1
         --AND     xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND    xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         --Fin ChO ***51967670***
         AND 	xmde.oracle_cr = xmt.reql_attribute3_cr
         AND 	xmde.oracle_cr_superior = xmt.reql_attribute2_crsup
         AND 	xmde.oracle_ef = xmt.af_oracle_ef
         AND 	xmde.estado = 'A'
-- JP 12.2.4         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, '0% IVA')
         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, 'TASA-0%IVA')
         AND 	apc.enabled_flag = 'Y'
         AND 	NVL (xmt.msi_attribute7_mae_tipo, 'XXX') = 'GPOTOTAL'
         AND 	flv.flex_value_meaning = xmt.msi_attribute2_mae_activo
-- JP 12.2.4         AND 	flv.parent_flex_value_low = '04'
-- JP 12.2.4         AND 	flex_value_set_id  = '1008151'
         AND 	xxinv_item_fixed_asset_web_pkg.check_item_attribute (xmt.mmt_organization_id
                                                                   , xmt.mmt_inventory_item_id
                                                                   , xmt.reqh_requisition_header_id
                                                                   , xmt.rl_attribute1_req_line_id
                                                                     ) = '04'
         AND 	mmt_organization_id = p_org_id
         AND 	TRUNC (mmt_creation_date) = TRUNC (p_date)
         -- CHO 51413405 08.oct.2013: Los enseres menores que corresponden a departamentos de plaza (gasto) no deben generar activo
         -- Inicia CHO 51413405: Se comenta la validaci�n distinto a 17ADM y se agrega validacion con los CR que debe considerar
         /*-- NO debe armar grupo para departamentos de OS
         AND 	xmt.reql_attribute2_crsup != '17ADM'*/
         AND  ( (TO_NUMBER(SUBSTR(xmde.oracle_cr,1,2)) BETWEEN 50 AND 80) OR (TO_NUMBER(SUBSTR(xmde.oracle_cr,1,2))) = 10 )
         -- Finaliza CHO 51413405
         GROUP BY xmde.legacy_ef
                , xmde.legacy_cr
                , xmde.oracle_cr                         /*-- CHG-38343 --*/
                , xmde.oracle_ef
                , flv.description
                , DECODE (xmt.msi_attribute1_uso, '04', xmt.msi_attribute2_mae_activo, NULL)
-- JP 12.2.4 ppr                , DECODE (xmt.af_oracle_cia, '099', 3, 1)
                , DECODE (xmt.af_oracle_cia, '00099', 3, 1)   -- JP 12.2.4 ppr
                , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY')
                , 'AFALT' || xmt.msi_attribute1_uso || '.' || xmde.legacy_ef || '_'
                  || TO_CHAR (TRUNC (p_date), 'YYMMDD');
                --  GDS 15-jul-2010                , reqh_requisition_header_id;
      CURSOR c_insert_kit (p_org_id IN NUMBER, p_date IN DATE)
      IS
         SELECT xmt.msi_attribute4_parent_mand parent_item_number
              , SUM (ABS (xmt.mmt_transaction_quantity)) qty
              , xmt.msi_attribute2_mae_activo attr2
              , xmde.oracle_cr_superior
              , xmde.oracle_ef
              , xmt.reql_attribute3_cr oracle_cr
              , xmde.legacy_ef legacy_ef
              , xmde.legacy_cr legacy_cr
-- JP 12.2.4 ppr              , DECODE (xmt.af_oracle_cia, '099', 3, 1) sa_state
              , DECODE (xmt.af_oracle_cia, '00099', 3, 1) sa_state   -- JP 12.2.4 ppr
              , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY') creation_date
              , apc.tax_rate tax_rate
              , 'AFALT' || xmt.msi_attribute1_uso || '.' || xmde.legacy_ef || '_'
                || TO_CHAR (TRUNC (p_date), 'YYMMDD') interface_type
         FROM   xxinv_material_trx_temp xmt
              , xxfc_maestro_de_crs_v xmde
              ,(SELECT  tax_rate
                      , enabled_flag
                      , NAME                                       --R12 UPGRADE  ADDED BY  BHAVYA SHARMA 16-JULY-2008
                FROM    ap_tax_codes_all                      -- R12 UPG BY EDGAR VILLAGRAN 2008-11-06    AP_TAX_CODES
                WHERE   1 = 1
                AND     enabled_flag = 'Y'
                AND     SYSDATE BETWEEN NVL (start_date, SYSDATE - 1) AND NVL (inactive_date, SYSDATE + 1)
                AND     tax_type = 'AWT'
                UNION
                SELECT  b.percentage_rate tax_rate
                      , b.active_flag enabled_flag
                      , b.tax_rate_code NAME
                FROM    zx_taxes_b a, zx_rates_b b, zx_party_tax_profile c
                WHERE                                                                  --B.TAX_RATE_CODE = PCVATNAME
                        b.active_flag = 'Y'
                AND     a.tax_type_code <> 'AWT'
                AND     a.tax = b.tax
                AND     a.tax_regime_code = b.tax_regime_code
                AND     a.content_owner_id = b.content_owner_id
                AND     b.content_owner_id = c.party_tax_profile_id
-- JP 12.2.4                AND 	c.party_type_code = 'OU'
                AND     c.party_type_code = 'GCO'
                AND     SYSDATE BETWEEN NVL (b.effective_from, SYSDATE - 1) AND NVL (b.effective_to, SYSDATE + 1)) apc
         --inicio ChO ***51967670***
         WHERE     --xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND     xmt.mmt_transaction_action_id = 1
         --AND     xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND    xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         --Fin ChO ***51967670***
         AND    xmde.oracle_cr = xmt.reql_attribute3_cr
         AND    xmde.oracle_cr_superior = xmt.reql_attribute2_crsup
         AND    xmde.oracle_ef = xmt.af_oracle_ef
         AND    xmde.estado = 'A'
-- JP 12.2.4         AND 	apc.name = NVL (xmt.msi_purchasing_tax_code, '0% IVA')
         AND    apc.NAME = NVL (xmt.msi_purchasing_tax_code, 'TASA-0%IVA')
         AND    apc.enabled_flag = 'Y'
         AND    msi_attribute8_mae_yn = 'Y'
         AND    mmt_organization_id = p_org_id
         AND    TRUNC (mmt_creation_date) = TRUNC (p_date)
         GROUP BY xmt.msi_attribute4_parent_mand
                , xmt.msi_attribute2_mae_activo
                , xmde.oracle_cr_superior
                , xmde.oracle_ef
                , xmt.reql_attribute3_cr
                , xmde.legacy_ef
                , xmde.legacy_cr
-- JP 12.2.4                , DECODE (xmt.af_oracle_cia, '099', 3, 1)
                , DECODE (xmt.af_oracle_cia, '00099', 3, 1)  -- JP 12.2.4 ppr
                , TO_CHAR (TRUNC (xmt.mmt_creation_date), 'DD-MON-YYYY')
                , 'AFALT' || xmt.msi_attribute1_uso || '.' || xmde.legacy_ef || '_'
                  || TO_CHAR (TRUNC (p_date), 'YYMMDD')
                ,
                  ------ para que incluya el armado de kits en todas las salidas de un cr
                  apc.tax_rate;                                                    -------,  REQH_REQUISITION_HEADER_ID;
      t_seq_num           NUMBER;
      t_count             NUMBER;
      t_count1            NUMBER;
      t_qty               NUMBER;
      t_cost              NUMBER;
      t_tax_rate          NUMBER;
      t_change_attr1      VARCHAR2 (10);
      t_chk_attr1         VARCHAR2 (10);
      c_descr             VARCHAR2 (100);
      t_sa_state          VARCHAR2 (10);
      t_header_id         NUMBER;
      t_line_id           NUMBER;
      t_interface_type    VARCHAR2 (100);
      t_mo_order          NUMBER;
      t_parent_itm        NUMBER;
      t_child_item        NUMBER;
      t_mo_qty            NUMBER;
      t_qty_saldo         NUMBER (15, 2);
      w_item              VARCHAR (40)                                           := NULL;
      w_padre             VARCHAR (150)                                          := NULL;
      w_oracle_cr         VARCHAR (5)                                            := NULL;
      w_nokit             BOOLEAN                                                := FALSE;
      w_accounting_date   DATE;
      -- // Oracle Fixed Assets Variables     PRR-JUN2010
      l_interface_type    xxinv_issue_fixed_asset_web.interface_type%TYPE   := NULL;
      l_status            VARCHAR2(2);
   BEGIN
      retcode := 0;
      w_accounting_date := TRUNC (fnd_conc_date.string_to_date (p_date));
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('DETAIL GPOTOTAL Items', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('---------------------------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'DETAIL GPOTOTAL Items');
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      fnd_file.put_line (fnd_file.LOG, 't_seq_num :'||t_seq_num);  -- JP DEBUG
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      l_status:=NULL;
      FOR i IN c_insert_table_gpototal_det (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN c_insert_table_gpototal_det%NOTFOUND;
         t_count := t_count + 1;
      fnd_file.put_line (fnd_file.LOG, 't_count :'||t_count);  -- JP DEBUG
         /*   PRR16122009                    < ini >   */
         l_interface_type :=
            xxinv_item_fixed_asset_web_pkg.ofa_valid_iface_code (p_cursor_code         => 'C_INSERT_TABLE_GPOTOTAL_DET'
                                                               , p_legacy_ef           => i.legacy_ef
                                                               , p_interface_type      => i.interface_type
                                                                );

         /*   PRR16122009                    < fin >   */

         --SRV13072010 AGREGADO
      fnd_file.put_line (fnd_file.LOG, 'l_interface_type :'||l_interface_type);  -- JP DEBUG
         IF substr(l_interface_type,1,6)='AFSORA' THEN
            l_status:='Y';
         ELSE
            l_status:='L';
         END IF;
         --SRV13072010 FIN
         INSERT INTO xxinv_issue_fixed_asset_web
                     (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num
                    , header_id, line_number, creation_date, quantity, item_cost, cost_tax
                    , interface_type, wm_status, oracle_ef, oracle_cr                    /*-- CHG-38343 --*/
                     )
         VALUES (i.legacy_ef, i.legacy_cr, i.item_number, i.description, i.item_type, i.sa_state, t_seq_num
                    , i.header_number, i.line_number, i.creation_date, i.quantity, i.item_cost, i.tax_rate
                    -- // PRR-JUN2010  Modif Line
                    -- , i.interface_type, 'L'
                    --SRV13072010 COMMENT
         ,          --  l_interface_type, 'L'
                    --SRV13072010 Add line
                      l_interface_type, l_status, i.oracle_ef, i.oracle_cr              /*-- CHG-38343 --*/
                     );

         fnd_file.put_line (fnd_file.output
                          ,    RPAD (i.legacy_ef, 15, ' ')
                            || RPAD (i.legacy_cr, 15, ' ')
                            || RPAD (i.item_number, 15, ' ')
                            || RPAD (i.description, 40, ' ')
                            || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                            || RPAD (i.sa_state, 10, ' ')
                            || RPAD (t_seq_num, 10, ' ')
                            || RPAD (i.header_number, 12, ' ')
                            || RPAD (i.line_number, 10, ' ')
                            || RPAD (i.creation_date, 15, ' ')
                            || RPAD (NVL (i.quantity, 0), 12, ' ')
                            || RPAD (NVL (i.item_cost, 0), 20, ' ')
                            || RPAD (NVL (i.tax_rate, 0), 20, ' ')
                            -- // PRR-JUN2010  Modif Line
                            -- || RPAD (i.interface_type, 30, ' ')
                            || RPAD (l_interface_type, 30, ' ')
                           );
      END LOOP;
      IF t_count = 0 THEN
         fnd_file.put_line (fnd_file.output
                          ,    'No data found to Insert into the Temporary table XXINV_ISSUE_FIXED_ASSET_WEB :'
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );
         retcode := 1;
      END IF;

      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('          DEVOLUCIONES           ', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('---------------------------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fecha salida', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'DETAIL RETURN TO STORE');
      devoluciones (p_date => p_date, p_org_id =>p_org_id, p_retcode => retcode);
      COMMIT;
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      --SRV09JUL2010 ADD LINE
      l_status:=NULL;
      FOR i IN c_dev  LOOP
         EXIT WHEN c_dev%NOTFOUND;
         t_count := t_count + 1;

         --- Obtiene la descripcion del activo
         SELECT MAX(ffv.description)  INTO c_descr
         FROM   fnd_flex_value_sets fvs
               ,fnd_flex_values_vl ffv
         WHERE  fvs.flex_value_set_name = 'XXINV_AF_CLAVES'
         AND    fvs.flex_value_set_id   = ffv.flex_value_set_id
         AND    NVL(ffv.enabled_flag,'Y') = 'Y'
         AND    ffv.parent_flex_value_low= '04'
         AND    ffv.flex_value          = i.item_type   ;

         -- CHO 51413405 08.oct.2013: Se elimina la validacion de si una plaza es Legacy u Oracle
         -- Inicia CHO 51413405
         --- Determina si el EF esta en Oracle Activos  o Legacy
         /*SELECT count(*) INTO t_count1
           FROM fnd_flex_value_sets a, fnd_flex_values b
          WHERE a.flex_value_set_name = 'XXFC_FA_EF_ACTIVO_ORACLE_ALM'
            AND a.flex_value_set_id = b.flex_value_set_id
            AND b.enabled_flag = 'Y'
            AND TRIM (b.flex_value) = i.oracle_ef;

         IF t_count1 = 0  THEN
            l_status := 'L' ;
            l_interface_type := 'AFDEV'|| i.legacy_ef || '_' || TO_CHAR (TRUNC (p_date), 'YYMMDD');
         ELSE*/
            l_status := 'Y' ;
            l_interface_type := 'AFORA'|| i.legacy_ef || '_' || TO_CHAR (TRUNC (p_date), 'YYMMDD');
            UPDATE  XXFC_INV_DEVOLUCION_ALMACEN  SET STATUS_INVENTARIO = NULL WHERE CURRENT OF c_dev;
         --END IF; -- CHO 51413405 08.oct.2013: Se comenta
         -- Finaliza CHO 51413405

         INSERT INTO xxinv_issue_fixed_asset_web
                  (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num
                  ,header_id, line_number, creation_date, quantity, item_cost, cost_tax
                  ,interface_type, wm_status, oracle_ef, oracle_cr
                  )
         VALUES (i.legacy_ef, i.legacy_cr, null, c_descr, i.item_type, i.sa_state, t_seq_num
                  , i.header_number, null, i.fecha_salida, 1, i.item_cost, null
                  ,l_interface_type, l_status, i.oracle_ef, i.oracle_cr
                  );
         fnd_file.put_line (fnd_file.output
                          ,    RPAD (i.legacy_ef, 15, ' ')
                            || RPAD (i.legacy_cr, 15, ' ')
                            || RPAD (' ', 15, ' ')
                            || RPAD (c_descr, 40, ' ')
                            || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                            || RPAD (i.sa_state, 10, ' ')
                            || RPAD (t_seq_num, 10, ' ')
                            || RPAD (i.header_number, 12, ' ')
                            || RPAD (' ', 10, ' ')
                            || RPAD (i.fecha_salida, 15, ' ')
                            || RPAD (1, 12, ' ')
                            || RPAD (NVL (i.item_cost, 0), 20, ' ')
                            || RPAD (' ', 20, ' ')
                            || RPAD (l_interface_type, 30, ' ')
                           );

      END LOOP;
      DELETE  XXFC_INV_DEVOLUCION_ALMACEN
      WHERE   status_inventario = 'P';
      COMMIT;
      IF t_count = 0 THEN
         fnd_file.put_line (fnd_file.output
                          ,    'No data found to Insert into the Temporary table XXINV_ISSUE_FIXED_ASSET_WEB :'
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );
         retcode := 1;
      END IF;
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      fnd_file.put_line (fnd_file.LOG, 'line 1.1');
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('Articulo hijos sin padre en la orden', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('--------------------------------------------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'HIJOS SIN PAPA');
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      l_status:=NULL;
      FOR i IN hijos_sin_papa (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN hijos_sin_papa%NOTFOUND;
         fnd_file.put_line (fnd_file.LOG, '  ');
         fnd_file.put_line (fnd_file.LOG, ' i.ITEM_NUMBER : ' || i.item_number);
         fnd_file.put_line (fnd_file.LOG, ' i.ATTRIBUTE6 : ' || i.attribute6);
         fnd_file.put_line (fnd_file.LOG, ' i.ORACLE_CR : ' || i.oracle_cr);
         fnd_file.put_line (fnd_file.LOG, ' i.req_header_id : ' || i.req_header_id);
         fnd_file.put_line (fnd_file.LOG, ' i.Quantity      : ' || i.quantity);

         /*   PRR-JUN2010                    < ini >   */
         ---SRV09JUL2010 COMMENT  LINE
         ---SRV09JUL2010  IF i.attribute1 = '04' THEN
         l_interface_type :=
               ofa_valid_iface_code (p_cursor_code         => 'HIJOS_SIN_PAPA'
                                   , p_legacy_ef           => i.legacy_ef
                                   , p_interface_type      => i.interface_type
                                    );
         --SRV09JUL2010 COMMENT LINE
         --  ELSE
         --SRV09JUL2010 COMMENT LINE
         --     l_interface_type := i.interface_type;
         --SRV09JUL2010 COMMENT LINE
         --  END IF;
         /*   PRR-JUN2010                    < fin >   */

         ---SRV09JUL2010 ADD LINES <INICIO>
         IF substr(l_interface_type,1,7)='AFORA04' OR substr(l_interface_type,1,5)='AFALT' THEN
            l_status:='L';
         ELSE
            l_status:='Y';
         END IF;


         ---SRV09JUL2010 ADD LINES <FIN>
         INSERT INTO xxinv_issue_fixed_asset_web
                     (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num
                    , header_id, line_number, creation_date, quantity, item_cost, cost_tax
                    , interface_type, wm_status, oracle_ef, oracle_cr              /*-- CHG-38343 --*/
                     )
         VALUES (i.legacy_ef, i.legacy_cr, i.item_number, i.description, i.item_type, i.sa_state, t_seq_num
                    , i.header_number, i.line_number, i.creation_date, i.quantity, i.item_cost, i.tax_rate
                    -- // PRR-JUN2010 Modif Line
                    -- , i.interface_type, 'L'
                    --SRV09JUL2010 COMMENT LINE
                    --, l_interface_type, 'L'
                    --SRV09JUL2010 ADD LINE
                    , l_interface_type, l_status, i.oracle_ef, i.oracle_cr              /*-- CHG-38343 --*/
                     );

         fnd_file.put_line (fnd_file.output
                          ,    RPAD (i.legacy_ef, 15, ' ')
                            || RPAD (i.legacy_cr, 15, ' ')
                            || RPAD (i.item_number, 15, ' ')
                            || RPAD (i.description, 40, ' ')
                            || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                            || RPAD (i.sa_state, 10, ' ')
                            || RPAD (t_seq_num, 10, ' ')
                            || RPAD (i.header_number, 12, ' ')
                            || RPAD (i.line_number, 10, ' ')
                            || RPAD (i.creation_date, 15, ' ')
                            || RPAD (NVL (i.quantity, 0), 12, ' ')
                            || RPAD (NVL (i.item_cost, 0), 20, ' ')
                            || RPAD (NVL (i.tax_rate, 0), 20, ' ')
                            -- // PRR-JUN2010 Modif Line
                            -- || RPAD (i.interface_type, 30, ' ')
                            || RPAD (l_interface_type, 30, ' ')
                           );

         UPDATE xxinv_material_trx_temp
             -- // PRR-JUN2010 Modif Line
             -- SET af_interface_type = i.interface_type
         SET    af_interface_type = l_interface_type
         WHERE  CURRENT OF hijos_sin_papa;
      END LOOP;                                                                                         --hijos_sin_papa
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      fnd_file.put_line (fnd_file.LOG, 'line 1.1');
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('GPOTOTAL contabiliza al gasto', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('--------------------------------------------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'GPOTOTAL al Gasto');
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      -- // SRV-09JUL2010 add Line
      l_status:=NULL ;
      FOR i IN gpototal_gasto (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN gpototal_gasto%NOTFOUND;
         fnd_file.put_line (fnd_file.LOG, '  ');
         fnd_file.put_line (fnd_file.LOG, ' i.ITEM_NUMBER : ' || i.item_number);
         fnd_file.put_line (fnd_file.LOG, ' W.ITEM : ' || w_item);

         --SRV09JUL2010 add line
         l_interface_type := i.interface_type;
         /*   PRR-JUN2010                    < ini >   */
         l_interface_type :=
            ofa_valid_iface_code (p_cursor_code         => 'GPOTOTAL_GASTO'
                                , p_legacy_ef           => i.legacy_ef
                                --SRV09JUL2010 COMMENTS LINE
                                --, p_interface_type      => t_interface_type
                                --SRV09JUL2010 ADD LINE
                                , p_interface_type      => l_interface_type
                                 );

         IF substr(l_interface_type,1,5)='AFORA' THEN
            l_status:='Y';
         ELSE
            l_status:='L';
         END IF;
         /*   PRR-JUN2010                    < fin >   */
         INSERT INTO xxinv_issue_fixed_asset_web
                     (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num
                    , header_id, line_number, creation_date, quantity, item_cost, cost_tax
                    , interface_type, wm_status, oracle_ef, oracle_cr              /*-- CHG-38343 --*/
                     )
         VALUES (i.legacy_ef, i.legacy_cr, i.item_number, i.description, i.item_type, i.sa_state, t_seq_num
                    , i.header_number, i.line_number, i.creation_date, i.quantity, i.item_cost, i.tax_rate
                    -- // PRR-JUN2010  Modif Line
                    -- , i.interface_type, 'L'
                    --SRV09JUL2010 COMMENT LINE
         ,          --  l_interface_type, 'L'
                    --SRV09JUL2010 ADD LINE
                      l_interface_type, l_status, i.oracle_ef, i.oracle_cr              /*-- CHG-38343 --*/
                     );

         fnd_file.put_line (fnd_file.output
                          ,    RPAD (i.legacy_ef, 15, ' ')
                            || RPAD (i.legacy_cr, 15, ' ')
                            || RPAD (i.item_number, 15, ' ')
                            || RPAD (i.description, 40, ' ')
                            || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                            || RPAD (i.sa_state, 10, ' ')
                            || RPAD (t_seq_num, 10, ' ')
                            || RPAD (i.header_number, 12, ' ')
                            || RPAD (i.line_number, 10, ' ')
                            || RPAD (i.creation_date, 15, ' ')
                            || RPAD (NVL (i.quantity, 0), 12, ' ')
                            || RPAD (NVL (i.item_cost, 0), 20, ' ')
                            || RPAD (NVL (i.tax_rate, 0), 20, ' ')
                            -- // PRR-JUN2010  Modif Line
                            -- || RPAD (i.interface_type, 30, ' ')
                            || RPAD (l_interface_type, 30, ' ')
                           );

         UPDATE xxinv_material_trx_temp
            -- // PRR-JUN2010   Modif Line
            -- SET af_interface_type = i.interface_type
         SET    af_interface_type = l_interface_type
         WHERE  CURRENT OF gpototal_gasto;
      END LOOP;                                                                                         --gpototal gasto
      fnd_file.put_line (fnd_file.LOG, 'line 2');
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('Items Other Then GPOTOTAL/KIT and asset type <> 04', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('--------------------------------------------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'Items Other Then GPOTOTAL/KIT and asset type <> 04');
      FOR i IN c_insert_table (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN c_insert_table%NOTFOUND;
         -- Verify the change of attribute
--  GDS 15-jul-2010       ***
         t_chk_attr1 :=
              xxinv_item_fixed_asset_web_pkg.check_item_attribute (p_org_id, i.item_id, i.req_header_number, i.line_number);
         IF t_chk_attr1 != '04'
         THEN
            t_count := t_count + 1;
            t_interface_type :=
                   'AFALT' || t_chk_attr1 || '.' || i.legacy_ef || '_' || TO_CHAR (TRUNC (w_accounting_date), 'YYMMDD');

         /*   SRV02JUL2010                    < Inicio >   */
            l_interface_type :=
            xxinv_item_fixed_asset_web_pkg.ofa_valid_iface_code (p_cursor_code         => 'C_INSERT_TABLE'
                                                               , p_legacy_ef           => i.legacy_ef
                                                               , p_interface_type      => t_interface_type
                                                                );

         /*   SRV02JUL2010                    < fin >   */
            IF substr(l_interface_type,1,5)='AFORA' THEN
               l_status:='Y';
            ELSE
               l_status:='L';
            END IF;
            INSERT INTO xxinv_issue_fixed_asset_web
                        (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num
                       , header_id, line_number, creation_date, quantity, item_cost, cost_tax
                       , interface_type, wm_status, oracle_ef, oracle_cr              /*-- CHG-38343 --*/
                        )
            VALUES (i.legacy_ef, i.legacy_cr, i.item_number, i.description, i.item_type, i.sa_state, t_seq_num
                       , i.header_number, i.line_number, i.creation_date, i.quantity, i.item_cost, i.tax_rate
                       -- // SRV-JUN2010 Modif Line
                    --, t_interface_type, 'L'
                      , l_interface_type, l_status, i.oracle_ef, i.oracle_cr              /*-- CHG-38343 --*/
                        );

            fnd_file.put_line (fnd_file.output
                             ,    RPAD (i.legacy_ef, 15, ' ')
                               || RPAD (i.legacy_cr, 15, ' ')
                               || RPAD (i.item_number, 15, ' ')
                               || RPAD (i.description, 40, ' ')
                               || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                               || RPAD (i.sa_state, 10, ' ')
                               || RPAD (t_seq_num, 10, ' ')
                               || RPAD (i.header_number, 12, ' ')
                               || RPAD (i.line_number, 10, ' ')
                               || RPAD (i.creation_date, 15, ' ')
                               || RPAD (NVL (i.quantity, 0), 12, ' ')
                               || RPAD (NVL (i.item_cost, 0), 20, ' ')
                               || RPAD (NVL (i.tax_rate, 0), 20, ' ')
                               --SRV09JUL2010 COMMENT LINE
                               --|| RPAD (t_interface_type, 30, ' ')
                               --SRV09JUL2010 ADD LINE
                               || RPAD (l_interface_type, 30, ' ')
                              );

            UPDATE  xxinv_material_trx_temp
              -- SRV09JUL2010 COMMENT LINE
              -- SET af_interface_type = t_interface_type
              --SRV09JUL2010 ADD LINE
            SET     af_interface_type = l_interface_type
            WHERE   CURRENT OF c_insert_table;
         END IF;
      END LOOP;
      IF t_count = 0
      THEN
         fnd_file.put_line (fnd_file.output
                          ,    'No data found to Insert into the Temparary table XXINV_ISSUE_FIXED_ASSET_WEB :'
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );
         retcode := 1;
      END IF;
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('Items Other Then GPOTOTAL/KIT and asset type = 04', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('---------------------------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'Items Other Then GPOTOTAL/KIT and asset type = 04');
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      FOR i IN c_insert_table (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN c_insert_table%NOTFOUND;
--  GDS 15-jul-2010       ***
         t_chk_attr1 :=
              xxinv_item_fixed_asset_web_pkg.check_item_attribute (p_org_id, i.item_id, i.req_header_number, i.line_number);
         IF t_chk_attr1 = '04'
         THEN
            t_count := t_count + 1;
            t_interface_type :=
                  'AFALT' || i.attribute1 || '.' || i.legacy_ef || '_' || TO_CHAR (TRUNC (w_accounting_date), 'YYMMDD');
            /*   PRR-JUN2010                    < ini >   */
            l_interface_type :=
               ofa_valid_iface_code (p_cursor_code         => 'C_INSERT_TABLE_STG1'
                                   , p_legacy_ef           => i.legacy_ef
                                   , p_interface_type      => t_interface_type
                                    );

            /*   PRR-JUN2010                    < fin >   */
            INSERT INTO xxinv_issue_fixed_asset_web
                        (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num
                       , header_id, line_number, creation_date, quantity, item_cost, cost_tax
                       , interface_type, wm_status, oracle_ef, oracle_cr              /*-- CHG-38343 --*/
                        )
            VALUES (i.legacy_ef, i.legacy_cr, i.item_number, i.description, i.item_type, i.sa_state, t_seq_num
                       , i.header_number, i.line_number, i.creation_date, i.quantity, i.item_cost, i.tax_rate
                    -- // SRV-JUN2010  Modif Line
                    -- , t_interface_type, 'L'
         ,            l_interface_type, 'L', i.oracle_ef, i.oracle_cr              /*-- CHG-38343 --*/
                        );

            fnd_file.put_line (fnd_file.output
                             ,    RPAD (i.legacy_ef, 15, ' ')
                               || RPAD (i.legacy_cr, 15, ' ')
                               || RPAD (i.item_number, 15, ' ')
                               || RPAD (i.description, 40, ' ')
                               || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                               || RPAD (i.sa_state, 10, ' ')
                               || RPAD (t_seq_num, 10, ' ')
                               || RPAD (i.header_number, 12, ' ')
                               || RPAD (i.line_number, 10, ' ')
                               || RPAD (i.creation_date, 15, ' ')
                               || RPAD (NVL (i.quantity, 0), 12, ' ')
                               || RPAD (NVL (i.item_cost, 0), 20, ' ')
                               || RPAD (NVL (i.tax_rate, 0), 20, ' ')
                               -- // PRR-JUN2010  Modif Line
                               -- || RPAD (t_interface_type, 30, ' ')
                               || RPAD (l_interface_type, 30, ' ')
                              );

            UPDATE  xxinv_material_trx_temp
               -- // PRR-JUN2010  Modif Line
               -- SET af_interface_type = t_interface_type
            SET     af_interface_type = l_interface_type
            WHERE   CURRENT OF c_insert_table;
         END IF;
      END LOOP;
      IF t_count = 0 THEN
         fnd_file.put_line (fnd_file.output
                          ,    'No data found to Insert into the Temparary table XXINV_ISSUE_FIXED_ASSET_WEB :'
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );
         retcode := 1;
      END IF;
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('GPOTOTAL Items', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('--------------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'GPOTOTAL Items');
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      FOR i IN c_insert_table_gpototal (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN c_insert_table_gpototal%NOTFOUND;
         t_count := t_count + 1;
         t_header_id := i.header_id;
         t_line_id := i.line_id;
         /*   PRR-JUN2010                    < ini >   */
         l_interface_type :=
            ofa_valid_iface_code (p_cursor_code         => 'C_INSERT_TABLE_GPOTOTAL'
                                , p_legacy_ef           => i.legacy_ef
                                , p_interface_type      => i.interface_type
                                 );

         /*   PRR-JUN2010                    < fin >   */
         IF substr(l_interface_type,1,7)='AFORA04' OR substr(l_interface_type,1,5)='AFALT' THEN
            l_status:='L';
         ELSE
            l_status:='Y';

         END IF;


         INSERT INTO xxinv_issue_fixed_asset_web
                     (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num, header_id
                    , line_number, creation_date, quantity, item_cost, cost_tax, interface_type, wm_status
                    , oracle_ef, oracle_cr              /*-- CHG-38343 --*/
                     )
         VALUES (i.legacy_ef, i.legacy_cr, NULL, i.description, i.item_type, i.sa_state, t_seq_num, t_header_id
                    , t_line_id, i.creation_date, 1, i.item_cost, i.tax_rate,
                                                                             -- // PRR-JUN2010  Modif Line
                                                                             -- i.interface_type, 'L'
                                                                             l_interface_type,l_status -- SRV19Jul2010 ---'L'
                     , i.oracle_ef, i.oracle_cr              /*-- CHG-38343 --*/
                     );

         fnd_file.put_line (fnd_file.output
                          ,    RPAD (i.legacy_ef, 15, ' ')
                            || RPAD (i.legacy_cr, 15, ' ')
                            || RPAD ('GPOTOTAL', 15, ' ')
                            || RPAD (i.description, 40, ' ')
                            || RPAD (NVL (i.item_type, 'NIL'), 14, ' ')
                            || RPAD (i.sa_state, 10, ' ')
                            || RPAD (t_seq_num, 10, ' ')
                            || RPAD (t_header_id, 12, ' ')
                            || RPAD (t_line_id, 10, ' ')
                            || RPAD (i.creation_date, 15, ' ')
                            || RPAD ('1', 12, ' ')
                            || RPAD (NVL (i.item_cost, 0), 20, ' ')
                            || RPAD (NVL (i.tax_rate, 0), 20, ' ')
                            -- // PRR-JUN2010    Modif Line
                            -- || RPAD (i.interface_type, 30, ' ')
                            || RPAD (l_interface_type, 30, ' ')
                           );
      END LOOP;
      IF t_count = 0 THEN
         fnd_file.put_line
                          (fnd_file.output
                         ,    'No GPOTOTAL data found to Insert into the Temparary table XXINV_ISSUE_FIXED_ASSET_WEB :'
                           || SQLCODE
                           || '-'
                           || SQLERRM
                          );
         retcode := 1;
      ELSE
         BEGIN
            UPDATE  xxinv_material_trx_temp xmt
            SET     af_interface_type = 'GPOTOTAL'
            WHERE   --xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                    xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
            AND     xmt.mmt_transaction_action_id = 1
            --AND     xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
            AND     xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
            AND     NVL (xmt.msi_attribute7_mae_tipo, 'XXX') = 'GPOTOTAL'
            AND     xxinv_item_fixed_asset_web_pkg.check_item_attribute (xmt.mmt_organization_id
                                                                      , xmt.mmt_inventory_item_id
                                                                      , xmt.reqh_requisition_header_id
                                                                      , xmt.rl_attribute1_req_line_id
                                                                       ) = '04';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG
                                , 'Error ocuured while updating the XXINV_MATERIAL_TRX_TEMP:' || SQLCODE || '-'
                                  || SQLERRM
                                 );
               retcode := 2;
         END;
      END IF;
      t_seq_num := xxinv_legacy_seq_pkg.main (p_org_id);
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('Legacy Asset File creation', 60, ' ')
                         || LPAD (RPAD ('Creation Date :', 20, ' '), 60, ' ')
                         || TRUNC (SYSDATE)
                        );
      fnd_file.put_line (fnd_file.output
                       ,    LPAD ('--------------------------', 60, ' ')
                         || LPAD (RPAD ('-------------  ', 20, ' '), 60, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output, LPAD ('KIT ITEMS', 100));
      fnd_file.put_line (fnd_file.output, LPAD ('---------', 100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('legacy Ef', 15, ' ')
                         || RPAD ('Legacy Cr', 15, ' ')
                         || RPAD ('Articulo', 15, ' ')
                         || RPAD ('Descripti�n', 40, ' ')
                         || RPAD ('Articulo Type', 14, ' ')
                         || RPAD ('Sa State', 10, ' ')
                         || RPAD ('Seq Num', 10, ' ')
                         || RPAD ('Header Num', 12, ' ')
                         || RPAD ('Line Num', 10, ' ')
                         || RPAD ('Fetcha Date', 15, ' ')
                         || RPAD ('Quantity', 12, ' ')
                         || RPAD ('Unit Cost', 20, ' ')
                         || RPAD ('Item Tax', 20, ' ')
                         || RPAD ('Interface Type', 30, ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('---------', 15, ' ')
                         || RPAD ('---------', 15, ' ')
                         || RPAD ('--------', 15, ' ')
                         || RPAD ('-----------', 40, ' ')
                         || RPAD ('-------------', 14, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-------', 10, ' ')
                         || RPAD ('----------', 12, ' ')
                         || RPAD ('--------', 10, ' ')
                         || RPAD ('-----------', 15, ' ')
                         || RPAD ('--------', 12, ' ')
                         || RPAD ('---------', 20, ' ')
                         || RPAD ('--------', 20, ' ')
                         || RPAD ('--------------', 30, ' ')
                        );
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.LOG, 'KIT ITEMS');
      -- // PRR-JUN2010  add Line
      l_interface_type := NULL;
      FOR i IN c_insert_kit (p_org_id, w_accounting_date)
      LOOP
         EXIT WHEN c_insert_kit%NOTFOUND;
         t_count := t_count + 1;
         FOR v_qty_kit IN 1 .. i.qty
         LOOP
            t_cost := 0;
            t_tax_rate := 0;

            SELECT  SUM (x.item_cost)
                  , SUM (x.tax_rate)
            INTO    t_cost
                  , t_tax_rate
            FROM   (SELECT  xmt.mmt_actual_cost item_cost
                          , DECODE (i.sa_state
                                   , 3, NULL
                                   , DECODE (i.tax_rate, 0, NULL, ((xmt.mmt_actual_cost) * (i.tax_rate / 100)))
                                    ) tax_rate
                          , SUM (xkmoi.quantity) mo_qty
                    FROM    xxinv_material_trx_temp xmt, xxinv_kit_items_diario xkmoi
                    WHERE   xkmoi.item_id = xmt.mmt_inventory_item_id
                    AND     xkmoi.parent_item_number = i.parent_item_number
                    AND     xkmoi.p_oracle_cr_superior = xmt.reql_attribute2_crsup
                    AND     xkmoi.p_oracle_cr = xmt.reql_attribute3_cr
                    AND     xkmoi.oracle_ef = xmt.af_oracle_ef
                    AND     xkmoi.p_oracle_cr_superior = i.oracle_cr_superior
                    AND     xkmoi.p_oracle_cr = i.oracle_cr
                    AND     xkmoi.oracle_ef = i.oracle_ef
------ para que incluya el armado de kits en todas las salidas de un cr
--               AND xkmoi.req_header_id            = i.req_header_id
                    AND xkmoi.move_order_header_id = xmt.rh_header_id
                    AND xkmoi.req_header_id = xmt.reqh_requisition_header_id
                    AND xkmoi.req_line_id = xmt.rl_attribute1_req_line_id
                    AND xkmoi.transaction_id = xmt.mmt_transaction_id
------ para que incluya el armado de kits en todas las salidas de un cr
--            GROUP BY XMT.RH_HEADER_ID ,xkmoi.parent_item_number,xkmoi.item_number,XMT.MMT_ACTUAL_COST
                    GROUP BY xkmoi.parent_item_number
                           , xkmoi.item_number
                           , xmt.mmt_actual_cost
                           , DECODE (i.sa_state
                                   , 3, NULL
                                   , DECODE (i.tax_rate, 0, NULL, ((xmt.mmt_actual_cost) * (i.tax_rate / 100)))
                                    )) x
            WHERE   x.mo_qty >= v_qty_kit;

            fnd_file.put_line (fnd_file.LOG
                             ,    'parent: '
                               || i.parent_item_number
                               || ', qty: '
                               || v_qty_kit
                               || '/'
                               || i.qty
                               || ', cost: '
                               || t_cost
                              );

            BEGIN
               SELECT   flv.description
               INTO     c_descr
               FROM     fnd_flex_values_vl flv
               WHERE    flv.flex_value_meaning = i.attr2
               AND      flv.parent_flex_value_low = '04';
            EXCEPTION
               WHEN OTHERS
               THEN
                  c_descr := LPAD (' ', 40);
            END;

            BEGIN
               SELECT   MAX (move_order_header_id)
               INTO     t_header_id
               FROM     xxinv_kit_items_diario xkmoi
               WHERE    xkmoi.p_oracle_cr_superior = i.oracle_cr_superior
               AND      xkmoi.p_oracle_cr = i.oracle_cr
               AND      xkmoi.oracle_ef = i.oracle_ef
               AND      parent_item_number = i.parent_item_number
			   AND      trunc(xkmoi.creation_date) = w_accounting_date;  --JP 12.2.4
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  t_header_id := NULL;
               WHEN OTHERS
               THEN
                  t_header_id := NULL;
            END;

            IF t_header_id IS NOT NULL
            THEN
               BEGIN
                  SELECT    MAX (mtrl.line_id)
                  INTO      t_line_id
                  FROM      mtl_txn_request_lines mtrl, mtl_system_items msi
                  WHERE     mtrl.header_id = t_header_id
                  AND       msi.attribute2 = i.attr2
                  AND       msi.inventory_item_id = mtrl.inventory_item_id
                  AND       msi.attribute7 = 'KIT'
                  AND       msi.organization_id = p_org_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     t_line_id := NULL;
                  WHEN OTHERS
                  THEN
                     t_line_id := NULL;
               END;
            END IF;
            /*   PRR-JUN2010                    < ini >   */
            l_interface_type :=
               ofa_valid_iface_code (p_cursor_code         => 'C_INSERT_KIT'
                                   , p_legacy_ef           => i.legacy_ef
                                   , p_interface_type      => i.interface_type
                                    );

            /*   PRR-JUN2010                    < fin >   */

            IF substr(l_interface_type,1,7)='AFORA04' OR substr(l_interface_type,1,5)='AFALT' THEN
               l_status:='L';
            ELSE
               l_status:='Y';
            END IF;

            INSERT INTO xxinv_issue_fixed_asset_web
                        (legacy_ef, legacy_cr, item_number, description, item_type, sa_state, row_num, header_id
                       , line_number, creation_date, quantity, item_cost, cost_tax, interface_type, wm_status
                       , oracle_ef, oracle_cr )             /*-- CHG-38343 --*/
            VALUES (i.legacy_ef, i.legacy_cr, NULL, c_descr, i.attr2, i.sa_state, t_seq_num, t_header_id
                       -- // PRR-JUN2010     Modif Line
                       -- , t_line_id, i.creation_date, 1, t_cost, t_tax_rate, i.interface_type, 'L'
            ,            t_line_id, i.creation_date, 1, t_cost, t_tax_rate, l_interface_type, l_status--SRV20JUL2010 --'L'
                        , i.oracle_ef, i.oracle_cr)              /*-- CHG-38343 --*/;

            fnd_file.put_line (fnd_file.output
                             ,    RPAD (i.legacy_ef, 15, ' ')
                               || RPAD (i.legacy_cr, 15, ' ')
                               || RPAD ('KIT', 15, ' ')
                               || RPAD (c_descr, 40, ' ')
                               || RPAD (NVL (i.attr2, 'NIL'), 14, ' ')
                               || RPAD (i.sa_state, 10, ' ')
                               || RPAD (t_seq_num, 10, ' ')
                               || RPAD (t_header_id, 12, ' ')
                               || RPAD (NVL (t_line_id, 0), 10, ' ')
                               || RPAD (i.creation_date, 15, ' ')
                               || RPAD ('1', 12, ' ')
                               || RPAD (NVL (t_cost, 0), 20, ' ')
                               || RPAD (NVL (t_tax_rate, 0), 20, ' ')
                               -- // PRR-JUN2010    Modif Line
                               -- || RPAD (i.interface_type, 30, ' ')
                               || RPAD (l_interface_type, 30, ' ')
                              );
         END LOOP;
      END LOOP;

      BEGIN
         UPDATE xxinv_material_trx_temp xmt
         SET    af_interface_type = 'KITS'
         WHERE  --xmt.mmt_transaction_type_id = 63--comment change WMS 25/03/2017**
                xmt.mmt_transaction_type_id = 33--33-change Sales order issue WMS 25-03-17
         AND    xmt.mmt_transaction_action_id = 1
         --AND    xmt.mmt_transaction_source_type_id = 4--comment change WMS 25/03/2017**
         AND    xmt.mmt_transaction_source_type_id = 2--2-change Sales order issue WMS 25-03-17
         AND    msi_attribute8_mae_yn = 'Y';

         INSERT INTO xxinv_material_transactions
            SELECT  *
            FROM    xxinv_material_trx_temp;

         DELETE FROM xxinv_material_trx_temp;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG
                             , 'Error ocuured while updating the XXINV_MATERIAL_TRX_TEMP:' || SQLCODE || '-' || SQLERRM
                              );
            retcode := 2;
      END;

      COMMIT;
      /*   PRR-JUN2010                   < ini >   */
      fa_mass_additions_iface (p_date => p_date, p_retcode => retcode);
      /*   PRR-JUN2010                   < fin >   */
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
             (fnd_file.LOG
            ,    'System is showing error while inserting data  into the temparary table XXINV_ISSUE_FIXED_ASSET_WEB :'
              || SQLCODE
              || '-'
              || SQLERRM
             );
         retcode := 2;
   END main;

   /********************************************************************************************
   * Modulo      : CHECK_ITEM_ATTRIBUTE
   * Autor       :
   * Fecha       :
   * Descripci�n :

   * Modificado Por        	Fecha           	Codigo      Descripci�n
   ---------------------------------------------------------------------------------------------
   * LmC OTConsulting		15.Nov.2006						To check the item attribute must be with
   *														the org_id in mtl_system_items, So Add parameter p_org_id
   ********************************************************************************************/
   FUNCTION check_item_attribute (p_org_id IN NUMBER, p_item_id IN NUMBER, p_move_id IN NUMBER, p_line_num IN NUMBER)
      RETURN VARCHAR2
   IS
      t_change_attribute1   VARCHAR2 (10);
      t_org_attribute1      VARCHAR2 (10);
      t_rtn_attribute1      VARCHAR2 (10);
   BEGIN
      BEGIN
         SELECT change_attribute1
         INTO   t_change_attribute1
         FROM   xxinv_change_item_attribute_kc
         WHERE  pr_header_id = p_move_id
         AND    pr_line_id = p_line_num
         AND    item_id = p_item_id
         AND    ROWNUM = 1; -- 25.mar.2014 CHO 51906487 LDSM: Se agrega rownum
      EXCEPTION
         WHEN OTHERS
         THEN
            t_change_attribute1 := NULL;
      END;

      BEGIN
         SELECT DISTINCT attribute1
         INTO   t_org_attribute1
         FROM   mtl_system_items msi
         WHERE  msi.inventory_item_id = p_item_id
         AND    msi.organization_id = p_org_id;
      -- 15.Nov.2006 LmC OTConsulting. Line Add, cus the org_id is part of the primary key
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'error getting the attribute1: ' || SQLERRM);
      END;

--  FND_FILE.PUT_LINE(FND_FILE.LOG,'CHECK_ITEM_ATTRIBUTE ');
--  FND_FILE.PUT_LINE(FND_FILE.LOG,'P_MOVE_ID  : '||TO_CHAR(p_move_id));
--  FND_FILE.PUT_LINE(FND_FILE.LOG,'P_LINE_NUM : '||TO_CHAR(p_line_num));
--  FND_FILE.PUT_LINE(FND_FILE.LOG,'P_ITEM_ID  : '||TO_CHAR(p_item_id));
--  FND_FILE.PUT_LINE(FND_FILE.LOG,'T_CHANGE_ATTRIBUTE1 : '|| NVL(T_CHANGE_ATTRIBUTE1,' VACIO'));
--  FND_FILE.PUT_LINE(FND_FILE.LOG,'T_ORG_ATTRIBUTE1 : '|| NVL(T_ORG_ATTRIBUTE1,' VACIO'));
      IF t_change_attribute1 IS NOT NULL
      THEN
   --07.Dic.2006, LmC OTConsultingo next 5 lines commented
--    IF T_ORG_ATTRIBUTE1 = '04' AND T_CHANGE_ATTRIBUTE1 != '04' THEN
--      T_RTN_ATTRIBUTE1 := T_CHANGE_ATTRIBUTE1;
--    ELSIF T_ORG_ATTRIBUTE1 = '04' AND  T_CHANGE_ATTRIBUTE1 = '04' THEN
--      T_RTN_ATTRIBUTE1 := T_CHANGE_ATTRIBUTE1;
--    END IF;
    --07.Dic.2006, LmC OTConsulting, always must be return the changed attribute
         t_rtn_attribute1 := t_change_attribute1;
      ELSIF t_change_attribute1 IS NULL
      THEN
         t_rtn_attribute1 := t_org_attribute1;
      END IF;
      RETURN t_rtn_attribute1;
   END;

   /********************************************************************************************
   * Modulo      : OFA_VALID_IFACE_CODE
   * Autor       :
   * Fecha       :
   * Descripci�n : In Oracle Fixed Assets GoLive
   *			   Validate every Item if it must be interfaced to LegacyFA or OracleFA

   * Modificado Por        	Fecha           	Codigo          Descripci�n
   ---------------------------------------------------------------------------------------------
   * Paulino Reyes
   * OTConsulting			December 2009
   * Laura De Santiago      08.oct.2013         CHO 51413405    Se elimina las validaciones para determinar
   *                                                            si es plaza Legacy u Oracle
   ********************************************************************************************/
   FUNCTION ofa_valid_iface_code (
      p_cursor_code      IN   VARCHAR2 DEFAULT NULL
    , p_legacy_ef        IN   VARCHAR2 DEFAULT NULL
    , p_interface_type   IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      l_legacy_ef        xxfc_estados_financieros.legacy_ef%TYPE           := NULL;
      l_interface_code   xxinv_issue_fixed_asset_web.interface_type%TYPE   := NULL;
   BEGIN
      -- CHO 51413405 08.oct.2013: Se elimina validaci�n para determinar si es plaza Legacy u Oracle
      -- Inicia CHO 51413405: Se comentan lineas
      /* -- // Verifica codigo dado de alta en ValueSet
      BEGIN
         SELECT xef.legacy_ef
           INTO l_legacy_ef
           FROM fnd_flex_value_sets a, fnd_flex_values b, xxfc.xxfc_estados_financieros xef
          WHERE 1 = 1
            AND ROWNUM = 1
            AND a.flex_value_set_name = 'XXFC_FA_EF_ACTIVO_ORACLE_ALM'                             -- // PRR OTC Mar2010
            AND a.flex_value_set_id = b.flex_value_set_id
            AND b.enabled_flag = 'Y'
            AND TRIM (b.flex_value) = xef.oracle_ef
            AND xef.legacy_ef = NVL (p_legacy_ef, '#&@$?');
      EXCEPTION
         WHEN OTHERS
         THEN
            l_legacy_ef := NULL;
      END;

      IF l_legacy_ef IS NOT NULL
      THEN*/
      -- Finaliza CHO 51413405
         CASE p_cursor_code
            --SRV05Jul2010 Inicio Linea Agregada
            WHEN 'C_INSERT_TABLE'
            THEN
               l_interface_code := REPLACE (p_interface_type, 'AFALT', 'AFORA');
            --SRV05Jul2010 FIN de agregado
            WHEN 'C_INSERT_TABLE_GPOTOTAL_DET'
            THEN                                                                                             -- // Nooo
               l_interface_code := REPLACE (p_interface_type, 'AFSAL001_GPO', 'AFSORA01_GPO');
            WHEN 'C_DEV'
            THEN                                                                                              -- // Nooo
               l_interface_code := REPLACE (p_interface_type, 'AFDEV', 'AFDOR');
            WHEN 'HIJOS_SIN_PAPA'
            THEN                                                                                              -- // Siii
               l_interface_code := REPLACE (p_interface_type, 'AFALT', 'AFORA');
            WHEN 'GPOTOTAL_GASTO'
            THEN                                                                                              -- // Siii
               l_interface_code := REPLACE (p_interface_type, 'AFALT01', 'AFORA01');
            WHEN 'C_INSERT_TABLE_STG0'
            THEN                                                                              -- // Stage ( 0 )  -- Siii
               l_interface_code := REPLACE (p_interface_type, 'AFALT', 'AFORA');
            WHEN 'C_INSERT_TABLE_STG1'
            THEN                                                                              -- // Stage ( 1 )  -- Siii
               l_interface_code := REPLACE (p_interface_type, 'AFALT', 'AFORA');
            WHEN 'C_INSERT_TABLE_GPOTOTAL'
            THEN                                                                                   -- //    -- Siii ????
               l_interface_code := REPLACE (p_interface_type, 'AFALT', 'AFORA');
            WHEN 'C_INSERT_KIT'
            THEN                                                                                     -- // -- Siii  ????
               l_interface_code := REPLACE (p_interface_type, 'AFALT', 'AFORA');
            ELSE
               l_interface_code := p_interface_type;
         END CASE;
      -- CHO 51413405 08.oct.2013: Se comentan lineas porque se elimina validaci�n para determinar si es plaza Legacy u Oracle
      -- Inicia CHO 51413405
      -- ELSE
      --    l_interface_code := p_interface_type;
      -- END IF;
      -- Finaliza CHO 51413405
      RETURN (l_interface_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (p_interface_type);
   END ofa_valid_iface_code;

   /********************************************************************************************
   * Modulo      : FA_MASS_ADDITIONS_IFACE
   * Autor       :
   * Fecha       :
   * Descripci�n : In Oracle Fixed Assets GoLive
   *   			   After Inventory to Legacy FA interface ends, This procedure
   *			   must be executed to validate and send all items identified in the
   *			   Interface_Type column to FA_MASS_ADDITIONS table to upload Assets.

   * Modificado Por        	Fecha           	Codigo          Descripci�n
   ---------------------------------------------------------------------------------------------
   * Paulino Reyes
   * OTConsulting			December 2009
   * Laura De Santiago      08.oct.2013         CHO 51413405    Al encontrar un error en categoria no
   *                                                            inserte activo y envie correo a usuarios
   * Armando Padilla        Diciembre 2020		CHO 52070104    Para descartar Activos y Devoluciones de OxxoGas
   ********************************************************************************************/
   PROCEDURE fa_mass_additions_iface (p_date IN DATE, p_retcode IN OUT VARCHAR2)
   IS
      -- CHO 51413405 08.oct.2013: Cursor para obtener las cuentas de correo de usuarios para avisar sobre error en categoria
      -- Inicia CHO 51413405
      CURSOR c_correos
      IS
      SELECT  c.description
      FROM    fnd_flex_value_sets d
             ,fnd_flex_values a
             ,fnd_flex_values_tl c
      WHERE   d.flex_value_set_name='XXFC_VALIDA_ACTIVO_FIJO'
      AND     a.flex_value_set_id=d.flex_value_set_id
      AND     c.flex_value_id=a.flex_value_id
      AND     c.language='ESA'
      AND     NVL(a.enabled_flag,'N') = 'Y';
      -- Finaliza CHO 51413405

      CURSOR c_insert_mass_additions (cp_date IN DATE)
      IS
         SELECT header_id
              , line_number
              , description
              , item_cost costo
              , quantity
              , creation_date
              , item_type
              --, legacy_cr                 /*-- CHG-38343 --*/
              --, legacy_ef
              , oracle_cr
              , oracle_ef
              , item_number
         FROM   xxinv_issue_fixed_asset_web
         WHERE  1 = 1
         AND    (interface_type LIKE 'AFORA04%' ) ---SRV13072010 COMMENT PART LINE ---OR interface_type LIKE 'AFSORA01%' )
         AND    TRUNC (creation_date) = TRUNC (cp_date)
         AND    wm_status = 'L'
		 -- Inicia CHO 52070104
         AND  oracle_ef IN
	     (SELECT oracle_ef
	     FROM apps.xxfc_maestro_de_crs_v
	     WHERE 1=1
	     AND estado='A'
         AND oracle_cia NOT IN ('00202','00110'));
         -- Termina CHO 52070104
         -- // 22DIC2009 PRR AND NVL (wm_status, 'N') = 'N';

         -- // Variables uso exclusivo interface con OFA
                                                                           /*-- BEGIN CHG-38343 --*/
/*    l_oracle_ef            VARCHAR (5)                  := NULL;
      l_oracle_cr            VARCHAR (5)                  := NULL;
      l_oracle_cr_type       VARCHAR2 (1);
*/                                                                     /*-- END CHG-38343 --*/
      l_oracle_cr_superior   VARCHAR (5)                  := NULL;
      l_context              VARCHAR2 (200);
      l_expense_ccid         NUMBER;
      l_category_id          NUMBER;
      l_asset_key_ccid       NUMBER;
      l_location_id          NUMBER;
      l_period_num           NUMBER;
      l_period_year          NUMBER;
      l_count                NUMBER;
      l_asset_type           VARCHAR2 (11);
      l_libro_contable       VARCHAR2 (30);
      l_description_cat      VARCHAR2 (80);
      l_cuenta               xxfc_fa_tools_pkg.acc_record;
      l_result               VARCHAR2 (250);
      l_post                 VARCHAR2(10);
      l_ef_flex_value        VARCHAR2(5);--date;
      -- CHO 51413405 08.oct.2013: Variables para el manejo de error en categoria de activo
      -- Inicia CHO 51413405
      lv_CategoriaErr        VARCHAR2(2);
      lv_ErrorMessage        VARCHAR2(4000);
      ln_ErrorStatus         NUMBER;
      lv_Error               VARCHAR2(600):= NULL;
      -- Finaliza CHO 51413405
      ln_Error               NUMBER:= 0; -- CHO 51906487 10.mar.2014 LDSM: Variable para control de errores

   BEGIN
      fnd_file.put_line (fnd_file.LOG, '* * * * * * * * * * * * * * * * * * * * * * * * * * * *');
      fnd_file.put_line (fnd_file.LOG, 'I N I C I A   OFA MASS ADDITIONS   I N T E R F A C E');
      fnd_profile.get ('OXXO_FA_BOOK', l_libro_contable);
      --l_libro_contable := 'ADQUISICION02';
      fnd_file.put_line (fnd_file.LOG, '');
      fnd_file.put_line (fnd_file.LOG, 'Valor Profile OXXO_FA_BOOK -> ' || l_libro_contable);
      fnd_file.put_line (fnd_file.LOG, '=======================================================');

      -- CHO 51906487 10.mar.2014 LDSM: Se agrega en output registros procesados correctamente
      -- Inicia CHO 51906487
      fnd_file.new_line (fnd_file.output);
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output,LPAD('REGISTROS PROCESADOS PARA CREAR ACTIVO',100));
      fnd_file.put_line (fnd_file.output,LPAD('--------------------------------------',100));
      fnd_file.new_line (fnd_file.output);
      fnd_file.put_line (fnd_file.output,      RPAD ('Header_Id', 15, ' ')
                                            || RPAD ('Line_Number', 15, ' ')
                                            || RPAD ('Item_Type', 15, ' ')
                                            || RPAD ('Item_Number', 20, ' ')
                                            || RPAD ('Description', 60, ' ')
                                            || RPAD ('Quantity', 15, ' ')
                                            || RPAD ('Costo', 30, ' ')
                                            || RPAD ('Estado', 15, ' '));
      fnd_file.put_line (fnd_file.output,      RPAD ('---------', 15, ' ')
                                            || RPAD ('---------', 15, ' ')
                                            || RPAD ('---------', 15, ' ')
                                            || RPAD ('-----------', 20, ' ')
                                            || RPAD ('-------------', 60, ' ')
                                            || RPAD ('---------', 15, ' ')
                                            || RPAD ('---------', 30, ' ')
                                            || RPAD ('---------', 15, ' '));
      fnd_file.put_line (fnd_file.LOG,'Obtiene registros a procesar para crear activos');
      -- Finaliza CHO 51906487

      FOR i IN c_insert_mass_additions (p_date)
      LOOP
         fnd_file.put_line (fnd_file.LOG,'TRANSACCION: header id '||i.header_id||', line number '||i.line_number
                            ||', item type '||i.item_type||', item number '||i.item_number||', description '||i.description
                            ||', qty '||i.quantity||', cost '||i.costo);    -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro

         -- CHO 51413405 08.oct.2013: Al comenzar ciclo se agrega N, para decir que no existe error
         lv_CategoriaErr := 'N';
         ln_Error := 0;     -- CHO 51906487 10.mar.2014 LDSM: Inicializa para controlar errores en cada transaccion

         BEGIN
                                                                     /*-- BEGIN CHG-38343 --*/
            SELECT
/*                  oracle_cr
               , oracle_ef
               , oracle_cr_type
*/                  oracle_cr_superior
            INTO
/*              l_oracle_cr
                 , l_oracle_ef
                 , l_oracle_cr_type
                 ,
*/                  l_oracle_cr_superior

            FROM    xxfc_maestro_de_crs_v
            WHERE
               --    legacy_ef = i.legacy_ef
               --AND legacy_cr = i.legacy_cr
                    oracle_ef = i.oracle_ef
            AND     oracle_cr = i.oracle_cr
            AND     estado = 'A';                                                     -- se a�adio oracle_cr_type 17Sep08
                                                              /*-- END CHG-38343 --*/
            -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
            fnd_file.put_line (fnd_file.LOG,'Obtiene CR superior '||l_oracle_cr_superior||' para el estado financiero '||i.oracle_ef||', CR '||i.oracle_cr||', Item Type '||i.item_type||', Header_id '||i.header_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               -- CHO 51906487 10.mar.2014 LDSM: Se modifica descripcion del error
               fnd_file.put_line (fnd_file.LOG
                                ,    'Error C_INSERT_MASS_ADDITIONS al obtener CR superior en maestro de Crs NO_DATA_FOUND'
                                  || ' '
                                  || i.oracle_ef                        /*-- CHG-38343 --*/
                                  || ' '
                                  || i.oracle_cr
                                  || ' '
                                  || 'Item Type '
                                  || i.item_type
                                  || 'Header_id '
                                  || i.header_id
                                 );
               p_retcode := 1;
            WHEN TOO_MANY_ROWS
            THEN
               fnd_file.put_line (fnd_file.LOG
                                ,    'Error C_INSERT_MASS_ADDITIONS al obtener CR superior en maestro de Crs TOO_MANY_ROWS'
                                  || ' '
                                  || i.oracle_ef                        /*-- CHG-38343 --*/
                                  || ' '
                                  || i.oracle_cr
                                  || ' '
                                  || 'Item Type '
                                  || i.item_type
                                  || 'Header_id '
                                  || i.header_id
                                 );
               p_retcode := 1;
         END;

         BEGIN
            SELECT  concatenated_segments
            INTO    l_context
            FROM    fnd_shorthand_flex_aliases
            WHERE   id_flex_code = 'CAT#'
            AND     alias_name = i.item_type;
            fnd_file.put_line (fnd_file.LOG,'Obtiene context '||l_context||' para el tipo de activo '||i.item_type); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Error C_INSERT_MASS_ADDITIONS al obtener CONTEXT NO_DATA_FOUND');
               p_retcode := 1;
            WHEN TOO_MANY_ROWS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Error C_INSERT_MASS_ADDITIONS al obtener CONTEXT TOO_MANY_ROWS');
               p_retcode := 1;
         END;

         -- Inicia CHO 51413405 08.oct.2013: Se Agrega c�digo para marcar si existi� alg�n error en el loop
         fnd_file.put_line (fnd_file.LOG,'Busca categoria del activo');
         BEGIN
            SELECT  c.category_id
            INTO    l_category_id
            FROM    fa_categories c
            WHERE   c.segment1 || '.' || c.segment2 || '.' || c.segment3 || '.' || c.segment4 = l_context;
            fnd_file.put_line (fnd_file.LOG,'Obtiene el ID de la categoria del activo '||l_category_id||' para '||l_context); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_CategoriaErr := 'S'; -- CHO 51413405 08.oct.2013: Para manejo de error en categoria
               lv_Error := 'Error: No se encontr� la categor�a del articulo '||l_context||'. '||SQLCODE||' - '||SQLERRM;
               fnd_file.put_line (fnd_file.LOG, 'Error C_INSERT_MASS_ADDITIONS al obtener CATEGORY_ID DO_DATA_FOUND');
               p_retcode := 1;
            WHEN TOO_MANY_ROWS
            THEN
               lv_CategoriaErr := 'S'; -- CHO 51413405 08.oct.2013: Para manejo de error en categoria
               lv_Error := 'Error: No se pudo obtener la categor�a del articulo '||l_context||', existe mas de un registro. '||SQLCODE||' - '||SQLERRM;
               fnd_file.put_line (fnd_file.LOG, 'Error C_INSERT_MASS_ADDITIONS al obtener CATEGORY_ID TOO_MANY_ROWS');
               p_retcode := 1;
         END;
         -- Finaliza CHO 51413405 08.oct.2013: Cuando exista cualquiera de estos errores al buscar categoria, se asigna la S de error
         BEGIN
            SELECT  c.location_id
            INTO    l_location_id
            FROM    fa_locations c
            WHERE   c.segment1 = i.oracle_cr;
            fnd_file.put_line (fnd_file.LOG,'Obtiene location_id '||l_location_id||' para el CR '||i.oracle_cr); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  -- En caso de no encontrar datos dentro de Locations, se agrega automaticamente. .. 15Sep08 SRV
                  BEGIN
                     INSERT INTO fa_locations
                                 (location_id, segment1, enabled_flag, summary_flag, last_update_date
                                , last_updated_by, last_update_login
                                 )
                     VALUES (fa_locations_s.NEXTVAL, i.oracle_cr, 'Y', 'N', SYSDATE
                                , 1, 1
                                 );
                     fnd_file.put_line (fnd_file.LOG,'Inserta en la tabla fa_locations registro para '||i.oracle_cr); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
                     -- COMMIT; -- CHO 51906487 11.mar.2014 LDSM: Se comenta ya que se manejara almacenar por transaccion
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line (fnd_file.LOG
                                         , 'Error al insertar en la tabla fa_locations ' || SQLCODE || '-' || SQLERRM
                                          );
                        p_retcode := 1;
                  END;

                  BEGIN
                     SELECT c.location_id
                     INTO   l_location_id
                     FROM   fa_locations c
                     WHERE  c.segment1 = i.oracle_cr;
                     fnd_file.put_line (fnd_file.LOG,'Obtiene el valor de l_location_id '||l_location_id||' para el CR '||i.oracle_cr); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line (fnd_file.LOG
                                         , 'Error al determinar el valor de l_location_id ' || SQLCODE || '-' || SQLERRM
                                          );
                        p_retcode := 1;
                  END;
               -- Termina insercion dentro de Locations
               END;

               p_retcode := 1;
            WHEN TOO_MANY_ROWS THEN
               fnd_file.put_line (fnd_file.LOG, 'Error C_INSERT_MASS_ADDITIONS al obtener LOCATION_ID TOO_MANY_ROWS');
               p_retcode := 1;
         END;

         BEGIN
            SELECT  c.code_combination_id
            INTO    l_asset_key_ccid
            FROM    fa_asset_keywords c
            WHERE   c.segment1 = l_oracle_cr_superior;
            fnd_file.put_line (fnd_file.LOG,'Obtiene el ASSET_KEY_CCID '||l_asset_key_ccid||' para el CR superior '||l_oracle_cr_superior); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               fnd_file.put_line (fnd_file.LOG
                                , 'Error C_INSERT_MASS_ADDITIONS al obtener ASSET_KEY_CCID NO_DATA_FOUND');
               p_retcode := 1;
            WHEN TOO_MANY_ROWS THEN
               fnd_file.put_line (fnd_file.LOG
                                , 'Error C_INSERT_MASS_ADDITIONS al obtener ASSET_KEY_CCID TOO_MANY_ROWS');
               p_retcode := 1;
         END;

         --proceso para obtener la cuenta de Expense, y en caso de que no exista que la cree.
         l_result := NULL;
         l_cuenta := NULL;

         BEGIN
            SELECT  oracle_cia
                  , oracle_ef
                  , oracle_cr
            INTO    l_cuenta.segment1
                  , l_cuenta.segment2
                  , l_cuenta.segment3
            FROM    xxfc_maestro_de_crs_v
            WHERE                              /*-- CHG-38343 --*/
               --    legacy_ef = i.legacy_ef
               --AND legacy_cr = i.legacy_cr
                    oracle_ef = i.oracle_ef
            AND     oracle_cr = i.oracle_cr
            AND     estado = 'A';
            -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
            fnd_file.put_line (fnd_file.LOG,'Obtiene EF '||l_cuenta.segment2||', CR '||l_cuenta.segment3||' y CIA '||l_cuenta.segment1||' para el estado financiero y CR '||i.oracle_ef||', '||i.oracle_cr);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG
                                ,    'Error C_INSERT_MASS_ADDITIONS al obtener EF, CR y CIA de Oracle en maestro de Crs NO_DATA_FOUND'
                                  || ' '
                                  || i.oracle_ef                        /*-- CHG-38343 --*/
                                  || ' '
                                  || i.oracle_cr
                                  || ' '
                                  || 'Item Type '
                                  || i.item_type
                                  || 'Header_id '
                                  || i.header_id
                                 ); -- CHO 51906487 10.mar.2014 LDSM: Se modifica descripcion del error
               p_retcode := 1;
            WHEN TOO_MANY_ROWS
            THEN
               fnd_file.put_line (fnd_file.LOG
                                ,    'Error C_INSERT_MASS_ADDITIONS al obtener EF, CR y CIA de Oracle en maestro de Crs TOO_MANY_ROWS'
                                  || ' '
                                  || i.oracle_ef                        /*-- CHG-38343 --*/
                                  || ' '
                                  || i.oracle_cr
                                  || ' '
                                  || 'Item Type '
                                  || i.item_type
                                  || 'Header_id '
                                  || i.header_id
                                 ); -- CHO 51906487 10.mar.2014 LDSM: Se modifica descripcion del error
               p_retcode := 1;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG
                 ,    'Error C_INSERT_MASS_ADDITIONS al obtener EF, CR y CIA de Oracle de l_EXPENSE_CCID para Legacy EF : '
                   || i.oracle_ef
                   || ' y el CR : '
                   || i.oracle_cr
                  );
               p_retcode := 1;
         END;

         l_cuenta.segment4 := xxfc_fa_tools_pkg.obtiene_segmento4_tipo_act (l_cuenta.segment3, i.item_type);
         fnd_file.put_line (fnd_file.LOG,'Obtiene segment4 '||l_cuenta.segment4||' para el tipo de activo '||i.item_type||' - '||l_cuenta.segment3); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         l_cuenta.account_type := 'E';
         l_cuenta.enabled_flag := 'Y';
         xxfc_fa_tools_pkg.obtiene_cuenta (p_reg => l_cuenta, x_result => l_result, p_crea_cta => 'Y');
         l_expense_ccid := l_cuenta.code_combination_id;
         fnd_file.put_line (fnd_file.LOG,'Obtiene cuenta '||l_expense_ccid); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         IF l_result IS NOT NULL
         THEN
            fnd_file.put_line (fnd_file.LOG
                             , 'Error en la funci�n "XXFC_FA_TOOLS_PKG.obtiene_cuenta" : [' || TRIM (l_result) || ']'
                              );
         END IF;
         IF NVL (l_expense_ccid, 0) = 0
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Error C_INSERT_MASS_ADDITIONS al obtener EXPENSE_CCID NO_DATA_FOUND');
            p_retcode := 1;
         END IF;
         l_asset_type := 'CIP';

         BEGIN
            SELECT  description
            INTO    l_description_cat
            FROM    fa_categories
            WHERE   category_id = l_category_id;
            fnd_file.put_line (fnd_file.LOG,'Obtiene descripcion de la categoria '||l_category_id||' - '||l_description_cat); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG
                                , 'Error al determinar la descripcion de la categoria' || SQLCODE || '-' || SQLERRM
                                 );
         END;

         fnd_file.put_line (fnd_file.LOG, '-> l_EXPENSE  ' || l_expense_ccid);
         fnd_file.put_line (fnd_file.LOG, '-> ORACLE_EF  ' || i.oracle_ef);                 /*-- CHG-38343 --*/
         fnd_file.put_line (fnd_file.LOG, '-> ORACLE_CR  ' || i.oracle_cr);
         fnd_file.put_line (fnd_file.LOG, '-> ITEM_TYPE  ' || i.item_type);
         fnd_file.put_line (fnd_file.LOG, '-> ITEM_NUMBER  ' || i.item_number);
         fnd_file.put_line (fnd_file.LOG, '-> l_LOCATION_ID  ' || l_location_id);
         fnd_file.put_line (fnd_file.LOG, '-> l_ASSET_TYPE  ' || l_asset_type);
         fnd_file.put_line (fnd_file.LOG, '-> HEADER_ID  ' || i.header_id);
         fnd_file.put_line (fnd_file.LOG, '-> LINE_NUMBER ' || i.line_number);

         ---SRV05 INICIA /* validacion de tipo de post
         -- // Verifica codigo dado de alta en ValueSet
         l_post:=NULL;
         -- CHO 51413405 08.oct.2013: Se elimina validaci�n para determinar si es plaza Legacy u Oracle
         -- Inicia CHO 51413405: Se comentan lineas
         /*BEGIN
            SELECT  b.flex_value--b.START_DATE_ACTIVE
            INTO    l_ef_flex_value
            FROM    fnd_flex_value_sets a, fnd_flex_values b, xxfc.xxfc_estados_financieros xef
            WHERE   1 = 1
            AND     ROWNUM = 1
            AND     a.flex_value_set_name = 'XXFC_FA_EF_ACTIVO_ORACLE_ALM'                             -- // PRR OTC Mar2010
            AND     a.flex_value_set_id = b.flex_value_set_id
            AND     b.enabled_flag = 'Y'
            AND     TO_DATE(b.START_DATE_ACTIVE,'DD/MM/YYYY') <= TO_DATE(TRUNC(SYSDATE),'DD/MM/YYYY')
            AND     TRIM (b.flex_value) = i.oracle_ef; --SRV22JUL2010--xef.oracle_ef
            --SRV22JUL2010  AND xef.legacy_ef = NVL (i.legacy_ef, '#&@$?');
            l_post:='POST';
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_post := 'ON HOLD';
            WHEN OTHERS THEN
              l_post:='ON HOLD';
         END;*/
         -- Se asigna POST para plaza Oracle y Legacy
         l_post:= 'POST';
         -- Finaliza CHO 51413405
         BEGIN
            --SRV05Jul2010 Se agrega para que cuando se tenga ya habilitado la fecha en la lista de valores se pueda procesar ..
            UPDATE  fa_mass_additions
            SET     posting_status='POST', queue_name='POST'
            WHERE   posting_status='ON HOLD' AND l_post='POST' AND i.oracle_ef=attribute7 AND property_type_code='ALMACEN';
            -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
            fnd_file.put_line (fnd_file.LOG, 'Se Modifico dentro del FA_MASS_ADDITIONS activos que estaban PENDING a POST de Origen Almacen ' || TO_CHAR(SQL%ROWCOUNT) );
            --COMMIT; -- CHO 51906487 11.mar.2014 LDSM: Se comenta ya que se manejara almacenar por transaccion
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               fnd_file.put_line (fnd_file.LOG, 'NO se Modifico dentro del FA_MASS_ADDITIONS activos que estaban PENDING a POST de Origen Almacen ' || TO_CHAR(SQL%ROWCOUNT) );
            WHEN OTHERS THEN
               fnd_file.put_line (fnd_file.LOG, 'Existe problemas al modificar FA_MASS_ADDITIONS  activos que estaban PENDING a POST de Origen Almacen ' || TO_CHAR(SQL%ROWCOUNT) );
         END;
         -- SRV05Julio2010 FINALIZA /* validacion de tipo de post
         -- CHO 51413405 08.oct.2013: Si exisit� alg�n error en el category, entonces que no inserte y mande correo, de lo contrario entonces que inserte los datos en el loop
         -- Inicia CHO 51413405
         IF lv_CategoriaErr = 'S' THEN
            fnd_file.put_line (fnd_file.LOG,'Env�a correo con detalle de error en categor�a de activo');
            FOR correos IN c_correos LOOP
               fnd_file.put_line (fnd_file.LOG,'Envia correo a '||correos.description); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro
               ln_ErrorStatus  := XXFC_UTL_JAVA_PKG.SENDMAIL
                          (smtpservername        => ''
                          ,sender                => 'no-reply@oxxo.com'
                          ,recipient             => correos.description
                          ,ccrecipient           =>NULL
                          ,bccrecipient          =>NULL
                          ,subject               =>  'Concurrente XXINV: Creacion de movs de salida legacy (OL3)  <<Category_id>>'
                          ,BODY                  => ('Se encontr� un error al obtener los datos del Category_Id en el proceso diario de almac�n ' || to_char(sysdate, 'DD-MM-YYYY HH:MI:SS'))||
                                                    CONCAT (CHR (13), CHR (13))||
                                                    lv_Error||CONCAT (CHR (13), CHR (13))||
                                                    'Los datos del registro con error son: '||
                                                    CONCAT (CHR (13), CHR (13))||'
                                                    Salida: '||i.header_id||'
                                                    No linea: '||i.Line_number||'
                                                    No Articulo: '||i.Item_number||'
                                                    Descripcion: '||i.description||'
                                                    Costo: '||round(i.costo, 2)||'
                                                    Cantidad: '||i.quantity||'
                                                    Tipo_Articulo: '||i.item_type||'
                                                    Oracle_CR: '||i.Oracle_cr||'
                                                    Oracle_EF: '||i.Oracle_ef||'
                                                    Fecha Creacion: '||i.creation_date||'
                                                    Categor�a: '||l_context||
                                                    CONCAT (CHR (13), CHR (13))||
                                                    'Nota: Por favor no responda a este correo ya que la cuenta no-reply@oxxo.com no acepta correos.'
                          ,errormessage          => lv_ErrorMessage
                          ,attachments           => NULL
                          ,attachmentsnames      => NULL
                          ,zipfiles              => 'N'
                          ,zipfilename           => NULL
                          );


            END LOOP;  --Logica de correo
            ln_Error := 1;
         ELSE -- Finaliza CHO 51413405
            FOR j IN 1 .. i.quantity
            LOOP
               BEGIN
                  INSERT INTO fa_mass_additions
                              (description, fixed_assets_units, book_type_code, fixed_assets_cost
                             , date_placed_in_service, accounting_date, attribute8, attribute6, attribute7
                             , global_attribute1, global_attribute_category, feeder_system_name
                             , property_type_code, in_use_flag, create_batch_date, create_batch_id, posting_status
                             , queue_name, asset_type, mass_addition_id, CONTEXT, asset_category_id
                             , asset_key_ccid, expense_code_combination_id, location_id, invoice_number
                              )
                  VALUES (l_description_cat, 1, TRIM (l_libro_contable), i.costo
                             , i.creation_date, i.creation_date, i.item_type, '', i.oracle_ef
                             , TO_CHAR (i.creation_date, 'YYYY/MM/DD HH:MM:SS'), 'JL.MX.FAXMADDS.FA_MASS_ADD', 'ALMACEN'
                             --SRV05Jul2010 Modifique linea
                             --, 'ALMACEN', 'YES', i.creation_date, 1, 'POST'
                             , 'ALMACEN', 'YES', i.creation_date, 1, l_post
                             --SRV05Jul2010 Modifique linea
                             --, 'POST', l_asset_type, fa_mass_additions_s.NEXTVAL, l_context, l_category_id
                             , l_post, l_asset_type, fa_mass_additions_s.NEXTVAL, l_context, l_category_id
                             , l_asset_key_ccid, l_expense_ccid, l_location_id, i.header_id
                              );

                  fnd_file.put_line (fnd_file.LOG
                                   , 'Se inserto Correctamente dentro de la interface Activos Fijos FA_MASS_ADDITIONS'
                                    );
                  fnd_file.put_line (fnd_file.LOG,'Description '||l_description_cat||', units 1, cost '||i.costo||
                                    ', item type '||i.item_type||', oracle ef '||i.oracle_ef||', posting_status '||l_post||
                                    ', queue_name '||l_post||', asset_type'||l_asset_type||', context '||l_context||
                                    ', asset_category_id '||l_category_id||', asset_key_ccid '||l_asset_key_ccid||
                                    ', expense_code_combination_id '||l_expense_ccid||', location_id '||l_location_id||
                                    ', invoice_number '||i.header_id); -- CHO 51906487 11.mar.2014 LDSM: Se incluye mensaje para archivo de registro

                  --COMMIT; -- CHO 51906487 11.mar.2014 LDSM: Se comenta ya que se manejara almacenar por transaccion

                  BEGIN
                     UPDATE xxinv_issue_fixed_asset_web
                     SET    wm_status = 'Y'
                     WHERE  i.header_id = header_id
                     AND    i.line_number = line_number;

                     fnd_file.put_line
                                  (fnd_file.LOG
                                 , 'Actualizacion  Satisfactoria en XXINV_ISSUE_FIXED_ASSET_WEB  de envio de Activos Fijos. Header_id: '||i.header_id||', line number: '||i.line_number
                                  );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                                  (fnd_file.LOG
                                 ,    'Error al modificar el estatus de procesado en la tabla XXINV_ISSUE_FIXED_ASSET_WEB'
                                   || SQLCODE
                                   || '-'
                                   || SQLERRM
                                  );
                        ln_Error := 1;
                  END;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line (fnd_file.LOG, 'Error al insertar FA_MASS_ADDITIONS' || SQLCODE || '-' || SQLERRM);
                     ln_Error := 1;
               END;
            END LOOP;
         END IF; -- Finaliza CHO 51413405

         -- 10.mar.2014 CHO 51906487 LDSM: Se agrega el detalle de las lineas procesadas en la creacion de activo
         -- Inicia CHO 51906487
         -- Se muestran en el output las transacciones procesadas y se aplica el cambio si no existe error
         --COMMIT;
         IF ln_Error = 0 THEN
            COMMIT;
            fnd_file.put_line (fnd_file.LOG,'Guarda transaccion');
            fnd_file.put_line (fnd_file.LOG,'---------------------------------------------------------------------');
            fnd_file.put_line (fnd_file.output,RPAD(NVL(TO_CHAR(i.header_id),RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(TO_CHAR(i.line_number),RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(i.item_type,RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(i.item_number,RPAD(' ',20,' ')), 20, ' ')
                                            || RPAD(NVL(i.description,RPAD(' ',60,' ')), 60, ' ')
                                            || RPAD(NVL(TO_CHAR(i.quantity),RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(TO_CHAR(i.costo),RPAD(' ',30,' ')), 30, ' ')
                                            || RPAD('CORRECTO', 15, ' '));
         ELSE
            ROLLBACK;
            fnd_file.put_line (fnd_file.LOG,'Rollback transaccion');
            fnd_file.put_line (fnd_file.LOG,'---------------------------------------------------------------------');
            fnd_file.put_line (fnd_file.output,RPAD(NVL(TO_CHAR(i.header_id),RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(TO_CHAR(i.line_number),RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(i.item_type,RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(i.item_number,RPAD(' ',20,' ')), 20, ' ')
                                            || RPAD(NVL(i.description,RPAD(' ',60,' ')), 60, ' ')
                                            || RPAD(NVL(TO_CHAR(i.quantity),RPAD(' ',15,' ')), 15, ' ')
                                            || RPAD(NVL(TO_CHAR(i.costo),RPAD(' ',30,' ')), 30, ' ')
                                            || RPAD('INCORRECTO', 15, ' '));
         END IF;
         -- Finaliza CHO

      END LOOP;
      fnd_file.put_line (fnd_file.LOG, '* * * * * * * * * * * * * * * * * * * * * * * * * * * *');
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK; -- CHO 51906487 11.mar.2014 LDSM: Se agrega para no guardar la transaccion en caso de falla
         p_retcode := 2; -- CHO 51906487 13.mar.2014 LDSM: Se debe terminar en error en luegar de advertencia --1;
         fnd_file.put_line (fnd_file.LOG,'Rollback transaccion');
         fnd_file.put_line (fnd_file.LOG, '=======================================================');
         fnd_file.put_line (fnd_file.LOG, 'ERROR while Interface items to Oracle Fixed Assets :');
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         fnd_file.put_line (fnd_file.LOG, '* * * * * * * * * * * * * * * * * * * * * * * * * *');
   END fa_mass_additions_iface;

   /********************************************************************************************
   * Modulo      : DEVOLUCIONES
   * Autor       :
   * Fecha       :
   * Descripci�n :

   * Modificado Por        	Fecha           	Codigo      Descripci�n
   ---------------------------------------------------------------------------------------------
   * Armando Padilla      Diciembre 2020		CHO 52070104    Para descartar Activos y Devoluciones de OxxoGas
   *
   ********************************************************************************************/
   PROCEDURE devoluciones (p_date IN DATE, p_org_id IN NUMBER, p_retcode IN OUT VARCHAR2)
   IS
      --  Cursor de devoluciones
      CURSOR fa_devs (p_org_id IN NUMBER) IS
         SELECT   mtl.attribute4 Plaza,mtl.attribute5 cr, mtl.attribute8 numero_salida,mtl.attribute9 line_id,
-- JP 12.2.4 PPR  mtl.inventory_item_id item_id, mtl.transaction_quantity cantidad,mtl.actual_cost monto
                  mtl.inventory_item_id item_id,mtl.actual_cost monto, SUM(mtl.transaction_quantity) cantidad  -- JP 12.2.4 PPR
         FROM     mtl_material_transactions mtl
         WHERE    mtl.transaction_type_id = 42
         AND      mtl.transaction_action_id = 27
         AND      mtl.transaction_source_type_id = 13
         --AND mtl.attribute10 IS NOT NULL
         --AND mtl.attribute14 = 'R12 Upg'
         AND      mtl.attribute1 = 'DEV'
         AND      mtl.organization_id = p_org_id
         AND      TRUNC (mtl.creation_date) = TRUNC (p_date)
		 -- Inicia CHO 52070104
         AND  mtl.attribute4 IN
	     (SELECT oracle_cr_superior
	     FROM apps.xxfc_maestro_de_crs_v
	     WHERE 1=1
	     AND estado='A'
	     AND oracle_cia NOT IN ('00202','00110'))
         -- Termina CHO 52070104
         GROUP BY mtl.attribute4 ,mtl.attribute5 , mtl.attribute8 ,mtl.attribute9,  mtl.inventory_item_id,mtl.actual_cost --JP  12.2.4 PPR
         ORDER BY mtl.attribute8       ;


      --  Cursor salidas sin KITS ni GRUPOS
      CURSOR fa_salidas (p_salida IN NUMBER, p_line_id IN NUMBER, p_item_id IN NUMBER) IS
         SELECT af_oracle_cia sa,   msi_attribute2_mae_activo clave_activo,  mmt_transaction_date fecha_salida, null grupo_o_kit,
                mmt_inventory_item_id item_id, msi_segment1_no_articulo articulo, mmt_transaction_quantity cantidad,mmt_actual_cost monto, msi_attribute1_uso  tipo_uso, af_tipo_uso_convertido
         FROM   xxinv_material_transactions xmt
         WHERE  rh_header_id            =  p_salida --5126345    --- fa_devs.numero_salida
         AND    rl_line_id               =  p_line_id --16261707   --- fa_devs.LINE_ID
         AND    mmt_inventory_item_id    =  p_item_id --13167      --- fa_devs.INVENTORY_ITEM_ID
         AND    xmt.msi_attribute7_mae_tipo NOT IN ('GPOTOTAL','KIT')
         -----------------AND ((msi_attribute1_uso = '04' AND  SUBSTR(AF_INTERFACE_TYPE,6,2) != '01') OR (msi_attribute1_uso = '01' AND AF_TIPO_USO_CONVERTIDO= '04'));
         AND    ((msi_attribute1_uso = '04' AND  NVL(SUBSTR(AF_INTERFACE_TYPE,6,2),'00') != '01') OR (msi_attribute1_uso = '01' AND AF_TIPO_USO_CONVERTIDO= '04'));
         ------------------------------------------------------------------------------------------------------------------
         --      OR xmt.AF_INTERFACE_TYPE like 'AF___03%');

      --  Cursor salidas solo GRUPOS
      CURSOR fa_salidas_grupos (p_salida IN NUMBER, p_line_id IN NUMBER, p_item_id IN NUMBER) IS
         SELECT af_oracle_cia sa,   msi_attribute2_mae_activo clave_activo,  mmt_transaction_date fecha_salida,
                DECODE(xmt.msi_attribute7_mae_tipo,'KIT',xmt.msi_attribute2_mae_activo,'GPOTOTAL',xmt.msi_attribute2_mae_activo, NULL) GRUPO_O_KIT,
                mmt_inventory_item_id item_id, msi_segment1_no_articulo articulo, mmt_transaction_quantity cantidad,mmt_actual_cost Monto, msi_attribute1_uso  tipo_uso, af_tipo_uso_convertido
         FROM   xxinv_material_transactions xmt
         WHERE  rh_header_id            =  p_salida --5126345    --- fa_devs.numero_salida
         AND    rl_line_id               =  p_line_id --16261707   --- fa_devs.LINE_ID
         AND    mmt_inventory_item_id    =  p_item_id --13167      --- fa_devs.INVENTORY_ITEM_ID
         AND    xmt.msi_attribute7_mae_tipo ='GPOTOTAL'
         ---------------AND ((msi_attribute1_uso = '04' AND  SUBSTR(AF_INTERFACE_TYPE,6,2) != '01') OR (msi_attribute1_uso = '01' AND AF_TIPO_USO_CONVERTIDO= '04'));
         AND    ((msi_attribute1_uso = '04' AND  NVL(SUBSTR(AF_INTERFACE_TYPE,6,2),'04') != '01') OR (msi_attribute1_uso = '01' AND AF_TIPO_USO_CONVERTIDO= '04'));
         --      OR xmt.AF_INTERFACE_TYPE like 'AF___03%');

      --  Cursor salidas solo KITS
      CURSOR fa_salidas_kits (p_salida IN number, p_line_id IN number, p_item_id IN number) is
         SELECT af_oracle_cia sa,   msi_attribute2_mae_activo clave_activo,  mmt_transaction_date fecha_salida,
                DECODE(xmt.msi_attribute7_mae_tipo,'KIT',xmt.msi_attribute2_mae_activo,'GPOTOTAL',xmt.msi_attribute2_mae_activo, NULL) GRUPO_O_KIT,
                mmt_inventory_item_id item_id, msi_segment1_no_articulo articulo, mmt_transaction_quantity cantidad,mmt_actual_cost monto, msi_attribute1_uso  tipo_uso, af_tipo_uso_convertido,
                msi_attribute8_mae_YN
         FROM   xxinv_material_transactions xmt
         WHERE  rh_header_id            =  p_salida --5126345    --- fa_devs.numero_salida
         AND    rl_line_id               =  p_line_id --16261707   --- fa_devs.LINE_ID
         AND    mmt_inventory_item_id    =  p_item_id --13167      --- fa_devs.INVENTORY_ITEM_ID
         AND    xmt.msi_attribute7_mae_tipo ='KIT'
         ------------------
         AND      ((msi_attribute1_uso = '04' AND  NVL(SUBSTR(af_interface_type,6,2),'04') != '01') OR (msi_attribute1_uso = '01' AND af_tipo_uso_convertido= '04'));
         --      OR xmt.af_interface_type LIKE 'AF___03%');

      w_count NUMBER;

   BEGIN
   /*
   fnd_file.put_line (fnd_file.LOG, 'Devoluciones');
   fnd_file.put_line (fnd_file.output,RPAD ('Plaza', 10, ' ') || RPAD ('Cr', 10, ' ')|| RPAD ('Salida', 15, ' ')|| RPAD ('line_id', 15, ' ') );
   fnd_file.put_line (fnd_file.output,RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' '));
   fnd_file.new_line (fnd_file.output);
   FOR devs IN fa_devs (org_id) LOOP
      fnd_file.put_line (fnd_file.output,RPAD (devs.plaza, 10, ' ')|| RPAD (devs.cr, 10, ' ')|| RPAD (devs.numero_salida, 15, ' ')|| RPAD (devs.line_id, 15, ' '));
----- Datos de Salidas
      fnd_file.put_line (fnd_file.output,RPAD ('SA', 10, ' ') || RPAD ('Activo', 10, ' ')|| RPAD ('FechaSalida', 15, ' ')|| RPAD ('Grupo/Kit', 10, ' ') );
      fnd_file.put_line (fnd_file.output,RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 10, ' '));
      fnd_file.new_line (fnd_file.output);

      FOR salidas IN FA_SALIDAS(devs.numero_salida, devs.LINE_ID, devs.INVENTORY_ITEM_ID ) LOOP
          fnd_file.put_line (fnd_file.output,RPAD (salidas.SA, 10, ' ')|| RPAD (salidas.clave_activo, 10, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')|| RPAD (salidas.grupo_o_kit, 10, ' '));
      END LOOP;
      fnd_file.new_line (fnd_file.output);
   END LOOP;
*/
      dbms_output.put_line('Devoluciones');
      dbms_output.put_line(RPAD ('Plaza', 10, ' ') || RPAD ('Cr', 10, ' ')|| RPAD ('Salida', 15, ' ')||
                           RPAD ('Articulo', 10, ' ') || RPAD ('Cantidad', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('line_id', 15, ' ') );
      dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                           RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' '));
      FOR devs IN fa_devs (p_org_id) LOOP
         dbms_output.put_line(RPAD (devs.plaza, 10, ' ')|| RPAD (devs.cr, 10, ' ')|| RPAD (devs.numero_salida, 15, ' ')||
                              RPAD (devs.item_id, 10, ' ')|| RPAD (devs.cantidad, 10, ' ')|| RPAD (devs.monto, 15, ' ')|| RPAD (devs.line_id, 15, ' '));
   ---------- Procesa Salidas Sin Grupos y sin Kits
         FOR salidas IN FA_SALIDAS(devs.numero_salida, devs.LINE_ID, devs.ITEM_ID ) LOOP
            dbms_output.put_line(RPAD ('SA', 10, ' ') || RPAD ('Activo', 10, ' ')|| RPAD ('FechaSalida', 15, ' ')||
                                  RPAD ('Articulo', 10, ' ') || RPAD ('Cantidad', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('Grupo/Kit', 15, ' '));
            dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' '));
            dbms_output.put_line(RPAD (salidas.SA, 10, ' ')|| RPAD (salidas.clave_activo, 10, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')||
                                 RPAD (salidas.articulo, 10, ' ')|| RPAD (salidas.cantidad, 10, ' ')|| RPAD (salidas.monto, 15, ' ')|| RPAD (salidas.grupo_o_kit, 15, ' '));

            dbms_output.put_line('..');

            dbms_output.put_line(RPAD ('SA', 10, ' ') || RPAD ('Plaza', 10, ' ')|| RPAD ('CR', 15, ' ')||
                                 RPAD ('activo', 10, ' ') || RPAD ('Salida', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('fecha_salida', 15, ' ')||
                                 RPAD ('tipo_uso', 10, ' ') || RPAD ('GPO/KIT', 10, ' '));
            dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' '));
            FOR sal IN 1..devs.cantidad LOOP
               dbms_output.put_line(RPAD (salidas.SA, 10, ' ')|| RPAD (devs.plaza, 10, ' ')|| RPAD (devs.CR, 15, ' ')||
                                    RPAD (salidas.clave_activo, 10, ' ')|| RPAD (devs.numero_salida, 10, ' ')|| RPAD (devs.monto, 15, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')||
                                    RPAD (salidas.tipo_uso, 15, ' ')|| RPAD (salidas.GRUPO_O_KIT, 15, ' '));
               INSERT INTO XXFC_INV_DEVOLUCION_ALMACEN  (SA,PLAZA,CR,CLAVE_ACTIVO,NUMERO_SALIDA,MONTO,FECHA_SALIDA, TIPO_DE_USO,
                                                         GRUPO_O_KIT,CREATION_DATE,CREATION_BY,LAST_UPDATED_DATE,LAST_UPDATED_BY,STATUS_INVENTARIO)
                  VALUES (salidas.SA,devs.plaza,devs.CR,salidas.clave_activo,devs.numero_salida,devs.monto,salidas.fecha_salida,
                          salidas.tipo_uso,salidas.GRUPO_O_KIT,SYSDATE,1,SYSDATE,1,'P');
               dbms_output.put_line('..'||sal||'..');
            END LOOP;
         END LOOP;
   ---------- Procesa Salidas de Grupos
         FOR salidas IN FA_SALIDAS_GRUPOS(devs.numero_salida, devs.line_id, devs.item_id ) LOOP
            dbms_output.put_line(RPAD ('SA', 10, ' ') || RPAD ('Activo', 10, ' ')|| RPAD ('FechaSalida', 15, ' ')||
                                  RPAD ('Articulo', 10, ' ') || RPAD ('Cantidad', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('Grupo/Kit', 15, ' '));
            dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' '));
            dbms_output.put_line(RPAD (salidas.SA, 10, ' ')|| RPAD (salidas.clave_activo, 10, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')||
                                 RPAD (salidas.articulo, 10, ' ')|| RPAD (salidas.cantidad, 10, ' ')|| RPAD (salidas.monto, 15, ' ')|| RPAD (salidas.grupo_o_kit, 15, ' '));

            dbms_output.put_line('..');

            dbms_output.put_line(RPAD ('SA', 10, ' ') || RPAD ('Plaza', 10, ' ')|| RPAD ('CR', 15, ' ')||
                                 RPAD ('activo', 10, ' ') || RPAD ('Salida', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('fecha_salida', 15, ' ')||
                                 RPAD ('tipo_uso', 10, ' ') || RPAD ('GPO/KIT', 10, ' '));
            dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' '));

-----            FOR sal IN 1..devs.cantidad LOOP
            dbms_output.put_line(RPAD (salidas.SA, 10, ' ')|| RPAD (devs.plaza, 10, ' ')|| RPAD (devs.CR, 15, ' ')||
                                    RPAD (salidas.clave_activo, 10, ' ')|| RPAD (devs.numero_salida, 10, ' ')|| RPAD (devs.monto, 15, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')||
                                    RPAD (salidas.tipo_uso, 15, ' ')|| RPAD (salidas.GRUPO_O_KIT, 15, ' '));
            SELECT count(*) INTO w_count
              FROM  xxfc_inv_devolucion_almacen
             WHERE sa            = salidas.SA
               AND plaza         = devs.plaza
               AND cr            = devs.CR
               AND clave_activo  = salidas.clave_activo
               AND numero_salida = devs.numero_salida  ;
            IF w_count = 1 THEN
                UPDATE XXFC_INV_DEVOLUCION_ALMACEN SET MONTO = MONTO + (devs.monto*devs.cantidad)
                 WHERE sa            = salidas.SA
                   AND plaza         = devs.plaza
                   AND cr            = devs.CR
                   AND clave_activo  = salidas.clave_activo
                   AND numero_salida = devs.numero_salida  ;
            ELSE
               INSERT INTO XXFC_INV_DEVOLUCION_ALMACEN  (SA,PLAZA,CR,CLAVE_ACTIVO,NUMERO_SALIDA,MONTO,FECHA_SALIDA, TIPO_DE_USO,
                                                      GRUPO_O_KIT,ES_GRUPO_KIT,CREATION_DATE,CREATION_BY,LAST_UPDATED_DATE,LAST_UPDATED_BY,STATUS_INVENTARIO)
                  VALUES (salidas.SA,devs.plaza,devs.CR,salidas.clave_activo,devs.numero_salida,(devs.monto*devs.cantidad),salidas.fecha_salida,
                       salidas.tipo_uso,salidas.GRUPO_O_KIT,'GRUPO',SYSDATE,1,SYSDATE,1,'P');
            END IF;
-----            dbms_output.put_line('..'||sal||'..');
-----         END LOOP;
         END LOOP;
---------- Procesa Salidas de KITS
         FOR salidas IN FA_SALIDAS_KITS(devs.numero_salida, devs.line_id, devs.item_id ) LOOP
            dbms_output.put_line(RPAD ('SA', 10, ' ') || RPAD ('Activo', 10, ' ')|| RPAD ('FechaSalida', 15, ' ')||
                                  RPAD ('Articulo', 10, ' ') || RPAD ('Cantidad', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('Grupo/Kit', 15, ' '));
            dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' '));
            dbms_output.put_line(RPAD (salidas.SA, 10, ' ')|| RPAD (salidas.clave_activo, 10, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')||
                                 RPAD (salidas.articulo, 10, ' ')|| RPAD (salidas.cantidad, 10, ' ')|| RPAD (salidas.monto, 15, ' ')|| RPAD (salidas.grupo_o_kit, 15, ' '));
            dbms_output.put_line('..');
            dbms_output.put_line(RPAD ('SA', 10, ' ') || RPAD ('Plaza', 10, ' ')|| RPAD ('CR', 15, ' ')||
                                 RPAD ('activo', 10, ' ') || RPAD ('Salida', 10, ' ')|| RPAD ('Monto', 15, ' ')|| RPAD ('fecha_salida', 15, ' ')||
                                 RPAD ('tipo_uso', 10, ' ') || RPAD ('GPO/KIT', 10, ' '));
            dbms_output.put_line(RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' ')|| RPAD ('--------', 15, ' ')|| RPAD ('-----------', 15, ' ')||
                                 RPAD ('---------', 10, ' ')|| RPAD ('---------', 10, ' '));
            FOR sal IN 1..devs.cantidad LOOP
               dbms_output.put_line(RPAD (salidas.SA, 10, ' ')|| RPAD (devs.plaza, 10, ' ')|| RPAD (devs.CR, 15, ' ')||
                                 RPAD (salidas.clave_activo, 10, ' ')|| RPAD (devs.numero_salida, 10, ' ')|| RPAD (devs.monto, 15, ' ')|| RPAD (salidas.fecha_salida, 15, ' ')||
                                 RPAD (salidas.tipo_uso, 15, ' ')|| RPAD (salidas.GRUPO_O_KIT, 15, ' '));
               SELECT count(*) INTO w_count
                 FROM  XXFC_INV_DEVOLUCION_ALMACEN
                WHERE sa            = salidas.sa
                  AND plaza         = devs.plaza
                  AND cr            = devs.cr
                  AND clave_activo  = salidas.clave_activo
--                  AND numero_salida = devs.numero_salida
                  AND numero_activo  = sal;
               IF w_count = 1 THEN
                  IF salidas.msi_attribute8_mae_YN = 'Y' THEN
                     UPDATE xxfc_inv_devolucion_almacen SET monto = monto + devs.monto, va_padre = 'Y'
                      WHERE sa            = salidas.SA
                        AND plaza         = devs.plaza
                        AND cr            = devs.CR
                        AND clave_activo  = salidas.clave_activo
--                        AND numero_salida = devs.numero_salida
                        AND numero_activo  = sal ;
                  ELSE
                     UPDATE xxfc_inv_devolucion_almacen SET monto = monto + devs.monto
                      WHERE sa            = salidas.SA
                        AND plaza         = devs.plaza
                        AND cr            = devs.CR
                        AND clave_activo  = salidas.clave_activo
--                        AND numero_salida = devs.numero_salida
                        AND numero_activo  = sal ;
                  END IF;
               ELSE
                  INSERT INTO XXFC_INV_DEVOLUCION_ALMACEN
                         (SA,PLAZA,CR,CLAVE_ACTIVO,NUMERO_SALIDA,MONTO,FECHA_SALIDA, TIPO_DE_USO,
                          GRUPO_O_KIT,ES_GRUPO_KIT,VA_PADRE,CREATION_DATE,CREATION_BY,LAST_UPDATED_DATE,LAST_UPDATED_BY,NUMERO_ACTIVO,STATUS_INVENTARIO)
                  VALUES (salidas.SA,devs.plaza,devs.CR,salidas.clave_activo,devs.numero_salida,devs.monto,salidas.fecha_salida,
                       salidas.tipo_uso,salidas.grupo_o_kit,'KIT',salidas.msi_attribute8_mae_YN,SYSDATE,1,SYSDATE,1,sal,'I');
               END IF;
---            dbms_output.put_line('..'||sal||'..');
            END LOOP;
         END LOOP;
      END LOOP;
      UPDATE xxfc_inv_devolucion_almacen SET status_inventario = 'P', numero_activo = NULL
      WHERE status_inventario = 'I';
      EXCEPTION
         WHEN OTHERS
         THEN
            p_retcode := 1;
            fnd_file.put_line (fnd_file.LOG, '=======================================================');
            fnd_file.put_line (fnd_file.LOG, 'ERROR Procesando Devoluciones :');
            fnd_file.put_line (fnd_file.LOG, SQLERRM);
            fnd_file.put_line (fnd_file.LOG, '* * * * * * * * * * * * * * * * * * * * * * * * * *');
   END Devoluciones;

END xxinv_item_fixed_asset_web_pkg;
/